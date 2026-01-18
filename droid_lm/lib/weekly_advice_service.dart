import 'package:droid_lm/advice_engine.dart';
import 'package:droid_lm/advice_trigger_context.dart';
import 'package:droid_lm/advice_trigger_rule.dart';
import 'package:droid_lm/behavior_analysis.dart';
import 'package:droid_lm/distraction_advice_rule.dart';
import 'package:droid_lm/generated_advice.dart';
import 'package:droid_lm/habit_advice_rule.dart';

/// A pure computation service that bridges raw behavioral data with the Advice Engine.
///
/// This service is responsible for:
/// 1. Transforming [WeeklyBehaviorSummary] and other raw signals into a standardized [AdviceTriggerContext].
/// 2. configuring the [AdviceEngine] with the appropriate set of [AdviceTriggerRule]s.
/// 3. Executing the engine to produce a final list of [GeneratedAdvice].
class WeeklyAdviceService {
  
  // Simple in-memory cache for gating.
  // In a real app, this should be persisted to local storage so it survives app restarts.
  static DateTime? _lastGeneratedTime;
  static List<GeneratedAdvice>? _cachedAdvice;

  /// Generates a list of personalized advice based on the provided behavioral summary.
  ///
  /// This method is stateless and synchronous (conceptually), dependent only on the inputs.
  ///
  /// [summary]: The aggregated stats for the week.
  /// [dominantApp]: The app with the most usage/launches.
  /// [dominantTimeWindow]: The time of day with peak usage.
  /// [daysObserved]: How many days were included in the summary.
  /// [forceRefresh]: If true, bypasses the weekly gating and forces regeneration.
  static List<GeneratedAdvice> generate(
    WeeklyBehaviorSummary summary, {
    required String dominantApp,
    required String dominantTimeWindow,
    required int daysObserved,
    bool forceRefresh = false,
  }) {
    // 0. Gating Logic
    // Why gating?
    // Consistency builds trust. If the advice changes every time the user opens the app,
    // it feels random and the user is less likely to take it seriously.
    // By holding advice constant for a period (e.g., a week), we give the user time
    // to reflect and act on it.
    if (!forceRefresh && _lastGeneratedTime != null && _cachedAdvice != null) {
      final daysSinceGeneration = DateTime.now().difference(_lastGeneratedTime!).inDays;
      if (daysSinceGeneration < 7) {
        print("WeeklyAdviceService: Gating active. Returning cached advice from $_lastGeneratedTime");
        return _cachedAdvice!;
      }
    }

    // 1. Build the Context
    // We map the aggregated analysis results into the standardized context object
    // required by the Advice Engine.
    final context = AdviceTriggerContext(
      // The full summary object is passed for any complex rules that need it.
      weeklySummary: summary,
      
      // Directly map the average scores (0.0 - 1.0)
      averageHabitStrength: summary.averageHabituality,
      averageDistractionScore: summary.averageDistraction,
      
      // Signals passed from the caller (likely derived from a separate usage aggregation pass)
      // We ensure these are not null, though the Engine handles empty strings gracefully.
      dominantApp: dominantApp,
      dominantTimeWindow: dominantTimeWindow,
      
      // Trend direction ("Increasing", "Decreasing", "Flat", "Stable")
      // derived from the WeeklyAnalyzer.
      habitTrend: summary.habitualityTrend,
      
      // Data quantity signal
      daysObserved: daysObserved,
    );

    // 2. Configure Rules
    // We instantiate the specific rules we want to be active for this analysis.
    // In the future, we could injection these or load them dynamically.
    final List<AdviceTriggerRule> rules = [
      HabitAdviceRule(),
      DistractionAdviceRule(),
      // TODO: Add PositiveAdviceRule when implemented
    ];

    // 3. Run the Engine
    final engine = AdviceEngine(rules: rules);
    final results = engine.evaluate(context);

    // Debug logging for transparency
    print("WeeklyAdviceService: Analysis [Days: $daysObserved] | Habit: ${summary.averageHabituality.toStringAsFixed(2)} | Distraction: ${summary.averageDistraction.toStringAsFixed(2)}");
    print("WeeklyAdviceService: Generated ${results.length} advice items.");
    for (var advice in results) {
       print(" - [${advice.category.name}] ${advice.title}");
    }

    // 4. Update Cache
    _lastGeneratedTime = DateTime.now();
    _cachedAdvice = results;

    return results;
  }
}
