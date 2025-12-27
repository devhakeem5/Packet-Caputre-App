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
            val builder = Builder()
            builder.setSession("PacketCapture")
            builder.addAddress("10.0.0.2", 24)
            builder.addRoute("0.0.0.0", 0)
            builder.setMtu(1280)
            
            if (selectedPackageName != null) {
                try {
                    builder.addAllowedApplication(selectedPackageName!!)
                } catch (e: PackageManager.NameNotFoundException) {
                    Log.e(TAG, "Package not found: $selectedPackageName")
                }
            }

            vpnInterface = builder.establish()
            isRunning = true
            selector = Selector.open()

            startTrafficLoop()
            
            Log.d(TAG, "VPN Started")
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
            val buffer = ByteBuffer.allocate(32767)

            while (isRunning && vpnInterface != null) {
                try {
                    val length = fis.read(buffer.array())
                    if (length > 0) {
                        buffer.limit(length)
                        buffer.position(0)
                        processPacket(buffer, length)
                        buffer.clear()
                    }
                } catch (e: IOException) {
                   if (isRunning) Log.e(TAG, "TUN Read Error", e)
                }
            }
        }

        // 2. Thread for Reading from Network -> TUN (Selector)
        thread(start = true) {
            while (isRunning && selector != null && selector!!.isOpen) {
                try {
                    if (selector!!.select() == 0) continue
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
        val data = buffer.array()
        val version = (data[0].toInt() shr 4) and 0x0F
        if (version != 4) return // IPv4 only

        val headerLength = (data[0].toInt() and 0x0F) * 4
        val protocol = data[9].toInt()
        val srcIp = ipToString(data, 12)
        val destIp = ipToString(data, 16)

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
            else -> {} // Ignore other protocols
        }
    }
    
    // --- UDP HANDLING ---

    private fun handleUdpPacket(buffer: ByteBuffer, ipHeaderLen: Int, srcIp: String, destIp: String, meta: MutableMap<String, Any>) {
        val data = buffer.array()
        val srcPort = ((data[ipHeaderLen].toInt() and 0xFF) shl 8) or (data[ipHeaderLen + 1].toInt() and 0xFF)
        val destPort = ((data[ipHeaderLen + 2].toInt() and 0xFF) shl 8) or (data[ipHeaderLen + 3].toInt() and 0xFF)
        
        meta["srcPort"] = srcPort
        meta["destPort"] = destPort
        meta["method"] = "UDP"
        meta["url"] = "$destIp:$destPort"
        meta["domain"] = destIp
        
        // Enhance Meta
        fillAppInfo(srcPort, "udp", meta)
        if (destPort == 53) meta["domain"] = "DNS"
        
        TrafficHandler.sendPacket(meta) // SEND TO FLUTTER
        
        val key = "$srcIp:$srcPort:$destIp:$destPort"
        var channel = udpTable[key]
        
        try {
            if (channel == null) {
                channel = DatagramChannel.open()
                channel.configureBlocking(false)
                protect(channel.socket()) // CRITICAL: Protect socket
                channel.connect(InetSocketAddress(destIp, destPort))
                channel.register(selector, SelectionKey.OP_READ, key)
                udpTable[key] = channel
            }
            
            // Payload
            val udpHeaderLen = 8
            val payloadLen = buffer.limit() - ipHeaderLen - udpHeaderLen
            if (payloadLen > 0) {
                buffer.position(ipHeaderLen + udpHeaderLen)
                channel.write(buffer)
            }
        } catch (e: Exception) {
            Log.e(TAG, "UDP Error", e)
        }
    }

    private fun handleUdpRead(key: SelectionKey) {
        val channel = key.channel() as DatagramChannel
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
        
        meta["srcPort"] = srcPort
        meta["destPort"] = destPort
        meta["method"] = "TCP"
        meta["url"] = "$destIp:$destPort"
        meta["domain"] = destIp
        fillAppInfo(srcPort, "tcp", meta)

        // Only emit new connection events to avoid spam, or emit all? User wants traffic.
        // Let's emit all logic packets (SYN/PUSH).
        val isSyn = (flags and 0x02) != 0
        val isPsh = (flags and 0x08) != 0
        val isFin = (flags and 0x01) != 0
        
        if (isSyn || isPsh || isFin) {
             TrafficHandler.sendPacket(meta) // SEND TO FLUTTER
        }

        val key = "$srcIp:$srcPort:$destIp:$destPort"
        var session = tcpTable[key]

        try {
            if (isSyn) {
                if (session == null) {
                    val channel = SocketChannel.open()
                    channel.configureBlocking(false)
                    protect(channel.socket()) // CRITICAL
                    channel.connect(InetSocketAddress(destIp, destPort))
                    channel.register(selector, SelectionKey.OP_CONNECT, key)
                    
                    session = TcpSession(channel, key, seq + 1, 0, 0, 0)
                    tcpTable[key] = session
                    
                    // Respond with UDP-like SYN-ACK handled via local flow? 
                    // To keep strictly minimal, we wait for connect to succeed then send SYN-ACK.
                    // But client will retry SYN. That's fine.
                }
            } else if (session != null) {
                // DATA Transfer (PSH or just ACK with data)
                val tcpHeaderLen = ((data[ipHeaderLen + 12].toInt() shr 4) and 0x0F) * 4
                val dataLen = buffer.limit() - ipHeaderLen - tcpHeaderLen
                
                if (dataLen > 0) {
                     buffer.position(ipHeaderLen + tcpHeaderLen)
                     session.channel.write(buffer)
                     session.clientSeq += dataLen // Track sequence
                     // ACK this data
                     sendTcpPacket(session, destIp, srcIp, destPort, srcPort, 0x10, null) // ACK
                } else if (isFin) {
                    session.channel.close()
                    tcpTable.remove(key)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "TCP Error", e)
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
        val buffer = ByteBuffer.allocate(32767)
        
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
                // PSH+ACK (0x08 + 0x10 = 0x18)
                sendTcpPacket(session, parts[2], parts[0], parts[3].toInt(), parts[1].toInt(), 0x18, buffer)
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
        val uid = getUidForPort(protocol, port)
        if (uid != null) {
            meta["uid"] = uid
            getNameForUid(uid)?.let { 
                meta["package"] = it 
                meta["appName"] = getAppName(it)
            }
        }
    }
    
    // Stubbed helper methods for Proc reading (Requires actual implementation to work, but keeping structure)
    // For now returning null to not block connectivity
    private fun getUidForPort(protocol: String, port: Int): Int? = null
    
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
