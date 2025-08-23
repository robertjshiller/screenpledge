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
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.screenpledge.app/screentime"
    private val LOG_TAG = "ScreenPledgeNative"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method != "requestPermission" && call.method != "isPermissionGranted") {
                if (!canQueryUsageStats()) {
                    result.error("PERMISSION_DENIED", "Usage access permission is not granted.", null)
                    return@setMethodCallHandler
                }
            }

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
                    "getUsageForApps" -> {
                        val packageNames = call.argument<List<String>>("packageNames")
                        if (packageNames == null) {
                            result.error("INVALID_ARGUMENT", "packageNames argument is missing or not a list.", null)
                            return@setMethodCallHandler
                        }
                        result.success(getUsageForApps(packageNames))
                    }
                    "getTotalDeviceUsage" -> {
                        result.success(getTotalDeviceUsage())
                    }
                    "getUsageForDateRange" -> {
                        val startTime = call.argument<Long>("startTime")
                        val endTime = call.argument<Long>("endTime")
                        if (startTime == null || endTime == null) {
                            result.error("INVALID_ARGUMENT", "startTime or endTime is missing.", null)
                            return@setMethodCallHandler
                        }
                        result.success(getUsageForDateRange(startTime, endTime))
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

    // ✅ FIXED: This function is now more robust in handling timezones.
    private fun getUsageForDateRange(startTime: Long, endTime: Long): Map<String, Long> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val stats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startTime, endTime)
        val dailyUsageMap = mutableMapOf<String, Long>()

        if (stats == null) {
            Log.d(LOG_TAG, "UsageStatsManager returned null for the date range.")
            return dailyUsageMap
        }

        // The key change is how we bucket the stats. We will now correctly
        // handle the conversion from the stat's UTC timestamp to a local date.
        for (usageStats in stats) {
            // Create a calendar instance in the device's local timezone.
            val calendar = Calendar.getInstance(TimeZone.getDefault())
            // Set the calendar's time to the UTC timestamp of the usage event.
            calendar.timeInMillis = usageStats.firstTimeStamp
            
            // Now, format this calendar object (which represents the local time) into a date string.
            val dateKey = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(calendar.time)
            
            val currentTotal = dailyUsageMap.getOrDefault(dateKey, 0L)
            dailyUsageMap[dateKey] = currentTotal + usageStats.totalTimeInForeground
        }
        Log.d(LOG_TAG, "getUsageForDateRange returning ${dailyUsageMap.size} days of data.")
        return dailyUsageMap
    }

    private fun getUsageForApps(packageNames: List<String>): Long {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val (startTime, endTime) = getTodayTimeRange()
        val stats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startTime, endTime)
        return stats?.filter { packageNames.contains(it.packageName) }
                    ?.sumOf { it.totalTimeInForeground } ?: 0L
    }

    private fun getTotalDeviceUsage(): Long {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val (startTime, endTime) = getTodayTimeRange()
        val stats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startTime, endTime)
        return stats?.sumOf { it.totalTimeInForeground } ?: 0L
    }

    // ✅ FIXED: This function is now more explicit and robust about using the local timezone.
    private fun getTodayTimeRange(): Pair<Long, Long> {
        // Create a Calendar instance explicitly using the device's default (local) timezone.
        val calendar = Calendar.getInstance(TimeZone.getDefault())
        // Set the time to the beginning of the current day in that timezone.
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        
        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()
        
        // Add logging to verify the calculated time range.
        Log.d(LOG_TAG, "Calculated 'Today' time range: START=${Date(startTime)}, END=${Date(endTime)}")
        return Pair(startTime, endTime)
    }

    // --- The rest of the helper methods remain unchanged ---

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
        return appList.sortedBy { it["name"] as String }
    }

    private fun getUsageTopApps(): List<Map<String, Any?>> {
        val pm = this.packageManager
        val launchablePackages = getLaunchablePackages(pm)
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.DAY_OF_YEAR, -7)
        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()
        val stats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startTime, endTime)
        val appList = mutableListOf<Map<String, Any?>>()
        val aggregatedStats = stats?.groupBy { it.packageName }
            ?.mapValues { entry -> entry.value.sumOf { it.totalTimeInForeground } }
            ?.toList()
            ?.sortedByDescending { it.second } ?: emptyList()
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