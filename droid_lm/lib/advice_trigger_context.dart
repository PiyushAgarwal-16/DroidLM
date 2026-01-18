import 'package:droid_lm/behavior_analysis.dart';

/// Context object containing aggregated behavioral metrics used to trigger advice.
///
/// This dataset is passed to the Advice Engine to evaluate which [AdviceTemplate]
/// is most relevant for the user at the current moment. It acts as a bridge
/// between raw ML outputs and the localized advice logic.
class AdviceTriggerContext {
  /// The aggregated summary of the past week's behavior (or available history).
  final WeeklyBehaviorSummary weeklySummary;

  /// Average habituality score (0.0 - 1.0) over the observation period.
  /// Derived from [weeklySummary] but exposed directly for easy access.
  final double averageHabitStrength;

  /// Average distraction score (0.0 - 1.0) over the observation period.
  final double averageDistractionScore;

  /// The name of the app that consumed the most screen time or had the most launches.
  /// Used to fill `{app}` placeholders in advice templates.
  final String dominantApp;

  /// The time of day (e.g., "Morning", "Late Night") where usage was most intense.
  /// Used to fill `{timeWindow}` placeholders.
  final String dominantTimeWindow;

  /// The direction of the habit strength trend ("Increasing", "Decreasing", "Stable").
  /// Directly corresponds to [WeeklyBehaviorSummary.habitualityTrend].
  final String habitTrend;

  /// Number of days of data used to compute these metrics.
  /// Useful for filtering out advice that requires long-term history.
  final int daysObserved;

  const AdviceTriggerContext({
    required this.weeklySummary,
    required this.averageHabitStrength,
    required this.averageDistractionScore,
    required this.dominantApp,
    required this.dominantTimeWindow,
    required this.habitTrend,
    required this.daysObserved,
  });
}
