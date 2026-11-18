package dev.placeholder.ai_stylist

import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openLens" -> result.success(openLens(call.argument<String>("path")))
                    "appIdentity" -> result.success(
                        mapOf("package" to packageName, "sha1" to signingSha1()),
                    )
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

    /**
     * SHA-1 of this app's signing certificate, as upper-case hex: sent as
     * X-Android-Cert so a Google API key restricted to this app works (D-43).
     */
    private fun signingSha1(): String? = try {
        val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            packageManager.getPackageInfo(
                packageName,
                PackageManager.GET_SIGNING_CERTIFICATES,
            ).signingInfo?.apkContentsSigners
        } else {
            @Suppress("DEPRECATION")
            packageManager.getPackageInfo(
                packageName,
                PackageManager.GET_SIGNATURES,
            ).signatures
        }
        signatures?.firstOrNull()?.toByteArray()?.let { cert ->
            MessageDigest.getInstance("SHA-1").digest(cert)
                .joinToString("") { "%02X".format(it) }
        }
    } catch (e: PackageManager.NameNotFoundException) {
        null
    }

    companion object {
        private const val CHANNEL = "ai_stylist/visual_search"
        private const val GOOGLE_APP = "com.google.android.googlequicksearchbox"
        private const val LENS_ACTIVITY =
            "com.google.android.apps.search.lens.LensShareEntryPointActivity"
    }
}
