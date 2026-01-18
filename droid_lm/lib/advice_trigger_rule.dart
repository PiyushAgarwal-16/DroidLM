import 'package:droid_lm/advice_category.dart';
import 'package:droid_lm/advice_trigger_context.dart';

/// Abstract base class for defining logic that triggers advice.
///
/// Each rule encapsulates a specific heuristic or condition (e.g., "High Distraction",
/// "Morning Habit") and evaluates whether it applies to the user's current context.
abstract class AdviceTriggerRule {
  /// The category of advice this rule intends to trigger.
  AdviceCategory get category;

  /// Determines if this rule's conditions are met based on the [context].
  ///
  /// Returns `true` if the advice is applicable, `false` otherwise.
  bool matches(AdviceTriggerContext context);

  /// Calculates the strength of the signal for this rule (0.0 - 1.0).
  ///
  /// A higher score indicates stronger evidence or urgency for this advice.
  /// This is used to prioritize competing advice rules.
  double confidenceScore(AdviceTriggerContext context);
}
