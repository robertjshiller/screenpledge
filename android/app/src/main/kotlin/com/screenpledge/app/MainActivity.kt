package com.screenpledge.app

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Process
import android.provider.Settings
// REMOVED: These imports are no longer needed as we've removed the ActivityResultLauncher.
// import androidx.activity.result.ActivityResultLauncher
// import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    // Define a unique name for our platform channel.
    private val CHANNEL = "com.screenpledge.app/screentime"

    // ✅ REMOVED: The pendingResult variable is no longer needed because we are not waiting for a result from the settings screen.
    // private var pendingResult: MethodChannel.Result? = null

    // ✅ REMOVED: The entire Activity Result Launcher has been removed.
    // This "request and wait" approach is not compatible with the ACTION_USAGE_ACCESS_SETTINGS screen,
    // which does not return a result to the calling app.
    // private val usageAccessSettingsLauncher = ...

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Set up the MethodChannel and its handler.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            // This is where we handle incoming calls from Dart.
            when (call.method) {
                // ✅ CHANGED: This method is now a "fire and forget" operation.
                // It simply opens the settings page and immediately returns success to Flutter
                // to acknowledge that the call was received. It does NOT wait for the user.
                "requestPermission" -> {
                    openUsageAccessSettings()
                    result.success(null)
                }
                "isPermissionGranted" -> {
                    // This method still uses our reliable "verify by action" check.
                    result.success(canQueryUsageStats())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    /**
     * ✅ NEW: A simple method that launches an Intent to open the Usage Access Settings screen.
     * This is the "fire" part of our "fire and re-check" strategy.
     */
    private fun openUsageAccessSettings() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        startActivity(intent)
    }

    /**
     * The reliable "Verify by Action" method. This is the "re-check" part of our strategy.
     * It proactively tries to perform an action that requires the permission.
     * This remains the most reliable way to check the real-time permission status.
     */
    private fun canQueryUsageStats(): Boolean {
        // First, do a quick, potentially stale check using AppOpsManager. This can fail-fast.
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            packageName
        )
        if (mode != AppOpsManager.MODE_ALLOWED) {
            return false
        }

        // The crucial step: To confirm the permission is *really* active,
        // we perform a tiny, harmless query. If this query throws an exception,
        // it means the permission is not yet active or has been revoked.
        return try {
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val time = System.currentTimeMillis()
            // We query for stats in the last minute. The result doesn't matter,
            // only that the call itself doesn't crash.
            usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, time - 60 * 1000, time)
            // If we reach this line without an exception, permission is truly granted.
            true
        } catch (e: Exception) {
            // If any exception is thrown (e.g., SecurityException), it means the permission is not active.
            false
        }
    }
}