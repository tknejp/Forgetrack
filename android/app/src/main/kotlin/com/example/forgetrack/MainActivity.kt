package com.knejp.forgetrack

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "forgetrack/health_connect_settings")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openSettings" -> result.success(openHealthConnectSettings())
                    else -> result.notImplemented()
                }
            }

        // DIY in-app updater bridge — Dart only calls these on the internal
        // flavor (gated by BuildConfig.isInternal). On dev/prod the channel
        // is registered but never invoked; the FileProvider authority lives
        // in the internal manifest only, so installApk would throw on
        // dev/prod even if reached.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "forgetrack/app_update")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canRequestInstallPackages" ->
                        result.success(canRequestInstallPackages())
                    "openInstallPermissionSettings" -> {
                        openInstallPermissionSettings()
                        result.success(null)
                    }
                    "installApk" -> {
                        val path = call.argument<String>("path")
                        if (path.isNullOrEmpty()) {
                            result.error("INVALID_ARGS", "path argument missing", null)
                        } else {
                            try {
                                installApk(path)
                                result.success(null)
                            } catch (e: Exception) {
                                result.error("INSTALL_FAILED", e.message, e.stackTraceToString())
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun canRequestInstallPackages(): Boolean {
        // API 26+ unknown-sources is a per-app runtime grant. minSdk is 26
        // so this check applies on every supported device.
        return packageManager.canRequestPackageInstalls()
    }

    private fun openInstallPermissionSettings() {
        val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
            data = Uri.parse("package:$packageName")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    private fun installApk(path: String) {
        val file = File(path)
        if (!file.exists()) {
            throw IllegalStateException("APK not found at $path")
        }

        val uri: Uri = FileProvider.getUriForFile(
            this,
            "$packageName.update_file_provider",
            file,
        )

        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            // PackageInstaller runs in a different process; grant it read
            // access to the content URI for the lifetime of the intent.
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    private fun openHealthConnectSettings(): Boolean {
        val intents = listOf(
            Intent("androidx.health.ACTION_HEALTH_CONNECT_SETTINGS"),
            packageManager.getLaunchIntentForPackage("com.google.android.apps.healthdata"),
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:com.google.android.apps.healthdata")
            },
        ).filterNotNull()

        for (intent in intents) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            if (intent.resolveActivity(packageManager) == null) continue
            startActivity(intent)
            return true
        }

        return false
    }
}
