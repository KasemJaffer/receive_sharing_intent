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

    private var changeReceiverImage: BroadcastReceiver? = null
    private var changeReceiverLink: BroadcastReceiver? = null

    private var initialIntentData: ArrayList<String>? = null
    private var latestIntentData: ArrayList<String>? = null

    private var initialLink: String? = null
    private var latestLink: String? = null

    init {
        handleIntent(registrar.context(), registrar.activity().intent, true)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        when (arguments) {
            "image" -> changeReceiverImage = createChangeReceiver(events)
            "link" -> changeReceiverLink = createChangeReceiver(events)
        }
    }

    override fun onCancel(arguments: Any?) {
        when (arguments) {
            "image" -> changeReceiverImage = null
            "link" -> changeReceiverLink = null
        }
    }

    override fun onNewIntent(intent: Intent): Boolean {
        handleIntent(registrar.context(), intent, false)
        return false
    }

    companion object {
        private val MESSAGES_CHANNEL = "receive_sharing_intent/messages"
        private val EVENTS_CHANNEL_IMAGE = "receive_sharing_intent/events-image"
        private val EVENTS_CHANNEL_LINK = "receive_sharing_intent/events-link"

        @JvmStatic
        fun registerWith(registrar: Registrar) {
            // Detect if we've been launched in background
            if (registrar.activity() == null) {
                return
            }

            val instance = ReceiveSharingIntentPlugin(registrar)

            val mChannel = MethodChannel(registrar.messenger(), MESSAGES_CHANNEL)
            mChannel.setMethodCallHandler(instance)

            val eChannelImage = EventChannel(registrar.messenger(), EVENTS_CHANNEL_IMAGE)
            eChannelImage.setStreamHandler(instance)

            val eChannelLink = EventChannel(registrar.messenger(), EVENTS_CHANNEL_LINK)
            eChannelLink.setStreamHandler(instance)

            registrar.addNewIntentListener(instance)
        }
    }


    override fun onMethodCall(call: MethodCall, result: Result) {
        when {
            call.method == "getInitialIntentData" -> result.success(initialIntentData)
            call.method == "getInitialLink" -> result.success(initialLink)
            else -> result.notImplemented()
        }
    }

    private fun handleIntent(context: Context, intent: Intent, initial: Boolean) {
        when {
            intent.type?.startsWith("image") == true
                    && (intent.action == Intent.ACTION_SEND
                    || intent.action == Intent.ACTION_SEND_MULTIPLE) -> {

                val value = getImageUris(intent)
                if (initial) initialIntentData = value
                latestIntentData = value
                changeReceiverImage?.onReceive(context, intent)
            }
            (intent.type == null || intent.type?.startsWith("text") == true)
                    && (intent.action == Intent.ACTION_SEND
                    || intent.action == Intent.ACTION_VIEW) -> {
                val value = intent.dataString
                if (initial) initialLink = value
                latestLink = value
                changeReceiverLink?.onReceive(context, intent)
            }
        }
    }

    private fun getImageUris(intent: Intent?): ArrayList<String>? {
        if (intent == null) return null

        return when {
            intent.action == Intent.ACTION_SEND -> {
                val uri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                if (uri != null) arrayListOf(uri.toString()) else null
            }
            intent.action == Intent.ACTION_SEND_MULTIPLE -> {
                val uris = intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
                val value = uris?.map { it.toString() }?.toList()
                if (value != null) ArrayList(value) else null
            }
            else -> null
        }
    }

    private fun createChangeReceiver(events: EventChannel.EventSink): BroadcastReceiver {

        return object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                val value: Any? = when {
                    intent?.type?.startsWith("image") == true
                            && (intent.action == Intent.ACTION_SEND
                            || intent.action == Intent.ACTION_SEND_MULTIPLE) -> getImageUris(intent)
                    (intent?.type == null || intent.type?.startsWith("text") == true)
                            && (intent?.action == Intent.ACTION_SEND
                            || intent?.action == Intent.ACTION_VIEW) -> intent.dataString
                    else -> null
                }

                if (value == null) {
                    events.error("UNAVAILABLE", "Link unavailable", null)
                } else {
                    events.success(value)
                }
            }
        }
    }
}
