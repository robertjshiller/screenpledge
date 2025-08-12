package com.screenpledge.app

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.Calendar

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.screenpledge.app/screentime"

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
                // ✅ ADDED: New method handlers for fetching app lists.
                "getInstalledApps" -> {
                    try {
                        result.success(getInstalledApps())
                    } catch (e: Exception) {
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
     * ✅ ADDED: Fetches a list of all user-installed, non-system applications.
     */
    private fun getInstalledApps(): List<Map<String, Any?>> {
        val packageManager = this.packageManager
        val apps = packageManager.getInstalledApplications(PackageManager.GET_META_DATA)
        val appList = mutableListOf<Map<String, Any?>>()

        for (app in apps) {
            // Filter out system apps to only show user-installed apps.
            if (app.flags and ApplicationInfo.FLAG_SYSTEM == 0) {
                val appName = packageManager.getApplicationLabel(app).toString()
                val packageName = app.packageName
                val icon = packageManager.getApplicationIcon(app)

                appList.add(mapOf(
                    "name" to appName,
                    "packageName" to packageName,
                    "icon" to drawableToBytes(icon)
                ))
            }
        }
        return appList.sortedBy { it["name"] as String }
    }

    /**
     * ✅ ADDED: Fetches the most used apps in the last 7 days.
     */
    private fun getUsageTopApps(): List<Map<String, Any?>> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val packageManager = this.packageManager

        val calendar = Calendar.getInstance()
        calendar.add(Calendar.DAY_OF_YEAR, -7) // Look at the last 7 days
        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()

        val stats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startTime, endTime)
        val appList = mutableListOf<Map<String, Any?>>()

        // Group stats by package name and sum up the total time
        val aggregatedStats = stats.groupBy { it.packageName }
            .mapValues { entry -> entry.value.sumOf { it.totalTimeInForeground } }
            .toList()
            .sortedByDescending { it.second } // Sort by most time used
            .take(20) // Take the top 20 most used apps

        for ((packageName, totalTime) in aggregatedStats) {
            if (totalTime <= 0) continue
            try {
                val appInfo = packageManager.getApplicationInfo(packageName, 0)
                // Also filter out system apps from the top usage list.
                if (appInfo.flags and ApplicationInfo.FLAG_SYSTEM == 0) {
                    val appName = packageManager.getApplicationLabel(appInfo).toString()
                    val icon = packageManager.getApplicationIcon(appInfo)
                    appList.add(mapOf(
                        "name" to appName,
                        "packageName" to packageName,
                        "icon" to drawableToBytes(icon)
                    ))
                }
            } catch (e: PackageManager.NameNotFoundException) {
                // App might have been uninstalled after usage was logged.
                continue
            }
        }
        return appList
    }

    /**
     * ✅ ADDED: Helper function to convert a drawable (like an app icon) to a byte array.
     * This is necessary to send the image data over the platform channel to Flutter.
     */
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