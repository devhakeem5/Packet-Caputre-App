package com.example.packet_capture

import android.content.Context
import android.util.Log
import java.io.InputStream
import java.io.OutputStream
import java.net.InetAddress
import java.net.ServerSocket
import java.net.Socket
import java.util.concurrent.Executors
import javax.net.ssl.SSLContext
import javax.net.ssl.SSLSocket
import kotlin.concurrent.thread
import kotlin.math.min

class HttpProxyServer(private val port: Int) {

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
        } catch (e: Exception) {
        }
        serverSocket = null
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

    private fun handleClient(clientSocket: Socket) {
        var targetSocket: Socket? = null
        try {
            val clientIn = clientSocket.getInputStream()
            val clientOut = clientSocket.getOutputStream()

            // 1. Read Request Headers
            val requestLines = readHeaders(clientIn)
            if (requestLines.isEmpty()) {
                clientSocket.close()
                return
            }

            // 2. Parse Request Method and Target Host
            val requestLine = requestLines[0] // "GET /path HTTP/1.1" or "CONNECT host:port HTTP/1.1"
            val parts = requestLine.split(" ")
            if (parts.size < 3) {
                clientSocket.close()
                return
            }
            val method = parts[0]
            val url = parts[1] // could be absolute or relative
            
            val headers = parseHeaders(requestLines.drop(1))
            val hostHeader = headers["Host"] ?: headers["host"]
            
            // Retrieve App Metadata using the client's connection port (which matches VPN Service's local port)
            val clientPort = clientSocket.port
            val appMeta = sessionMap[clientPort]
            
            if (method == "CONNECT") {
                handleHttpsConnect(clientSocket, url, appMeta)
                return 
            }
            
            // --- Standard HTTP Handling (GET/POST/etc) ---
            if (hostHeader == null) {
                Log.e(TAG, "No Host header found")
                clientSocket.close()
                return
            }
            
            // Handle Host: example.com:80
            val hostParts = hostHeader.split(":")
            val targetHost = hostParts[0]
            val targetPort = if (hostParts.size > 1) hostParts[1].toInt() else 80

            Log.d(TAG, "Proxying $method $url to $targetHost:$targetPort")

            // 3. Connect to Target
            targetSocket = Socket(targetHost, targetPort)
            val targetIn = targetSocket.getInputStream()
            val targetOut = targetSocket.getOutputStream()

            // 4. Forward Request
            val initialPayload = StringBuilder()
            requestLines.forEach { initialPayload.append(it).append("\r\n") }
            initialPayload.append("\r\n") // End of headers
            
            targetOut.write(initialPayload.toString().toByteArray())
            
            // If POST/PUT, we might have a body. Check Content-Length.
            val contentLength = (headers["Content-Length"] ?: headers["content-length"])?.toLongOrNull() ?: 0L
            
            // Capture Request Data
            val requestMeta = mutableMapOf<String, Any>(
                "id" to System.nanoTime().toString(),
                "timestamp" to System.currentTimeMillis(),
                "protocol" to "HTTP",
                "method" to method,
                "url" to "http://$hostHeader$url",
                "domain" to targetHost,
                "headers" to headers,
                "requestSize" to initialPayload.length + contentLength,
                "responseSize" to 0,
                "responseTime" to 0
            )

            // Inject App Metadata
            appMeta?.let {
                requestMeta["package"] = it["package"] ?: "unknown"
                requestMeta["appName"] = it["appName"] ?: "Unknown"
                requestMeta["uid"] = it["uid"]?.toIntOrNull() ?: 0
            }

            if (contentLength > 0) {
                 // Forward body
                 val buffer = ByteArray(4096)
                 var remaining = contentLength
                 val captureLimit = 16384 // 16KB limit
                 val bodyBuilder = java.io.ByteArrayOutputStream()
                 
                 while (remaining > 0) {
                     val count = clientIn.read(buffer, 0, Math.min(buffer.size.toLong(), remaining).toInt())
                     if (count == -1) break
                     targetOut.write(buffer, 0, count)
                     
                     if (bodyBuilder.size() < captureLimit) {
                         bodyBuilder.write(buffer, 0, Math.min(count, captureLimit - bodyBuilder.size()))
                     }
                     
                     remaining -= count
                 }
                 
                 // Check if content is binary based on request Content-Type
                 val contentType = (headers["Content-Type"] ?: headers["content-type"] ?: "").lowercase()
                 if (isBinaryContentType(contentType)) {
                     requestMeta["requestBody"] = "[Binary Data - ${bodyBuilder.size()} bytes]"
                 } else {
                     try {
                         requestMeta["requestBody"] = bodyBuilder.toString("UTF-8")
                     } catch (e: Exception) {
                         requestMeta["requestBody"] = "[Data - ${bodyBuilder.size()} bytes]"
                     }
                 }
            }

            // 5. Read Response
            val responseLines = readHeaders(targetIn)
            if (responseLines.isNotEmpty()) {
                val statusLine = responseLines[0]
                val responseHeaders = parseHeaders(responseLines.drop(1))
                
                // Reconstruct response headers
                val responseHeadBuffer = StringBuilder()
                responseLines.forEach { responseHeadBuffer.append(it).append("\r\n") }
                responseHeadBuffer.append("\r\n")
                
                clientOut.write(responseHeadBuffer.toString().toByteArray())
                
                requestMeta["statusCode"] = statusLine.split(" ").getOrNull(1)?.toIntOrNull() ?: 0
                requestMeta["responseTime"] = System.currentTimeMillis() - (requestMeta["timestamp"] as Long)
                requestMeta["responseHeaders"] = responseHeaders
                
                var totalBodyBytes = 0L
                val bodyBuilder = java.io.ByteArrayOutputStream() // For response
                val captureLimit = 16384
                
                // Pipe body
                val buffer = ByteArray(4096)
                var bytesRead: Int
                while (targetIn.read(buffer).also { bytesRead = it } != -1) {
                    clientOut.write(buffer, 0, bytesRead)
                    totalBodyBytes += bytesRead
                    
                    if (bodyBuilder.size() < captureLimit) {
                        bodyBuilder.write(buffer, 0, Math.min(bytesRead, captureLimit - bodyBuilder.size()))
                    }
                }
                
                // Check if response is binary
                val responseContentType = (responseHeaders["Content-Type"] ?: responseHeaders["content-type"] ?: "").lowercase()
                if (isBinaryContentType(responseContentType)) {
                    requestMeta["responseBody"] = "[Binary Data - ${bodyBuilder.size()} bytes]"
                } else {
                    try {
                        requestMeta["responseBody"] = bodyBuilder.toString("UTF-8")
                    } catch (e: Exception) {
                        requestMeta["responseBody"] = "[Data - ${bodyBuilder.size()} bytes]"
                    }
                }
                
                requestMeta["responseSize"] = responseHeadBuffer.length + totalBodyBytes
                
                // 6. Emit Event
                // Log only metadata for security (no bodies/headers in production)
                Log.d(TAG, "HTTP Request: $method $targetHost$urlPath - Status: ${requestMeta["statusCode"]} - Size: ${requestMeta["responseSize"]}B")
                TrafficHandler.sendPacket(requestMeta)
            } else {
                TrafficHandler.sendPacket(requestMeta) // failed request?
            }

        } catch (e: Exception) {
            Log.e(TAG, "Proxy handling error", e)
        } finally {
            try { clientSocket.close() } catch (e: Exception) {}
            try { targetSocket?.close() } catch (e: Exception) {}
        }
    }
    
    // --- HTTPS HANDLING ---
    
    private fun handleHttpsConnect(clientSocket: Socket, hostPort: String, appMeta: Map<String, String>?) {
        val parts = hostPort.split(":")
        val targetHost = parts[0]
        val targetPort = if (parts.size > 1) parts[1].toInt() else 443
        
        // 1. Respond 200 Connection Established
        try {
            val clientOut = clientSocket.getOutputStream()
            clientOut.write("HTTP/1.1 200 Connection Established\r\n\r\n".toByteArray())
            clientOut.flush()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send 200 OK", e)
            return
        }
        
        // 2. Attempt TLS Interception
        try {
            Log.d(TAG, "Attempting TLS Handshake for $targetHost")
            val sslContext = CertificateGenerator.getSslContextForHost(targetHost)
            val sslSocketFactory = sslContext.socketFactory
            val sslClientSocket = sslSocketFactory.createSocket(clientSocket, null, clientSocket.port, false) as SSLSocket
            sslClientSocket.useClientMode = false // We are Server
            
            // Handshake
            sslClientSocket.startHandshake()
            Log.d(TAG, "TLS Handshake Success for $targetHost")
            
            // --- DECRYPTED PATH ---
            handleDecryptedHttps(sslClientSocket, targetHost, targetPort, appMeta)
            
        } catch (e: Exception) {
            Log.w(TAG, "TLS Handshake Failed for $targetHost (${e.message}). Falling back to Tunnel. (Note: Fallback usually fails if handshake started)")
            // Try to fallback if possible, but the connection might be dirty.
            // In a real scenario, we would prefer to peek or handle this better.
            // For now, attempting fallback on the original socket.
             tunnelConnection(clientSocket, targetHost, targetPort, appMeta, decrypted=false)
        }
    }
    
    private fun handleDecryptedHttps(clientSslSocket: Socket, targetHost: String, targetPort: Int, appMeta: Map<String, String>?) {
        var targetSocket: SSLSocket? = null
        try {
            // Connect to Target as Client (SSL)
            val sslContext = SSLContext.getInstance("TLS")
            sslContext.init(null, null, null) // Default trust
            val factory = sslContext.socketFactory
            targetSocket = factory.createSocket(targetHost, targetPort) as SSLSocket
            targetSocket.startHandshake()
            
            val clientIn = clientSslSocket.getInputStream()
            val clientOut = clientSslSocket.getOutputStream()
            val targetIn = targetSocket.getInputStream()
            val targetOut = targetSocket.getOutputStream()
            
             while (true) {
                val requestLines = readHeaders(clientIn)
                if (requestLines.isEmpty()) break
                
                val requestLine = requestLines[0]
                val parts = requestLine.split(" ")
                val method = parts[0]
                val urlPath = parts.getOrNull(1) ?: "/"
                val headers = parseHeaders(requestLines.drop(1))
                
                // Reconstruct Request
                val initialPayload = StringBuilder()
                requestLines.forEach { initialPayload.append(it).append("\r\n") }
                initialPayload.append("\r\n")
                
                targetOut.write(initialPayload.toString().toByteArray())
                
                val contentLength = (headers["Content-Length"] ?: headers["content-length"])?.toLongOrNull() ?: 0L
                
                // Handle request body if present
                var reqBodyString: String? = null
                if (contentLength > 0) {
                     val buffer = ByteArray(4096)
                     var remaining = contentLength
                     val captureLimit = 16384
                     val bodyBuilder = java.io.ByteArrayOutputStream()
                     
                     while (remaining > 0) {
                         val count = clientIn.read(buffer, 0, Math.min(buffer.size.toLong(), remaining).toInt())
                         if (count == -1) break
                         targetOut.write(buffer, 0, count)
                         
                         if (bodyBuilder.size() < captureLimit) {
                             bodyBuilder.write(buffer, 0, Math.min(count, captureLimit - bodyBuilder.size()))
                         }
                         
                         remaining -= count
                     }
                     
                     // Determine body string based on content type
                     val reqContentType = (headers["Content-Type"] ?: headers["content-type"] ?: "").lowercase()
                     reqBodyString = if (isBinaryContentType(reqContentType)) {
                         "[Binary Data - ${bodyBuilder.size()} bytes]"
                     } else {
                         try {
                             bodyBuilder.toString("UTF-8")
                         } catch (e: Exception) {
                             "[Data - ${bodyBuilder.size()} bytes]"
                         }
                     }
                }
                
                // Create requestMeta with proper initial values
                val requestMeta = mutableMapOf<String, Any>(
                    "id" to System.nanoTime().toString(),
                    "timestamp" to System.currentTimeMillis(),
                    "protocol" to "HTTPS",
                    "method" to method,
                    "url" to "https://$targetHost$urlPath",
                    "domain" to targetHost,
                    "headers" to headers,
                    "requestSize" to initialPayload.length + contentLength,
                    "responseSize" to 0,
                    "responseTime" to 0
                )
                
                // Add request body if present
                if (reqBodyString != null) {
                    requestMeta["requestBody"] = reqBodyString
                }
                 
                 // Inject App Metadata
                 appMeta?.let {
                     requestMeta["package"] = it["package"] ?: "unknown"
                     requestMeta["appName"] = it["appName"] ?: "Unknown"
                     requestMeta["uid"] = it["uid"]?.toIntOrNull() ?: 0
                 }
                
                // Read Response
                val responseLines = readHeaders(targetIn)
                if (responseLines.isNotEmpty()) {
                    val statusLine = responseLines[0]
                    val responseHeaders = parseHeaders(responseLines.drop(1))
                    
                    val responseHeadBuffer = StringBuilder()
                    responseLines.forEach { responseHeadBuffer.append(it).append("\r\n") }
                    responseHeadBuffer.append("\r\n")
                    
                    clientOut.write(responseHeadBuffer.toString().toByteArray())
                    
                    requestMeta["statusCode"] = statusLine.split(" ").getOrNull(1)?.toIntOrNull() ?: 0
                    requestMeta["responseTime"] = System.currentTimeMillis() - (requestMeta["timestamp"] as Long)
                    requestMeta["responseHeaders"] = responseHeaders
                    
                    val rLen = (responseHeaders["Content-Length"] ?: responseHeaders["content-length"])?.toLongOrNull()
                    val bodyBuilder = java.io.ByteArrayOutputStream()
                    val captureLimit = 16384
                    
                    if (rLen != null) {
                         val buffer = ByteArray(4096)
                         var remaining = rLen
                         while (remaining > 0) {
                             val count = targetIn.read(buffer, 0, Math.min(buffer.size.toLong(), remaining).toInt())
                             if (count == -1) break
                             clientOut.write(buffer, 0, count)
                             
                             if (bodyBuilder.size() < captureLimit) {
                                  bodyBuilder.write(buffer, 0, Math.min(count, captureLimit - bodyBuilder.size()))
                             }
                             
                             remaining -= count
                         }
                         requestMeta["responseSize"] = responseHeadBuffer.length + rLen
                    } else {
                        // Just pipe widely if unknown
                        // Note: If chunked, we should ideally decode it for the body capture, but that's complex.
                        // For now we just capture raw stream.
                        val buffer = ByteArray(4096)
                        if (targetIn.available() > 0) {
                             while(targetIn.available() > 0) {
                                  val count = targetIn.read(buffer)
                                  if (count == -1) break
                                  clientOut.write(buffer, 0, count)
                                  
                                  if (bodyBuilder.size() < captureLimit) {
                                      bodyBuilder.write(buffer, 0, Math.min(count, captureLimit - bodyBuilder.size()))
                                  }
                             }
                        }
                    }
                    
                    // Check if response is binary
                    val responseContentType = (responseHeaders["Content-Type"] ?: responseHeaders["content-type"] ?: "").lowercase()
                    if (isBinaryContentType(responseContentType)) {
                        requestMeta["responseBody"] = "[Binary Data - ${bodyBuilder.size()} bytes]"
                    } else {
                        try {
                            requestMeta["responseBody"] = bodyBuilder.toString("UTF-8")
                        } catch (e: Exception) {
                            requestMeta["responseBody"] = "[Data - ${bodyBuilder.size()} bytes]"
                        }
                    }
                    
                    // Log only metadata for security (no bodies/headers in production)
                    Log.d(TAG, "HTTPS Request: $method $targetHost - Status: ${requestMeta["statusCode"]} - Size: ${requestMeta["responseSize"]}B")
                    TrafficHandler.sendPacket(requestMeta)
                }
             }
        } catch (e: Exception) {
            Log.e(TAG, "HTTPS Decrypted Error", e)
        } finally {
            try { clientSslSocket.close() } catch (e: Exception) {}
            try { targetSocket?.close() } catch (e: Exception) {}
        }
    }
    
    // Blind Tunnel for Failed Handshakes or Non-Intercepted
    private fun tunnelConnection(clientSocket: Socket, host: String, port: Int, appMeta: Map<String, String>?, decrypted: Boolean) {
        // Connect to Target
        try {
            val targetSocket = Socket(host, port)
            
            val clientIn = clientSocket.getInputStream()
            val clientOut = clientSocket.getOutputStream()
            val targetIn = targetSocket.getInputStream()
            val targetOut = targetSocket.getOutputStream()
            
            // Relay Threads
            val t1 = thread {
                try { clientIn.copyTo(targetOut) } catch (e: Exception) {}
            }
            val t2 = thread {
                try { targetIn.copyTo(clientOut) } catch (e: Exception) {}
            }
            
            // Log Event
            val meta = mutableMapOf<String, Any>(
                "id" to System.nanoTime().toString(),
                "timestamp" to System.currentTimeMillis(),
                "protocol" to "HTTPS",
                "method" to "CONNECT",
                "url" to "https://$host:$port",
                "domain" to host,
                "isDecrypted" to decrypted,
                "note" to "Tunnelled/Encrypted"
            )
            appMeta?.let {
                meta["package"] = it["package"] ?: "unknown"
                meta["appName"] = it["appName"] ?: "Unknown"
                meta["uid"] = it["uid"]?.toIntOrNull() ?: 0
            }
            TrafficHandler.sendPacket(meta)
            
            t1.join()
            t2.join()
        } catch (e: Exception) {
             Log.e(TAG, "Tunnel Error", e)
        } finally {
            try { clientSocket.close() } catch (e: Exception) {}
        }
    }
    
    // Helper to read header lines until empty line
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
                buffer.append(c.toChar()) // Keep it in buffer
            } else {
                if (lastCr) {
                    lastCr = false 
                }
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
}
