package com.example.droid_lm

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * MainActivity handles Flutter MethodChannel communication for Usage Access permissions.
 * 
 * Exposes two methods via "usage_stats_channel":
 * - openUsageAccessSettings: Opens Android Usage Access settings screen
 * - hasUsageAccess: Checks if usage access permission is granted
 * 
 * Compatible with Android 11+ (API 30+), no deprecated APIs.
 */
class MainActivity : FlutterActivity() {

    // MethodChannel name for Flutter communication
    private val CHANNEL = "usage_stats_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Set up MethodChannel for usage stats operations
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openUsageAccessSettings" -> {
                    openUsageAccessSettings()
                    result.success(null)
                }
                "hasUsageAccess" -> {
                    result.success(hasUsageAccess())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    /**
     * Opens the Android Usage Access settings screen.
     * User must manually grant permission from this screen.
     */
    private fun openUsageAccessSettings() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    /**
     * Checks whether this app has Usage Access permission.
     * Uses AppOpsManager.checkOpNoThrow() which is the modern, non-deprecated approach.
     * 
     * @return true if usage access is granted, false otherwise
     */
    private fun hasUsageAccess(): Boolean {
        val appOpsManager = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOpsManager.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }
}
