package com.kasem.receive_sharing_intent

import android.content.ContentUris
import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.DocumentsContract
import android.provider.MediaStore
import java.io.File
import java.io.FileOutputStream
import java.util.*
import android.webkit.MimeTypeMap
import android.util.Log


object FileDirectory {

    /**
     * Get a file path from a Uri. This will get the the path for Storage Access
     * Framework Documents, as well as the _data field for the MediaStore and
     * other file-based ContentProviders.
     *
     * @param context The context.
     * @param uri The Uri to query.
     * @author paulburke
     */
    fun getAbsolutePath(context: Context, uri: Uri): String? {

        // DocumentProvider
        if (DocumentsContract.isDocumentUri(context, uri)) {
            // ExternalStorageProvider
            if (isExternalStorageDocument(uri)) {
                val docId = DocumentsContract.getDocumentId(uri)
                val split = docId.split(":".toRegex()).dropLastWhile { it.isEmpty() }.toTypedArray()
                val type = split[0]

                return if ("primary".equals(type, ignoreCase = true)) {
                    Environment.getExternalStorageDirectory().toString() + "/" + split[1]
                } else {
                    getDataColumn(context, uri, null, null)
                }
            } else if (isDownloadsDocument(uri)) {
                return try {
                    val id = DocumentsContract.getDocumentId(uri)
                    val contentUri = ContentUris.withAppendedId(
                            Uri.parse("content://downloads/public_downloads"), java.lang.Long.valueOf(id))

                    getDataColumn(context, contentUri, null, null)
                } catch (exception: Exception) {
                    getDataColumn(context, uri, null, null)
                }
            } else if (isMediaDocument(uri)) {
                val docId = DocumentsContract.getDocumentId(uri)
                val split = docId.split(":".toRegex()).dropLastWhile { it.isEmpty() }.toTypedArray()
                val type = split[0]

                var contentUri: Uri? = null
                when (type) {
                    "image" -> contentUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                    "video" -> contentUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                    "audio" -> contentUri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
                }

                if (contentUri == null) return null

                val selection = "_id=?"
                val selectionArgs = arrayOf(split[1])
                return getDataColumn(context, contentUri, selection, selectionArgs)
            }// MediaProvider
            // DownloadsProvider
        } else if ("content".equals(uri.scheme, ignoreCase = true)) {
            return getDataColumn(context, uri, null, null)
        }

        return uri.path
    }

    /**
     * Get the value of the data column for this Uri. This is useful for
     * MediaStore Uris, and other file-based ContentProviders.
     *
     * @param context The context.
     * @param uri The Uri to query.
     * @param selection (Optional) Filter used in the query.
     * @param selectionArgs (Optional) Selection arguments used in the query.
     * @return The value of the _data column, which is typically a file path.
     */
    private fun getDataColumn(context: Context, uri: Uri, selection: String?,
                              selectionArgs: Array<String>?): String? {

        if (uri.authority != null) {
            var cursor: Cursor? = null
            val column = "_display_name"
            val projection = arrayOf(column)
            var targetFile: File? = null
            // Some providers (e.g. Google Photos'
            // com.google.android.apps.photos.contentprovider) do not expose the
            // "_display_name" column. getColumnIndexOrThrow would throw here and the
            // exception propagates out of handleIntent, leaving initialMedia == null
            // (shared file silently lost). Use getColumnIndex with a guard and wrap
            // the query so we fall through to the generated-name fallback below.
            try {
                cursor = context.contentResolver.query(uri, projection, selection, selectionArgs, null)
                if (cursor != null && cursor.moveToFirst()) {
                    val columnIndex = cursor.getColumnIndex(column)
                    if (columnIndex >= 0) {
                        val fileName = cursor.getString(columnIndex)
                        if (!fileName.isNullOrEmpty()) {
                            Log.i("FileDirectory", "File name: $fileName")
                            targetFile = File(context.cacheDir, fileName)
                        }
                    }
                }
            } catch (e: Exception) {
                Log.w("FileDirectory", "query _display_name failed: $e")
            } finally {
                cursor?.close()
            }

            if (targetFile == null) {
                val mimeType = context.contentResolver.getType(uri)
                val prefix = with(mimeType ?: "") {
                    when {
                        startsWith("image") -> "IMG"
                        startsWith("video") -> "VID"
                        else -> "FILE"
                    }
                }
                val type = MimeTypeMap.getSingleton().getExtensionFromMimeType(mimeType)
                targetFile = File(context.cacheDir, "${prefix}_${Date().time}.$type")
            }

            // Copying may throw for cloud-backed / not-yet-downloaded items. Guard it
            // so one failed item does not abort the whole intent (other shared files
            // can still be delivered).
            return try {
                context.contentResolver.openInputStream(uri)?.use { input ->
                    FileOutputStream(targetFile).use { fileOut ->
                        input.copyTo(fileOut)
                    }
                }
                targetFile.path
            } catch (e: Exception) {
                Log.w("FileDirectory", "copy uri failed: $e")
                null
            }
        }

        var cursor: Cursor? = null
        val column = "_data"
        val projection = arrayOf(column)

        try {
            cursor = context.contentResolver.query(uri, projection, selection, selectionArgs, null)
            if (cursor != null && cursor.moveToFirst()) {
                val columnIndex = cursor.getColumnIndexOrThrow(column)
                return cursor.getString(columnIndex)
            }
        } finally {
            cursor?.close()
        }
        return null
    }


    /**
     * @param uri The Uri to check.
     * @return Whether the Uri authority is ExternalStorageProvider.
     */
    fun isExternalStorageDocument(uri: Uri): Boolean {
        return "com.android.externalstorage.documents" == uri.authority
    }

    /**
     * @param uri The Uri to check.
     * @return Whether the Uri authority is DownloadsProvider.
     */
    fun isDownloadsDocument(uri: Uri): Boolean {
        return "com.android.providers.downloads.documents" == uri.authority
    }

    /**
     * @param uri The Uri to check.
     * @return Whether the Uri authority is MediaProvider.
     */
    fun isMediaDocument(uri: Uri): Boolean {
        return "com.android.providers.media.documents" == uri.authority
    }
}