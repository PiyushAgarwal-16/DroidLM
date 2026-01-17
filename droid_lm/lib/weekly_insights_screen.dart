import 'package:flutter/material.dart';
import 'package:droid_lm/behavior_analysis.dart';

/// A temporary debug screen to view Weekly Behavior Analysis.
class WeeklyInsightsScreen extends StatelessWidget {
  final WeeklyBehaviorSummary summary;
  final String dateRange;

  const WeeklyInsightsScreen({
    super.key, 
    required this.summary,
    this.dateRange = "Last 7 Days",
  });

  @override
  Widget build(BuildContext context) {
    // Generate simple text insights
    final insights = WeeklyInsightGenerator.generateInsights(summary);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Weekly Insights"),
        backgroundColor: Colors.grey,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Stats
            Text("Range: $dateRange", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            Text("Avg Habituality: ${summary.averageHabituality.toStringAsFixed(3)}"),
            Text("Avg Distraction: ${summary.averageDistraction.toStringAsFixed(3)}"),
            Text("Habituality Trend: ${summary.habitualityTrend}"),
            Text("Dominant Stability: ${summary.dominantStability}"),
            
            const Divider(height: 40),
            
            // Insight List
            const Text("Generated Insights:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            Expanded(
              child: ListView.builder(
                itemCount: insights.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text("• ${insights[index]}"),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
