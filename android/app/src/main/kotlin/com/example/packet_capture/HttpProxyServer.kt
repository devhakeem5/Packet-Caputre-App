package com.example.packet_capture

import android.content.Context
import android.util.Log
import java.io.InputStream
import java.io.OutputStream
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.ServerSocket
import java.net.Socket
import java.util.concurrent.Executors
import javax.net.ssl.SSLContext
import javax.net.ssl.SSLSocket
import java.security.SecureRandom
import javax.net.ssl.KeyManagerFactory
import javax.net.ssl.TrustManagerFactory
import javax.net.ssl.X509TrustManager
import java.security.cert.X509Certificate
import kotlin.concurrent.thread

class HttpProxyServer(private val port: Int, private val protectSocket: (Socket) -> Boolean) {

    companion object {
        const val TAG = "HttpProxyServer"
        private val sessionMap = java.util.concurrent.ConcurrentHashMap<Int, Map<String, String>>()

        fun registerSession(port: Int, meta: Map<String, String>) {
            sessionMap[port] = meta
        }

        fun unregisterSession(port: Int) {
            sessionMap.remove(port)
        }
    }

    private var serverSocket: ServerSocket? = null
    @Volatile private var isRunning = false
    private val executor = Executors.newCachedThreadPool()

    fun start(context: Context) {
        if (isRunning) return
        isRunning = true

        CertificateGenerator.init(context)

        thread(start = true) {
            try {
                // Listen only on localhost
                serverSocket = ServerSocket(port, 50, InetAddress.getByName("127.0.0.1"))
                Log.d(TAG, "HTTP Proxy started on 127.0.0.1:$port")

                while (isRunning) {
                    try {
                        val clientSocket = serverSocket?.accept() ?: break
                        executor.submit { handleClient(clientSocket) }
                    } catch (e: Exception) {
                        if (isRunning) Log.e(TAG, "Accept error", e)
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Server start error", e)
            } finally {
                stop()
            }
        }
    }

    fun stop() {
        isRunning = false
        try {
            serverSocket?.close()
        } catch (e: Exception) {}
        serverSocket = null
    }

    private fun handleClient(clientSocket: Socket) {
        try {
            val clientPort = clientSocket.port
            val appMeta = sessionMap[clientPort]
            
            // Check for Transparent Mode driven by VpnService mapping
            if (appMeta != null) {
                val destHost = appMeta["destHost"] ?: appMeta["destIp"]
                val destPort = appMeta["destPort"]?.toIntOrNull() ?: 443
                
                Log.d(TAG, "Handling Transparent Connection from port $clientPort to $destHost:$destPort")
                
                if (destPort == 443) {
                    handleTransparentHttps(clientSocket, destHost!!, destPort, appMeta)
                } else {
                    // Transparent HTTP is currently not routed here by default logic, but if so:
                    tunnelConnection(clientSocket, destHost!!, destPort, appMeta, false) 
                }
                return
            }

            // Fallback to Standard Proxy Mode (if used explicitly)
            Log.d(TAG, "Handling Standard Proxy Connection from port $clientPort (No session map)")
            handleStandardProxy(clientSocket)
            
        } catch (e: Exception) {
            Log.e(TAG, "Client Handling Error", e)
            try { clientSocket.close() } catch (e2: Exception) {}
        } finally {
            // Clean up session map if we are done? 
            // VpnService usually manages functionality, but we can remove it to keep map clean if strictly 1-1
            // But keep it safe for now.
             val clientPort = clientSocket.port
             sessionMap.remove(clientPort)
        }
    }
    
    // --- TRANSPARENT HTTPS HANDLING ---
    
    private fun handleTransparentHttps(
        clientSocket: Socket,
        destHost: String,
        destPort: Int,
        appMeta: Map<String, String>?
    ) {
        try {
            // 1. TLS Handshake (Server Mode)
            // We do NOT send 200 Connection Established because the client expects a TLS handshake immediately.
            
            val sslContext = CertificateGenerator.getSslContextForHost(destHost)
            val sslSocketFactory = sslContext.socketFactory
            val sslClientSocket = sslSocketFactory.createSocket(clientSocket, null, clientSocket.port, false) as SSLSocket
            sslClientSocket.useClientMode = false 
            
            // Handshake
            sslClientSocket.startHandshake()
            Log.d(TAG, "TLS Handshake Success (Transparent) for $destHost")
            
            // 2. Connect Upstream and Relay
            handleDecryptedSession(sslClientSocket, destHost, destPort, appMeta)
            
        } catch (e: Exception) {
             Log.e(TAG, "TLS Handshake Failed for $destHost: ${e.message}")
             // Fallback to Tunnel not easily possible here because we likely already consumed bytes/alerted.
             // But we can try relying on the fact that VpnService handles fallback if we close? 
             // No, VpnService considers it established.
             // We just close.
        }
    }
    
    // --- DECRYPTED SESSION (CORE ASYNC RELAY) ---
    
    private fun handleDecryptedSession(
        clientSslSocket: Socket,
        destHost: String,
        destPort: Int,
        appMeta: Map<String, String>?
    ) {
        var targetSocket: Socket? = null
        try {
             // 1. Connect Upstream (Client Mode)
             val plainSocket = Socket()
             if (!protectSocket(plainSocket)) {
                 throw Exception("Failed to protect upstream socket")
             }
             plainSocket.connect(InetSocketAddress(destHost, destPort), 10000)
             
             // Wrap with TLS
             val sslContext = SSLContext.getInstance("TLS")
             // Trust all or system? Using null trusts default system certs.
             sslContext.init(null, null, null) 
             val factory = sslContext.socketFactory
             targetSocket = factory.createSocket(plainSocket, destHost, destPort, true) as SSLSocket
             (targetSocket as SSLSocket).startHandshake()
             Log.d(TAG, "Upstream TLS Success for $destHost")

             // 2. Async Bidirectional Relay
             val clientIn = clientSslSocket.getInputStream()
             val clientOut = clientSslSocket.getOutputStream()
             val targetIn = targetSocket.getInputStream()
             val targetOut = targetSocket.getOutputStream()
             
             // We need separate threads for full duplex
             val clientToServer = thread(start = true) {
                 relayStream(clientIn, targetOut, "request", destHost, destPort, appMeta)
             }
             
             val serverToClient = thread(start = true) {
                 relayStream(targetIn, clientOut, "response", destHost, destPort, appMeta)
             }
             
             clientToServer.join()
             serverToClient.join()
             
        } catch (e: Exception) {
            Log.e(TAG, "Decrypted Session Error ($destHost)", e)
        } finally {
            try { clientSslSocket.close() } catch(e: Exception){}
            try { targetSocket?.close() } catch(e: Exception){}
        }
    }
    
    private fun relayStream(
        input: InputStream, 
        output: OutputStream, 
        direction: String, // "request" or "response"
        host: String,
        port: Int,
        appMeta: Map<String, String>?
    ) {
        val buffer = ByteArray(32768)
        
        // BUFFERING FOR PARSING
        // We accumulate bytes to try and parse HTTP messages. 
        // We must be careful not to buffer indefinitely.
        val parseBuffer = java.io.ByteArrayOutputStream()
        var parsed = false
        
        try {
            while (true) {
                val read = input.read(buffer)
                if (read == -1) break
                
                // 1. Forward immediately (Transparent)
                output.write(buffer, 0, read)
                output.flush()
                
                // 2. Side-Channel Parsing
                // Currently only supported if we haven't successfully parsed enough yet or if we want to stream body
                // For simplicity, we parse headers and some body, then stop adding to parseBuffer to avoid OOM
                if (parseBuffer.size() < 1024 * 1024) { // 1MB limit for parsing consideration
                    parseBuffer.write(buffer, 0, read)
                    attemptParse(parseBuffer, direction, host, port, appMeta)
                }
            }
        } catch (e: Exception) {
            // Stream closed or error
        }
    }
    
    // --- VISIBILITY / PARSING LOGIC ---
    // This is similar to processBufferedData in VpnService
    
    private fun attemptParse(
        bufferStream: java.io.ByteArrayOutputStream,
        direction: String,
        host: String,
        port: Int,
        appMeta: Map<String, String>?
    ) {
        val data = bufferStream.toByteArray()
        if (data.isEmpty()) return
        
        // Simple state check: Have we emitted an event for this stream yet?
        // Ideally we track state. For now, we just try to parse a complete message at start.
        
        if (direction == "request") {
             if (isRequestStart(data)) {
                 tryParseAndEmitRequest(data, host, port, appMeta)
             }
        } else {
             if (isResponseStart(data)) {
                 tryParseAndEmitResponse(data, host, port, appMeta)
             }
        }
    }

    private fun isRequestStart(data: ByteArray): Boolean {
        if (data.size < 10) return false
        val start = String(data.take(10).toByteArray(), Charsets.UTF_8).uppercase()
        return start.startsWith("GET ") || start.startsWith("POST ") || start.startsWith("PUT ") || 
               start.startsWith("DELETE ") || start.startsWith("HEAD ") || start.startsWith("OPTIONS ")
    }
    
    private fun isResponseStart(data: ByteArray): Boolean {
        if (data.size < 10) return false
         val start = String(data.take(10).toByteArray(), Charsets.UTF_8).uppercase()
        return start.startsWith("HTTP/")
    }
    
    private fun tryParseAndEmitRequest(data: ByteArray, host: String, port: Int, appMeta: Map<String, String>?) {
        try {
            val headerEnd = findHeaderEnd(data)
            if (headerEnd == -1) return
            
            // We have headers
            val headerString = String(data.take(headerEnd).toByteArray(), Charsets.UTF_8)
            val lines = headerString.split("\r\n")
            if (lines.isEmpty()) return
            
            val reqLine = lines[0].split(" ")
            if (reqLine.size < 2) return
            val method = reqLine[0]
            val path = reqLine[1]
            
            val headers = parseHeaders(lines.drop(1))
            val contentLength = headers["Content-Length"]?.toIntOrNull() ?: 0
            
            val totalNeeded = headerEnd + 4 + contentLength
            var body: String? = null
            
            if (data.size >= totalNeeded && contentLength > 0) {
                 val bodyBytes = data.drop(headerEnd + 4).take(contentLength).toByteArray()
                 val ct = (headers["Content-Type"] ?: "").lowercase()
                 if (isBinaryContentType(ct)) {
                     body = "[Binary Data $contentLength bytes]"
                 } else {
                     body = String(bodyBytes, Charsets.UTF_8)
                 }
            }
            
            // Emit Event
            val meta = mutableMapOf<String, Any>(
                "id" to System.nanoTime().toString(),
                "timestamp" to System.currentTimeMillis(),
                "protocol" to "HTTPS",
                "method" to method,
                "url" to "https://$host$path", // Reconstruct URL
                "domain" to host,
                "requestHeaders" to headers,
                "source" to "mitm",
                "isDecrypted" to true
            )
            if (body != null) meta["requestBody"] = body
            
             appMeta?.let {
                meta["package"] = it["package"] ?: "unknown"
                meta["appName"] = it["appName"] ?: "Unknown"
                meta["uid"] = it["uid"]?.toIntOrNull() ?: 0
            }
            
            TrafficHandler.sendPacket(meta)
            // Clear buffer? No, stream continues. But we might duplicate events if we keep parsing.
            // In a real relay, we should mark as parsed.
            // For this simpler implementations, we rely on duplicate filtering or just accept it (since we parse from start).
            // To prevent duplicates: We need a state object passed to relayStream.
            
        } catch (e: Exception) {
            Log.e(TAG, "Request Parse Error", e)
        }
    }

    private fun tryParseAndEmitResponse(data: ByteArray, host: String, port: Int, appMeta: Map<String, String>?) {
         try {
            val headerEnd = findHeaderEnd(data)
            if (headerEnd == -1) return

            val headerString = String(data.take(headerEnd).toByteArray(), Charsets.UTF_8)
            val lines = headerString.split("\r\n")
             if (lines.isEmpty()) return
            
            val statusLine = lines[0].split(" ")
            if (statusLine.size < 2) return
            val statusCode = statusLine[1].toIntOrNull() ?: 200
            
            val headers = parseHeaders(lines.drop(1))
            val contentLength = headers["Content-Length"]?.toIntOrNull() ?: 0
            
            val totalNeeded = headerEnd + 4 + contentLength
            var body: String? = null
             if (data.size >= totalNeeded && contentLength > 0) {
                 val bodyBytes = data.drop(headerEnd + 4).take(contentLength).toByteArray()
                 val ct = (headers["Content-Type"] ?: "").lowercase()
                 if (isBinaryContentType(ct)) {
                     body = "[Binary Data $contentLength bytes]"
                 } else {
                     body = String(bodyBytes, Charsets.UTF_8)
                 }
            }

             val meta = mutableMapOf<String, Any>(
                 "timestamp" to System.currentTimeMillis(),
                 "statusCode" to statusCode,
                 "responseHeaders" to headers,
                 "source" to "mitm",
                 "isDecrypted" to true,
                 // To link to request, usually we need ID. 
                 // Here we just emit response info, UI usually merges by recent activity or domain.
                 "domain" to host,
                 "protocol" to "HTTPS"
             )
             if (body != null) meta["responseBody"] = body
             
             TrafficHandler.sendPacket(meta)

         } catch (e: Exception) {
             Log.e(TAG, "Response Parse Error", e)
         }
    }
    
    // --- STANDARD PROXY HANDLING (Legacy/Direct) ---
    
    private fun handleStandardProxy(clientSocket: Socket) {
        // Implement if needed for standard CONNECT support, reusing old logic logic but safer
        // For now, implementing basic CONNECT handling solely for completeness
        try {
             val clientIn = clientSocket.getInputStream()
             // Read headers...
             val requestLines = readHeaders(clientIn)
             if (requestLines.isEmpty()) return
             val parts = requestLines[0].split(" ")
             if (parts[0] == "CONNECT") {
                 val hostPort = parts[1]
                 val p = hostPort.split(":")
                 val host = p[0]
                 val port = if(p.size > 1) p[1].toInt() else 443
                 
                 val clientOut = clientSocket.getOutputStream()
                 clientOut.write("HTTP/1.1 200 Connection Established\r\n\r\n".toByteArray())
                 clientOut.flush()
                 
                 // Now act as decrypted session
                 // But we need to wrap the socket?
                 // Wait, handleDecryptedSession expects a connected SSL socket for client side?
                 // Yes. So we must wrap clientSocket first.
                  val sslContext = CertificateGenerator.getSslContextForHost(host)
                  val sslSocketFactory = sslContext.socketFactory
                  val sslClientSocket = sslSocketFactory.createSocket(clientSocket, null, clientSocket.port, false) as SSLSocket
                  sslClientSocket.useClientMode = false 
                  sslClientSocket.startHandshake()
                  
                  handleDecryptedSession(sslClientSocket, host, port, null)
             }
        } catch (e: Exception) {
            Log.e(TAG, "Standard Proxy Error", e)
        }
    }

    // --- HELPERS ---
    
    private fun tunnelConnection(
            clientSocket: Socket,
            host: String,
            port: Int,
            appMeta: Map<String, String>?,
            decrypted: Boolean
    ) {
        // Simple tunnel
        try {
            val targetSocket = Socket()
            if (!protectSocket(targetSocket)) return
            targetSocket.connect(InetSocketAddress(host, port), 10000)
            
            val t1 = thread(start = true) { try { clientSocket.getInputStream().copyTo(targetSocket.getOutputStream()) } catch(e: Exception){} }
            val t2 = thread(start = true) { try { targetSocket.getInputStream().copyTo(clientSocket.getOutputStream()) } catch(e: Exception){} }
            t1.join(); t2.join()
        } catch(e: Exception) {}
    }

    private fun readHeaders(inputStream: InputStream): List<String> {
        val lines = mutableListOf<String>()
        val buffer = StringBuilder()
        var c: Int
        var lastCr = false
        while (true) {
            c = inputStream.read()
            if (c == -1) break
            if (c == '\n'.code) {
                if (lastCr) {
                    val line = buffer.toString().trimEnd('\r')
                    if (line.isEmpty()) return lines
                    lines.add(line)
                    buffer.clear()
                    lastCr = false
                } else {
                    buffer.append(c.toChar())
                }
            } else if (c == '\r'.code) {
                lastCr = true
                buffer.append(c.toChar())
            } else {
                if (lastCr) lastCr = false
                buffer.append(c.toChar())
            }
            if (lines.size > 100 || buffer.length > 8192) break
        }
        return lines
    }

    private fun parseHeaders(lines: List<String>): Map<String, String> {
        val map = mutableMapOf<String, String>()
        for (line in lines) {
            val idx = line.indexOf(':')
            if (idx != -1) {
                val key = line.substring(0, idx).trim()
                val value = line.substring(idx + 1).trim()
                map[key] = value
            }
        }
        return map
    }
    
    private fun isBinaryContentType(contentType: String): Boolean {
        return contentType.contains("image/") ||
                contentType.contains("video/") ||
                contentType.contains("audio/") ||
                contentType.contains("application/pdf") ||
                contentType.contains("application/zip") ||
                contentType.contains("application/x-") ||
                contentType.contains("application/octet-stream") ||
                contentType.contains("font/") ||
                contentType.contains("application/vnd.") ||
                contentType.contains("multipart/form-data")
    }
    
    private fun findHeaderEnd(data: ByteArray): Int {
        for (i in 0 until data.size - 3) {
            if (data[i] == 13.toByte() && data[i + 1] == 10.toByte() &&
                data[i + 2] == 13.toByte() && data[i + 3] == 10.toByte()) return i
        }
        return -1
    }
}
