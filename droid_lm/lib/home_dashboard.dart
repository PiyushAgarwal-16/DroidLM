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

class _HomeDashboardState extends State<HomeDashboard> {
  int _sampleCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
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
