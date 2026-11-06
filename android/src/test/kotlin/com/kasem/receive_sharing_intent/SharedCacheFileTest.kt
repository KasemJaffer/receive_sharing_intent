package com.kasem.receive_sharing_intent

import java.nio.file.Files
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Assume.assumeNoException
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder

class SharedCacheFileTest {
    @get:Rule val temporary = TemporaryFolder()

    @Test fun preservesOrdinaryFileName() {
        val cache = temporary.newFolder("cache")
        val result = SharedCacheFile.fromDisplayName(cache, "report 2026.pdf")
        assertEquals("report 2026.pdf", result?.name)
        assertEquals(cache.canonicalFile, result?.canonicalFile?.parentFile)
    }

    @Test fun stripsRelativeTraversalIntoSiblingDirectory() {
        val cache = temporary.newFolder("cache")
        val result = SharedCacheFile.fromDisplayName(cache, "../databases/marker.txt")
        assertEquals("marker.txt", result?.name)
        assertEquals(cache.canonicalFile, result?.canonicalFile?.parentFile)
    }

    @Test fun stripsWindowsStyleSeparators() {
        val cache = temporary.newFolder("cache")
        val result = SharedCacheFile.fromDisplayName(cache, "..\\shared_prefs\\settings.xml")
        assertEquals("settings.xml", result?.name)
        assertEquals(cache.canonicalFile, result?.canonicalFile?.parentFile)
    }

    @Test fun stripsAbsolutePath() {
        val cache = temporary.newFolder("cache")
        val result = SharedCacheFile.fromDisplayName(cache, "/data/data/target/files/marker.txt")
        assertEquals("marker.txt", result?.name)
        assertEquals(cache.canonicalFile, result?.canonicalFile?.parentFile)
    }

    @Test fun dropsInvalidNamesForGeneratedNameFallback() {
        val cache = temporary.newFolder("cache")
        listOf(null, "", "  ", ".", "..", "/", "a/..", "bad\u0000name").forEach { name ->
            assertNull("invalid name: $name", SharedCacheFile.fromDisplayName(cache, name))
        }
    }

    @Test fun rejectsExistingSymlinkEscapingCache() {
        val cache = temporary.newFolder("cache")
        val outside = temporary.newFile("outside.txt")
        val link = cache.toPath().resolve("linked.txt")
        try {
            Files.createSymbolicLink(link, outside.toPath())
        } catch (e: Exception) {
            assumeNoException("Filesystem does not allow symlink tests", e)
        }
        assertTrue(Files.isSymbolicLink(link))
        assertNull(SharedCacheFile.fromDisplayName(cache, "linked.txt"))
    }
}
