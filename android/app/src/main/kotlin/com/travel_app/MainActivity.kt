package com.travel_app

import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Package name + signing SHA-1 let REST calls to Google pass an
        // Android-app-restricted API key (X-Android-Package / X-Android-Cert).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sunroute/app_identity")
            .setMethodCallHandler { call, result ->
                if (call.method == "getIdentity") {
                    result.success(mapOf("packageName" to packageName, "certSha1" to signingSha1()))
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun signingSha1(): String? = try {
        val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
                .signingInfo?.apkContentsSigners
        } else {
            @Suppress("DEPRECATION")
            packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES).signatures
        }
        signatures?.firstOrNull()?.let { sig ->
            MessageDigest.getInstance("SHA-1").digest(sig.toByteArray())
                .joinToString("") { "%02X".format(it) }
        }
    } catch (e: Exception) {
        null
    }
}
