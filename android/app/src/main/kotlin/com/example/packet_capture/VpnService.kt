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

    private class TcpSession(
        val channel: SocketChannel,
        val key: String,
        var clientSeq: Long,
        var clientAck: Long,
        var serverSeq: Long,
        var serverAck: Long
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
            
            // DO NOT use addAllowedApplication() - it restricts traffic and breaks connectivity
            // Instead, we'll capture ALL traffic and filter in Flutter based on selected apps
            
            vpnInterface = builder.establish()
            isRunning = true
            selector = Selector.open()

            startTrafficLoop()
            
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
        // CRITICAL FIX: Reduce buffer to fit in MTU
        val buffer = ByteBuffer.allocate(1024)
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
        
        meta["srcPort"] = srcPort
        meta["destPort"] = destPort
        meta["method"] = protocol
        meta["url"] = "$destIp:$destPort"
        meta["domain"] = destIp
        meta["direction"] = "outgoing"
        meta["payloadSize"] = payloadLen
        fillAppInfo(srcPort, "tcp", meta)

        val key = "$srcIp:$srcPort:$destIp:$destPort"
        var session = tcpTable[key]

        try {
            if (isSyn) {
                // SYN packet - connection setup, no data yet
                // Only create session, don't emit event (no payload)
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

                    channel.connect(InetSocketAddress(destIp, destPort))
                    channel.register(selector, SelectionKey.OP_CONNECT, key)
                    
                    session = TcpSession(channel, key, seq + 1, 0, 0, 0)
                    tcpTable[key] = session
                    Log.d(TAG, "TCP session created: $key, total: ${tcpTable.size}")
                }
            } else {
                // Handle data packets (PSH, ACK with data, etc.)
                if (session == null) {
                    // Session not found - might be a response or late packet
                    // Try to create session or find existing one
                    Log.d(TAG, "TCP packet without session: $key, flags: SYN=$isSyn PSH=$isPsh ACK=$isAck FIN=$isFin")
                    
                    // For data packets without session, try to create one
                    if (payloadLen > 0 && !isSyn) {
                        val channel = SocketChannel.open()
                        channel.configureBlocking(false)
                        val protected = protect(channel.socket())
                        Log.d(TAG, "TCP Protect Result (Late): $protected")
                        
                        if (!protected) {
                            Log.e(TAG, "Failed to protect TCP socket (Late) - Closing")
                            channel.close()
                            return // Or continue without session, but usually bad.
                        }

                        channel.connect(InetSocketAddress(destIp, destPort))
                        channel.register(selector, SelectionKey.OP_CONNECT, key)
                        
                        session = TcpSession(channel, key, seq, 0, 0, 0)
                        tcpTable[key] = session
                        Log.d(TAG, "Created late TCP session: $key")
                    }
                }
                
                if (session != null) {
                    // DATA Transfer - emit if there's actual payload
                    if (payloadLen > 0) {
                        buffer.position(ipHeaderLen + tcpHeaderLen)
                        val bytesWritten = session.channel.write(buffer)
                        session.clientSeq += payloadLen
                        
                        Log.d(TAG, "TCP data: port=$srcPort->$destPort, payload=$payloadLen bytes, written=$bytesWritten")
                        
                        // Emit event - Flutter will filter based on selected apps
                        TrafficHandler.sendPacket(meta)
                        Log.d(TAG, "✓ Sent TCP packet event: port=$srcPort, payload=$payloadLen, package=${meta["package"] ?: "unknown"}")
                        
                        // ACK this data
                        sendTcpPacket(session, destIp, srcIp, destPort, srcPort, 0x10, null) // ACK
                    } else if (isFin) {
                        Log.d(TAG, "TCP FIN received, closing session: $key")
                        session.channel.close()
                        tcpTable.remove(key)
                    } else if (isAck && !isPsh) {
                        // Pure ACK without data - just forward, don't emit
                        Log.d(TAG, "TCP pure ACK (no data): $key")
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "TCP Error for $key", e)
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
                return
            }
            if (bytesRead > 0) {
                buffer.flip()
                val parts = keyStr.split(":")
                val srcIp = parts[2]
                val destIp = parts[0]
                val srcPort = parts[3].toInt()
                val destPort = parts[1].toInt()
                
                // Determine protocol based on port
                val protocol = when {
                    srcPort == 80 || destPort == 80 -> "HTTP"
                    srcPort == 443 || destPort == 443 -> "HTTPS"
                    else -> "TCP"
                }
                
                Log.d(TAG, "TCP response: $srcPort->$destPort, bytes=$bytesRead, protocol=$protocol")
                
                // Emit incoming response event
                val meta = mutableMapOf<String, Any>(
                    "timestamp" to System.currentTimeMillis(),
                    "protocol" to protocol,
                    "srcIp" to srcIp,
                    "destIp" to destIp,
                    "srcPort" to srcPort,
                    "destPort" to destPort,
                    "method" to protocol,
                    "url" to "$srcIp:$srcPort",
                    "domain" to srcIp,
                    "direction" to "incoming",
                    "payloadSize" to bytesRead,
                    "size" to bytesRead
                )
                fillAppInfo(destPort, "tcp", meta)
                
                // Emit event - always send, Flutter will filter
                TrafficHandler.sendPacket(meta)
                Log.d(TAG, "✓ Sent TCP response event: port=$destPort, bytes=$bytesRead, package=${meta["package"] ?: "unknown"}")
                
                // PSH+ACK (0x08 + 0x10 = 0x18)
                sendTcpPacket(session, srcIp, destIp, srcPort, destPort, 0x18, buffer)
            }
        } catch (e: Exception) {
            Log.e(TAG, "TCP Read Error", e)
            tcpTable.remove(keyStr)
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
                Log.d(TAG, "Found app: $it for port $port")
            } ?: run {
                Log.d(TAG, "UID $uid found but no package name")
            }
        } else {
            // Even if we can't identify the app, we'll still send the event
            // Flutter will filter it if needed
            Log.d(TAG, "Could not identify app for port $port (protocol: $protocol)")
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
}
