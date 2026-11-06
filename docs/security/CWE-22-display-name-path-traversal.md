# Security advisory: `receive_sharing_intent` path traversal via `_display_name` (CWE-22)

**Researcher:** Edward "Actuator" Warren, [actuator.sh](https://actuator.sh/)  
**Component:** Android implementation of the Flutter/Dart `receive_sharing_intent` package  
**Affected releases:** 1.4.1 through 1.9.0 inclusive, based on researcher provenance analysis  
**Last unaffected:** 1.4.0+2  
**CVE:** **CVE-2026-60117** (provisionally allocated by VulnCheck on July 9, 2026; public CVE publication status not established by this advisory)  
**Researcher-proposed CVSS v3.1:** 7.7 High (`AV:L/AC:L/PR:N/UI:N/S:U/C:N/I:H/A:H`), subject to review  
**Fixed version:** No patched release known as of November 6, 2026; this pull-request branch proposes remediation

## Summary

`FileDirectory.getDataColumn` stages shared content inside the receiving application's private cache. In the `uri.authority != null` path, it reads `_display_name` from an untrusted ContentProvider and directly uses that string to construct `File(context.cacheDir, fileName)`. The sender controls the provider metadata and stream bytes. A path-shaped display name can cause a write outside `cache/` into another directory within the receiving application's private sandbox.

This is an inter-app confused-deputy primitive: the copy occurs under the receiving application's UID. Android scoped storage does not stop an app from writing within its own sandbox.

## Root cause and reachability

```text
ACTION_SEND / ACTION_SEND_MULTIPLE
  -> receiving activity (if exported and reachable)
  -> plugin handles EXTRA_STREAM content:// URI
  -> FileDirectory.getAbsolutePath(context, uri)
  -> FileDirectory.getDataColumn(context, uri, ...)
  -> ContentResolver.query(uri, ["_display_name"], ...)
  -> File(context.cacheDir, providerSuppliedName)  [untrusted path]
  -> ContentResolver.openInputStream(uri)
  -> FileOutputStream(targetFile)                    [write as receiving app]
```

For example, a provider-supplied display name `../databases/proof.txt` escapes the intended `cache/` directory into a sibling directory. Whether this path is reachable without user interaction depends on the consuming application's exported activity and intent filters. In the package's documented integration, the share receiver can be exported and explicitly targeted.

The regression is attributed to [commit c61c0e7](https://github.com/KasemJaffer/receive_sharing_intent/commit/c61c0e75ec518c0c6a68c57252cff8801247c8ee), "Preserve original file name", dated August 27, 2020. The preceding published version was `1.4.0+2`, and the introducing release was `1.4.1`. The direct file construction remained in upstream `master` as inspected on November 6, 2026.

## Demonstrated versus potential impact

The researcher reports a benign marker-file demonstration confirming attacker-directed writes inside a receiving app's private sandbox. This upstream advisory intentionally **omits the separately coordinated consuming application**, whose report is handled on a different disclosure track.

Potential downstream effects include tampering with trusted SQLite databases, shared preferences and other application-controlled files, depending on the consumer's behavior. Arbitrary code execution, account takeover, and additional downstream exploit chains are **not demonstrated** in this advisory. The CVSS score above is proposed, not CNA-assigned.

## Fix implemented in this pull request

1. Treat `_display_name` as a filename, not a filesystem path: normalize `/` and `\` separators and retain only the final basename.
2. Reject missing, blank, dot, dot-dot and NUL-containing names, using the existing generated-name fallback.
3. Canonicalize the destination and cache root and require exact canonical parent equality. This rejects path-prefix confusion and existing symlinks that escape the cache.
4. Add JVM/JUnit tests for benign names, relative and absolute traversal, Windows-style separators, invalid names, and symlink escapes.

Affected consumers should update after maintainers review and publish a patched release. Limiting exported share entry points may reduce attack surface in some apps but does not resolve the library defect.

## Verification

The isolated Kotlin path-resolution helper previously passed 25,017 local JVM checks, including randomized filenames and symlinks. The JUnit tests in `android/src/test/kotlin/com/kasem/receive_sharing_intent/SharedCacheFileTest.kt` should be run by maintainers using the Android module's `testDebugUnitTest` task. A full Android/Flutter integration build and real-device share-intent regression were **not run** in this submission environment.



Version provenance can be independently reproduced:

```sh
git blame -sL '/File(context.cacheDir, fileName)/,+1' master -- android/src/main/kotlin/com/kasem/receive_sharing_intent/FileDirectory.kt
git show c61c0e7^:pubspec.yaml | grep '^version:'
git show c61c0e7:pubspec.yaml | grep '^version:'
```
