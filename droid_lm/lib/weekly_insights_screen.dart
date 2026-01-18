import 'package:flutter/material.dart';
import 'package:droid_lm/advice_list.dart';
import 'package:droid_lm/behavior_analysis.dart';
import 'package:droid_lm/generated_advice.dart';
import 'package:droid_lm/weekly_advice_service.dart';

/// A screen to view Weekly Behavior Analysis and Generated Advice.
/// A screen to view Weekly Behavior Analysis and Generated Advice.
class WeeklyInsightsScreen extends StatefulWidget {
  final WeeklyBehaviorSummary summary;
  final String dateRange;
  
  // Context signals required for personalization
  final String dominantApp;
  final String dominantTimeWindow;
  final int daysObserved;

  const WeeklyInsightsScreen({
    super.key, 
    required this.summary,
    this.dateRange = "Last 7 Days",
    this.dominantApp = "",
    this.dominantTimeWindow = "",
    this.daysObserved = 7,
  });

  @override
  State<WeeklyInsightsScreen> createState() => _WeeklyInsightsScreenState();
}

class _WeeklyInsightsScreenState extends State<WeeklyInsightsScreen> {
  late Future<List<GeneratedAdvice>> _adviceFuture;

  @override
  void initState() {
    super.initState();
    _adviceFuture = _loadAdvice();
  }

  /// Simulates an async loading process for smoother UX.
  Future<List<GeneratedAdvice>> _loadAdvice() async {
    // Artificial delay to prevent UI jank and allow the user to see the "processing" state.
    // In a real app involving network calls or heavy ML, this would be real latency.
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (!mounted) return [];

    return WeeklyAdviceService.generate(
      widget.summary,
      dominantApp: widget.dominantApp,
      dominantTimeWindow: widget.dominantTimeWindow,
      daysObserved: widget.daysObserved,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Weekly Insights"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Stats Section (Always visible)
            _buildStatsHeader(context),
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            
            // Async Advice List
            FutureBuilder<List<GeneratedAdvice>>(
              future: _adviceFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildSkeletonLoader();
                } else if (snapshot.hasError) {
                  return const Center(child: Text("Could not load insights."));
                } else if (snapshot.hasData) {
                  return AdviceList(advices: snapshot.data!);
                }
                return const SizedBox(); // Should not reach here
              },
            ),
            
            const SizedBox(height: 32),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.security, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 6),
                  Text(
                    "These insights are generated locally on your device",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    // A simple visual placeholder (skeleton) to indicate loading
    // without layout jumping.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Skeleton Header
        Container(
          width: 150,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 16),
        // Skeleton Cards
        ...List.generate(3, (index) => Container(
          margin: const EdgeInsets.only(bottom: 12.0),
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Skeleton Icon
                CircleAvatar(backgroundColor: Colors.grey[100], radius: 20),
                const SizedBox(width: 16),
                // Skeleton Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: double.infinity, height: 16, color: Colors.grey[100]),
                      const SizedBox(height: 8),
                      Container(width: 100, height: 12, color: Colors.grey[50]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildStatsHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
           BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Analysis Range", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              Text(widget.dateRange, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem("Habit Score", widget.summary.averageHabituality.toStringAsFixed(2)),
              _buildStatItem("Distraction", widget.summary.averageDistraction.toStringAsFixed(2)),
              _buildStatItem("Trend", widget.summary.habitualityTrend),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }
}
