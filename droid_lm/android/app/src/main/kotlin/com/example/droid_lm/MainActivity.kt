package com.example.droid_lm

import android.app.AppOpsManager
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * MainActivity handles Flutter MethodChannel communication for Usage Access permissions
 * and app usage statistics.
 * 
 * Exposes methods via "usage_stats_channel":
 * - openUsageAccessSettings: Opens Android Usage Access settings screen
 * - hasUsageAccess: Checks if usage access permission is granted
 * - getSimpleUsageStats: Returns aggregated app usage data for the last 7 days as JSON
 * - getDailyUsageStats: Returns daily usage breakdown for the last 7 days as JSON
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
                "getSimpleUsageStats" -> {
                    // Return usage stats as JSON string
                    result.success(getSimpleUsageStats())
                }
                "getDailyUsageStats" -> {
                    // Return daily usage stats as JSON string
                    result.success(getDailyUsageStats())
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

    /**
     * Fetches aggregated app usage statistics for the LAST 7 DAYS.
     * 
     * @return JSON array string with format:
     *         [{"packageName": "com.example.app", "totalTimeInForeground": 123456}, ...]
     */
    private fun getSimpleUsageStats(): String {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis
        calendar.add(Calendar.DAY_OF_YEAR, -7)
        val startTime = calendar.timeInMillis

        val usageStatsList: List<UsageStats> = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        ) ?: emptyList()

        val aggregatedStats = mutableMapOf<String, Long>()
        for (usageStats in usageStatsList) {
            val packageName = usageStats.packageName
            val timeInForeground = usageStats.totalTimeInForeground
            if (timeInForeground > 0) {
                aggregatedStats[packageName] = 
                    aggregatedStats.getOrDefault(packageName, 0L) + timeInForeground
            }
        }

        val jsonArray = JSONArray()
        for ((packageName, totalTime) in aggregatedStats) {
            val jsonObject = JSONObject()
            jsonObject.put("packageName", packageName)
            jsonObject.put("totalTimeInForeground", totalTime)
            jsonArray.put(jsonObject)
        }

        return jsonArray.toString()
    }

    /**
     * Fetches app usage statistics for the LAST 7 DAYS, grouped by DAY.
     * 
     * @return JSON array string with format:
     * [
     *   {
     *     "date": "YYYY-MM-DD",
     *     "apps": [
     *       { "package": "com.instagram.android", "minutes": 54 },
     *       ...
     *     ]
     *   }
     * ]
     */
    private fun getDailyUsageStats(): String {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis
        calendar.add(Calendar.DAY_OF_YEAR, -7)
        val startTime = calendar.timeInMillis

        // Query daily stats for the last 7 days
        val usageStatsList: List<UsageStats> = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        ) ?: emptyList()

        // Map to hold daily data: Date String -> List of UsageStats
        val dailyMap = mutableMapOf<String, MutableList<UsageStats>>()
        val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())

        for (stats in usageStatsList) {
            // Filter out entries with no usage
            if (stats.totalTimeInForeground > 0) {
                // Use the start of the interval (firstTimeStamp) to determine the date
                val date = Date(stats.firstTimeStamp)
                val dateString = dateFormat.format(date)
                
                if (!dailyMap.containsKey(dateString)) {
                    dailyMap[dateString] = mutableListOf()
                }
                dailyMap[dateString]?.add(stats)
            }
        }

        val jsonArray = JSONArray()

        // Sort dates to ensure chronological order (optional but good)
        val sortedDates = dailyMap.keys.sorted()

        for (dateString in sortedDates) {
            val dayObject = JSONObject()
            dayObject.put("date", dateString)

            val appsArray = JSONArray()
            val appsList = dailyMap[dateString] ?: emptyList()
            
            // Should we aggregate by package per day? 
            // queryUsageStats with INTERVAL_DAILY might return multiple entries for same package if not aligned?
            // Usually returns one per package per interval. We will aggregate just in case.
            val dailyPackageMap = mutableMapOf<String, Long>()

            for (app in appsList) {
                dailyPackageMap[app.packageName] = 
                    dailyPackageMap.getOrDefault(app.packageName, 0L) + app.totalTimeInForeground
            }

            for ((packageName, timeMillis) in dailyPackageMap) {
                val appObject = JSONObject()
                appObject.put("package", packageName)
                // Convert to minutes
                appObject.put("minutes", timeMillis / 1000 / 60)
                appsArray.put(appObject)
            }

            dayObject.put("apps", appsArray)
            jsonArray.put(dayObject)
        }

        return jsonArray.toString()
    }
}
