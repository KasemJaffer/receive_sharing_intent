package com.kasem.receive_sharing_intent

import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.provider.OpenableColumns
import android.util.Log
import android.webkit.MimeTypeMap
import java.io.File
import java.io.FileOutputStream
import java.util.*


object FileDirectory {

    /**
     * Get a file path the app can read for a shared Uri.
     *
     * A content:// item is copied into cacheDir. The sending app grants read
     * access to that exact Uri and nothing else: a path or another Uri derived
     * from it (the MediaStore _data column, /storage/emulated/0/... for an
     * external-storage document, the MediaStore collection behind a media
     * document, content://downloads/public_downloads behind a downloads
     * document) lies outside the app's sandbox. Under scoped storage the app
     * can't open such a path (EACCES), and opening the collection Uri throws
     * "Multiple items". Any other scheme (file://) is returned as its path.
     *
     * @param context The context.
     * @param uri The Uri to resolve.
     * @return A readable file path, or null when the item couldn't be copied.
     */
    fun getAbsolutePath(context: Context, uri: Uri): String? {
        if ("content".equals(uri.scheme, ignoreCase = true)) {
            return copyToCacheDir(context, uri)
        }
        return uri.path
    }

    /**
     * Copy a content:// item into cacheDir under its display name, or under a
     * generated IMG_/VID_/FILE_ name when the provider doesn't expose one.
     *
     * @param context The context.
     * @param uri The content:// Uri granted by the sending app.
     * @return The copy's path, or null when the provider fails to open the item.
     */
    private fun copyToCacheDir(context: Context, uri: Uri): String? {
        var cursor: Cursor? = null
        val column = OpenableColumns.DISPLAY_NAME
        val projection = arrayOf(column)
        var targetFile: File? = null
        // Some providers (e.g. Google Photos'
        // com.google.android.apps.photos.contentprovider) do not expose the
        // "_display_name" column. getColumnIndexOrThrow would throw here and the
        // exception propagates out of handleIntent, leaving initialMedia == null
        // (shared file silently lost). Use getColumnIndex with a guard and wrap
        // the query so we fall through to the generated-name fallback below.
        try {
            cursor = context.contentResolver.query(uri, projection, null, null, null)
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
            Log.w("FileDirectory", "query _display_name failed: uri=$uri $e")
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
            val stream = context.contentResolver.openInputStream(uri)
            if (stream == null) {
                // Without this the path of a file that was never written went out.
                Log.w("FileDirectory", "copy uri failed: uri=$uri provider returned no stream")
                null
            } else {
                stream.use { input ->
                    FileOutputStream(targetFile).use { fileOut ->
                        input.copyTo(fileOut)
                    }
                }
                targetFile.path
            }
        } catch (e: Exception) {
            Log.w("FileDirectory", "copy uri failed: uri=$uri $e")
            null
        }
    }
}
