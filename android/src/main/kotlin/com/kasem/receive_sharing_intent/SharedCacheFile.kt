package com.kasem.receive_sharing_intent

import java.io.File
import java.io.IOException

/**
 * Ensures ContentProvider display names resolve to a file directly in cacheDir.
 */
internal object SharedCacheFile {
    fun fromDisplayName(cacheDir: File, displayName: String?): File? {
        if (displayName.isNullOrBlank()) return null
        val baseName = displayName.replace('\\', '/').substringAfterLast('/')
        if (baseName.isBlank() || baseName == "." || baseName == ".." || '\u0000' in baseName) return null

        return try {
            val trustedCache = cacheDir.canonicalFile
            val candidate = File(trustedCache, baseName)
            if (candidate.canonicalFile.parentFile == trustedCache) candidate else null
        } catch (_: IOException) {
            null
        } catch (_: SecurityException) {
            null
        }
    }
}
