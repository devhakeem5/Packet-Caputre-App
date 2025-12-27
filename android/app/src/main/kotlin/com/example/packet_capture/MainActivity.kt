package com.example.packet_capture

import android.content.Intent
import android.net.VpnService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.example.packet_capture/methods"
    private val EVENT_CHANNEL = "com.example.packet_capture/events"
    private val VPN_REQUEST_CODE = 0x0F

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startCapture" -> {
                    val intent = VpnService.prepare(this)
                    if (intent != null) {
                        startActivityForResult(intent, VPN_REQUEST_CODE)
                    } else {
                        onActivityResult(VPN_REQUEST_CODE, RESULT_OK, null)
                    }
                    result.success(null)
                }
                "stopCapture" -> {
                    val intent = Intent(this, com.example.packet_capture.VpnService::class.java)
                    intent.action = "STOP"
                    startService(intent)
                    result.success(null)
                }
                "getInstalledApps" -> {
                    // Fetch installed apps
                    val pm = packageManager
                    val apps = pm.getInstalledPackages(0)
                    android.util.Log.d("PacketCapture", "Total packages found: ${apps.size}")
                    
                    val appList = mutableListOf<Map<String, Any>>()
                    
                    for (packageInfo in apps) {
                        val appInfo = packageInfo.applicationInfo
                        if (appInfo != null) {
                            // Simple filter: non-system or updated system apps
                            val isSystemApp = (appInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0
                            val isUpdatedSystemApp = (appInfo.flags and android.content.pm.ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0
                            
                            if (!isSystemApp || isUpdatedSystemApp) {
                                val appName = appInfo.loadLabel(pm).toString()
                                val packageName = packageInfo.packageName
                                
                                val icon = try {
                                    val drawable = appInfo.loadIcon(pm)
                                    val bitmap = if (drawable is android.graphics.drawable.BitmapDrawable) {
                                        drawable.bitmap
                                    } else {
                                        val bmp = android.graphics.Bitmap.createBitmap(drawable.intrinsicWidth, drawable.intrinsicHeight, android.graphics.Bitmap.Config.ARGB_8888)
                                        val canvas = android.graphics.Canvas(bmp)
                                        drawable.setBounds(0, 0, canvas.width, canvas.height)
                                        drawable.draw(canvas)
                                        bmp
                                    }
                                    val stream = java.io.ByteArrayOutputStream()
                                    bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG, 50, stream) // 50% quality
                                    stream.toByteArray()
                                } catch (e: Exception) {
                                    android.util.Log.e("PacketCapture", "Error loading icon for $packageName", e)
                                    null
                                }

                                val map = mutableMapOf<String, Any>(
                                    "name" to appName,
                                    "packageName" to packageName,
                                    "isSystemApp" to isSystemApp
                                )
                                if (icon != null) {
                                    map["iconBytes"] = icon
                                }
                                
                                appList.add(map)
                            }
                        }
                    }
                    android.util.Log.d("PacketCapture", "Filtered app list size: ${appList.size}")
                    result.success(appList)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(TrafficHandler)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == VPN_REQUEST_CODE && resultCode == RESULT_OK) {
            val intent = Intent(this, com.example.packet_capture.VpnService::class.java)
            startService(intent)
        }
        super.onActivityResult(requestCode, resultCode, data)
    }
}
