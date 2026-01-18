import 'package:droid_lm/advice_category.dart';
import 'package:droid_lm/advice_trigger_context.dart';
import 'package:droid_lm/advice_trigger_rule.dart';

/// Rule to detect high levels of digital distraction.
///
/// Triggers when the user's distraction score (derived from frequent switching,
/// app dominance, or fragmentation) exceeds a threshold.
class DistractionAdviceRule extends AdviceTriggerRule {
  @override
  AdviceCategory get category => AdviceCategory.distraction;

  /// Decides if distraction advice is necessary.
  ///
  /// Criteria:
  /// - [averageDistractionScore] > 0.6: Used as a soft threshold where usage
  ///   patterns suggest significant fragmentation or focus loss.
  ///
  /// Distraction advice is sensitive; we avoid triggering it on minor fluctuations
  /// to prevent the user from feeling nagging or adjudged. A 0.6 score implies
  /// clearest evidence of scattered attention.
  @override
  bool matches(AdviceTriggerContext context) {
    return context.averageDistractionScore > 0.6;
  }

  /// Calculates the urgency/confidence of the distraction signal.
  ///
  /// The score scales linearly with the severity of the distraction.
  /// A score of 0.6 yields 0.6 confidence, while 1.0 yields 1.0 (maximum urgency).
  @override
  double confidenceScore(AdviceTriggerContext context) {
    return context.averageDistractionScore.clamp(0.0, 1.0);
  }
}
