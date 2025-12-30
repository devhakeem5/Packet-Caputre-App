package com.example.packet_capture

import android.content.Intent
import android.content.pm.PackageManager
import android.net.VpnService
import android.os.ParcelFileDescriptor
import android.util.Log
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException
import java.net.InetSocketAddress
import java.nio.ByteBuffer
import java.nio.channels.DatagramChannel
import java.nio.channels.SelectionKey
import java.nio.channels.Selector
import java.nio.channels.SocketChannel
import java.util.concurrent.ConcurrentHashMap
import kotlin.concurrent.thread

class VpnService : VpnService() {

    companion object {
        const val TAG = "PacketCaptureVpn"
        var isRunning = false
        var selectedPackageName: String? = null
    }

    private var vpnInterface: ParcelFileDescriptor? = null
    private var selector: Selector? = null
    private lateinit var connectivityManager: android.net.ConnectivityManager
    
    // Key: SourceIP:SourcePort:DestIP:DestPort
    private val udpTable = ConcurrentHashMap<String, DatagramChannel>()
    private val tcpTable = ConcurrentHashMap<String, TcpSession>()
    
    // DNS and Connection tracking
    private val dnsCache = ConcurrentHashMap<String, String>() // IP -> Domain
    private val connectionData = ConcurrentHashMap<String, ConnectionTracker>() // Connection key -> Tracker

    // Proxy Server
    private var proxyServer: HttpProxyServer? = null
    private val PROXY_PORT = 8080


    private class TcpSession(
        val channel: SocketChannel,
        val key: String,
        var clientSeq: Long,
        var clientAck: Long,
        var serverSeq: Long,
        var serverAck: Long
    )
    
    private class ConnectionTracker(
        val connectionKey: String,
        val startTime: Long,
        var totalBytesSent: Int = 0,
        var totalBytesReceived: Int = 0,
        var serverName: String? = null, // SNI from TLS
        var httpHost: String? = null, // Host from HTTP
        var httpPath: String? = null,
        var httpMethod: String? = null,
        val requestHeaders: MutableMap<String, String> = mutableMapOf(),
        var lastActivityTime: Long = System.currentTimeMillis(),
        var eventSent: Boolean = false, // To avoid duplicate events
        var appInfo: Map<String, Any>? = null
    )

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "STOP") {
            stopVpn()
            return START_NOT_STICKY
        }
        
        selectedPackageName = intent?.getStringExtra("SELECTED_PACKAGE")
        
        if (!isRunning) {
            startVpn()
        }
        return START_STICKY
    }

    override fun onDestroy() {
        stopVpn()
        super.onDestroy()
    }

    private fun startVpn() {
        try {
            connectivityManager = getSystemService(android.content.Context.CONNECTIVITY_SERVICE) as android.net.ConnectivityManager
            
            val builder = Builder()
            builder.setSession("PacketCapture")
            builder.addAddress("10.0.0.2", 24)
            builder.addRoute("0.0.0.0", 0)
            builder.setMtu(1280)
            builder.addDnsServer("8.8.8.8")
            
            // DO NOT use addAllowedApplication() - it restricts traffic and breaks connectivity
            // Instead, we'll capture ALL traffic and filter in Flutter based on selected apps
            
            vpnInterface = builder.establish()
            isRunning = true
            selector = Selector.open()

            startTrafficLoop()
            
            // Start Local HTTP Proxy
            proxyServer = HttpProxyServer(PROXY_PORT) { socket ->
                this.protect(socket)
            }
            proxyServer?.start(applicationContext)

            Log.d(TAG, "VPN Started - Monitoring all traffic")
        } catch (e: Exception) {
            Log.e(TAG, "Error starting VPN", e)
            stopVpn()
        }
    }

    private fun stopVpn() {
        isRunning = false
        try {
            selector?.wakeup() // Wake up selector to exit loop
            vpnInterface?.close()
            selector?.close()
            udpTable.values.forEach { try { it.close() } catch (e: Exception) {} }
            udpTable.clear()
            tcpTable.values.forEach { try { it.channel.close() } catch (e: Exception) {} }
            tcpTable.clear()
            proxyServer?.stop()
            proxyServer = null
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping VPN", e)
        }
        vpnInterface = null
    }

    private fun startTrafficLoop() {
        // 1. Thread for Reading from TUN -> Network
        thread(start = true) {
            val fis = FileInputStream(vpnInterface?.fileDescriptor)
            // FIX: Buffer for READING from TUN must be large enough to hold the full packet (MTU 1280).
            // Apps send packets up to MTU size. If we use 1024, we truncate them.
            // But when WRITING to TUN (from network), we must match MTU.
            val buffer = ByteBuffer.allocate(32767)

            while (isRunning && vpnInterface != null) {
                try {
                    val length = fis.read(buffer.array())
                    if (length > 0) {
                        buffer.limit(length)
                        buffer.position(0)
                        processPacket(buffer, length)
                        buffer.clear()
                    } else if (length == -1) {
                        Log.w(TAG, "TUN interface closed")
                        break
                    }
                } catch (e: IOException) {
                   if (isRunning) {
                       Log.e(TAG, "TUN Read Error", e)
                       // Don't break on error, continue reading
                   }
                }
            }
            Log.d(TAG, "TUN read thread exiting")
        }

        // 2. Thread for Reading from Network -> TUN (Selector)
        thread(start = true) {
            while (isRunning && selector != null && selector!!.isOpen) {
                try {
                    // Log.d(TAG, "Selector waiting...")
                    val readyChannels = selector!!.select(1000) // Wait 1s max
                    if (readyChannels == 0) continue
                    
                    val keys = selector!!.selectedKeys()
                    val iterator = keys.iterator()
                    
                    while (iterator.hasNext()) {
                        val key = iterator.next()
                        iterator.remove()
                        
                        if (!key.isValid) continue
                        
                        if (key.isReadable) {
                            if (key.channel() is DatagramChannel) {
                                handleUdpRead(key)
                            } else {
                                handleTcpRead(key)
                            }
                        } else if (key.isConnectable) {
                            handleTcpConnect(key)
                        }
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Selector Loop Error", e)
                }
            }
        }
    }

    private fun processPacket(buffer: ByteBuffer, length: Int) {
        try {
            val data = buffer.array()
            val version = (data[0].toInt() shr 4) and 0x0F
            if (version != 4) {
                // Log.d(TAG, "Ignoring non-IPv4 packet (version: $version)")
                return // IPv4 only
            }

            val headerLength = (data[0].toInt() and 0x0F) * 4
            // Sanity check
            if (headerLength < 20) {
                 Log.e(TAG, "Invalid IP Header Length: $headerLength")
                 return
            }
            val protocol = data[9].toInt()
            val srcIp = ipToString(data, 12)
            val destIp = ipToString(data, 16)

            // Log packet reception for debugging
            if (protocol == 6 || protocol == 17) {
                Log.d(TAG, "Processing packet: protocol=$protocol, src=$srcIp, dest=$destIp, size=$length")
            }

            // Capture Request Event (Simplified)
            val meta = mutableMapOf<String, Any>(
                "timestamp" to System.currentTimeMillis(),
                "protocol" to (if (protocol == 6) "TCP" else if (protocol == 17) "UDP" else "OTHER"),
                "srcIp" to srcIp,
                "destIp" to destIp,
                "size" to length
            )

            when (protocol) {
                17 -> handleUdpPacket(buffer, headerLength, srcIp, destIp, meta)
                6 -> handleTcpPacket(buffer, headerLength, srcIp, destIp, meta)
                else -> {
                    Log.d(TAG, "Ignoring protocol: $protocol")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error processing packet", e)
        }
    }
    
    // --- UDP HANDLING ---

    private fun handleUdpPacket(buffer: ByteBuffer, ipHeaderLen: Int, srcIp: String, destIp: String, meta: MutableMap<String, Any>) {
        val data = buffer.array()
        val srcPort = ((data[ipHeaderLen].toInt() and 0xFF) shl 8) or (data[ipHeaderLen + 1].toInt() and 0xFF)
        val destPort = ((data[ipHeaderLen + 2].toInt() and 0xFF) shl 8) or (data[ipHeaderLen + 3].toInt() and 0xFF)
        
        val udpHeaderLen = 8
        val payloadLen = buffer.limit() - ipHeaderLen - udpHeaderLen
        
        // Only emit if there's actual payload
        if (payloadLen <= 0) {
            Log.d(TAG, "UDP packet with no payload, skipping: $srcPort->$destPort")
            return
        }
        
        // UDP Blocking removed to allow connectivity. 
        // QUIC traffic will be passed through as UDP (encrypted).

        meta["srcPort"] = srcPort
        meta["destPort"] = destPort
        meta["method"] = "UDP"
        meta["url"] = "$destIp:$destPort"
        meta["domain"] = destIp
        meta["direction"] = "outgoing"
        meta["payloadSize"] = payloadLen
        
        Log.d(TAG, "UDP packet: $srcPort->$destPort, payload=$payloadLen bytes")
        
        // Enhance Meta
        fillAppInfo(srcPort, "udp", meta)
        if (destPort == 53) meta["domain"] = "DNS"
        
        // Emit event - always send, Flutter will filter
        TrafficHandler.sendPacket(meta)
        Log.d(TAG, "✓ Sent UDP packet event: port=$srcPort, payload=$payloadLen, package=${meta["package"] ?: "unknown"}")
        
        val key = "$srcIp:$srcPort:$destIp:$destPort"
        var channel = udpTable[key]
        
        try {
            if (channel == null) {
                channel = DatagramChannel.open()
                channel.configureBlocking(false)
                val protected = protect(channel.socket())
                Log.d(TAG, "UDP Protect Result for $key: $protected")
                
                if (!protected) {
                    Log.e(TAG, "Failed to protect UDP socket for $key - Closing to prevent loop")
                    channel.close()
                    return
                }

                channel.connect(InetSocketAddress(destIp, destPort))
                if (channel.isConnected) {
                     Log.d(TAG, "UDP Channel Connected to $destIp:$destPort")
                } else {
                     Log.e(TAG, "UDP Channel FAILED to Connect to $destIp:$destPort")
                }

                selector?.wakeup()
                channel.register(selector, SelectionKey.OP_READ, key)
                udpTable[key] = channel
            }
            
            // Forward payload
            buffer.position(ipHeaderLen + udpHeaderLen)
            val written = channel.write(buffer)
            Log.d(TAG, "UDP Write to Network: $written bytes (Expected: ${buffer.remaining() + written})")

        } catch (e: Exception) {
            Log.e(TAG, "UDP Error", e)
        }
    }

    private fun handleUdpRead(key: SelectionKey) {
        val channel = key.channel() as DatagramChannel
        // CRITICAL FIX: Increased buffer to fit in larger MTU/packets (QUIC/DNS/etc)
        val buffer = ByteBuffer.allocate(32767)
        try {
            val bytesRead = channel.read(buffer)
            if (bytesRead > 0) {
                buffer.flip()
                val mapKey = key.attachment() as String
                val parts = mapKey.split(":")
                val srcIp = parts[2]
                val destIp = parts[0] 
                val srcPort = parts[3].toInt()
                val destPort = parts[1].toInt()

                // Emit incoming response event
                val meta = mutableMapOf<String, Any>(
                    "timestamp" to System.currentTimeMillis(),
                    "protocol" to "UDP",
                    "srcIp" to srcIp,
                    "destIp" to destIp,
                    "srcPort" to srcPort,
                    "destPort" to destPort,
                    "method" to "UDP",
                    "url" to "$srcIp:$srcPort",
                    "domain" to srcIp,
                    "direction" to "incoming",
                    "payloadSize" to bytesRead,
                    "size" to bytesRead
                )
                Log.d(TAG, "UDP response: $srcPort->$destPort, bytes=$bytesRead")
                
                fillAppInfo(destPort, "udp", meta)
                if (srcPort == 53) meta["domain"] = "DNS"
                
                // Emit event - always send, Flutter will filter
                TrafficHandler.sendPacket(meta)
                Log.d(TAG, "✓ Sent UDP response event: port=$destPort, bytes=$bytesRead, package=${meta["package"] ?: "unknown"}")

                writeIpPacket(srcIp, destIp, 17, srcPort, destPort, buffer)
            }
        } catch (e: Exception) {
            Log.e(TAG, "UDP Read Error", e)
        }
    }

    // --- TCP HANDLING (Minimal Proxy) ---

    private fun handleTcpPacket(buffer: ByteBuffer, ipHeaderLen: Int, srcIp: String, destIp: String, meta: MutableMap<String, Any>) {
        val data = buffer.array()
        val srcPort = ((data[ipHeaderLen].toInt() and 0xFF) shl 8) or (data[ipHeaderLen + 1].toInt() and 0xFF)
        val destPort = ((data[ipHeaderLen + 2].toInt() and 0xFF) shl 8) or (data[ipHeaderLen + 3].toInt() and 0xFF)
        val seq = getInt(data, ipHeaderLen + 4)
        val ack = getInt(data, ipHeaderLen + 8)
        val flags = data[ipHeaderLen + 13].toInt()
        
        val tcpHeaderLen = ((data[ipHeaderLen + 12].toInt() shr 4) and 0x0F) * 4
        val payloadLen = buffer.limit() - ipHeaderLen - tcpHeaderLen
        
        val isSyn = (flags and 0x02) != 0
        val isPsh = (flags and 0x08) != 0
        val isFin = (flags and 0x01) != 0
        val isAck = (flags and 0x10) != 0
        
        // Determine protocol based on port
        val protocol = when {
            destPort == 80 || srcPort == 80 -> "HTTP"
            destPort == 443 || srcPort == 443 -> "HTTPS"
            else -> "TCP"
        }
        
        val key = "$srcIp:$srcPort:$destIp:$destPort"
        var session = tcpTable[key]
        
        // Get or create connection tracker
        var tracker = connectionData[key]
        if (tracker == null && (payloadLen > 0 || isSyn)) {
            tracker = ConnectionTracker(
                connectionKey = key,
                startTime = System.currentTimeMillis()
            )
            
            // Capture App Info immediately while connection is active
            val tempMeta = mutableMapOf<String, Any>(
                "srcIp" to srcIp, "destIp" to destIp, "srcPort" to srcPort, "destPort" to destPort
            )
            fillAppInfo(srcPort, "tcp", tempMeta)
            tracker.appInfo = tempMeta.filterKeys { it == "uid" || it == "package" || it == "appName" || it == "isSystemApp" || it == "appIcon" }
            
            connectionData[key] = tracker
        }

        try {
            if (isSyn) {
                // SYN packet - connection setup
                if (session == null) {
                    Log.d(TAG, "Creating new TCP session: $key")
                    val channel = SocketChannel.open()
                    channel.configureBlocking(false)
                    val protected = protect(channel.socket())
                    Log.d(TAG, "TCP Protect Result (SYN): $protected")
                    
                    if (!protected) {
                        Log.e(TAG, "Failed to protect TCP socket (SYN) - Closing")
                        channel.close()
                        return
                    }

                    if (destPort == 80 || destPort == 443) {
                        Log.d(TAG, "Routing Traffic (Port $destPort) to Local Proxy (Port $PROXY_PORT)")
                        channel.connect(InetSocketAddress("127.0.0.1", PROXY_PORT))
                        
                        // Register session metadata
                        // We need to wait for connect to finish? 
                        // Actually, local port is assigned on connect. 
                        // But since it's non-blocking, connect() might return false.
                        // However, the local port IS assigned.
                        val localPort = channel.socket().localPort
                        if (localPort != -1) {
                            val appMeta = mutableMapOf<String, String>()
                            tracker?.let { t ->
                                val info = t.appInfo
                                if (info != null) {
                                    appMeta["package"] = info["package"] as? String ?: ""
                                    appMeta["appName"] = info["appName"] as? String ?: ""
                                    appMeta["uid"] = info["uid"]?.toString() ?: ""
                                } else {
                                    appMeta["package"] = meta["package"] as? String ?: ""
                                    appMeta["appName"] = meta["appName"] as? String ?: ""
                                    appMeta["uid"] = meta["uid"]?.toString() ?: ""
                                }
                            }
                            HttpProxyServer.registerSession(localPort, appMeta)
                            Log.d(TAG, "Registered Proxy Session: LocalPort $localPort -> ${appMeta["package"]}")
                        }
                    } else {
                        channel.connect(InetSocketAddress(destIp, destPort))
                    }
                    selector?.wakeup()
                    channel.register(selector, SelectionKey.OP_CONNECT, key)
                    
                    session = TcpSession(channel, key, seq + 1, 0, 0, 0)
                    tcpTable[key] = session
                    Log.d(TAG, "TCP session created: $key, total: ${tcpTable.size}")
                }
            } else {
                // Handle data packets
                if (session == null && payloadLen > 0 && !isSyn) {
                    // Late packet with data, create session
                    val channel = SocketChannel.open()
                    channel.configureBlocking(false)
                    val protected = protect(channel.socket())
                    
                    if (!protected) {
                        Log.e(TAG, "Failed to protect TCP socket (Late) - Closing")
                        channel.close()
                        return
                    }

                    if (destPort == 80 || destPort == 443) {
                        channel.connect(InetSocketAddress("127.0.0.1", PROXY_PORT))
                         val localPort = channel.socket().localPort
                        if (localPort != -1) {
                            val appMeta = mutableMapOf<String, String>()
                            // Use tracker info if available (it should be, as we just created/retrieved tracker)
                             val info = connectionData[key]?.appInfo
                             if (info != null) {
                                 appMeta["package"] = info["package"] as? String ?: ""
                                 appMeta["appName"] = info["appName"] as? String ?: ""
                                 appMeta["uid"] = info["uid"]?.toString() ?: ""
                                 HttpProxyServer.registerSession(localPort, appMeta)
                             } else {
                                val pkg = meta["package"] as? String
                                if (pkg != null) {
                                    appMeta["package"] = pkg
                                    appMeta["appName"] = meta["appName"] as? String ?: ""
                                    appMeta["uid"] = meta["uid"].toString()
                                    HttpProxyServer.registerSession(localPort, appMeta)
                                }
                             }
                        }
                    } else {
                        channel.connect(InetSocketAddress(destIp, destPort))
                    }
                    selector?.wakeup()
                    channel.register(selector, SelectionKey.OP_CONNECT, key)
                    
                    session = TcpSession(channel, key, seq, 0, 0, 0)
                    tcpTable[key] = session
                }
                
                if (session != null && payloadLen > 0) {
                    // Update tracker
                    tracker?.totalBytesSent = (tracker?.totalBytesSent ?: 0) + payloadLen
                    tracker?.lastActivityTime = System.currentTimeMillis()
                    
                    // Extract payload for analysis
                    val payloadStart = ipHeaderLen + tcpHeaderLen
                    val payload = ByteArray(payloadLen)
                    System.arraycopy(data, payloadStart, payload, 0, payloadLen)
                    
                    // Try to extract information from payload
                    if (destPort == 443 || srcPort == 443) {
                        // Try to extract SNI from TLS ClientHello
                        extractSNI(payload, tracker)
                    } else if (destPort == 80 || srcPort == 80) {
                        // Try to parse HTTP
                        parseHttpRequest(payload, tracker)
                    }
                    
                    // Forward data ONLY if channel is connected
                    if (session.channel.isConnected) {
                        buffer.position(payloadStart)
                        val bytesWritten = session.channel.write(buffer)
                        session.clientSeq += payloadLen
                    } else {
                        // Queue data for later or wait for connection
                        Log.d(TAG, "Channel not yet connected, skipping write for $key")
                    }
                    
                    // Send event only once per connection (when we have meaningful data)
                    // Send event only once per connection (when we have meaningful data)
                    // For Port 80 (HTTP) and 443 (HTTPS), the Proxy emits the event, so we skip it here to avoid duplication/noise
                    if (tracker != null && !tracker.eventSent && shouldSendEvent(tracker) && destPort != 80 && srcPort != 80 && destPort != 443 && srcPort != 443) {
                        sendAggregatedEvent(key, tracker, srcIp, destIp, srcPort, destPort, protocol, meta)
                        tracker.eventSent = true
                    }
                    
                    // ACK this data
                    sendTcpPacket(session, destIp, srcIp, destPort, srcPort, 0x10, null)
                } else if (isFin) {
                    Log.d(TAG, "TCP FIN received, closing session: $key")
                    session?.channel?.close()
                    tcpTable.remove(key)
                    // Clean up tracker after some delay or send final event if not sent
                    tracker?.let {
                        if (!it.eventSent && it.totalBytesSent > 0) {
                            sendAggregatedEvent(key, it, srcIp, destIp, srcPort, destPort, protocol, meta)
                        }
                    }
                    connectionData.remove(key)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "TCP Error for $key", e)
             // Check if we need to clean up proxy session
             // access session?.channel?.socket()?.localPort
             try {
                session?.channel?.socket()?.localPort?.let { 
                    HttpProxyServer.unregisterSession(it) 
                }
             } catch(ex: Exception) {}
            tcpTable.remove(key)
        }
    }
    
    private fun handleTcpConnect(key: SelectionKey) {
        val channel = key.channel() as SocketChannel
        val keyStr = key.attachment() as String
        val session = tcpTable[keyStr] ?: return
        
        try {
            if (channel.finishConnect()) {
                key.interestOps(SelectionKey.OP_READ)
                // Connection Established. 
                // Send SYN-ACK to Client (TUN)
                // Parse IP from key
                val parts = keyStr.split(":")
                // srcIp = parts[0], srcPort=parts[1], ...
                // Remember: Key is Client->Server. Response is Server->Client.
                // Response Src = Server IP (parts[2]), Response Dest = Client IP (parts[0])
                
                // Initialize Server Sequence
                session.serverSeq = 1000 // Random start
                session.serverAck = session.clientSeq 
                
                // Send SYN-ACK (Flags: SYN=0x02, ACK=0x10 -> 0x12)
                sendTcpPacket(session, parts[2], parts[0], parts[3].toInt(), parts[1].toInt(), 0x12, null)
                session.serverSeq++ // SYN consumes 1
            }
        } catch (e: Exception) {
            key.cancel()
            tcpTable.remove(keyStr)
        }
    }

    private fun handleTcpRead(key: SelectionKey) {
        val channel = key.channel() as SocketChannel
        val keyStr = key.attachment() as String
        val session = tcpTable[keyStr] ?: return
        // CRITICAL FIX: Reduce buffer to fit in MTU
        val buffer = ByteBuffer.allocate(1024)
        
        try {
            val bytesRead = channel.read(buffer)
            if (bytesRead == -1) {
                // FIN received from remote
                val parts = keyStr.split(":")
                sendTcpPacket(session, parts[2], parts[0], parts[3].toInt(), parts[1].toInt(), 0x11, null) // FIN+ACK
                channel.close()
                tcpTable.remove(keyStr)
                
                // Clean up connection tracker
                connectionData.remove(keyStr)
                
                // Unregister Proxy Session
                try {
                     HttpProxyServer.unregisterSession(channel.socket().localPort)
                } catch(e: Exception) {}
                
                return
            }
            if (bytesRead > 0) {
                buffer.flip()
                val parts = keyStr.split(":")
                val srcIp = parts[2]
                val destIp = parts[0]
                val srcPort = parts[3].toInt()
                val destPort = parts[1].toInt()
                
                // Update connection tracker with received bytes
                val tracker = connectionData[keyStr]
                tracker?.totalBytesReceived = (tracker?.totalBytesReceived ?: 0) + bytesRead
                tracker?.lastActivityTime = System.currentTimeMillis()
                
                // Determine protocol based on port
                val protocol = when {
                    srcPort == 80 || destPort == 80 -> "HTTP"
                    srcPort == 443 || destPort == 443 -> "HTTPS"
                    else -> "TCP"
                }
                
                // Don't send separate incoming events - they're handled by aggregated events
                // Just forward the data back to the app
                Log.d(TAG, "TCP response: $srcPort->$destPort, bytes=$bytesRead, protocol=$protocol")
                
                // PSH+ACK (0x08 + 0x10 = 0x18)
                sendTcpPacket(session, srcIp, destIp, srcPort, destPort, 0x18, buffer)
            }
        } catch (e: Exception) {
            Log.e(TAG, "TCP Read Error", e)
            tcpTable.remove(keyStr)
            connectionData.remove(keyStr)
        }
    }

    // --- PACKET CONSTRUCTION HELPERS ---

    private fun writeIpPacket(srcIp: String, destIp: String, protocol: Int, srcPort: Int, destPort: Int, payload: ByteBuffer?) {
        try {
            if (vpnInterface == null) return
            val fos = FileOutputStream(vpnInterface?.fileDescriptor)
            
            val payloadLen = payload?.remaining() ?: 0
            val ipHeaderLen = 20
            val udpHeaderLen = 8
            val totalLen = ipHeaderLen + udpHeaderLen + payloadLen
            
            val packet = ByteBuffer.allocate(totalLen)
            
            // IP Header
            packet.put(0x45)
            packet.put(0x00)
            packet.putShort(totalLen.toShort())
            packet.putShort(0) // ID
            packet.putShort(0x4000) // No frag
            packet.put(64) // TTL
            packet.put(protocol.toByte())
            packet.putShort(0) // IP Checksum Placeholder
            packet.put(parseIp(srcIp))
            packet.put(parseIp(destIp))
            
            // Calculate IP Checksum
            val ipChecksum = computeChecksum(packet, 0, 20)
            packet.putShort(10, ipChecksum.toShort())
            
            // UDP Header
            packet.putShort(srcPort.toShort())
            packet.putShort(destPort.toShort())
            packet.putShort((udpHeaderLen + payloadLen).toShort())
            packet.putShort(0)
            
            if (payload != null) packet.put(payload)
            
            fos.write(packet.array())
        } catch (e: Exception) {
             Log.e(TAG, "Write Error", e)
        }
    }
    
    private fun sendTcpPacket(session: TcpSession, srcIp: String, destIp: String, srcPort: Int, destPort: Int, flags: Int, payload: ByteBuffer?) {
        try {
            if (vpnInterface == null) return
            val fos = FileOutputStream(vpnInterface?.fileDescriptor)
            
            val payloadLen = payload?.remaining() ?: 0
            val ipHeaderLen = 20
            val tcpHeaderLen = 20
            val totalLen = ipHeaderLen + tcpHeaderLen + payloadLen
            
            val packet = ByteBuffer.allocate(totalLen)
            
            // IP Header
            packet.put(0x45)
            packet.put(0x00)
            packet.putShort(totalLen.toShort())
            packet.putShort(0)
            packet.putShort(0x4000)
            packet.put(64)
            packet.put(6) // TCP
            packet.putShort(0) // IP Checksum
            packet.put(parseIp(srcIp))
            packet.put(parseIp(destIp))
            
            // Calculate IP Checksum (Standard requirement, though TUN might forgive it, better safe)
            val ipChecksum = computeChecksum(packet, 0, 20)
            packet.putShort(10, ipChecksum.toShort())

            // TCP Header
            val tcpStart = 20
            packet.position(tcpStart)
            packet.putShort(srcPort.toShort())
            packet.putShort(destPort.toShort())
            packet.putInt(session.serverSeq.toInt())
            packet.putInt(session.clientSeq.toInt())
            packet.putShort((0x5000 or flags).toShort())
            packet.putShort(0x7FFF)
            packet.putShort(0) // TCP Checksum placeholder
            packet.putShort(0)
            
            if (payload != null) packet.put(payload)
            
            // Calculate TCP Checksum
            val tcpChecksum = calculateTcpChecksum(srcIp, destIp, packet.array(), tcpStart, tcpHeaderLen + payloadLen)
            packet.putShort(tcpStart + 16, tcpChecksum.toShort())

            fos.write(packet.array())
            
            session.serverSeq += payloadLen
        } catch (e: Exception) {
             Log.e(TAG, "Write TCP Error", e)
        }
    }

    private fun calculateTcpChecksum(srcIp: String, destIp: String, data: ByteArray, offset: Int, length: Int): Int {
        var sum = 0
        
        // Pseudo Header
        // Source IP
        val src = parseIp(srcIp)
        for (i in 0 until 4 step 2) {
             sum += ((src[i].toInt() and 0xFF) shl 8) or (src[i+1].toInt() and 0xFF)
        }
        // Dest IP
        val dest = parseIp(destIp)
        for (i in 0 until 4 step 2) {
             sum += ((dest[i].toInt() and 0xFF) shl 8) or (dest[i+1].toInt() and 0xFF)
        }
        // Reserved + Protocol
        sum += 6 // TCP
        // TCP Length
        sum += length
        
        // TCP Header + Data
        return computeChecksum(ByteBuffer.wrap(data), offset, length, sum)
    }

    private fun computeChecksum(buffer: ByteBuffer, offset: Int, length: Int, initialSum: Int = 0): Int {
        var sum = initialSum
        val data = buffer.array()
        
        for (i in 0 until length step 2) {
            if (i == length - 1) {
                sum += (data[offset + i].toInt() and 0xFF) shl 8
            } else {
                sum += ((data[offset + i].toInt() and 0xFF) shl 8) or (data[offset + i + 1].toInt() and 0xFF)
            }
        }
        
        while ((sum shr 16) > 0) {
            sum = (sum and 0xFFFF) + (sum shr 16)
        }
        return sum.inv() and 0xFFFF
    }

    private fun parseIp(ip: String): ByteArray {
        return ip.split(".").map { it.toInt().toByte() }.toByteArray()
    }

    private fun ipToString(data: ByteArray, offset: Int): String {
        return "${data[offset].toInt() and 0xFF}.${data[offset+1].toInt() and 0xFF}.${data[offset+2].toInt() and 0xFF}.${data[offset+3].toInt() and 0xFF}"
    }

    private fun getInt(data: ByteArray, offset: Int): Long {
         return ((data[offset].toLong() and 0xFF) shl 24) or
                ((data[offset+1].toLong() and 0xFF) shl 16) or
                ((data[offset+2].toLong() and 0xFF) shl 8) or
                (data[offset+3].toLong() and 0xFF)
    }

    private fun fillAppInfo(port: Int, protocol: String, meta: MutableMap<String, Any>) {
        // Updated to support modern Android APIs
        // We need SrcIP and DestIP for Q+ API, but here we just have Port.
        // For outgoing (packets we capture from app -> VPN -> Internet):
        // Src Port is the App's port. Src IP is 10.0.0.2.
        // Dest Port is random server port.
        
        // Wait, for getConnectionOwnerUid we need the CONNECTION tuple.
        // protocol: IPPROTO_TCP or UDP
        // local: (SrcIP, SrcPort)
        // remote: (DestIP, DestPort)
        
        // We have these in the meta map or caller!
        val srcIp = meta["srcIp"] as? String
        val destIp = meta["destIp"] as? String
        val srcPort = meta["srcPort"] as? Int
        val destPort = meta["destPort"] as? Int
        
        var uid: Int? = null
        
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q && 
            srcIp != null && destIp != null && srcPort != null && destPort != null) {
            try {
                val protocolInt = if (protocol.lowercase() == "tcp") 6 else 17
                val localAddress = java.net.InetAddress.getByName(srcIp)
                val remoteAddress = java.net.InetAddress.getByName(destIp)
                
                val localSock = InetSocketAddress(localAddress, srcPort)
                val remoteSock = InetSocketAddress(remoteAddress, destPort)
                
                uid = connectivityManager.getConnectionOwnerUid(protocolInt, localSock, remoteSock)
                
                // Retry with wildcard 0.0.0.0 if failed (sometimes connections are bound to ANY)
                if (uid == null || uid == -1) {
                     val wildcardSock = InetSocketAddress("0.0.0.0", srcPort)
                     uid = connectivityManager.getConnectionOwnerUid(protocolInt, wildcardSock, remoteSock)
                }

                if (uid != null && uid != -1) {
                     Log.d(TAG, "Found Connection Owner UID: $uid")
                }
            } catch (e: Exception) {
                // Log.w(TAG, "Failed C.M. lookup: ${e.message}")
            }
        }
        
        if ((uid == null || uid == -1)) {
             // Fallback
             uid = getUidForPortImproved(protocol, port)
        }
        
        if (uid != null && uid >= 10000) { // Only user apps (UID >= 10000)
            meta["uid"] = uid
            getNameForUid(uid)?.let { 
                meta["package"] = it 
                meta["appName"] = getAppName(it)
                meta["isSystemApp"] = isSystemApp(it)
                
                // Add app icon as base64 string
                getAppIconBase64(it)?.let { iconBase64 ->
                    meta["appIcon"] = iconBase64
                }
                
                Log.d(TAG, "Found app: $it for port $port")
            } ?: run {
                Log.d(TAG, "UID $uid found but no package name")
            }
        } else {
            // Even if we can't identify the app, we'll still send the event
            // Flutter will filter it if needed
            Log.d(TAG, "Could not identify app for port $port (protocol: $protocol)")
            // Mark as likely system if UID < 10000 or unknown
             if (uid != null && uid < 10000) {
                 meta["isSystemApp"] = true
             }
        }
    }
    
    // Read UID from /proc/net files (original method)
    private fun getUidForPort(protocol: String, port: Int): Int? {
        return try {
            val procFile = when (protocol.lowercase()) {
                "tcp" -> "/proc/net/tcp"
                "udp" -> "/proc/net/udp"
                else -> return null
            }
            
            val file = java.io.File(procFile)
            if (!file.exists() || !file.canRead()) {
                Log.d(TAG, "Cannot read $procFile")
                return null
            }
            
            file.readLines().forEach { line ->
                if (line.startsWith("sl") || line.trim().isEmpty()) return@forEach
                
                val parts = line.trim().split("\\s+".toRegex())
                if (parts.size < 10) return@forEach
                
                // Parse local address (format: IP:PORT in hex)
                val localAddr = parts[1]
                val addrParts = localAddr.split(":")
                if (addrParts.size != 2) return@forEach
                
                val portHex = addrParts[1]
                val portNum = portHex.toIntOrNull(16) ?: return@forEach
                
                if (portNum == port) {
                    // UID is typically the 7th field (index 7)
                    val uid = parts[7].toIntOrNull()
                    if (uid != null && uid >= 10000) {
                        Log.d(TAG, "Found UID $uid for port $port in $procFile")
                        return uid
                    }
                }
            }
            null
        } catch (e: Exception) {
            Log.e(TAG, "Error reading /proc/net for port $port", e)
            null
        }
    }
    
    // Improved method: Use ConnectivityManager for Android Q+ (API 29+)
    // Fallback to /proc/net only for older devices
    private fun getUidForPortImproved(protocol: String, port: Int): Int? {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
            try {
                // We need Source & Dest to look up the connection owner.
                // But here we only have the "Local Port" (which is Source Port in the packet).
                // The ConnectionOwnerUid API requires complete tuple (Src IP, Src Port, Dest IP, Dest Port).
                // We don't have that in this helper function's signature yet.
                // We will rely on the "fillAppInfo" call passing more data?
                // Actually, let's keep it simple for now and stick to /proc/net for < Q, 
                // but for Q+, /proc/net is restricted.
                // To function correctly on Q+, we MUST pass the full tuple.
                return null // Placeholder until we update call site
            } catch (e: Exception) {
                Log.e(TAG, "Error getting UID from ConnectivityManager", e)
            }
        }
        return readProcNet(protocol, port)
    }

    private fun readProcNet(protocol: String, port: Int): Int? {
        return try {
             val procFile = when (protocol.lowercase()) {
                "tcp" -> "/proc/net/tcp"
                "udp" -> "/proc/net/udp"
                else -> return null
            }
            
            val file = java.io.File(procFile)
            if (!file.exists() || !file.canRead()) return null
            
            // Read lines using useLines for efficient streaming and valid return
            return file.useLines { lines ->
                for (line in lines) {
                    // Parsing logic...
                    val parts = line.trim().split(Regex("\\s+"))
                    if (parts.size >= 10) {
                         val localAddr = parts[1] // IP:PORT
                         val addrParts = localAddr.split(":")
                         if (addrParts.size == 2) {
                             val portHex = addrParts[1]
                             val portNum = portHex.toIntOrNull(16)
                             if (portNum == port) {
                                 val uidStr = parts[7]
                                 val uid = uidStr.toIntOrNull()
                                 if (uid != null && uid >= 10000) {
                                     return@useLines uid
                                 }
                             }
                         }
                    }
                }
                null
            }
        } catch (e: Exception) {
            null
        }
    }
    
    private fun getNameForUid(uid: Int): String? {
        return packageManager.getPackagesForUid(uid)?.firstOrNull()
    }
    
    private fun getAppName(packageName: String): String {
        return try {
            val info = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(info).toString()
        } catch (e: Exception) {
            packageName
        }
    }
    
    private fun getAppIconBase64(packageName: String): String? {
        return try {
            val info = packageManager.getApplicationInfo(packageName, 0)
            val icon = packageManager.getApplicationIcon(info)
            
            // Convert drawable to bitmap then to base64
            val bitmap = android.graphics.Bitmap.createBitmap(
                icon.intrinsicWidth,
                icon.intrinsicHeight,
                android.graphics.Bitmap.Config.ARGB_8888
            )
            val canvas = android.graphics.Canvas(bitmap)
            icon.setBounds(0, 0, canvas.width, canvas.height)
            icon.draw(canvas)
            
            val outputStream = java.io.ByteArrayOutputStream()
            bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, outputStream)
            val byteArray = outputStream.toByteArray()
            
            "data:image/png;base64," + android.util.Base64.encodeToString(byteArray, android.util.Base64.NO_WRAP)
        } catch (e: Exception) {
            null
        }
    }
      private fun isSystemApp(packageName: String): Boolean {
        return try {
            val info = packageManager.getApplicationInfo(packageName, 0)
            (info.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0
        } catch (e: Exception) {
            false
        }
    }
    
    // --- Helper Functions for Enhanced Parsing ---
    
    private fun extractSNI(payload: ByteArray, tracker: ConnectionTracker?) {
        try {
            if (payload.size < 43) return // Too small for TLS ClientHello
            
            // Check if it's a TLS Handshake (0x16) and ClientHello (0x01)
            if (payload[0] != 0x16.toByte()) return
            if (payload.size < 6) return
            
            val contentType = payload[0].toInt() and 0xFF
            val handshakeType = payload[5].toInt() and 0xFF
            
            if (contentType != 0x16 || handshakeType != 0x01) return
            
            // Parse TLS ClientHello to find SNI
            var pos = 43 // Skip fixed headers
            
            // Skip session ID
            if (pos >= payload.size) return
            val sessionIdLen = payload[pos].toInt() and 0xFF
            pos += 1 + sessionIdLen
            
            // Skip cipher suites
            if (pos + 2 >= payload.size) return
            val cipherSuitesLen = ((payload[pos].toInt() and 0xFF) shl 8) or (payload[pos + 1].toInt() and 0xFF)
            pos += 2 + cipherSuitesLen
            
            // Skip compression methods
            if (pos >= payload.size) return
            val compressionLen = payload[pos].toInt() and 0xFF
            pos += 1 + compressionLen
            
            // Extensions
            if (pos + 2 >= payload.size) return
            val extensionsLen = ((payload[pos].toInt() and 0xFF) shl 8) or (payload[pos + 1].toInt() and 0xFF)
            pos += 2
            
            val extensionsEnd = pos + extensionsLen
            while (pos + 4 <= extensionsEnd && pos + 4 < payload.size) {
                val extType = ((payload[pos].toInt() and 0xFF) shl 8) or (payload[pos + 1].toInt() and 0xFF)
                val extLen = ((payload[pos + 2].toInt() and 0xFF) shl 8) or (payload[pos + 3].toInt() and 0xFF)
                pos += 4
                
                if (extType == 0x0000) { // SNI extension
                    if (pos + 5 <= payload.size) {
                        val listLen = ((payload[pos].toInt() and 0xFF) shl 8) or (payload[pos + 1].toInt() and 0xFF)
                        val nameType = payload[pos + 2].toInt() and 0xFF
                        val nameLen = ((payload[pos + 3].toInt() and 0xFF) shl 8) or (payload[pos + 4].toInt() and 0xFF)
                        
                        if (nameType == 0 && pos + 5 + nameLen <= payload.size) {
                            val serverName = String(payload, pos + 5, nameLen, Charsets.UTF_8)
                            tracker?.serverName = serverName
                            Log.d(TAG, "Extracted SNI: $serverName")
                            return
                        }
                    }
                }
                pos += extLen
            }
        } catch (e: Exception) {
            Log.w(TAG, "Error extracting SNI: ${e.message}")
        }
    }
    
    private fun parseHttpRequest(payload: ByteArray, tracker: ConnectionTracker?) {
        try {
            val request = String(payload, Charsets.UTF_8)
            val lines = request.split("\r\n")
            
            if (lines.isEmpty()) return
            
            // Parse request line (GET /path HTTP/1.1)
            val requestLine = lines[0]
            val parts = requestLine.split(" ")
            if (parts.size >= 2) {
                tracker?.httpMethod = parts[0]
                tracker?.httpPath = parts[1]
                Log.d(TAG, "HTTP: ${parts[0]} ${parts[1]}")
            }
            
            // Parse headers
            for (i in 1 until lines.size) {
                val line = lines[i]
                if (line.isEmpty()) break // End of headers
                
                val colonIndex = line.indexOf(":")
                if (colonIndex > 0) {
                    val key = line.substring(0, colonIndex).trim()
                    val value = line.substring(colonIndex + 1).trim()
                    
                    if (key.equals("Host", ignoreCase = true)) {
                        tracker?.httpHost = value
                        Log.d(TAG, "HTTP Host: $value")
                    }
                    
                    tracker?.requestHeaders?.put(key, value)
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "Error parsing HTTP: ${e.message}")
        }
    }
    
    private fun shouldSendEvent(tracker: ConnectionTracker): Boolean {
        // Send event more aggressively to ensure traffic is captured
        // Even small amounts of data should trigger event for better user experience
        return tracker.totalBytesSent > 0 || // Any payload
               tracker.serverName != null || // SNI extracted
               tracker.httpHost != null // HTTP Host found
    }
    
    private fun sendAggregatedEvent(
        key: String, 
        tracker: ConnectionTracker,
        srcIp: String,
        destIp: String, 
        srcPort: Int,
        destPort: Int,
        protocol: String,
        baseMeta: MutableMap<String, Any>
    ) {
        val meta = mutableMapOf<String, Any>(
            "timestamp" to tracker.startTime,
            "protocol" to protocol,
            "srcIp" to srcIp,
            "destIp" to destIp,
            "srcPort" to srcPort,
            "destPort" to destPort,
            "method" to (tracker.httpMethod ?: protocol),
            "direction" to "outgoing",
            "payloadSize" to tracker.totalBytesSent,
            "size" to tracker.totalBytesSent
        )
        
        // Build better URL and domain
        val domain = tracker.serverName ?: tracker.httpHost ?: dnsCache[destIp] ?: destIp
        val path = tracker.httpPath ?: ""
        
        val url = when {
            tracker.httpHost != null -> "http://${tracker.httpHost}$path"
            tracker.serverName != null -> "https://${tracker.serverName}$path"
            dnsCache.containsKey(destIp) -> "${protocol.lowercase()}://${dnsCache[destIp]}:$destPort"
            else -> "${protocol.lowercase()}://$destIp:$destPort"
        }
        
        meta["url"] = url
        meta["domain"] = domain
        
        // Add headers if available
        if (tracker.requestHeaders.isNotEmpty()) {
            meta["requestHeaders"] = tracker.requestHeaders.toMap()
        }
        
        // Fill app info
        // Fill app info (use cached if available, otherwise try to resolve)
        if (tracker.appInfo != null && tracker.appInfo!!.isNotEmpty()) {
            meta.putAll(tracker.appInfo!!)
        } else {
            fillAppInfo(srcPort, "tcp", meta)
        }
        
        TrafficHandler.sendPacket(meta)
        Log.d(TAG, "✓ Sent aggregated event: $url (${tracker.totalBytesSent}B)")
    }
    
    private fun handleDnsResponse(payload: ByteArray, srcIp: String) {
        try {
            // Simple DNS response parser 
            if (payload.size < 12) return
            
            val flags = ((payload[2].toInt() and 0xFF) shl 8) or (payload[3].toInt() and 0xFF)
            val isResponse = (flags and 0x8000) != 0
            
            if (!isResponse) return
            
            val answerCount = ((payload[6].toInt() and 0xFF) shl 8) or (payload[7].toInt() and 0xFF)
            if (answerCount == 0) return
            
            // Parse domain name and IP from DNS response
            // This is a simplified parser - full DNS parsing is complex
            var pos = 12
            
            // Skip question section
            while (pos < payload.size) {
                val len = payload[pos].toInt() and 0xFF
                if (len == 0) {
                    pos += 5 // Skip null terminator + QTYPE + QCLASS
                    break
                }
                pos += len + 1
            }
            
            // Parse answer section (simplified - only A records)
            if (pos + 14 <= payload.size) {
                // We could parse the full answer, but for now just log
                Log.d(TAG, "DNS response received, caching IP mappings")
            }
        } catch (e: Exception) {
            Log.w(TAG, "Error parsing DNS: ${e.message}")
        }
    }
}
