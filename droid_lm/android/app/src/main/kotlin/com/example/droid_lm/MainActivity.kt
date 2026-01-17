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
import java.nio.MappedByteBuffer
import java.nio.channels.FileChannel
import java.io.FileInputStream
import org.tensorflow.lite.Interpreter
import java.nio.ByteBuffer
import java.nio.ByteOrder

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
                "trainHabitModel" -> {
                    // Extract args safely on Main Thread
                    val featuresArg = call.argument<List<Any>>("features")
                    val labelsArg = call.argument<List<Any>>("labels")
                    
                    if (featuresArg != null && labelsArg != null) {
                        try {
                             // Expected Shapes:
                             // features: List<List<Double>> (Batch Size x 102)
                             // labels: List<List<Double>> (Batch Size x 2) OR List<Double> (Batch Size x 1)
                             
                             // Safely parse Features
                             val features = featuresArg.map { element ->
                                 when (element) {
                                     is List<*> -> element.map { (it as Number).toDouble() }
                                     else -> throw IllegalArgumentException("Feature sample expected to be a List, got: ${element?.javaClass?.simpleName}")
                                 }
                             }

                             // Safely parse Labels (Handle both 1D and 2D from Dart)
                             val labels = labelsArg.map { element ->
                                 when (element) {
                                     is List<*> -> element.map { (it as Number).toDouble() }
                                     is Number -> listOf(element.toDouble()) // Wrap scalar in list -> [0.5]
                                     else -> throw IllegalArgumentException("Label sample expected to be List or Number, got: ${element?.javaClass?.simpleName}")
                                 }
                             }
                             
                             // Run training on background thread
                             Thread {
                                 try {
                                     val output = trainHabitModel(features, labels)
                                     runOnUiThread {
                                         result.success(output)
                                     }
                                 } catch (e: Exception) {
                                     runOnUiThread {
                                         result.error("TRAIN_ERROR", e.message, null)
                                     }
                                 }
                             }.start()
                        } catch (e: Exception) {
                             result.error("ARG_ERROR", "Parsing Error: ${e.message}", null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "Features or labels missing", null)
                    }
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

    /**
     * Trains the local TFLite model with the provided behavioral data.
     * 
     * @param features: List of 102-dim temporal window vectors.
     * @param labels: List of 2-dim target vectors [HabitScore, DistractionScore].
     */
    private fun trainHabitModel(features: List<List<Double>>, labels: List<List<Double>>): String {
        try {
            // 1. Load Model
            val modelBuffer = loadModelFile("trainable_micro_model.tflite")
            val interpreter = org.tensorflow.lite.Interpreter(modelBuffer)
            
            // 2. Prepare Data Buffers
            val NUM_EPOCHS = 10
            val NUM_FEATURES = 102 // 34 features * 3 days
            val NUM_TARGETS = 2   // [HabitScore, DistractionScore]
            var totalLoss = 0.0f
            
            // --- Sanity Checks START ---
            if (features.isEmpty()) {
                return "Error: Training dataset is empty."
            }
            
            val actualFeatureDim = features[0].size
            val actualTargetDim = labels[0].size // Now checking list inside list
            
            val sb = StringBuilder()
            sb.append("Training Report:\n")
            sb.append("Samples: ${features.size}\n")
            sb.append("Input Dim: $actualFeatureDim (Expected: $NUM_FEATURES)\n")
            sb.append("Target Dim: $actualTargetDim (Expected: $NUM_TARGETS)\n")
            
            // Validate Logic match
            if (features.size != labels.size) {
                 return "Error: Data mismatch. Features: ${features.size}, Labels: ${labels.size}"
            }
            // Validate Input shape
            if (actualFeatureDim != NUM_FEATURES) {
                return "Error: Input dimension mismatch. Got $actualFeatureDim, expected $NUM_FEATURES."
            }
            // Validate Target shape
            if (actualTargetDim != NUM_TARGETS) {
                return "Error: Target dimension mismatch. Got $actualTargetDim, expected $NUM_TARGETS."
            }
            // --- Sanity Checks END ---
            
            val inputBuffer = java.nio.ByteBuffer.allocateDirect(4 * NUM_FEATURES).order(java.nio.ByteOrder.nativeOrder())
            val targetBuffer = java.nio.ByteBuffer.allocateDirect(4 * NUM_TARGETS).order(java.nio.ByteOrder.nativeOrder())
            
            // Output buffer for "loss" (returned by train signature)
            val outputMap = mutableMapOf<String, Any>()
            val lossBuffer = java.nio.ByteBuffer.allocateDirect(4 * 1).order(java.nio.ByteOrder.nativeOrder())
            outputMap["loss"] = lossBuffer
            
            for (epoch in 1..NUM_EPOCHS) {
                var epochLoss = 0.0f
                
                for (i in features.indices) {
                    val sample = features[i]
                    val labelVector = labels[i] // This is List<Double> of size 2
                    
                    if (labelVector.size != NUM_TARGETS) {
                         return "Error: Target vector size mismatch at index $i. Got ${labelVector.size}, expected $NUM_TARGETS."
                    }

                    // Fill Input Buffer (102 floats)
                    inputBuffer.rewind()
                    for (v in sample) {
                        inputBuffer.putFloat(v.toFloat())
                    }
                    
                    // Fill Target Buffer (2 floats: [Habituality, Distraction])
                    targetBuffer.rewind()
                    for (targetVal in labelVector) {
                         // Safely convert Double to Float
                        targetBuffer.putFloat(targetVal.toFloat())
                    }
                    
                    // Reset Loss Buffer
                    lossBuffer.rewind()
                    
                    // Run "train" signature
                    val inputs = mapOf("x" to inputBuffer, "y" to targetBuffer)
                    interpreter.runSignature(inputs, outputMap, "train")
                    
                    lossBuffer.rewind()
                    epochLoss += lossBuffer.float
                }
                
                val avgLoss = epochLoss / features.size
                
                // Log every epoch for feedback
                sb.append("Epoch $epoch Loss: ${"%.5f".format(avgLoss)}\n")
                totalLoss = avgLoss
            }
            
            interpreter.close()
            return sb.toString()
            
        } catch (e: Exception) {
            return "Error during training: ${e.message}"
        }
    }

    private fun loadModelFile(modelName: String): java.nio.MappedByteBuffer {
        val fileDescriptor = assets.openFd(modelName)
        val inputStream = java.io.FileInputStream(fileDescriptor.fileDescriptor)
        val fileChannel = inputStream.channel
        val startOffset = fileDescriptor.startOffset
        val declaredLength = fileDescriptor.declaredLength
        return fileChannel.map(java.nio.channels.FileChannel.MapMode.READ_ONLY, startOffset, declaredLength)
    }
}
