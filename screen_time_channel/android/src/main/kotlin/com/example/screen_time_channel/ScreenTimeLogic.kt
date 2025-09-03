package com.example.screen_time_channel

import android.app.AppOpsManager
import android.app.usage.UsageEvents
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
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import kotlin.math.max
import kotlin.math.min

class ScreenTimeLogic(private val context: Context) {

    private val LOG_TAG = "ScreenPledgeNativeLogic"

    // --- ALL THE HELPER METHODS FROM YOUR OLD MainActivity.kt ARE PASTED HERE ---
    
    private data class Interval(var start: Long, var end: Long)

    private fun merge(intervals: MutableList<Interval>): MutableList<Interval> {
        if (intervals.isEmpty()) return mutableListOf()
        intervals.sortBy { it.start }
        val out = mutableListOf<Interval>()
        var cur = intervals[0]
        for (i in 1 until intervals.size) {
            val nxt = intervals[i]
            if (nxt.start <= cur.end) {
                cur.end = max(cur.end, nxt.end)
            } else {
                out.add(cur)
                cur = nxt
            }
        }
        out.add(cur)
        return out
    }

    private fun intersectMerged(a: List<Interval>, b: List<Interval>): MutableList<Interval> {
        val out = mutableListOf<Interval>()
        var i = 0
        var j = 0
        while (i < a.size && j < b.size) {
            val s = max(a[i].start, b[j].start)
            val e = min(a[i].end, b[j].end)
            if (e > s) out.add(Interval(s, e))
            if (a[i].end < b[j].end) i++ else j++
        }
        return out
    }

    private fun sum(intervals: List<Interval>): Long {
        var total = 0L
        for (iv in intervals) total += (iv.end - iv.start)
        return total
    }

    private fun addClipped(out: MutableList<Interval>, start: Long, end: Long, lo: Long, hi: Long) {
        val s = max(start, lo)
        val e = min(end, hi)
        if (e > s) out.add(Interval(s, e))
    }

    private fun todayRange(): Pair<Long, Long> {
        val tz = TimeZone.getDefault()
        val cal = Calendar.getInstance(tz).apply {
            set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
        }
        val start = cal.timeInMillis
        val end = System.currentTimeMillis()
        return start to end
    }

    private fun last7LocalDays(): List<Pair<Long, Long>> {
        val tz = TimeZone.getDefault()
        val out = ArrayList<Pair<Long, Long>>(7)
        val start = Calendar.getInstance(tz).apply {
            set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
            add(Calendar.DAY_OF_YEAR, -6)
        }
        for (i in 0..6) {
            val s = (start.clone() as Calendar).apply { add(Calendar.DAY_OF_YEAR, i) }
            val e = (s.clone() as Calendar).apply { add(Calendar.DAY_OF_YEAR, 1) }
            out.add(s.timeInMillis to e.timeInMillis)
        }
        return out
    }

    private fun last6CompletedLocalDays(): List<Pair<Long, Long>> {
        val tz = TimeZone.getDefault()
        val out = ArrayList<Pair<Long, Long>>(6)
        val start = Calendar.getInstance(tz).apply {
            set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
            add(Calendar.DAY_OF_YEAR, -6)
        }
        for (i in 0..5) {
            val s = (start.clone() as Calendar).apply { add(Calendar.DAY_OF_YEAR, i) }
            val e = (s.clone() as Calendar).apply { add(Calendar.DAY_OF_YEAR, 1) }
            out.add(s.timeInMillis to e.timeInMillis)
        }
        return out
    }

    private fun resumePauseTypes(): Pair<Int, Int> {
        val resumed = if (Build.VERSION.SDK_INT >= 29)
            UsageEvents.Event.ACTIVITY_RESUMED else UsageEvents.Event.MOVE_TO_FOREGROUND
        val paused  = if (Build.VERSION.SDK_INT >= 29)
            UsageEvents.Event.ACTIVITY_PAUSED  else UsageEvents.Event.MOVE_TO_BACKGROUND
        return resumed to paused
    }

    private val SCREEN_ON  = UsageEvents.Event.SCREEN_INTERACTIVE
    private val SCREEN_OFF = UsageEvents.Event.SCREEN_NON_INTERACTIVE
    private val UNLOCKED   = UsageEvents.Event.KEYGUARD_HIDDEN
    private val LOCKED     = UsageEvents.Event.KEYGUARD_SHOWN

    @Volatile private var cachedLaunchable: Set<String>? = null
    private fun launchablePackages(): Set<String> {
        cachedLaunchable?.let { return it }
        val pm = context.packageManager
        val main = Intent(Intent.ACTION_MAIN, null).addCategory(Intent.CATEGORY_LAUNCHER)
        val set = mutableSetOf<String>()
        val infos = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.queryIntentActivities(main, PackageManager.ResolveInfoFlags.of(0L))
        } else {
            @Suppress("DEPRECATION") pm.queryIntentActivities(main, 0)
        }
        for (ri in infos) set.add(ri.activityInfo.packageName)
        cachedLaunchable = set
        return set
    }

    private fun queryEvents(lo: Long, hi: Long, lookbackHours: Int = 12): UsageEvents {
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val from = lo - lookbackHours * 60L * 60L * 1000L
        return usm.queryEvents(from, hi)
    }

    private fun buildToggleIntervals(onType: Int, offType: Int, lo: Long, hi: Long): MutableList<Interval> {
        val e = UsageEvents.Event()
        val out = mutableListOf<Interval>()
        var open: Long? = null
        val evs = queryEvents(lo, hi)
        fun close(at: Long) {
            val start = open ?: return
            addClipped(out, start, at, lo, hi)
            open = null
        }
        while (evs.hasNextEvent()) {
            evs.getNextEvent(e)
            when (e.eventType) {
                onType  -> if (open == null) open = e.timeStamp
                offType -> close(e.timeStamp)
            }
        }
        if (open != null) close(hi)
        return merge(out)
    }

    private fun buildAppActiveIntervals(
        lo: Long,
        hi: Long,
        include: (String) -> Boolean
    ): MutableList<Interval> {
        val (RESUMED, PAUSED) = resumePauseTypes()
        val evs = queryEvents(lo, hi)
        val e = UsageEvents.Event()
        val openSince = HashMap<String, Long>()
        val out = mutableListOf<Interval>()

        fun start(pkg: String, t: Long) {
            if (!include(pkg)) return
            if (!openSince.containsKey(pkg)) openSince[pkg] = t
        }
        fun stop(pkg: String, t: Long) {
            if (!include(pkg)) return
            val st = openSince.remove(pkg) ?: return
            addClipped(out, st, t, lo, hi)
        }

        while (evs.hasNextEvent()) {
            evs.getNextEvent(e)
            val pkg = e.packageName ?: continue
            val t = e.timeStamp
            when (e.eventType) {
                RESUMED -> start(pkg, t)
                PAUSED  -> stop(pkg, t)
            }
        }
        for ((pkg, st) in openSince) {
            if (!include(pkg)) continue
            addClipped(out, st, hi, lo, hi)
        }
        return merge(out)
    }

    private fun gateAndSumStrict(active: MutableList<Interval>, lo: Long, hi: Long): Long {
        val screen = buildToggleIntervals(SCREEN_ON, SCREEN_OFF, lo, hi)
        val unlocked = buildToggleIntervals(UNLOCKED, LOCKED, lo, hi)
        if (screen.isEmpty()) {
            return 0L
        }
        if (unlocked.isEmpty()) {
            unlocked.clear()
            unlocked.add(Interval(lo, hi))
        }
        val gate = intersectMerged(screen, unlocked)
        val activeMerged = merge(active)
        val counted = intersectMerged(activeMerged, gate)
        val total = sum(counted)
        val gateTotal = sum(gate)
        return min(total, gateTotal)
    }

    private data class RangeUsage(val perApp: Map<String, Long>, val deviceTotal: Long)

    private fun buildRangeUsage(lo: Long, hi: Long): RangeUsage {
        val launchable = launchablePackages()
        val activeIntervals = buildAppActiveIntervals(lo, hi) { pkg -> launchable.contains(pkg) }
        val deviceTotal = gateAndSumStrict(activeIntervals, lo, hi)
        val perApp = HashMap<String, Long>().apply {
            val (RESUMED, PAUSED) = resumePauseTypes()
            val evs = queryEvents(lo, hi)
            val e = UsageEvents.Event()
            val open = HashMap<String, Long>()
            fun open(pkg: String, t: Long) {
                if (!launchable.contains(pkg)) return
                if (!containsKey(pkg)) put(pkg, 0L)
                if (!open.containsKey(pkg)) open[pkg] = t
            }
            fun close(pkg: String, t: Long) {
                if (!launchable.contains(pkg)) return
                val st = open.remove(pkg) ?: return
                val s = max(st, lo); val end = min(t, hi)
                if (end > s) this[pkg] = (this[pkg] ?: 0L) + (end - s)
            }
            while (evs.hasNextEvent()) {
                evs.getNextEvent(e)
                val pkg = e.packageName ?: continue
                when (e.eventType) {
                    RESUMED -> open(pkg, e.timeStamp)
                    PAUSED  -> close(pkg, e.timeStamp)
                }
            }
            for ((pkg, st) in open) {
                if (!launchable.contains(pkg)) continue
                val s = max(st, lo)
                if (hi > s) this[pkg] = (this[pkg] ?: 0L) + (hi - s)
            }
        }
        return RangeUsage(perApp, deviceTotal)
    }

    fun getDailyUsageBreakdown(): List<Map<String, Any?>> {
        val pm = context.packageManager
        val launchablePackages = launchablePackages()
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val (startTime, endTime) = todayRange()

        val stats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startTime, endTime)
        val appList = mutableListOf<Map<String, Any?>>()

        if (stats == null) {
            return appList
        }

        for (usageStats in stats) {
            if (usageStats.totalTimeInForeground <= 0) continue
            if (launchablePackages.contains(usageStats.packageName)) {
                try {
                    val appInfo = pm.getApplicationInfo(usageStats.packageName, 0)
                    val appName = appInfo.loadLabel(pm).toString()
                    val icon = appInfo.loadIcon(pm)
                    appList.add(mapOf(
                        "name" to appName,
                        "packageName" to usageStats.packageName,
                        "icon" to drawableToBytes(icon),
                        "usageMillis" to usageStats.totalTimeInForeground
                    ))
                } catch (e: PackageManager.NameNotFoundException) {
                    continue
                }
            }
        }
        
        appList.sortByDescending { it["usageMillis"] as Long }
        return appList
    }

    fun getTotalUsageForDate(dateMillis: Long): Long {
        val tz = TimeZone.getDefault()
        val cal = Calendar.getInstance(tz).apply { timeInMillis = dateMillis }
        cal.set(Calendar.HOUR_OF_DAY, 0)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        val dayStart = cal.timeInMillis
        cal.add(Calendar.DAY_OF_YEAR, 1)
        val dayEnd = cal.timeInMillis
        val total = buildRangeUsage(dayStart, dayEnd).deviceTotal
        return min(total, 24L * 60L * 60L * 1000L)
    }

    fun getScreenTimeForLastSixDays(): List<Long> {
        val out = ArrayList<Long>(6)
        for ((lo, hi) in last6CompletedLocalDays()) {
            val usage = buildRangeUsage(lo, hi).deviceTotal
            val dayTotal = min(usage, 24L * 60L * 60L * 1000L)
            out.add(dayTotal)
        }
        return out
    }

    fun getWeeklyDeviceScreenTime(): Map<String, Long> {
        val out = LinkedHashMap<String, Long>(7)
        val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.US).apply { timeZone = TimeZone.getDefault() }
        for ((lo, hi) in last7LocalDays()) {
            val usage = buildRangeUsage(lo, hi).deviceTotal
            val dayTotal = min(usage, 24L * 60L * 60L * 1000L)
            val key = sdf.format(Date(lo))
            out[key] = dayTotal
        }
        return out
    }

    fun getTotalDeviceUsage(): Long {
        val (lo, hi) = todayRange()
        val total = buildRangeUsage(lo, hi).deviceTotal
        return total
    }

    fun getCountedDeviceUsage(goalType: String, tracked: List<String>, exempt: List<String>): Long {
        val (lo, hi) = todayRange()
        val launchable = launchablePackages().toSet()
        val active = when (goalType.lowercase(Locale.US)) {
            "custom_group" -> buildAppActiveIntervals(lo, hi) { pkg ->
                launchable.contains(pkg) && tracked.contains(pkg)
            }
            "total_time" -> buildAppActiveIntervals(lo, hi) { pkg ->
                launchable.contains(pkg) && !exempt.contains(pkg)
            }
            else -> buildAppActiveIntervals(lo, hi) { pkg ->
                launchable.contains(pkg)
            }
        }
        val counted = gateAndSumStrict(active, lo, hi)
        return counted
    }
    
    fun getUsageForDateRangeBucketed(startTime: Long, endTime: Long): Map<String, Long> {
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val daily = mutableMapOf<String, Long>()
        val cal = Calendar.getInstance(TimeZone.getDefault()).apply { timeInMillis = startTime }
        val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.US).apply { timeZone = TimeZone.getDefault() }
        while (cal.timeInMillis <= endTime) {
            val dayStart = (cal.clone() as Calendar).apply {
                set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
            }
            val dayEnd = (dayStart.clone() as Calendar).apply { add(Calendar.DAY_OF_YEAR, 1) }
            val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, dayStart.timeInMillis, dayEnd.timeInMillis)
            val total = stats?.sumOf { it.totalTimeInForeground } ?: 0L
            daily[sdf.format(dayStart.time)] = min(total, 24L * 60L * 60L * 1000L)
            cal.add(Calendar.DAY_OF_YEAR, 1)
        }
        return daily
    }

    fun getUsageForApps(packageNames: List<String>): Long {
        if (packageNames.isEmpty()) return 0L
        val (lo, hi) = todayRange()
        val perApp = buildRangeUsage(lo, hi).perApp
        var total = 0L
        for (pkg in packageNames) total += (perApp[pkg] ?: 0L)
        return total
    }

    fun openUsageAccessSettings() {
        // We need to add this flag when calling from a non-Activity context.
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }

    fun canQueryUsageStats(): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            context.packageName
        )
        if (mode != AppOpsManager.MODE_ALLOWED) return false
        return try {
            val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val t = System.currentTimeMillis()
            usm.queryEvents(t - 60_000L, t)
            true
        } catch (_: Exception) { false }
    }

    fun getInstalledApps(): List<Map<String, Any?>> {
        val pm = context.packageManager
        val main = Intent(Intent.ACTION_MAIN, null).addCategory(Intent.CATEGORY_LAUNCHER)
        val out = mutableListOf<Map<String, Any?>>()
        val infos = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.queryIntentActivities(main, PackageManager.ResolveInfoFlags.of(0L))
        } else {
            @Suppress("DEPRECATION") pm.queryIntentActivities(main, 0)
        }
        for (info in infos) {
            val appInfo = info.activityInfo.applicationInfo
            val name = appInfo.loadLabel(pm).toString()
            val pkg = appInfo.packageName
            val icon = appInfo.loadIcon(pm)
            out.add(mapOf(
                "name" to name,
                "packageName" to pkg,
                "icon" to drawableToBytes(icon)
            ))
        }
        return out.sortedBy { it["name"] as String }
    }

    fun getUsageTopApps(): List<Map<String, Any?>> {
        val pm = context.packageManager
        val launchable = launchablePackages()
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val cal = Calendar.getInstance().apply { add(Calendar.DAY_OF_YEAR, -7) }
        val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, cal.timeInMillis, System.currentTimeMillis())
        val list = mutableListOf<Map<String, Any?>>()
        val agg = stats?.groupBy { it.packageName }
            ?.mapValues { e -> e.value.sumOf { it.totalTimeInForeground } }
            ?.toList()
            ?.sortedByDescending { it.second } ?: emptyList()
        for ((pkg, total) in agg) {
            if (total <= 0) continue
            if (!launchable.contains(pkg)) continue
            try {
                val appInfo = pm.getApplicationInfo(pkg, 0)
                val name = appInfo.loadLabel(pm).toString()
                val icon = appInfo.loadIcon(pm)
                list.add(mapOf("name" to name, "packageName" to pkg, "icon" to drawableToBytes(icon)))
            } catch (_: PackageManager.NameNotFoundException) { /* skip */ }
        }
        return list.take(20)
    }

    private fun drawableToBytes(drawable: Drawable): ByteArray {
        val width = max(1, drawable.intrinsicWidth)
        val height = max(1, drawable.intrinsicHeight)
        val bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        val stream = ByteArrayOutputStream()
        bmp.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }

    // This is the new entry point for method calls
    fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "requestPermission" && call.method != "isPermissionGranted") {
            if (!canQueryUsageStats()) {
                result.error("PERMISSION_DENIED", "Usage access permission is not granted.", null)
                return
            }
        }
        try {
            when (call.method) {
                "requestPermission" -> { openUsageAccessSettings(); result.success(null) }
                "isPermissionGranted" -> result.success(canQueryUsageStats())
                "getInstalledApps" -> result.success(getInstalledApps())
                "getUsageTopApps"  -> result.success(getUsageTopApps())
                "getUsageForApps" -> {
                    val pkgs = call.argument<List<String>>("packageNames")
                    if (pkgs == null) {
                        result.error("INVALID_ARGUMENT", "packageNames argument is missing or not a list.", null)
                        return
                    }
                    result.success(getUsageForApps(pkgs))
                }
                "getTotalDeviceUsage" -> result.success(getTotalDeviceUsage())
                "getWeeklyDeviceScreenTime" -> result.success(getWeeklyDeviceScreenTime())
                "getCountedDeviceUsage" -> {
                    val goalType = call.argument<String>("goalType") ?: ""
                    val tracked  = call.argument<List<String>>("trackedPackages") ?: emptyList()
                    val exempt   = call.argument<List<String>>("exemptPackages")  ?: emptyList()
                    result.success(getCountedDeviceUsage(goalType, tracked, exempt))
                }
                "getUsageForDateRange" -> {
                    val start = call.argument<Long>("startTime")
                    val end   = call.argument<Long>("endTime")
                    if (start == null || end == null) {
                        result.error("INVALID_ARGUMENT", "startTime or endTime is missing.", null)
                        return
                    }
                    result.success(getUsageForDateRangeBucketed(start, end))
                }
                "getScreenTimeForLastSixDays" -> {
                    result.success(getScreenTimeForLastSixDays())
                }
                "getDailyUsageBreakdown" -> {
                    result.success(getDailyUsageBreakdown())
                }
                "getTotalUsageForDate" -> {
                    val dateMillis = call.argument<Long>("date")
                    if (dateMillis == null) {
                        result.error("INVALID_ARGUMENT", "date argument is missing or not a Long.", null)
                        return
                    }
                    result.success(getTotalUsageForDate(dateMillis))
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            Log.e(LOG_TAG, "Error handling method ${call.method}: ${e.message}", e)
            result.error("NATIVE_ERROR", "An unexpected error occurred on the native side: ${e.message}", null)
        }
    }
}