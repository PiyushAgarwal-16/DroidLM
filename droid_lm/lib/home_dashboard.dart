import 'package:flutter/material.dart';
import 'package:droid_lm/main.dart'; // Access to Pages and Services
import 'package:droid_lm/model_status_card.dart';
import 'package:droid_lm/weekly_insights_card.dart';
import 'package:droid_lm/app_usage_summary_card.dart';

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
    // Quick fetch of how many days we have saved
    final days = await LocalStorageService.getAllSavedDays();
    if (mounted) {
      setState(() {
        _sampleCount = days.length;
        _isLoading = false;
      });
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
                    // Navigate to Training console via SavedRecords
                    _navigateToSavedRecords(context);
                  },
                ),
                
                const SizedBox(height: 20),
                
                // 2. WEEKLY INSIGHTS
                WeeklyInsightsCard(
                  trend: "Analyzing...", // Placeholder until they click through
                  insightPreviews: const [
                    "Tap to generate your weekly usage report.",
                    "AI will analyze your stability and focus."
                  ],
                  onTap: () {
                    // Start analysis flow
                    _navigateToSavedRecords(context);
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
