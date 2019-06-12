package com.kasem.receive_sharing_intent

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.util.*

class ReceiveSharingIntentPlugin(val registrar: Registrar) :
        MethodCallHandler,
        EventChannel.StreamHandler,
        PluginRegistry.NewIntentListener {

    private var changeReceiver: BroadcastReceiver? = null
    private var initialIntentData: ArrayList<String>? = null
    private var latestIntentData: ArrayList<String>? = null

    init {
        handleIntent(registrar.context(), registrar.activity().intent, true)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        changeReceiver = createChangeReceiver(events)
    }

    override fun onCancel(p0: Any?) {
        changeReceiver = null
    }

    override fun onNewIntent(intent: Intent): Boolean {
        handleIntent(registrar.context(), intent, false)
        return false
    }

    companion object {
        private val MESSAGES_CHANNEL = "receive_sharing_intent/messages"
        private val EVENTS_CHANNEL = "receive_sharing_intent/events"

        @JvmStatic
        fun registerWith(registrar: Registrar) {
            // Detect if we've been launched in background
            if (registrar.activity() == null) {
                return
            }

            val instance = ReceiveSharingIntentPlugin(registrar)

            val mChannel = MethodChannel(registrar.messenger(), MESSAGES_CHANNEL)
            mChannel.setMethodCallHandler(instance)

            val eChannel = EventChannel(registrar.messenger(), EVENTS_CHANNEL)
            eChannel.setStreamHandler(instance)

            registrar.addNewIntentListener(instance)
        }
    }


    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "getInitialIntentData") {
            result.success(initialIntentData)
        } else {
            result.notImplemented()
        }
    }

    private fun handleIntent(context: Context, intent: Intent, initial: Boolean) {
        if (intent.type?.startsWith("image") == true
                && (intent.action == Intent.ACTION_SEND
                        || intent.action == Intent.ACTION_SEND_MULTIPLE)) {

            val value = getValue(intent)
            if (initial) initialIntentData = value
            latestIntentData = value
            changeReceiver?.onReceive(context, intent)
        }
    }

    private fun getValue(intent: Intent?): ArrayList<String>? {
        if (intent == null) return null

        if (intent.action == Intent.ACTION_SEND) {
            val uri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
            return if (uri != null) arrayListOf(uri.toString()) else null
        } else if (intent.action == Intent.ACTION_SEND_MULTIPLE) {
            val uris = intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
            val value = uris?.map { it.toString() }?.toList()
            return if (value != null) ArrayList(value) else null
        }

        return null
    }

    private fun createChangeReceiver(events: EventChannel.EventSink): BroadcastReceiver {

        return object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                val value = getValue(intent)
                if (value == null) {
                    events.error("UNAVAILABLE", "Link unavailable", null)
                } else {
                    events.success(value)
                }
            }
        }
    }
}
