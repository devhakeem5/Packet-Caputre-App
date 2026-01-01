package com.example.packet_capture

import android.net.Uri
import android.util.Log
import java.io.*
import java.net.ServerSocket
import java.net.Socket
import kotlin.concurrent.thread

class SimpleHttpProxy(private val port: Int) {
    
    companion object {
        const val TAG = "SimpleHttpProxy"
    }
    
    private var serverSocket: ServerSocket? = null
    private var isRunning = false
    
    fun start() {
        if (isRunning) return
        
        thread(start = true) {
            try {
                serverSocket = ServerSocket(port)
                isRunning = true
                Log.d(TAG, "HTTP Proxy started on 127.0.0.1:$port")
                
                while (isRunning) {
                    try {
                        val client = serverSocket?.accept()
                        if (client != null) {
                            thread(start = true) { handleClient(client) }
                        }
                    } catch (e: Exception) {
                        if (isRunning) {
                            Log.e(TAG, "Error accepting connection", e)
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Proxy server error", e)
            }
        }
    }
    
    fun stop() {
        isRunning = false
        try {
            serverSocket?.close()
        } catch (e: Exception) {
            Log.e(TAG, "Error closing proxy", e)
        }
        serverSocket = null
    }
    
    private fun handleClient(client: Socket) {
        try {
            val input = BufferedReader(InputStreamReader(client.getInputStream()))
            val output = client.getOutputStream()
            
            // Read request line
            val requestLine = input.readLine() ?: return
            Log.d(TAG, "Received: $requestLine")
            
            val parts = requestLine.split(" ")
            if (parts.size < 3) return
            
            val method = parts[0]
            val uri = parts[1]
            
            // Handle CONNECT (HTTPS tunneling)
            if (method == "CONNECT") {
                handleConnectTunnel(client, input, output, uri)
                return
            }
            
            // Handle regular HTTP
            handleHttpRequest(client, input, output, method, uri, requestLine)
            
        } catch (e: Exception) {
            Log.e(TAG, "Client handling error", e)
        } finally {
            try { client.close() } catch (e: Exception) {}
        }
    }
    
    private fun handleConnectTunnel(client: Socket, input: BufferedReader, output: OutputStream, hostPort: String) {
        try {
            // Parse host:port
            val parts = hostPort.split(":")
            val host = parts[0]
            val port = parts.getOrNull(1)?.toIntOrNull() ?: 443
            
            // Read remaining headers (discard)
            while (true) {
                val line = input.readLine()
                if (line.isNullOrEmpty()) break
            }
            
            // Connect to destination
            val remote = Socket(host, port)
            
            // Send 200 Connection Established
            output.write("HTTP/1.1 200 Connection Established\r\n\r\n".toByteArray())
            output.flush()
            
            Log.d(TAG, "CONNECT tunnel established to $host:$port")
            
            // Emit metadata event
            emitTunnelEvent(host, port)
            
            // Bidirectional tunnel (no decryption)
            val clientToRemote = thread(start = true) {
                try {
                    client.getInputStream().copyTo(remote.getOutputStream())
                } catch (e: Exception) {}
            }
            
            val remoteToClient = thread(start = true) {
                try {
                    remote.getInputStream().copyTo(output)
                } catch (e: Exception) {}
            }
            
            clientToRemote.join()
            remoteToClient.join()
            
            remote.close()
        } catch (e: Exception) {
            Log.e(TAG, "CONNECT tunnel error", e)
        }
    }
    
    private fun handleHttpRequest(
        client: Socket,
        input: BufferedReader,
        output: OutputStream,
        method: String,
        uri: String,
        requestLine: String
    ) {
        try {
            // Parse headers
            val headers = mutableMapOf<String, String>()
            var host = ""
            var contentLength = 0
            
            while (true) {
                val line = input.readLine()
                if (line.isNullOrEmpty()) break
                
                val colonIndex = line.indexOf(":")
                if (colonIndex > 0) {
                    val key = line.substring(0, colonIndex).trim()
                    val value = line.substring(colonIndex + 1).trim()
                    headers[key] = value
                    
                    if (key.equals("Host", ignoreCase = true)) {
                        host = value
                    }
                    if (key.equals("Content-Length", ignoreCase = true)) {
                        contentLength = value.toIntOrNull() ?: 0
                    }
                }
            }
            
            // Read body if present
            val body = if (contentLength > 0) {
                val bodyChars = CharArray(contentLength)
                input.read(bodyChars, 0, contentLength)
                String(bodyChars)
            } else ""
            
            Log.d(TAG, "HTTP Request: $method $uri (Host: $host, Body: ${body.length} bytes)")
            
            // Connect to destination
            val destPort = if (host.contains(":")) {
                host.substringAfter(":").toIntOrNull() ?: 80
            } else 80
            val destHost = host.substringBefore(":")
            
            val remote = Socket(destHost, destPort)
            val remoteOut = remote.getOutputStream()
            val remoteIn = BufferedInputStream(remote.getInputStream())
            
            // Forward request
            remoteOut.write("$requestLine\r\n".toByteArray())
            headers.forEach { (k, v) ->
                remoteOut.write("$k: $v\r\n".toByteArray())
            }
            remoteOut.write("\r\n".toByteArray())
            if (body.isNotEmpty()) {
                remoteOut.write(body.toByteArray())
            }
            remoteOut.flush()
            
            // Read response
            val responseHeaders = mutableMapOf<String, String>()
            val responseBuffer = ByteArrayOutputStream()
            
            // Read status line
            val statusLine = readLine(remoteIn) ?: ""
            responseBuffer.write("$statusLine\r\n".toByteArray())
            
            val statusParts = statusLine.split(" ")
            val statusCode = statusParts.getOrNull(1)?.toIntOrNull() ?: 200
            
            // Read response headers
            var responseContentLength = -1
            while (true) {
                val line = readLine(remoteIn)
                if (line.isNullOrEmpty()) {
                    responseBuffer.write("\r\n".toByteArray())
                    break
                }
                responseBuffer.write("$line\r\n".toByteArray())
                
                val colonIndex = line.indexOf(":")
                if (colonIndex > 0) {
                    val key = line.substring(0, colonIndex).trim()
                    val value = line.substring(colonIndex + 1).trim()
                    responseHeaders[key] = value
                    
                    if (key.equals("Content-Length", ignoreCase = true)) {
                        responseContentLength = value.toIntOrNull() ?: -1
                    }
                }
            }
            
            // Read response body
            val responseBody = if (responseContentLength > 0) {
                val bodyBytes = ByteArray(responseContentLength)
                remoteIn.read(bodyBytes)
                responseBuffer.write(bodyBytes)
                String(bodyBytes)
            } else ""
            
            // Emit complete HTTP event
            emitHttpEvent(
                method, 
                "http://$host$uri",
                headers,
                body,
                statusCode,
                responseHeaders,
                responseBody
            )
            
            // Forward response to client
            output.write(responseBuffer.toByteArray())
            output.flush()
            
            remote.close()
            
        } catch (e: Exception) {
            Log.e(TAG, "HTTP request error", e)
        }
    }
    
    private fun readLine(input: InputStream): String? {
        val line = StringBuilder()
        while (true) {
            val ch = input.read()
            if (ch == -1) return if (line.isEmpty()) null else line.toString()
            if (ch == '\n'.code) {
                return line.toString().trimEnd('\r')
            }
            line.append(ch.toChar())
        }
    }
    
    private fun emitHttpEvent(
        method: String,
        url: String,
        requestHeaders: Map<String, String>,
        requestBody: String,
        statusCode: Int,
        responseHeaders: Map<String, String>,
        responseBody: String
    ) {
        val meta = mutableMapOf<String, Any>(
            "timestamp" to System.currentTimeMillis(),
            "protocol" to "HTTP",
            "method" to method,
            "url" to url,
            "statusCode" to statusCode,
            "source" to "proxy",
            "isDecrypted" to true,
            "requestHeaders" to requestHeaders,
            "requestBody" to requestBody,
            "responseHeaders" to responseHeaders,
            "responseBody" to responseBody,
            "domain" to (Uri.parse(url).host ?: ""),
            "direction" to "outgoing"
        )
        
        TrafficHandler.sendPacket(meta)
        Log.d(TAG, "✓ Emitted HTTP event: $method $url (${requestBody.length}B req, ${responseBody.length}B resp)")
    }
    
    private fun emitTunnelEvent(host: String, port: Int) {
        val meta = mutableMapOf<String, Any>(
            "timestamp" to System.currentTimeMillis(),
            "protocol" to "HTTPS",
            "method" to "CONNECT",
            "url" to "https://$host:$port",
            "domain" to host,
            "source" to "proxy",
            "isDecrypted" to false,
            "direction" to "outgoing"
        )
        
        TrafficHandler.sendPacket(meta)
        Log.d(TAG, "✓ Emitted tunnel event: CONNECT $host:$port")
    }
}
