package com.example.packet_capture

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

object TrafficHandler : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null
    private val uiHandler = Handler(Looper.getMainLooper())

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    fun sendPacket(packetData: Map<String, Any>) {
        uiHandler.post {
            eventSink?.success(packetData)
        }
    }
}
