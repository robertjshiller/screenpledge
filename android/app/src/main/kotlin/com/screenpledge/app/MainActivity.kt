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
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.Calendar

class MainActivity: FlutterActivity() {
    // The unique name for our platform channel.
    private val CHANNEL = "com.screenpledge.app/screentime"
    // A tag for filtering our native logs in Logcat.
    private val LOG_TAG = "ScreenPledgeNative"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            // As a security best practice, we check for permission before executing
            // any method that requires access to usage stats.
            if (call.method != "requestPermission" && call.method != "isPermissionGranted") {
                if (!canQueryUsageStats()) {
                    // If permission is not granted, we return a specific error code
                    // that the Dart side can understand and handle gracefully.
                    result.error("PERMISSION_DENIED", "Usage access permission is not granted.", null)
                    return@setMethodCallHandler
                }
            }

            // We wrap the logic in a try-catch block to handle any unexpected native errors.
            try {
                when (call.method) {
                    "requestPermission" -> {
                        openUsageAccessSettings()
                        result.success(null)
                    }
                    "isPermissionGranted" -> {
                        result.success(canQueryUsageStats())
                    }
                    "getInstalledApps" -> {
                        result.success(getInstalledApps())
                    }
                    "getUsageTopApps" -> {
                        result.success(getUsageTopApps())
                    }
                    // ✅ ADDED: New handler for getting usage of specific apps.
                    "getUsageForApps" -> {
                        // We expect a list of package name strings from Flutter.
                        val packageNames = call.argument<List<String>>("packageNames")
                        if (packageNames == null) {
                            result.error("INVALID_ARGUMENT", "packageNames argument is missing or not a list.", null)
                            return@setMethodCallHandler
                        }
                        // Call the new function and return the result in milliseconds.
                        result.success(getUsageForApps(packageNames))
                    }
                    // ✅ ADDED: New handler for getting total device usage.
                    "getTotalDeviceUsage" -> {
                        result.success(getTotalDeviceUsage())
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            } catch (e: Exception) {
                Log.e(LOG_TAG, "Error handling method ${call.method}: ${e.message}", e)
                result.error("NATIVE_ERROR", "An unexpected error occurred on the native side: ${e.message}", null)
            }
        }
    }

    // ✅ ADDED: New function to get combined usage for a specific list of apps since midnight.
    private fun getUsageForApps(packageNames: List<String>): Long {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val (startTime, endTime) = getTodayTimeRange()
        val stats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startTime, endTime)
        
        // Filter the stats to only include the apps we care about and sum their foreground time.
        return stats.filter { packageNames.contains(it.packageName) }
                    .sumOf { it.totalTimeInForeground }
    }

    // ✅ ADDED: New function to get the total usage for all apps on the device since midnight.
    private fun getTotalDeviceUsage(): Long {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val (startTime, endTime) = getTodayTimeRange()
        val stats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startTime, endTime)
        
        // Sum the foreground time for all returned stats.
        return stats.sumOf { it.totalTimeInForeground }
    }

    // ✅ ADDED: A helper to get the start and end time for "today" (from midnight to now).
    private fun getTodayTimeRange(): Pair<Long, Long> {
        val calendar = Calendar.getInstance()
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()
        return Pair(startTime, endTime)
    }

    // --- Existing Helper Methods ---

    private fun openUsageAccessSettings() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        startActivity(intent)
    }

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

    private fun getInstalledApps(): List<Map<String, Any?>> {
        val pm = this.packageManager
        val mainIntent = Intent(Intent.ACTION_MAIN, null).addCategory(Intent.CATEGORY_LAUNCHER)
        val appList = mutableListOf<Map<String, Any?>>()

        val resolvedInfos = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.queryIntentActivities(mainIntent, PackageManager.ResolveInfoFlags.of(0L))
        } else {
            pm.queryIntentActivities(mainIntent, 0)
        }
        
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
        
        Log.d(LOG_TAG, "Final app list count for getInstalledApps: ${appList.size}")
        return appList.sortedBy { it["name"] as String }
    }

    private fun getUsageTopApps(): List<Map<String, Any?>> {
        val pm = this.packageManager
        val launchablePackages = getLaunchablePackages(pm)
        Log.d(LOG_TAG, "Found ${launchablePackages.size} launchable packages for filtering usage stats.")

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

    private fun drawableToBytes(drawable: Drawable): ByteArray {
        val bitmap = Bitmap.createBitmap(drawable.intrinsicWidth, drawable.intrinsicHeight, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }
}