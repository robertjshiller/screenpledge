package com.screenpledge.app

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.os.Build
import android.os.Process
import android.provider.Settings
import android.util.Log // ✅ ADDED: For native logging
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.Calendar

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.screenpledge.app/screentime"
    private val LOG_TAG = "ScreenPledgeNative" // ✅ ADDED: A tag for our logs

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "requestPermission" -> {
                    openUsageAccessSettings()
                    result.success(null)
                }
                "isPermissionGranted" -> {
                    result.success(canQueryUsageStats())
                }
                "getInstalledApps" -> {
                    try {
                        result.success(getInstalledApps())
                    } catch (e: Exception) {
                        Log.e(LOG_TAG, "Error in getInstalledApps: ${e.message}", e)
                        result.error("NATIVE_ERROR", "Failed to get installed apps: ${e.message}", null)
                    }
                }
                "getUsageTopApps" -> {
                     if (!canQueryUsageStats()) {
                        result.error("PERMISSION_DENIED", "Usage access permission is not granted.", null)
                        return@setMethodCallHandler
                    }
                    try {
                        result.success(getUsageTopApps())
                    } catch (e: Exception) {
                        Log.e(LOG_TAG, "Error in getUsageTopApps: ${e.message}", e)
                        result.error("NATIVE_ERROR", "Failed to get usage stats: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    // This method remains unchanged.
    private fun openUsageAccessSettings() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        startActivity(intent)
    }

    // This method remains unchanged.
    private fun canQueryUsageStats(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            packageName
        )
        if (mode != AppOpsManager.MODE_ALLOWED) {
            return false
        }
        return try {
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val time = System.currentTimeMillis()
            usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, time - 60 * 1000, time)
            true
        } catch (e: Exception) {
            false
        }
    }

    /**
     * ✅ REWRITTEN: Gets the definitive list of all user-launchable applications.
     * This version is simpler and relies on the <queries> tag in the manifest.
     */
    private fun getInstalledApps(): List<Map<String, Any?>> {
        val pm = this.packageManager
        val mainIntent = Intent(Intent.ACTION_MAIN, null).addCategory(Intent.CATEGORY_LAUNCHER)
        val appList = mutableListOf<Map<String, Any?>>()

        val resolvedInfos = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.queryIntentActivities(mainIntent, PackageManager.ResolveInfoFlags.of(0L))
        } else {
            pm.queryIntentActivities(mainIntent, 0)
        }
        
        // ✅ LOGGING ADDED: See how many apps the OS returns before any filtering.
        Log.d(LOG_TAG, "queryIntentActivities returned ${resolvedInfos.size} apps.")

        for (info in resolvedInfos) {
            val appInfo = info.activityInfo.applicationInfo
            val appName = appInfo.loadLabel(pm).toString()
            val packageName = appInfo.packageName
            val icon = appInfo.loadIcon(pm)

            appList.add(mapOf(
                "name" to appName,
                "packageName" to packageName,
                "icon" to drawableToBytes(icon)
            ))
        }
        
        // ✅ LOGGING ADDED: See the final count of apps being sent to Flutter.
        Log.d(LOG_TAG, "Final app list count for getInstalledApps: ${appList.size}")
        return appList.sortedBy { it["name"] as String }
    }

    /**
     * ✅ REWRITTEN: Gets the most used apps, filtered by the definitive list of launchable apps.
     */
    private fun getUsageTopApps(): List<Map<String, Any?>> {
        val pm = this.packageManager
        // Step 1: Get the definitive set of launchable package names.
        val launchablePackages = getLaunchablePackages(pm)
        Log.d(LOG_TAG, "Found ${launchablePackages.size} launchable packages for filtering usage stats.")

        // Step 2: Query usage stats.
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.DAY_OF_YEAR, -7)
        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()

        val stats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startTime, endTime)
        Log.d(LOG_TAG, "UsageStatsManager returned ${stats.size} usage events.")
        val appList = mutableListOf<Map<String, Any?>>()

        val aggregatedStats = stats.groupBy { it.packageName }
            .mapValues { entry -> entry.value.sumOf { it.totalTimeInForeground } }
            .toList()
            .sortedByDescending { it.second }

        // Step 3: Filter usage stats against the launchable packages set.
        for ((packageName, totalTime) in aggregatedStats) {
            if (totalTime <= 0) continue
            if (launchablePackages.contains(packageName)) {
                try {
                    val appInfo = pm.getApplicationInfo(packageName, 0)
                    val appName = appInfo.loadLabel(pm).toString()
                    val icon = appInfo.loadIcon(pm)
                    appList.add(mapOf(
                        "name" to appName,
                        "packageName" to packageName,
                        "icon" to drawableToBytes(icon)
                    ))
                } catch (e: PackageManager.NameNotFoundException) {
                    continue
                }
            }
        }
        Log.d(LOG_TAG, "Final app list count for getUsageTopApps: ${appList.size}")
        return appList.take(20)
    }

    // This helper function remains unchanged but is still critical.
    private fun getLaunchablePackages(pm: PackageManager): Set<String> {
        val mainIntent = Intent(Intent.ACTION_MAIN, null).addCategory(Intent.CATEGORY_LAUNCHER)
        val packages = mutableSetOf<String>()

        val resolvedInfos = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.queryIntentActivities(mainIntent, PackageManager.ResolveInfoFlags.of(0L))
        } else {
            pm.queryIntentActivities(mainIntent, 0)
        }

        for (info in resolvedInfos) {
            packages.add(info.activityInfo.packageName)
        }
        return packages
    }

    // This helper function remains unchanged.
    private fun drawableToBytes(drawable: Drawable): ByteArray {
        // ✅ FIXED: The body of this function was missing in the previous turn.
        val bitmap = Bitmap.createBitmap(drawable.intrinsicWidth, drawable.intrinsicHeight, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }
}