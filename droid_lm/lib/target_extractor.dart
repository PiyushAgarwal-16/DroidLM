import 'package:droid_lm/daily_behavior_features.dart';

/// Extracts training targets (Labels) from temporal windows.
///
/// **Strategy: Last-Step Prediction**
/// We align the target features with the **Last Day** of the window (Step $T$).
///
/// **Why?**
/// - We want the model to understand the *current state* based on recent context.
/// - "Given what I did D-2 and D-1, and how I behaved today (D), am I currently Habitual?"
/// - This fits the inference flow: We calculate features for Today, create a window [T-2, T-1, T], 
///   and ask the model for a Rating of T.
///
/// **Alternative (Next-Step/Forecast):**
/// - Predicting T+1 would be forecasting. That is useful for *intervention* ("You *will* be distracted tomorrow").
/// - For this Dashboard ("You *are* distracted"), Last-Step alignment is correct.
class TargetExtractor {
  
  /// Extracts the target vector for a single window.
  /// 
  /// [window]: List of DailyBehaviorFeatures. Must not be empty.
  /// 
  /// Returns: [habitualityScore, distractionScore] from the last day.
  List<double> extractTarget(List<DailyBehaviorFeatures> window) {
      if (window.isEmpty) return [0.0, 0.0];

      // Target is the state of the MOST RECENT day in the sequence.
      DailyBehaviorFeatures lastDay = window.last;

      // Primary Targets:
      // 1. Habit Strength (derived from volume/rigidity/re-entry)
      double habituality = lastDay.doomscrollingRisk; // mapped proxy in Assembler
      
      // 2. Distraction Load (derived from fragmentation/volatility)
      double distraction = lastDay.derivedDistractionScore;

      return [habituality, distraction];
  }

  /// Batch processes multiple windows to aligned targets.
  List<List<double>> extractBatchTargets(List<List<DailyBehaviorFeatures>> windows) {
     return windows.map((w) => extractTarget(w)).toList();
  }
}
