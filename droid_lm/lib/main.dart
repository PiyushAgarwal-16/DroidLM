import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:droid_lm/daily_usage_features.dart';
import 'package:droid_lm/training_console.dart';
import 'package:droid_lm/behavior_analysis.dart';
import 'package:droid_lm/weekly_insights_screen.dart';
import 'package:droid_lm/home_dashboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Droid LM Usage Stats',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeDashboard(),
    );
  }
}

/// Model class for single App Usage Information
class AppUsageInfo {
  final String packageName;
  final double totalTimeInMinutes;

  AppUsageInfo({
    required this.packageName,
    required this.totalTimeInMinutes,
  });

  factory AppUsageInfo.fromJson(Map<String, dynamic> json) {
    return AppUsageInfo(
      packageName: json['package'] as String, // Native sends "package"
      totalTimeInMinutes: (json['minutes'] as num).toDouble(), // Native sends "minutes"
    );
  }

  // To support saving to local storage
  Map<String, dynamic> toJson() {
    return {
      'package': packageName,
      'minutes': totalTimeInMinutes,
    };
  }
}

/// Model class for Daily Usage Information
class DailyUsageInfo {
  final String date;
  final List<AppUsageInfo> apps;

  DailyUsageInfo({
    required this.date,
    required this.apps,
  });

  factory DailyUsageInfo.fromJson(Map<String, dynamic> json) {
    var appsList = json['apps'] as List;
    List<AppUsageInfo> apps = appsList.map((i) => AppUsageInfo.fromJson(i)).toList();
    
    // Sort apps by usage time descending
    apps.sort((a, b) => b.totalTimeInMinutes.compareTo(a.totalTimeInMinutes));

    return DailyUsageInfo(
      date: json['date'] as String,
      apps: apps,
    );
  }

  // To support saving to local storage
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'apps': apps.map((app) => app.toJson()).toList(),
    };
  }
}

/// Service to handle MethodChannel communication
class UsageStatsService {
  static const platform = MethodChannel('usage_stats_channel');

  static Future<void> openUsageAccessSettings() async {
    try {
      await platform.invokeMethod('openUsageAccessSettings');
    } on PlatformException catch (e) {
      debugPrint("Failed to open settings: '${e.message}'.");
    }
  }

  static Future<bool> hasUsageAccess() async {
    try {
      final bool result = await platform.invokeMethod('hasUsageAccess');
      return result;
    } on PlatformException catch (e) {
      debugPrint("Failed to check permission: '${e.message}'.");
      return false;
    }
  }

  static Future<List<DailyUsageInfo>> getDailyUsageStats() async {
    try {
      final String jsonString = await platform.invokeMethod('getDailyUsageStats');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      List<DailyUsageInfo> dailyStats = jsonList
          .map((json) => DailyUsageInfo.fromJson(json))
          .toList();

      dailyStats.sort((a, b) => b.date.compareTo(a.date));
      return dailyStats;
    } on PlatformException catch (e) {
      debugPrint("Failed to get usage stats: '${e.message}'.");
      return [];
    }
  }

  /// Triggers on-device training via Native Layer
  static Future<String> trainHabitModel(List<List<double>> features, List<List<double>> labels) async {
    try {
      debugPrint("--- DART PRE-TRAINING CHECKS ---");
      debugPrint("Inputs Type: ${features.runtimeType}");
      if (features.isNotEmpty) {
        debugPrint("Inputs First Type: ${features.first.runtimeType}");
        debugPrint("Inputs First Length: ${features.first.length}");
      } else {
        debugPrint("Inputs: EMPTY");
      }
      
      debugPrint("Targets Type: ${labels.runtimeType}");
      if (labels.isNotEmpty) {
        debugPrint("Targets First Type: ${labels.first.runtimeType}");
        debugPrint("Targets First Length: ${labels.first.length}");
      } else {
        debugPrint("Targets: EMPTY");
      }
      debugPrint("--------------------------------");

      // Pass features and labels as arguments
      final result = await platform.invokeMethod('trainHabitModel', {
        "features": features,
        "labels": labels,
      });
      return result.toString();
    } on PlatformException catch (e) {
      return "Training Failed: ${e.message}";
    }
  }
}

/// Service to persist usage stats locally using SharedPreferences
class LocalStorageService {
  static const String _keysListKey = 'saved_usage_dates';
  static const String _keyPrefix = 'usage_stats_';

  /// Check if data exists for a given date
  static Future<bool> hasDataForDate(String date) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = '$_keyPrefix$date';
    return prefs.containsKey(key);
  }

  /// Sync data from native to local storage
  /// [forceSync]: If true, overwrites existing data for the same day.
  /// Returns a log of what happened.
  static Future<String> syncDataFromNative({bool forceSync = false}) async {
    final stats = await UsageStatsService.getDailyUsageStats();
    int savedCount = 0;
    int skippedCount = 0;
    
    for (var day in stats) {
      bool exists = await hasDataForDate(day.date);
      
      // Save if forced OR if it doesn't exist
      if (forceSync || !exists) {
        await saveDailyUsage(day);
        savedCount++;
      } else {
        skippedCount++;
      }
    }
    
    return "Synced: Saved $savedCount days, Skipped $skippedCount existing days (ForceSync: $forceSync).";
  }

  /// Saves daily usage data for a specific date
  static Future<void> saveDailyUsage(DailyUsageInfo dailyInfo) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = '$_keyPrefix${dailyInfo.date}';
    final String jsonString = jsonEncode(dailyInfo.toJson());

    // 1. Save the daily JSON
    await prefs.setString(key, jsonString);

    // 2. Update list of saved dates if needed
    final List<String> savedDates = prefs.getStringList(_keysListKey) ?? [];
    if (!savedDates.contains(dailyInfo.date)) {
      savedDates.add(dailyInfo.date);
      // Sort dates
      savedDates.sort((a, b) => b.compareTo(a));
      await prefs.setStringList(_keysListKey, savedDates);
    }
    
    debugPrint("Saved stats for ${dailyInfo.date}");
  }

  /// Retrieves daily usage data for a specific date
  static Future<DailyUsageInfo?> getDailyUsage(String date) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = '$_keyPrefix$date';
    final String? jsonString = prefs.getString(key);

    if (jsonString != null) {
      try {
        return DailyUsageInfo.fromJson(jsonDecode(jsonString));
      } catch (e) {
        debugPrint("Error parsing saved daily usage: $e");
        return null;
      }
    }
    return null;
  }

  /// Returns list of all dates that have saved data
  static Future<List<String>> getAllSavedDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keysListKey) ?? [];
  }
  
  /// Helper to clear all data (for testing)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

class UsageStatsPage extends StatefulWidget {
  const UsageStatsPage({super.key});

  @override
  State<UsageStatsPage> createState() => _UsageStatsPageState();
}

class _UsageStatsPageState extends State<UsageStatsPage> with WidgetsBindingObserver {
  bool _hasPermission = false;
  List<DailyUsageInfo> _dailyStats = [];
  bool _isLoading = false;
  
  // Demo State
  bool _forceSyncDemo = false;
  String? _lastSyncResult;
  bool _isSyncing = false;
  Color _resultColor = Colors.black;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionAndFetchStats();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionAndFetchStats();
    }
  }

  Future<void> _checkPermissionAndFetchStats() async {
    // Only show full loader if we have no data
    if (_dailyStats.isEmpty) {
      setState(() => _isLoading = true);
    }
    
    final hasPermission = await UsageStatsService.hasUsageAccess();
    
    if (hasPermission) {
      // Fetch latest stats from Android
      final stats = await UsageStatsService.getDailyUsageStats();
      
      if (mounted) {
        setState(() {
          _hasPermission = true;
          _dailyStats = stats;
          _isLoading = false;
        });

        // AUTO-SAVE: Persist fetched logs to local storage automatically
        // This ensures training data is available without manual sync
        for (var day in stats) {
          await LocalStorageService.saveDailyUsage(day);
        }
        debugPrint("Auto-saved ${stats.length} days of usage logs.");
      }
    } else {
      if (mounted) {
        setState(() {
          _hasPermission = false;
          _dailyStats = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSync({bool force = false}) async {
    setState(() {
      _isSyncing = true;
      _lastSyncResult = null;
    });

    final message = await LocalStorageService.syncDataFromNative(forceSync: force);
    
    // Determine color: Green if we actually saved something (not 0 days/skipped only)
    bool savedData = !message.contains("Saved 0 days");
    final color = savedData ? Colors.green.shade700 : Colors.grey.shade600;

    setState(() {
      _isSyncing = false;
      _lastSyncResult = message;
      _resultColor = color;
    });
    
    if (mounted) {
      // Refresh view (silently update list)
      _checkPermissionAndFetchStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily App Usage'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Saved Records',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SavedRecordsPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Tap to Sync / Long Press to Force',
            onPressed: !_isLoading && _hasPermission ? () => _handleSync(force: false) : null,
            onLongPress: !_isLoading && _hasPermission ? () => _handleSync(force: true) : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkPermissionAndFetchStats,
          )
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasPermission) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_clock, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Usage Access Required',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Please grant usage access permission to view your daily stats.',
                textAlign: TextAlign.center,
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await UsageStatsService.openUsageAccessSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // DEMO CONTROLS
        Card(
          margin: const EdgeInsets.all(12),
          elevation: 2,
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     const Text(
                       "Force Re-sync (Demo)", 
                       style: TextStyle(fontWeight: FontWeight.bold)
                     ),
                     Switch(
                       value: _forceSyncDemo,
                       onChanged: (val) => setState(() => _forceSyncDemo = val),
                     )
                   ],
                 ),
                 SizedBox(
                   width: double.infinity,
                   child: ElevatedButton.icon(
                     icon: _isSyncing 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.sync),
                     label: Text(_isSyncing ? "Syncing..." : "Sync Usage Data"),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.blue,
                       foregroundColor: Colors.white,
                     ),
                     onPressed: _isSyncing ? null : () => _handleSync(force: _forceSyncDemo),
                   ),
                 ),
                 const SizedBox(height: 8),
                 AnimatedSwitcher(
                   duration: const Duration(milliseconds: 500),
                   child: _lastSyncResult != null
                       ? Container(
                           key: ValueKey(_lastSyncResult), // helper for animation
                           padding: const EdgeInsets.all(8),
                           width: double.infinity,
                           decoration: BoxDecoration(
                             color: Colors.white,
                             borderRadius: BorderRadius.circular(4),
                             border: Border.all(color: _resultColor.withOpacity(0.3)),
                           ),
                           child: Text(
                             _lastSyncResult!,
                             style: TextStyle(
                               fontSize: 12, 
                               fontWeight: FontWeight.bold,
                               color: _resultColor
                             ),
                             textAlign: TextAlign.center,
                           ),
                         )
                       : const SizedBox.shrink(),
                 )
              ],
            ),
          ),
        ),

        // STATS LIST
        Expanded(
          child: _dailyStats.isEmpty
              ? const Center(child: Text("No usage data found."))
              : ListView.builder(
                  itemCount: _dailyStats.length,
                  itemBuilder: (context, index) {
                    final dayInfo = _dailyStats[index];
                    return _buildDaySection(dayInfo);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDaySection(DailyUsageInfo dayInfo) {
    if (dayInfo.apps.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dayInfo.date,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ...dayInfo.apps.map((app) => ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.teal.shade100,
            child: Text(
              app.packageName.isNotEmpty ? app.packageName[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 12, color: Colors.teal),
            ),
          ),
          title: Text(
            app.packageName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            '${app.totalTimeInMinutes.toStringAsFixed(0)}m',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        )),
      ],
    );
  }
}

/// Service to handle ML data preparation
class MLDataService {
  /// Reads all local data, converts to features, and prints to console
  static Future<void> processAndPrintFeatures() async {
    debugPrint("--- START ML FEATURE PROCESSING ---");
    
    // 1. Get all saved dates
    final List<String> dates = await LocalStorageService.getAllSavedDays();
    List<DailyUsageFeatures> featureSet = [];

    // 2. Iterate and convert
    for (String date in dates) {
      final DailyUsageInfo? dayInfo = await LocalStorageService.getDailyUsage(date);
      if (dayInfo != null) {
        // Convert the DailyUsageInfo (which matches raw JSON structure) to Map first
        // effectively simulating "fromRawUsageJson" input
        final rawJson = dayInfo.toJson();
        
        final features = DailyUsageFeatures.fromRawUsageJson(rawJson);
        featureSet.add(features);
        
        debugPrint("Processed ${features.date}: Total ${features.totalMinutes}m, Top: ${features.topApps}");
      }
    }

    // 3. Print Feature Vectors
    debugPrint("\n--- FEATURE VECTORS (Copy for Training) ---");
    debugPrint("[");
    for (int i = 0; i < featureSet.length; i++) {
        final comma = i < featureSet.length - 1 ? ',' : '';
        debugPrint("  ${jsonEncode(featureSet[i].toMap())}$comma");
    }
    debugPrint("]");

    // 4. Print Numeric Vectors
    debugPrint("\n--- NUMERIC ML VECTORS (Normalized) ---");
    debugPrint("[");
    for (int i = 0; i < featureSet.length; i++) {
        final comma = i < featureSet.length - 1 ? ',' : '';
        debugPrint("  ${featureSet[i].toMLVector()}$comma");
    }
    debugPrint("]");

    // 5. Mock Model Inference output
    debugPrint("\n--- MOCK MODEL OUTPUT (Simulation) ---");
    for (int i = 0; i < featureSet.length; i++) {
      final features = featureSet[i];
      final vector = features.toMLVector();
      final result = mockInference(vector);
      
      debugPrint("${features.date} -> Habituality: ${result['habituality']!.toStringAsFixed(2)}, Distraction: ${result['distraction']!.toStringAsFixed(2)}, Stability: ${result['stability']}");
    }

    debugPrint("-------------------------------------------");
  }

  /// Simulates ML model inference using the numeric input vector.
  /// 
  /// THIS IS A PLACEHOLDER.
  /// In the real implementation, this function will:
  /// 1. Load the TFLite model.
  /// 2. Pass [inputVector] to the interpreter.
  /// 3. Return the actual tensor outputs.
  static Map<String, dynamic> mockInference(List<double> inputVector) {
    // Generate deterministic-looking "fake" scores based on input features
    // just to verify the pipeline works.
    
    // Feature [0] is normalized total minutes.
    // Feature [8] is normalized active apps count.
    
    double habitualityScore = (inputVector[0] * 0.7 + 0.2).clamp(0.0, 1.0);
    double distractionScore = (inputVector[8] * 0.5 + inputVector[1] * 0.3).clamp(0.0, 1.0); // Apps + Morning usage
    
    // Determine stability class based on arbitrary logic for demo
    String stabilityClass = "Stable";
    if (distractionScore > 0.7) {
      stabilityClass = "Chaotic";
    } else if (habitualityScore < 0.4) {
      stabilityClass = "Drifting";
    }

    return {
      'habituality': habitualityScore,
      'distraction': distractionScore,
      'stability': stabilityClass,
    };
  }
}

class SavedRecordsPage extends StatefulWidget {
  const SavedRecordsPage({super.key});

  @override
  State<SavedRecordsPage> createState() => _SavedRecordsPageState();
}

class _SavedRecordsPageState extends State<SavedRecordsPage> {
  List<String> _savedDates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedDates();
  }

  Future<void> _loadSavedDates() async {
    final dates = await LocalStorageService.getAllSavedDays();
    if (mounted) {
      setState(() {
        _savedDates = dates;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleMLProcessing() async {
      setState(() => _isLoading = true);
      
      // Load all data
      List<DailyUsageFeatures> trainingData = [];
      for (String date in _savedDates) {
        final info = await LocalStorageService.getDailyUsage(date);
        if (info != null) {
          trainingData.add(DailyUsageFeatures.fromRawUsageJson(info.toJson()));
        }
      }

      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TrainingConsolePage(trainingData: trainingData),
          ),
        );
      }
  }

  Future<void> _openWeeklyInsights() async {
    setState(() => _isLoading = true);

    List<ModelOutput> outputs = [];
    
    // Process last 7 days max
    int count = 0;
    for (String date in _savedDates) {
      if (count >= 7) break;
      
      final info = await LocalStorageService.getDailyUsage(date);
      if (info != null) {
        final features = DailyUsageFeatures.fromRawUsageJson(info.toJson());
        
        // Run Inference
        final result = MLDataService.mockInference(features.toMLVector());
        outputs.add(ModelOutput.fromMap(result));
        
        count++;
      }
    }
    
    // Reverse to chronological order (oldest -> newest) for trend analysis
    // Assuming _savedDates is sorted DESC
    outputs = outputs.reversed.toList();

    final summary = WeeklyAnalyzer.computeSummary(outputs);
    
    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WeeklyInsightsScreen(
            summary: summary,
            dateRange: "Dynamic Analysis",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics), // Insights Icon
            tooltip: 'Open Weekly Insights',
            onPressed: !_isLoading && _savedDates.isNotEmpty ? _openWeeklyInsights : null,
          ),
          IconButton(
            icon: const Icon(Icons.model_training), // Icon for Training
            tooltip: 'Train Model',
            onPressed: !_isLoading && _savedDates.isNotEmpty ? _handleMLProcessing : null,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedDates.isEmpty
              ? const Center(child: Text('No saved records found.'))
              : ListView.builder(
                  itemCount: _savedDates.length,
                  itemBuilder: (context, index) {
                    final date = _savedDates[index];
                    return FutureBuilder<DailyUsageInfo?>(
                      future: LocalStorageService.getDailyUsage(date),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const ListTile(
                            title: Text("Loading..."),
                          );
                        }
                        final dayInfo = snapshot.data!;
                        return ListTile(
                          leading: const Icon(Icons.folder),
                          title: Text(date),
                          subtitle: Text('${dayInfo.apps.length} apps recorded'),
                          onTap: () {
                            // Print full JSON to console as requested
                            debugPrint("--- JSON Data for $date ---");
                            debugPrint(jsonEncode(dayInfo.toJson()));
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('JSON for $date printed to console')),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
    );
  }
}
