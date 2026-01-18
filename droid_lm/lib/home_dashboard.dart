import 'package:flutter/material.dart';
import 'package:droid_lm/main.dart'; // Access to Pages and Services
import 'package:droid_lm/model_status_card.dart';
import 'package:droid_lm/weekly_insights_card.dart';
import 'package:droid_lm/daily_usage_features.dart';
import 'package:droid_lm/training_console.dart';
import 'package:droid_lm/app_usage_summary_card.dart';
import 'package:droid_lm/behavior_analysis.dart';
import 'package:droid_lm/weekly_insights_screen.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> with WidgetsBindingObserver {
  int _sampleCount = 0;
  bool _isLoading = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission(); // Check initially
    _loadDashboardData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission(); // Re-check on return from Settings
      _loadDashboardData(); // Refresh data just in case
    }
  }

  Future<void> _checkPermission() async {
    final hasPerm = await UsageStatsService.hasUsageAccess();
    if (mounted) {
      setState(() {
        _hasPermission = hasPerm;
      });
    }
  }

  Future<void> _loadDashboardData() async {
    // 1. SILENT AUTO-SYNC
    // Automatically fetch latest data from native layer and save to local storage.
    // This ensures training data is available immediately without manual steps.
    if (_hasPermission) {
      await LocalStorageService.syncDataFromNative(forceSync: false);
    }
  
    // 2. Refresh Sample Count
    final days = await LocalStorageService.getAllSavedDays();
    if (mounted) {
      setState(() {
        _sampleCount = days.length;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleManualSync(BuildContext context) async {
    setState(() => _isLoading = true);
    
    // Force sync fetches latest stats from Android and saves to SharedPreferences
    final message = await LocalStorageService.syncDataFromNative(forceSync: true);
    
    // Refresh dashboard
    await _loadDashboardData();
    
    setState(() => _isLoading = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _handleDirectTraining(BuildContext context) async {
    setState(() => _isLoading = true);
    
    // 1. Fetch all saved dates
    final dates = await LocalStorageService.getAllSavedDays();
    
    // 2. Load and convert to features
    List<DailyUsageFeatures> trainingData = [];
    for (String date in dates) {
      final info = await LocalStorageService.getDailyUsage(date);
      if (info != null) {
        trainingData.add(DailyUsageFeatures.fromRawUsageJson(info.toJson()));
      }
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (trainingData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No data available for training. Sync first!")),
        );
      } else {
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => TrainingConsolePage(trainingData: trainingData)),
        );
      }
    }
  }

  Future<void> _handleDirectWeeklyInsights(BuildContext context) async {
    setState(() => _isLoading = true);

    final savedDates = await LocalStorageService.getAllSavedDays();
    List<ModelOutput> outputs = [];
    
    // Process last 7 days max
    int count = 0;
    for (String date in savedDates) {
      if (count >= 7) break;
      
      final info = await LocalStorageService.getDailyUsage(date);
      if (info != null) {
        final features = DailyUsageFeatures.fromRawUsageJson(info.toJson());
        
        // Run Inference (Mock for now, as in SavedRecordsPage)
        final result = MLDataService.mockInference(features.toMLVector());
        outputs.add(ModelOutput.fromMap(result));
        
        count++;
      }
    }
    
    // Reverse to chronological order (oldest -> newest) for trend analysis
    outputs = outputs.reversed.toList();

    // Compute Summary
    final summary = WeeklyAnalyzer.computeSummary(outputs);
    
    setState(() => _isLoading = false);

    if (mounted) {
      if (outputs.isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Not enough data for insights. Sync usage first!")),
         );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WeeklyInsightsScreen(
              summary: summary,
              dateRange: "Last 7 Days",
              // TODO: Calculate real dominant app/time from aggregation logic
              dominantApp: "Social Media", 
              dominantTimeWindow: "Evening",
              daysObserved: outputs.length,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("DroidLM Dashboard"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: Colors.grey.shade100,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 0. PERMISSION WARNING BANNER
                if (!_hasPermission)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Permission Missing",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                              Text(
                                "Usage access is needed to track habits.",
                                style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await UsageStatsService.openUsageAccessSettings();
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.orange.shade100,
                            foregroundColor: Colors.orange.shade900,
                          ),
                          child: const Text("Enable"),
                        )
                      ],
                    ),
                  ),

                // 1. ML MODEL CARD (Hero)
                ModelStatusCard(
                  status: ModelStatus.idle, // Default for dashboard visualization
                  sampleCount: _sampleCount,
                  lastTrainingTime: "Tap to Check",
                  onActionPressed: () {
                    // Navigate DIRECTLY to Training console
                    _handleDirectTraining(context);
                  },
                ),
                

                
                // Manual Sync Button (Sub-Action)
                TextButton.icon(
                  onPressed: () => _handleManualSync(context),
                  icon: const Icon(Icons.sync, size: 16),
                  label: const Text("Sync Usage Data"),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // 2. WEEKLY INSIGHTS
                WeeklyInsightsCard(
                  trend: "Analyzing...", // Placeholder until they click through
                  insightPreviews: const [
                    "Tap to generate your weekly usage report.",
                    "AI will analyze your stability and focus."
                  ],
                  onTap: () {
                    // Start analysis flow DIRECTLY
                    _handleDirectWeeklyInsights(context);
                  },
                ),

                const SizedBox(height: 20),

                // 3. APP USAGE SUMMARY
                AppUsageSummaryCard(
                  totalScreenTime: "View Details", // Placeholder
                  topAppName: "Daily Stats",
                  peakWindow: "Track",
                  onTap: () {
                    // Navigate to Raw Logs / Main List
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => const UsageStatsPage()),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // 4. EXPLORE / ADVANCED
                // Keeping a simple placeholder for now or removing if too cluttered.
                // Let's keep it as a simple button.
                OutlinedButton.icon(
                  onPressed: () {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text("Advanced Settings coming soon!")),
                     );
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text("Advanced Settings"),
                ),
              ],
            ),
          ),
    );
  }

  void _navigateToSavedRecords(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SavedRecordsPage()),
    );
  }
}
