package com.kasem.receive_sharing_intent

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.media.ThumbnailUtils
import android.net.Uri
import android.provider.MediaStore
import android.util.Log
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.*
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import java.net.URLConnection

private const val MESSAGES_CHANNEL = "receive_sharing_intent/messages"
private const val EVENTS_CHANNEL_MEDIA = "receive_sharing_intent/events-media"
private const val EVENTS_CHANNEL_TEXT = "receive_sharing_intent/events-text"

/** FlutterShareExtensionPlugin */
class ReceiveSharingIntentPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, EventChannel.StreamHandler, PluginRegistry.NewIntentListener {
    private lateinit var mChannel : MethodChannel
    private lateinit var eChannelMedia : EventChannel
    private lateinit var eChannelText : EventChannel
    private lateinit var activityBinding: ActivityPluginBinding
    private lateinit var activity: Activity
    private lateinit var applicationContext: Context

    private var initialMedia: JSONArray? = null
    private var latestMedia: JSONArray? = null
    private var initialText: String? = null
    private var latestText: String? = null
    private var eventSinkMedia: EventChannel.EventSink? = null
    private var eventSinkText: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        when (arguments) {
            "media" -> eventSinkMedia = events
            "text" -> eventSinkText = events
        }
    }

    override fun onCancel(arguments: Any?) {
        when (arguments) {
            "media" -> eventSinkMedia = null
            "text" -> eventSinkText = null
        }
    }

    override fun onNewIntent(intent: Intent): Boolean {
        handleIntent(applicationContext, intent, false)
        return false
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding;
        activityBinding.addOnNewIntentListener(this)

        // Handle launch-intent here if app was not running when the intent was shared to it
        handleIntent(applicationContext, activityBinding.activity.intent, true)
//        Log.d("flutter_share", "onAttachedToActivity | activityBinding.activity.intent: ${activityBinding.activity.intent}")
    }

    override fun onDetachedFromActivity() {
//        Log.d("flutter_share", "onDetachedFromActivity")
        activityBinding.removeOnNewIntentListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
//        Log.d("flutter_share", "onDetachedFromActivityForConfigChanges")
        activityBinding.removeOnNewIntentListener(this)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
//        Log.d("flutter_share", "onReattachedToActivityForConfigChanges")
        activity = binding.activity
        activityBinding.addOnNewIntentListener(this)
    }

    private fun setupCallbackChannels(messenger: BinaryMessenger) {
//        Log.d("flutter_share", "setupCallbackChannels")
        mChannel = MethodChannel(messenger, MESSAGES_CHANNEL)
        mChannel.setMethodCallHandler(this)

        eChannelMedia = EventChannel(messenger, EVENTS_CHANNEL_MEDIA)
        eChannelMedia.setStreamHandler(this)

        eChannelText = EventChannel(messenger, EVENTS_CHANNEL_TEXT)
        eChannelText.setStreamHandler(this)
    }

    private fun teardown() {
//        Log.d("flutter_share", "teardown")
        mChannel.setMethodCallHandler(null)
        eChannelMedia.setStreamHandler(null)
        eChannelText.setStreamHandler(null)
        activityBinding.removeOnNewIntentListener(this)
    }


    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
//        Log.d("flutter_share", "onAttachedToEngine")
        applicationContext = flutterPluginBinding.applicationContext
        setupCallbackChannels(flutterPluginBinding.binaryMessenger)
    }

    // This static function is optional and equivalent to onAttachedToEngine. It supports the old
    // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
    // plugin registration via this function while apps migrate to use the new Android APIs
    // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
    //
    // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
    // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
    // depending on the user's project. onAttachedToEngine or registerWith must both be defined
    // in the same class.
    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            Log.d("flutter_share", "registerWith")
            val instance = ReceiveSharingIntentPlugin()
            instance.applicationContext = registrar.context()
            instance.setupCallbackChannels(registrar.messenger())
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        teardown()
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
//        Log.d("flutter_share", "onMethodCall | call: $call")
        when (call.method) {
            "getInitialMedia" -> result.success(initialMedia?.toString())
            "getInitialText" -> result.success(initialText)
            "reset" -> {
                initialMedia = null
                latestMedia = null
                initialText = null
                latestText = null
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun handleIntent(context: Context, intent: Intent, initial: Boolean) {
//        Log.d("flutter_share", "handleIntent")
        when {
            (intent.type?.startsWith("image") == true || intent.type?.startsWith("video") == true)
                    && (intent.action == Intent.ACTION_SEND
                    || intent.action == Intent.ACTION_SEND_MULTIPLE) -> { // Sharing images or videos

                val value = getMediaUris(context, intent)
                if (initial) initialMedia = value
                latestMedia = value
                eventSinkMedia?.success(latestMedia?.toString())
            }
            (intent.type == null || intent.type?.startsWith("text") == true)
                    && intent.action == Intent.ACTION_SEND -> { // Sharing text
                val value = intent.getStringExtra(Intent.EXTRA_TEXT)
                if (initial) initialText = value
                latestText = value
                eventSinkText?.success(latestText)
            }
            intent.action == Intent.ACTION_VIEW -> { // Opening URL
                val value = intent.dataString
                if (initial) initialText = value
                latestText = value
                eventSinkText?.success(latestText)
            }
        }
    }

    private fun getMediaUris(context: Context, intent: Intent?): JSONArray? {
//        Log.d("flutter_share", "getMediaUris")
        if (intent == null) return null

        return when (intent.action) {
            Intent.ACTION_SEND -> {
                val uri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                val path = FileDirectory.getAbsolutePath(context, uri)
                if (path != null) {
                    val type = getMediaType(path)
                    val thumbnail = getThumbnail(context, path, type)
                    val duration = getDuration(path, type)
                    JSONArray().put(
                            JSONObject()
                                    .put("path", path)
                                    .put("type", type)
                                    .put("thumbnail", thumbnail)
                                    .put("duration", duration)
                    )
                } else null
            }
            Intent.ACTION_SEND_MULTIPLE -> {
                val uris = intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
                val value = uris?.mapNotNull { uri ->
                    val path = FileDirectory.getAbsolutePath(context, uri) ?: return@mapNotNull null
                    val type = getMediaType(path)
                    val thumbnail = getThumbnail(context, path, type)
                    val duration = getDuration(path, type)
                    return@mapNotNull JSONObject()
                            .put("path", path)
                            .put("type", type)
                            .put("thumbnail", thumbnail)
                            .put("duration", duration)
                }?.toList()
                if (value != null) JSONArray(value) else null
            }
            else -> null
        }
    }

    private fun getMediaType(path: String?): Int {
//        Log.d("flutter_share", "getMediaType")
        val mimeType = URLConnection.guessContentTypeFromName(path)
        val isImage = mimeType?.startsWith("image") == true
        return if (isImage) 0 else 1
    }

    private fun getThumbnail(context: Context, path: String, type: Int): String? {
//        Log.d("flutter_share", "getThumbnail")
        if (type != 1) return null // get video thumbnail only

        val videoFile = File(path)
        val targetFile = File(context.cacheDir, "${videoFile.name}.png")
        val bitmap = ThumbnailUtils.createVideoThumbnail(path, MediaStore.Video.Thumbnails.MINI_KIND)
                ?: return null
        FileOutputStream(targetFile).use { out ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
        }
        bitmap.recycle()
        return targetFile.path
    }

    private fun getDuration(path: String, type: Int): Long? {
//        Log.d("flutter_share", "getDuration")
        if (type != 1) return null // get duration for video only
        val retriever = MediaMetadataRetriever()
        retriever.setDataSource(path)
        val duration = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION).toLongOrNull()
        retriever.release()
        return duration
    }
}
