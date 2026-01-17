import 'package:flutter/material.dart';
import 'package:droid_lm/behavior_analysis.dart';

class WeeklyInsightsPage extends StatelessWidget {
  final WeeklyBehaviorSummary summary;
  final String dateRange; // e.g., "Jan 11 - Jan 17"

  const WeeklyInsightsPage({
    super.key,
    required this.summary,
    required this.dateRange,
  });

  @override
  Widget build(BuildContext context) {
    // Generate human-readable insights using our helper
    final insights = WeeklyInsightGenerator.generateInsights(summary);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Weekly Insights"),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. DATE HEADER
            Center(
              child: Text(
                dateRange,
                style: const TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.grey
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. SCORES ROW
            Row(
              children: [
                _buildScoreCard(
                  context,
                  label: "Habituality",
                  score: summary.averageHabituality,
                  trend: summary.habitualityTrend,
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildScoreCard(
                  context,
                  label: "Distraction",
                  score: summary.averageDistraction,
                  isDistraction: true,
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. STABILITY INDICATOR
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStabilityColor(summary.dominantStability).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getStabilityColor(summary.dominantStability)),
              ),
              child: Column(
                children: [
                   const Text("Dominant Stability", style: TextStyle(fontSize: 12, color: Colors.black54)),
                   const SizedBox(height: 4),
                   Text(
                     summary.dominantStability,
                     style: TextStyle(
                       fontSize: 24, 
                       fontWeight: FontWeight.bold,
                       color: _getStabilityColor(summary.dominantStability)
                     ),
                   ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. GENERATED INSIGHTS
            const Text(
              "Key Takeaways",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (insights.isEmpty)
              const Text("No specific insights generated for this week.", style: TextStyle(fontStyle: FontStyle.italic))
            else
              ...insights.map((text) => _buildInsightCard(text)),
          ],
        ),
      ),
    );
  }

  /// Helper to build the score summary cards
  Widget _buildScoreCard(BuildContext context, {
    required String label, 
    required double score, 
    String? trend,
    bool isDistraction = false,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    (score * 100).toStringAsFixed(0),
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
                  ),
                  if (trend != null)
                    Icon(
                      _getTrendIcon(trend),
                      color: _getTrendColor(trend),
                      size: 28,
                    ),
                ],
              ),
              if (isDistraction)
                Text(score < 0.3 ? "Low" : score > 0.6 ? "High" : "Moderate", style: TextStyle(color: color))
              else if (trend != null)
                 Text(trend, style: TextStyle(color: Colors.grey.shade600, fontSize: 12))
            ],
          ),
        ),
      ),
    );
  }

  /// Helper to build an individual insight card
  Widget _buildInsightCard(String text) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.tealAccent,
          child: Icon(Icons.lightbulb_outline, color: Colors.teal),
        ),
        title: Text(text, style: const TextStyle(fontSize: 14)),
      ),
    );
  }

  // --- HELPERS ---

  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case "Increasing": return Icons.trending_up;
      case "Decreasing": return Icons.trending_down;
      default: return Icons.trending_flat;
    }
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case "Increasing": return Colors.red; // Habit increasing might be bad? Or good? Context dependent. using neutral/warning.
      case "Decreasing": return Colors.green;
      default: return Colors.grey;
    }
  }

  Color _getStabilityColor(String status) {
    switch (status) {
      case "Stable": return Colors.green;
      case "Drifting": return Colors.orange;
      case "Chaotic": return Colors.red;
      default: return Colors.grey;
    }
  }
}
