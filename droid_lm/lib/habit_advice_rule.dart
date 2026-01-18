import 'package:droid_lm/advice_category.dart';
import 'package:droid_lm/advice_trigger_context.dart';
import 'package:droid_lm/advice_trigger_rule.dart';

/// Rule to detect significantly habitual behavior.
///
/// Triggers when the user exhibits a strong, repeated usage pattern over
/// a sufficient observation period.
class HabitAdviceRule extends AdviceTriggerRule {
  @override
  AdviceCategory get category => AdviceCategory.habit;

  /// Decides if habit advice is applicable.
  ///
  /// Criteria:
  /// - [averageHabitStrength] > 0.65: Represents a transition from random/occasional
  ///   behavior to a distinct, repeated routine.
  /// - [daysObserved] >= 5: Requires at least 5 days of data to distinguish
  ///   a genuine weekly pattern from a short-term anomaly (e.g., a busy weekend).
  @override
  bool matches(AdviceTriggerContext context) {
    return context.averageHabitStrength > 0.65 && context.daysObserved >= 5;
  }

  /// Calculates the confidence of this advice signal.
  ///
  /// The logic is linear: the stronger the habit score, the more confident we are
  /// that this behavior is ingrained.
  ///
  /// We clamp the result between 0.0 and 1.0 to ensure validity, although
  /// [averageHabitStrength] should theoretically be within range.
  @override
  double confidenceScore(AdviceTriggerContext context) {
    // Direct mapping: Stronger habits = Higher confidence.
    return context.averageHabitStrength.clamp(0.0, 1.0);
  }
}
