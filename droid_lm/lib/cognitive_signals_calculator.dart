import 'dart:math';
import 'package:droid_lm/usage_metrics_calculator.dart';
import 'package:droid_lm/temporal_metrics_calculator.dart';
import 'package:droid_lm/interaction_metrics_calculator.dart';
import 'package:droid_lm/stability_metrics_calculator.dart';

/// Output container for high-level cognitive signals.
class CognitiveSignals {
  final double habitStrengthIndex;    // 0-1: How entrenched the behavior is
  final double distractionLoadIndex;  // 0-1: How scattered/distracted the user is
  final double routineRigidityScore;  // 0-1: How inflexible the routine is
  final double usageFragmentationScore; // 0-1: How broken up the usage is

  CognitiveSignals({
    required this.habitStrengthIndex,
    required this.distractionLoadIndex,
    required this.routineRigidityScore,
    required this.usageFragmentationScore,
  });

  @override
  String toString() {
    return 'Cognitive(Habit: ${habitStrengthIndex.toStringAsFixed(2)}, Distraction: ${distractionLoadIndex.toStringAsFixed(2)})';
  }
}

class CognitiveSignalsCalculator {

  /// Computes derived cognitive signals by combining low-level metrics.
  static CognitiveSignals compute({
    required UsageVolumeMetrics volume,
    required TemporalMetrics temporal,
    required InteractionMetrics interaction,
    required StabilityMetrics stability,
  }) {
    // ==========================================================
    // 1. Usage Fragmentation Score
    // ==========================================================
    // Logic: High fragmentation means short bursts of usage and frequent switching.
    //
    // Components:
    // - Short Session Ratio: (Sessions < 1m) ? We don't have explicit count in VolumeMetrics, 
    //   but we have avgSessionLength. Low avg = High fragmentation.
    // - Switch Rate: High switching = High fragmentation.
    // - Reopen Rate: High reopens = Pogo-sticking (fragmented).
    
    // Normalize Avg Session Length (Inverse). Assume 20m is "Max Focus". <1m is High Frag.
    double avgSessionNorm = (volume.averageSessionLength / 20.0).clamp(0.0, 1.0);
    double shortSessionFactor = 1.0 - avgSessionNorm; // 1.0 if session is 0m, 0.0 if session is 20m+

    // Normalize Switch Rate. Assume 60 switches/hr is Max.
    double switchRateNorm = (interaction.appSwitchRate / 60.0).clamp(0.0, 1.0);

    // Formula: 
    // 40% Short Sessions
    // 40% Rapid Switching
    // 20% Re-opening
    double fragmentation = (0.4 * shortSessionFactor) + 
                           (0.4 * switchRateNorm) + 
                           (0.2 * interaction.reopenRate);


    // ==========================================================
    // 2. Distraction Load Index
    // ==========================================================
    // Logic: High Cognitive Load caused by multitasking, diversity, and chaos.
    //
    // Components:
    // - Fragmentation Score (calculated above)
    // - App Diversity (using many apps is more taxing than one)
    // - Volatility (erratic behavior)
    
    // Formula:
    // 50% Fragmentation
    // 30% Diversity
    // 20% Volatility
    double distraction = (0.5 * fragmentation) + 
                         (0.3 * interaction.appDiversityRatio) + 
                         (0.2 * stability.volatilityScore);


    // ==========================================================
    // 3. Routine Rigidity Score
    // ==========================================================
    // Logic: How "stuck" or "precise" the user is. 
    // High Rigidity = Doing the exact same thing at the exact same time.
    //
    // Components:
    // - Day Similarity (Stability): High = Rigid
    // - Time Window Entropy (Temporal): Low = Rigid (doing things only at specific times)
    // - Top App Ratio (Volume): High = Rigid (only using one app)
    
    // Formula:
    // 40% Similarity
    // 30% Low Entropy (1 - Entropy)
    // 30% Concentration (Top App Ratio)
    double rigidity = (0.4 * stability.daySimilarityScore) + 
                      (0.3 * (1.0 - temporal.timeWindowEntropy)) + 
                      (0.3 * volume.topAppUsageRatio);


    // ==========================================================
    // 4. Habit Strength Index
    // ==========================================================
    // Logic: How strong is the "Habit Loop"?
    // Habits are characterized by repetition (Similarity), Cues (Re-entry), and Intensity (Volume).
    //
    // Components:
    // - Routine Rigidity (calculated above): Habits are rigid.
    // - Top App Re-entry Rate (Interaction): Returning to the "Hook" app frequently.
    // - Total Usage Intensity: Assume 8h (480m) is Max Intensity.
    
    double intensityNorm = (volume.totalScreenTimeMinutes / 480.0).clamp(0.0, 1.0);
    
    // Formula:
    // 40% Rigidity (Predictability)
    // 30% Re-entry (Compulsion)
    // 30% Volume (Intensity)
    double habitStrength = (0.4 * rigidity) + 
                           (0.3 * interaction.topAppReentryRate) + 
                           (0.3 * intensityNorm);


    return CognitiveSignals(
      habitStrengthIndex: habitStrength.clamp(0.0, 1.0),
      distractionLoadIndex: distraction.clamp(0.0, 1.0),
      routineRigidityScore: rigidity.clamp(0.0, 1.0),
      usageFragmentationScore: fragmentation.clamp(0.0, 1.0),
    );
  }
}
