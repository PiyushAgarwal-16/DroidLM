import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:droid_lm/usage_metrics_calculator.dart';
import 'package:droid_lm/temporal_metrics_calculator.dart';
import 'package:droid_lm/interaction_metrics_calculator.dart';
import 'package:droid_lm/stability_metrics_calculator.dart';
import 'package:droid_lm/cognitive_signals_calculator.dart';
import 'package:droid_lm/daily_behavior_features.dart';

/// Orchestrator class that converts raw session logs into a complete ML-ready feature vector.
class DailyFeatureAssembler {

  /// Assembles a [DailyBehaviorFeatures] object from raw session logs.
  /// 
  /// [sessions]: Chronological list of app usage events for the day.
  /// [date]: The specific date being processing (used for time windows).
  /// [yesterdayFeatures]: (Optional) Features from the previous day for stability comparison.
  /// [yesterdayTopApp]: (Optional) Name of yesterday's top app for trend detection.
  static DailyBehaviorFeatures assemble({
    required List<AppSession> sessions,
    required DateTime date,
    DailyBehaviorFeatures? yesterdayFeatures,
    String? yesterdayTopApp,
  }) {
    if (kDebugMode) {
      print("--- Feature Assembly Start: ${date.toIso8601String().split('T')[0]} ---");
      print("Raw Sessions: ${sessions.length}");
    }

    // 1. Compute Usage Volume & Intensity
    final volume = UsageMetricsCalculator.compute(sessions);
    if (kDebugMode) print("Volume: $volume");

    // 2. Compute Temporal Structure
    final temporal = TemporalMetricsCalculator.compute(sessions, date);
    if (kDebugMode) print("Temporal: $temporal");

    // 3. Compute App Interaction
    final interaction = InteractionMetricsCalculator.compute(sessions);
    if (kDebugMode) print("Interaction: $interaction");

    // 4. Compute Stability & Trends (Relative to Yesterday)
    // We need to determine Today's top app first to pass to Stability calculator
    final todayTopApp = _identifyTopApp(sessions);

    final stability = StabilityMetricsCalculator.compute(
      today: _tempFeaturesForStability(volume, temporal, interaction), // Create a partial object
      yesterday: yesterdayFeatures,
      todayTopApp: todayTopApp,
      yesterdayTopApp: yesterdayTopApp,
    );
    if (kDebugMode) print("Stability: $stability");

    // 5. Compute Derived Cognitive Signals
    final cognitive = CognitiveSignalsCalculator.compute(
      volume: volume,
      temporal: temporal,
      interaction: interaction,
      stability: stability,
    );
    if (kDebugMode) print("Cognitive: $cognitive");

    // 6. Final Assembly
    return DailyBehaviorFeatures(
      // Volume
      totalScreenTimeMinutes: volume.totalScreenTimeMinutes,
      unlockCount: volume.numberOfSessions.toDouble(), // Using sessions as proxy for unlocks if identical
      avgSessionLengthMinutes: volume.averageSessionLength,
      maxSessionLengthMinutes: volume.maxSessionLength,
      shortSessionCount: 0, // Placeholder: UsageMetrics doesn't strictly count count <1min yet, could refine later
      longSessionCount: 0, // Placeholder
      
      // Temporal
      morningMinutes: temporal.morningMinutes,
      afternoonMinutes: temporal.afternoonMinutes,
      eveningMinutes: temporal.eveningMinutes,
      lateNightMinutes: temporal.nightMinutes,
      morningRatio: temporal.morningRatio,
      afternoonRatio: temporal.afternoonRatio,
      eveningRatio: temporal.eveningRatio,
      lateNightRatio: temporal.nightRatio,
      
      // Interaction
      uniqueAppsCount: interaction.uniqueAppsCount.toDouble(),
      topAppMinutes: volume.topAppMinutes,
      topAppRatio: volume.topAppUsageRatio,
      socialMinutes: 0.0, // Categories not yet implemented in basic scraper
      productivityMinutes: 0.0,
      entertainmentMinutes: 0.0,
      communicationMinutes: 0.0,
      appSwitchFrequency: interaction.appSwitchRate,
      
      // Stability
      sessionLengthVariance: 0.0, // Variance requires multi-pass, skipping for efficiency or implementation later
      avgInterSessionInterval: 0.0,
      routineConsistencyScore: stability.daySimilarityScore, // Similarity is good proxy for consistency
      isWeekend: (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) ? 1.0 : 0.0,
      wakeTimeOffset: 0.0, // Requires complex wake detection logic
      sleepTimeOffset: 0.0,
      
      // Cognitive
      fragmentationIndex: cognitive.usageFragmentationScore,
      derivedDistractionScore: cognitive.distractionLoadIndex,
      derivedFocusScore: 1.0 - cognitive.distractionLoadIndex, // Basic inversion for now
      circadianAlignmentScore: 1.0 - temporal.nightRatio, // Less night usage = better alignment
      flowStateProbability: 0.0, // Complex to derive
      doomscrollingRisk: cognitive.habitStrengthIndex, // High habit ~ risk? Proxy.
    );
  }

  /// Helper: Re-identifies top app name from sessions.
  /// (Logic duplicated from MetricsCalc but needed for String name pass-through)
  static String _identifyTopApp(List<AppSession> sessions) {
    if (sessions.isEmpty) return "None";
    
    Map<String, double> durations = {};
    for (var s in sessions) {
       durations[s.appName] = (durations[s.appName] ?? 0) + s.durationMinutes;
    }
    
    String topApp = "None";
    double maxDur = -1;
    durations.forEach((app, dur) {
      if (dur > maxDur) {
        maxDur = dur;
        topApp = app;
      }
    });
    return topApp;
  }

  /// Helper: Creates a partial [DailyBehaviorFeatures] object just for the Stability Calculator's use.
  /// The Stability Calculator primarily looks at: Volume, Temporal Ratios, Top Apps.
  /// We fill in what we have so far.
  static DailyBehaviorFeatures _tempFeaturesForStability(
    UsageVolumeMetrics v, 
    TemporalMetrics t, 
    InteractionMetrics i
  ) {
    return DailyBehaviorFeatures(
      totalScreenTimeMinutes: v.totalScreenTimeMinutes,
      unlockCount: v.numberOfSessions.toDouble(),
      avgSessionLengthMinutes: v.averageSessionLength,
      maxSessionLengthMinutes: v.maxSessionLength,
      shortSessionCount: 0,
      longSessionCount: 0,
      morningMinutes: t.morningMinutes,
      afternoonMinutes: t.afternoonMinutes,
      eveningMinutes: t.eveningMinutes,
      lateNightMinutes: t.nightMinutes,
      morningRatio: t.morningRatio,
      afternoonRatio: t.afternoonRatio,
      eveningRatio: t.eveningRatio,
      lateNightRatio: t.nightRatio,
      uniqueAppsCount: i.uniqueAppsCount.toDouble(),
      topAppMinutes: v.topAppMinutes,
      topAppRatio: v.topAppUsageRatio,
      socialMinutes: 0,
      productivityMinutes: 0,
      entertainmentMinutes: 0,
      communicationMinutes: 0,
      appSwitchFrequency: i.appSwitchRate,
      sessionLengthVariance: 0,
      avgInterSessionInterval: 0,
      routineConsistencyScore: 0,
      isWeekend: 0,
      wakeTimeOffset: 0,
      sleepTimeOffset: 0,
      fragmentationIndex: 0,
      derivedDistractionScore: 0,
      derivedFocusScore: 0,
      circadianAlignmentScore: 0,
      flowStateProbability: 0,
      doomscrollingRisk: 0,
    );
  }
}
