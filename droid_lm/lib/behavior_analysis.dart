import 'dart:math';

/// Represents a single day's output from the ML model.
class ModelOutput {
  final double habitualityScore; // 0.0 to 1.0
  final double distractionScore; // 0.0 to 1.0
  final String stabilityLabel;   // "Stable", "Drifting", "Chaotic"

  ModelOutput({
    required this.habitualityScore,
    required this.distractionScore,
    required this.stabilityLabel,
  });

  /// Factory to create from the raw map returned by mockInference
  factory ModelOutput.fromMap(Map<String, dynamic> map) {
    return ModelOutput(
      habitualityScore: (map['habituality'] as num).toDouble(),
      distractionScore: (map['distraction'] as num).toDouble(),
      stabilityLabel: map['stability'] as String,
    );
  }
}

/// Represents the aggregated summary of behavior over a week (or any list of days).
class WeeklyBehaviorSummary {
  final double averageHabituality;
  final double averageDistraction;
  final String dominantStability;
  final String habitualityTrend; // "Increasing", "Decreasing", "Flat", "Insufficient Data"

  WeeklyBehaviorSummary({
    required this.averageHabituality,
    required this.averageDistraction,
    required this.dominantStability,
    required this.habitualityTrend,
  });

  @override
  String toString() {
    return 'WeeklyBehaviorSummary(avgHab: ${averageHabituality.toStringAsFixed(2)}, '
           'avgDist: ${averageDistraction.toStringAsFixed(2)}, '
           'domStab: $dominantStability, '
           'trend: $habitualityTrend)';
  }
}

/// Logic for analyzing trend and aggregation.
class WeeklyAnalyzer {
  /// Computes the weekly summary from a list of model outputs.
  /// Expects the list to be chronological (index 0 = oldest, index N = newest).
  static WeeklyBehaviorSummary computeSummary(List<ModelOutput> outputs) {
    if (outputs.isEmpty) {
      return WeeklyBehaviorSummary(
        averageHabituality: 0.0,
        averageDistraction: 0.0,
        dominantStability: "Insufficient Data",
        habitualityTrend: "Insufficient Data",
      );
    }

    // 1. Calculate Averages
    double totalHab = 0;
    double totalDist = 0;
    Map<String, int> stabilityCounts = {};

    for (var out in outputs) {
      totalHab += out.habitualityScore;
      totalDist += out.distractionScore;
      
      stabilityCounts[out.stabilityLabel] = (stabilityCounts[out.stabilityLabel] ?? 0) + 1;
    }

    double avgHab = totalHab / outputs.length;
    double avgDist = totalDist / outputs.length;

    // 2. Determine Dominant Stability (Mode)
    String dominantStability = "Unknown";
    int maxCount = -1;
    stabilityCounts.forEach((label, count) {
      if (count > maxCount) {
        maxCount = count;
        dominantStability = label;
      }
    });

    // 3. Calculate Trend for Habituality
    // We use a "Half-Split" method:
    // Compare the average of the second half (recent) vs the first half (older).
    // If difference > threshold -> Increasing
    // If difference < -threshold -> Decreasing
    // Else -> Flat
    String trend = "Flat";
    
    if (outputs.length >= 2) {
      int midPoint = outputs.length ~/ 2;
      
      // Oldest half (0 to midPoint)
      List<ModelOutput> firstHalf = outputs.sublist(0, midPoint);
      
      // Newest half (midPoint to end)
      // If odd length, exact middle is included in second half (recent bias) or we can skip it.
      // Let's include middle in recent for weighted recency.
      List<ModelOutput> secondHalf = outputs.sublist(midPoint); 

      double avgFirst = firstHalf.map((e) => e.habitualityScore).reduce((a, b) => a + b) / firstHalf.length;
      double avgSecond = secondHalf.map((e) => e.habitualityScore).reduce((a, b) => a + b) / secondHalf.length;
      
      double diff = avgSecond - avgFirst;
      const double threshold = 0.05; // 5% shift is considered significant

      if (diff > threshold) {
        trend = "Increasing";
      } else if (diff < -threshold) {
        trend = "Decreasing";
      } else {
        trend = "Flat";
      }
    } else {
      trend = "Insufficient Data";
    }

    return WeeklyBehaviorSummary(
      averageHabituality: avgHab,
      averageDistraction: avgDist,
      dominantStability: dominantStability,
      habitualityTrend: trend,
    );
  }
}

/// Helper class to generate human-readable insights from numeric summaries.
class WeeklyInsightGenerator {
  /// Converts a [WeeklyBehaviorSummary] into a list of prioritized insight strings.
  /// Returns max 3 insights.
  static List<String> generateInsights(WeeklyBehaviorSummary summary) {
    List<String> insights = [];

    // 1. Check for Strong Habituality
    if (summary.averageHabituality > 0.7) {
      insights.add("Strong recurring usage habits detected this week.");
    } else if (summary.habitualityTrend == "Increasing") {
      // Priority catch: If not overwhelmingly strong yet, but increasing.
      insights.add("Your phone usage is becoming more habitual over time.");
    }

    // 2. Check for Distraction
    if (summary.averageDistraction > 0.6) {
      insights.add("High distraction load observed across the week.");
    } else if (summary.averageDistraction < 0.3) {
       insights.add("Your usage was relatively balanced this week.");
    }

    // 3. Check for Stability
    if (summary.dominantStability == "Stable") {
      insights.add("Your usage pattern remained consistent this week.");
    }

    // Limit to 3 items
    if (insights.length > 3) {
      return insights.sublist(0, 3);
    }
    return insights;
  }
}
