package com.handwriting.texter.handwriting_to_text

import android.content.ContentValues
import android.os.Build
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "handwriting_to_text/downloads")
            .setMethodCallHandler { call, result ->
                if (call.method == "saveToDownloads") {
                    result.success(saveToDownloads(call.argument("name"), call.argument("mimeType"), call.argument("bytes")))
                } else {
                    result.notImplemented()
                }
            }
    }

    // Publishes a file into the shared Downloads collection via MediaStore,
    // which requires no storage permission on Android 10+. Direct writes to
    // /storage/emulated/0/Download are blocked by scoped storage, so this is
    // the only permissionless way for exports to appear in Downloads.
    private fun saveToDownloads(name: String?, mimeType: String?, bytes: ByteArray?): Boolean {
        if (name == null || mimeType == null || bytes == null) return false
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return false
        return try {
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, name)
                put(MediaStore.Downloads.MIME_TYPE, mimeType)
            }
            val uri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values) ?: return false
            contentResolver.openOutputStream(uri)?.use { it.write(bytes) } ?: return false
            true
        } catch (e: Exception) {
            false
        }
    }
}
