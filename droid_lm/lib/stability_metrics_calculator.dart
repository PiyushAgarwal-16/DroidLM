import 'dart:math';
import 'package:droid_lm/daily_behavior_features.dart';

/// Output container for stability features.
class StabilityMetrics {
  final double daySimilarityScore; // 1.0 = Identical, 0.0 = Different
  final double screenTimeDeltaRatio; // +0.5 = 50% more time than yesterday
  final double topAppChangeFlag; // 1.0 = Changed, 0.0 = Same
  final double timeWindowShiftScore; // 0.0 - 1.0 (how much temporal pattern shifted)
  final double volatilityScore; // Composite score of change

  StabilityMetrics({
    required this.daySimilarityScore,
    required this.screenTimeDeltaRatio,
    required this.topAppChangeFlag,
    required this.timeWindowShiftScore,
    required this.volatilityScore,
  });

  @override
  String toString() {
    return 'Stability(Similarity: ${daySimilarityScore.toStringAsFixed(2)}, Volatility: ${volatilityScore.toStringAsFixed(2)})';
  }
}

class StabilityMetricsCalculator {

  /// Computes stability by comparing [today] vs [yesterday].
  /// 
  /// [todayTopApp] and [yesterdayTopApp] are optional strings to compute
  /// the [topAppChangeFlag], as the numeric feature vector doesn't contain names.
  static StabilityMetrics compute({
    required DailyBehaviorFeatures today,
    DailyBehaviorFeatures? yesterday,
    String? todayTopApp,
    String? yesterdayTopApp,
  }) {
    // 1. Handle Missing History (Neutral/Stable default)
    if (yesterday == null) {
      return StabilityMetrics(
        daySimilarityScore: 1.0, // Assume consistent if we don't know otherwise
        screenTimeDeltaRatio: 0.0,
        topAppChangeFlag: 0.0,
        timeWindowShiftScore: 0.0,
        volatilityScore: 0.0,
      );
    }

    // 2. Screen Time Delta
    // Formula: (Today - Yesterday) / Yesterday
    double timeDelta = 0.0;
    if (yesterday.totalScreenTimeMinutes > 0) {
      timeDelta = (today.totalScreenTimeMinutes - yesterday.totalScreenTimeMinutes) / yesterday.totalScreenTimeMinutes;
    } else if (today.totalScreenTimeMinutes > 0) {
      timeDelta = 1.0; // Infinite increase (0 -> Something)
    }
    // Cap delta to reasonable range -1.0 to 1.0 for stability score usage (though raw ratio is returned)
    double cappedDelta = timeDelta.clamp(-1.0, 1.0);


    // 3. Top App Change Flag
    // 1.0 if different, 0.0 if same.
    // Why? Changing your primary focus app often correlates with shifting interests or lack of routine.
    double appChange = 0.0;
    if (todayTopApp != null && yesterdayTopApp != null) {
      appChange = (todayTopApp != yesterdayTopApp) ? 1.0 : 0.0;
    }

    // 4. Time Window Shift (Temporal Stability)
    // Measures how much the distribution of time changed across 4 buckets.
    // Euclidean distance between the ratio vectors.
    // Max distance (e.g. [1,0,0,0] to [0,1,0,0]) is sqrt(2) approx 1.414.
    double dMorning = today.morningRatio - yesterday.morningRatio;
    double dAfternoon = today.afternoonRatio - yesterday.afternoonRatio;
    double dEvening = today.eveningRatio - yesterday.eveningRatio;
    double dNight = today.lateNightRatio - yesterday.lateNightRatio;

    double euclideanDist = sqrt(
      (dMorning * dMorning) + 
      (dAfternoon * dAfternoon) + 
      (dEvening * dEvening) + 
      (dNight * dNight)
    );
    // Normalize roughly to 0-1 range (dividing by sqrt(2))
    double temporalShift = (euclideanDist / 1.414).clamp(0.0, 1.0);


    // 5. Day Similarity (Cosine Similarity of full vectors)
    // Captures holistic behavioral match.
    double similarity = _computeCosineSimilarity(today.toList(), yesterday.toList());


    // 6. Volatility Score (Composite)
    // Weighted combination of changes. High score = High Volatility.
    // Weights:
    // - Time Delta (abs): 30%
    // - App Change: 20%
    // - Temporal Shift: 30%
    // - (1 - Similarity): 20%
    double invSimilarity = (1.0 - similarity).clamp(0.0, 1.0);
    double volatility = (0.3 * cappedDelta.abs()) + 
                        (0.2 * appChange) + 
                        (0.3 * temporalShift) + 
                        (0.2 * invSimilarity);

    return StabilityMetrics(
      daySimilarityScore: similarity,
      screenTimeDeltaRatio: timeDelta,
      topAppChangeFlag: appChange,
      timeWindowShiftScore: temporalShift,
      volatilityScore: volatility.clamp(0.0, 1.0),
    );
  }

  static double _computeCosineSimilarity(List<double> v1, List<double> v2) {
    if (v1.length != v2.length) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < v1.length; i++) {
      dotProduct += v1[i] * v2[i];
      normA += v1[i] * v1[i];
      normB += v2[i] * v2[i];
    }

    if (normA == 0 || normB == 0) return 0.0; // One vector is zero vector

    return dotProduct / (sqrt(normA) * sqrt(normB));
  }
}
