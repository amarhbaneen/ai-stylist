package dev.placeholder.ai_stylist

import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openLens" -> result.success(openLens(call.argument<String>("path")))
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Hands one image to Google Lens in the Google app, if installed (D-41).
     * Returns false when Lens is not available, so the caller can fall back
     * to the system share sheet. The image must be in files/visual_search/.
     */
    private fun openLens(path: String?): Boolean {
        if (path == null) return false
        val file = File(path)
        val dir = File(filesDir, "visual_search")
        if (file.parentFile?.canonicalPath != dir.canonicalPath || !file.exists()) return false
        val uri = FileProvider.getUriForFile(this, "$packageName.visualsearch", file)
        val intent = Intent(Intent.ACTION_SEND).apply {
            setClassName(GOOGLE_APP, LENS_ACTIVITY)
            type = "image/jpeg"
            putExtra(Intent.EXTRA_STREAM, uri)
            clipData = ClipData.newRawUri(null, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        return try {
            startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        } catch (e: SecurityException) {
            false
        }
    }

    companion object {
        private const val CHANNEL = "ai_stylist/visual_search"
        private const val GOOGLE_APP = "com.google.android.googlequicksearchbox"
        private const val LENS_ACTIVITY =
            "com.google.android.apps.search.lens.LensShareEntryPointActivity"
    }
}
