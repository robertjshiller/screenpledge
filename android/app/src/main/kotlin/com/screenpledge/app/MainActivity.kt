// File: android/app/src/main/kotlin/com/screenpledge/app/MainActivity.kt
// -------------------------------------------------------------------------------------------------
// ScreenPledge: Settings‑accurate screen‑time on Android
//
// This version implements a STRICT, Digital‑Wellbeing‑style parser for daily usage:
//   • Build app‑active intervals from foreground events (RESUMED/PAUSED or MOVE_TO_*, API‑aware)
//   • Build gating windows: SCREEN_INTERACTIVE/NON_INTERACTIVE  ∩  KEYGUARD_HIDDEN/SHOWN
//   • Intersect ACTIVE with the gate, CLIP to local day bounds, MERGE, and SUM
//   • Filter to LAUNCHABLE apps for device totals (avoid SystemUI inflating totals)
//   • Conservative fallbacks to avoid 24h spikes on emulators/OEMs with missing gates:
//       - If screen gate is MISSING for a day → return 0 for that day (strict & safe)
//       - If unlock gate is MISSING → use SCREEN gate only (many OEMs omit keyguard events)
//   • Hard‑cap per‑day total to 24h for additional safety
//
// Channel methods preserved:
//   - requestPermission / isPermissionGranted
//   - getInstalledApps / getUsageTopApps
//   - getUsageForApps (sum of specific packages since midnight; per‑app totals, overlaps allowed)
//   - getTotalDeviceUsage (strict, gated device total since midnight)
//   - getWeeklyDeviceScreenTime (strict, 7 daily totals, local TZ)
//   - getCountedDeviceUsage (goal‑aware today: total minus exemptions OR only tracked apps; strict)
//   - getUsageForDateRange (legacy bucketed aggregates; events are preferred for charts)
//
// Notes:
//   • This file is intentionally verbose and heavily commented for clarity and future maintenance.
//   • All intervals are treated as half‑open [start, end).
// -------------------------------------------------------------------------------------------------

package com.screenpledge.app

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
// ✅ CHANGED: We now import FlutterFragmentActivity instead of the basic FlutterActivity.
// This is required by the flutter_stripe package because it needs to display its own
// native UI components (Fragments) for the payment sheet.
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import kotlin.math.max
import kotlin.math.min

// ✅ CHANGED: The MainActivity class now extends FlutterFragmentActivity.
// This provides the necessary capabilities for plugins like flutter_stripe to function correctly.
// All of your existing screen time logic within this class remains completely unaffected by this change.
class MainActivity : FlutterFragmentActivity() {

    private val CHANNEL = "com.screenpledge.app/screentime"
    private val LOG_TAG = "ScreenPledgeNative"

    // =============================================================================================
    // 🧱 Interval helpers
    // =============================================================================================

    /** Simple half‑open interval [start, end) in ms. */
    private data class Interval(var start: Long, var end: Long)

    /** Merge overlapping intervals (input order irrelevant). */
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

    /** Intersect two **merged** lists. Result is merged. */
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

    /** Sum durations of intervals. */
    private fun sum(intervals: List<Interval>): Long {
        var total = 0L
        for (iv in intervals) total += (iv.end - iv.start)
        return total
    }

    /** Clip one interval to [lo, hi) and push to list if non‑empty. */
    private fun addClipped(out: MutableList<Interval>, start: Long, end: Long, lo: Long, hi: Long) {
        val s = max(start, lo)
        val e = min(end, hi)
        if (e > s) out.add(Interval(s, e))
    }

    // =============================================================================================
    // 🕓 Day windows (local midnight → midnight)
    // =============================================================================================

    /** Return [startOfToday, now] in **local** timezone. */
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

    /** Return 7 local day windows: [D‑6, D‑5, …, D] as pairs [start, end). */
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

    // ✅ ADDED: A new helper to get the specific time range for the last 6 *full* days.
    /** Return 6 local day windows for the past 6 days, EXCLUDING today. */
    private fun last6CompletedLocalDays(): List<Pair<Long, Long>> {
        val tz = TimeZone.getDefault()
        val out = ArrayList<Pair<Long, Long>>(6)
        // Start from yesterday.
        val start = Calendar.getInstance(tz).apply {
            set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
            add(Calendar.DAY_OF_YEAR, -6) // Start 6 days before today
        }
        for (i in 0..5) { // Loop 6 times
            val s = (start.clone() as Calendar).apply { add(Calendar.DAY_OF_YEAR, i) }
            val e = (s.clone() as Calendar).apply { add(Calendar.DAY_OF_YEAR, 1) }
            out.add(s.timeInMillis to e.timeInMillis)
        }
        return out
    }

    // =============================================================================================
    // 📲 Foreground & gating event types (API‑aware)
    // =============================================================================================

    /** Foreground types vary with API. */
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

    // =============================================================================================
    // 🧭 Launchable packages filter (prevents SystemUI inflating totals)
    // =============================================================================================

    @Volatile private var cachedLaunchable: Set<String>? = null

    private fun launchablePackages(): Set<String> {
        cachedLaunchable?.let { return it }
        val pm = packageManager
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

    // =============================================================================================
    // 🧩 Core parser: build intervals from events, gate, clip, merge, sum
    // =============================================================================================

    /** Query raw events for [lo, hi). We include a lookback to capture sessions that started before lo. */
    private fun queryEvents(lo: Long, hi: Long, lookbackHours: Int = 12): UsageEvents {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val from = lo - lookbackHours * 60L * 60L * 1000L
        return usm.queryEvents(from, hi)
    }

    /** Build **merged** toggle intervals from [onType]↔[offType], clipped to [lo, hi). */
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

    /**
     * Build **merged** app‑active intervals for **included packages only** using
     * ACTIVITY_RESUMED/PAUSED (or MOVE_TO_* pre‑29), clipped to [lo, hi).
     */
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

    /**
     * STRICT Settings‑style gating with **conservative fallbacks**.
     */
    private fun gateAndSumStrict(active: MutableList<Interval>, lo: Long, hi: Long): Long {
        Log.d(LOG_TAG, "--- gateAndSumStrict for day ${Date(lo)} ---")
        val screen = buildToggleIntervals(SCREEN_ON, SCREEN_OFF, lo, hi)
        val unlocked = buildToggleIntervals(UNLOCKED, LOCKED, lo, hi)
        Log.d(LOG_TAG, "  [Pipeline] Step 1: Raw Ungated App-Active Time = ${sum(active) / 1000}s (${active.size} intervals)")
        Log.d(LOG_TAG, "  [Pipeline] Step 2: Raw Screen-On Time         = ${sum(screen) / 1000}s (${screen.size} intervals)")
        Log.d(LOG_TAG, "  [Pipeline] Step 3: Raw Unlocked Time          = ${sum(unlocked) / 1000}s (${unlocked.size} intervals)")
        if (screen.isEmpty()) {
            Log.w(LOG_TAG, "  [Pipeline] FALLBACK: NO SCREEN events found. Returning 0 for this day.")
            return 0L
        }
        if (unlocked.isEmpty()) {
            Log.w(LOG_TAG, "  [Pipeline] FALLBACK: NO UNLOCK events found. Using SCREEN gate only.")
            unlocked.clear()
            unlocked.add(Interval(lo, hi))
        }
        val gate = intersectMerged(screen, unlocked)
        val activeMerged = merge(active)
        val counted = intersectMerged(activeMerged, gate)
        Log.d(LOG_TAG, "  [Pipeline] Step 4: Combined Gate Time         = ${sum(gate) / 1000}s (${gate.size} intervals)")
        Log.d(LOG_TAG, "  [Pipeline] Step 5: Final Counted Time         = ${sum(counted) / 1000}s (${counted.size} intervals)")
        val total = sum(counted)
        val gateTotal = sum(gate)
        val finalResult = min(total, gateTotal)
        Log.d(LOG_TAG, "  [Pipeline] Final Result (min of total and gate total): ${finalResult / 1000}s")
        Log.d(LOG_TAG, "--- End gateAndSumStrict ---")
        return finalResult
    }

    // =============================================================================================
    // 📊 Public builders
    // =============================================================================================

    /** Build per‑app (launchable only) and device total (gated) for [lo, hi). */
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

    // ✅ ADDED: A new function to get a detailed per-app usage breakdown for today.
    // This uses the high-level `queryUsageStats` as it provides a simple, aggregated list for the day.
    private fun getDailyUsageBreakdown(): List<Map<String, Any?>> {
        val pm = packageManager
        val launchablePackages = launchablePackages()
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val (startTime, endTime) = todayRange()

        val stats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startTime, endTime)
        val appList = mutableListOf<Map<String, Any?>>()

        if (stats == null) {
            Log.w(LOG_TAG, "getDailyUsageBreakdown: queryUsageStats returned null.")
            return appList
        }

        // Filter and map the stats to the format Flutter expects.
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
                        // We send the usage in milliseconds.
                        "usageMillis" to usageStats.totalTimeInForeground
                    ))
                } catch (e: PackageManager.NameNotFoundException) {
                    continue // Skip if app was uninstalled during the process.
                }
            }
        }
        
        // Sort the list by usage time, descending.
        appList.sortByDescending { it["usageMillis"] as Long }
        Log.d(LOG_TAG, "getDailyUsageBreakdown: Returning ${appList.size} apps with usage.")
        return appList
    }

    // =============================================================================================
    // 🔌 MethodChannel wiring
    // =============================================================================================

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method != "requestPermission" && call.method != "isPermissionGranted") {
                if (!canQueryUsageStats()) {
                    result.error("PERMISSION_DENIED", "Usage access permission is not granted.", null)
                    return@setMethodCallHandler
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
                            return@setMethodCallHandler
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
                            return@setMethodCallHandler
                        }
                        result.success(getUsageForDateRangeBucketed(start, end))
                    }
                    "getScreenTimeForLastSixDays" -> {
                        result.success(getScreenTimeForLastSixDays())
                    }

                    // ✅ ADDED: The new handler for the daily breakdown.
                    "getDailyUsageBreakdown" -> {
                        result.success(getDailyUsageBreakdown())
                    }
                    // ✅ NEW: Add the handler for our new method.
                    "getTotalUsageForDate" -> {
                        // Get the date from the arguments sent by Flutter.
                        val dateMillis = call.argument<Long>("date")
                        if (dateMillis == null) {
                            result.error("INVALID_ARGUMENT", "date argument is missing or not a Long.", null)
                            return@setMethodCallHandler
                        }
                        // Call our new Kotlin function and return the result.
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

    // =============================================================================================
    // 📅 Weekly (strict) and Today (strict)
    // =============================================================================================

    // ✅ NEW: The private Kotlin function that implements the logic for our new method.
    /**
     * Calculates the strict, gated device total for a specific historical day.
     * @param dateMillis The timestamp (any point during the target day) from Flutter.
     * @return The total usage in milliseconds for that entire day.
     */
    private fun getTotalUsageForDate(dateMillis: Long): Long {
        // Use the provided timestamp to construct a Calendar instance for the target day.
        val tz = TimeZone.getDefault()
        val cal = Calendar.getInstance(tz).apply { timeInMillis = dateMillis }

        // Calculate the exact start of that day (00:00:00).
        cal.set(Calendar.HOUR_OF_DAY, 0)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        val dayStart = cal.timeInMillis

        // Calculate the exact end of that day (the start of the next day).
        cal.add(Calendar.DAY_OF_YEAR, 1)
        val dayEnd = cal.timeInMillis

        // Reuse our existing, robust buildRangeUsage function to get the total.
        val total = buildRangeUsage(dayStart, dayEnd).deviceTotal
        Log.d(LOG_TAG, "getTotalUsageForDate (strict) for ${Date(dayStart)} = $total ms")

        // Hard-cap the result to 24 hours for safety and return it.
        return min(total, 24L * 60L * 60L * 1000L)
    }

    // ✅ ADDED: The new public method that will be called by Flutter.
    /** Last 6 full days, strict, hard‑capped to 24h each. Returns a simple list of durations. */
    private fun getScreenTimeForLastSixDays(): List<Long> {
        val out = ArrayList<Long>(6)
        for ((lo, hi) in last6CompletedLocalDays()) {
            val usage = buildRangeUsage(lo, hi).deviceTotal
            val dayTotal = min(usage, 24L * 60L * 60L * 1000L)
            out.add(dayTotal)
            Log.d(LOG_TAG, "Daily strict total for ${Date(lo)} = ${dayTotal}ms")
        }
        Log.d(LOG_TAG, "getScreenTimeForLastSixDays -> $out")
        return out
    }

    /** Last 7 days, strict, hard‑capped to 24h each. Keys: yyyy‑MM‑dd (local). */
    private fun getWeeklyDeviceScreenTime(): Map<String, Long> {
        val out = LinkedHashMap<String, Long>(7)
        val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.US).apply { timeZone = TimeZone.getDefault() }
        for ((lo, hi) in last7LocalDays()) {
            val usage = buildRangeUsage(lo, hi).deviceTotal
            val dayTotal = min(usage, 24L * 60L * 60L * 1000L)
            val key = sdf.format(Date(lo))
            out[key] = dayTotal
        }
        Log.d(LOG_TAG, "getWeeklyDeviceScreenTime -> $out")
        return out
    }

    /** Today’s strict device total (since local midnight). */
    private fun getTotalDeviceUsage(): Long {
        val (lo, hi) = todayRange()
        val total = buildRangeUsage(lo, hi).deviceTotal
        Log.d(LOG_TAG, "getTotalDeviceUsage (strict) $total ms")
        return total
    }

    /**
     * Goal‑aware counted time today (00:00→now), **strict** gating.
     */
    private fun getCountedDeviceUsage(goalType: String, tracked: List<String>, exempt: List<String>): Long {
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
        Log.d(LOG_TAG, "getCountedDeviceUsage type=$goalType -> ${counted}ms")
        return counted
    }

    // =============================================================================================
    // 📚 Historical (bucketed) — for compatibility only
    // =============================================================================================

    private fun getUsageForDateRangeBucketed(startTime: Long, endTime: Long): Map<String, Long> {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
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

    // =============================================================================================
    // 🔢 Per‑app (since midnight) — kept for existing Flutter calls
    // =============================================================================================

    private fun getUsageForApps(packageNames: List<String>): Long {
        if (packageNames.isEmpty()) return 0L
        val (lo, hi) = todayRange()
        val perApp = buildRangeUsage(lo, hi).perApp
        var total = 0L
        for (pkg in packageNames) total += (perApp[pkg] ?: 0L)
        Log.d(LOG_TAG, "getUsageForApps sum=${total}ms for $packageNames")
        return total
    }

    // =============================================================================================
    // 🔐 Permission helpers
    // =============================================================================================

    private fun openUsageAccessSettings() {
        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
    }

    private fun canQueryUsageStats(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            packageName
        )
        if (mode != AppOpsManager.MODE_ALLOWED) return false
        return try {
            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val t = System.currentTimeMillis()
            usm.queryEvents(t - 60_000L, t)
            true
        } catch (_: Exception) { false }
    }

    // =============================================================================================
    // 🧾 App listing + "top apps"
    // =============================================================================================

    private fun getInstalledApps(): List<Map<String, Any?>> {
        val pm = packageManager
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

    private fun getUsageTopApps(): List<Map<String, Any?>> {
        val pm = packageManager
        val launchable = launchablePackages()
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
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

    /** Convert a Drawable to PNG bytes for Flutter side. */
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
}