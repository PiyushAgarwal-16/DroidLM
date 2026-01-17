/// Represents a comprehensive feature vector for a single day of phone usage.
/// Designed for advanced ML analysis of digital wellbeing.
/// 
/// Total Features: 34
class DailyBehaviorFeatures {
  // ==========================================
  // 1. Usage Volume & Intensity (6 features)
  // ==========================================
  
  /// Total time screen was on in minutes.
  final double totalScreenTimeMinutes;
  
  /// Number of times device was unlocked.
  final double unlockCount;
  
  /// Average duration of a usage session in minutes.
  final double avgSessionLengthMinutes;
  
  /// Duration of the longest continuous session in minutes.
  final double maxSessionLengthMinutes;
  
  /// Count of sessions shorter than 1 minute (Checking behavior).
  final double shortSessionCount;
  
  /// Count of sessions longer than 30 minutes (Deep engagement).
  final double longSessionCount;

  // ==========================================
  // 2. Temporal Structure (8 features)
  // ==========================================

  /// Usage minutes during Morning (06:00 - 12:00).
  final double morningMinutes;
  
  /// Usage minutes during Afternoon (12:00 - 18:00).
  final double afternoonMinutes;
  
  /// Usage minutes during Evening (18:00 - 00:00).
  final double eveningMinutes;
  
  /// Usage minutes during Late Night (00:00 - 06:00).
  final double lateNightMinutes;

  /// Ratio of Morning usage to Total usage (0.0 - 1.0).
  final double morningRatio;
  
  /// Ratio of Afternoon usage to Total usage (0.0 - 1.0).
  final double afternoonRatio;
  
  /// Ratio of Evening usage to Total usage (0.0 - 1.0).
  final double eveningRatio;
  
  /// Ratio of Late Night usage to Total usage (0.0 - 1.0).
  final double lateNightRatio;

  // ==========================================
  // 3. App Interaction Behavior (8 features)
  // ==========================================

  /// Number of unique apps used for at least 30 seconds.
  final double uniqueAppsCount;
  
  /// Minutes spent in the #1 most used app.
  final double topAppMinutes;
  
  /// Ratio of top app minutes to total minutes (Concentration).
  final double topAppRatio;
  
  /// Total minutes in Social Media category.
  final double socialMinutes;
  
  /// Total minutes in Productivity/Tools category.
  final double productivityMinutes;
  
  /// Total minutes in Entertainment/Video/Games category.
  final double entertainmentMinutes;
  
  /// Total minutes in Communication/Chat category.
  final double communicationMinutes;
  
  /// Estimated frequency of app switching (switches per hour).
  final double appSwitchFrequency;

  // ==========================================
  // 4. Behavior Stability (6 features)
  // ==========================================

  /// Variance in session lengths (High = erratic, Low = consistent).
  final double sessionLengthVariance;
  
  /// Average time (minutes) between sessions (Inter-session Interval).
  final double avgInterSessionInterval;
  
  /// Routine Consistency Score (0.0 - 1.0) compared to rolling history.
  /// (1.0 = highly predictable start/stop times).
  final double routineConsistencyScore;
  
  /// 1.0 if Weekend, 0.0 if Weekday.
  final double isWeekend;
  
  /// Offset in minutes of first unlock from typical wake time (positive/negative).
  final double wakeTimeOffset;
  
  /// Offset in minutes of last lock from typical sleep time.
  final double sleepTimeOffset;

  // ==========================================
  // 5. Derived Cognitive Signals (6 features)
  // ==========================================

  /// Fragmentation Index: Ratio of short sessions to total sessions.
  /// (High = fragmented attention).
  final double fragmentationIndex;
  
  /// Distraction Score: Derived from high unlock count and fast switching.
  final double derivedDistractionScore;
  
  /// Focus Score: Derived from long productivity sessions.
  final double derivedFocusScore;
  
  /// Circadian Alignment: Penalty for high late-night usage.
  final double circadianAlignmentScore;
  
  /// Flow State Probability: Likelihood user entered flow (0.0 - 1.0).
  final double flowStateProbability;
  
  /// Doomscrolling Risk: High vertical scroll volume + social media time.
  final double doomscrollingRisk;

  const DailyBehaviorFeatures({
    required this.totalScreenTimeMinutes,
    required this.unlockCount,
    required this.avgSessionLengthMinutes,
    required this.maxSessionLengthMinutes,
    required this.shortSessionCount,
    required this.longSessionCount,
    required this.morningMinutes,
    required this.afternoonMinutes,
    required this.eveningMinutes,
    required this.lateNightMinutes,
    required this.morningRatio,
    required this.afternoonRatio,
    required this.eveningRatio,
    required this.lateNightRatio,
    required this.uniqueAppsCount,
    required this.topAppMinutes,
    required this.topAppRatio,
    required this.socialMinutes,
    required this.productivityMinutes,
    required this.entertainmentMinutes,
    required this.communicationMinutes,
    required this.appSwitchFrequency,
    required this.sessionLengthVariance,
    required this.avgInterSessionInterval,
    required this.routineConsistencyScore,
    required this.isWeekend,
    required this.wakeTimeOffset,
    required this.sleepTimeOffset,
    required this.fragmentationIndex,
    required this.derivedDistractionScore,
    required this.derivedFocusScore,
    required this.circadianAlignmentScore,
    required this.flowStateProbability,
    required this.doomscrollingRisk,
  });

  /// Converts the feature object into a flattened numeric vector.
  /// 
  /// ORDER IS CRITICAL for ML Model inference.
  List<double> toList() {
    return [
      // 1. Volume
      totalScreenTimeMinutes,
      unlockCount,
      avgSessionLengthMinutes,
      maxSessionLengthMinutes,
      shortSessionCount,
      longSessionCount,
      
      // 2. Temporal
      morningMinutes,
      afternoonMinutes,
      eveningMinutes,
      lateNightMinutes,
      morningRatio,
      afternoonRatio,
      eveningRatio,
      lateNightRatio,
      
      // 3. Interaction
      uniqueAppsCount,
      topAppMinutes,
      topAppRatio,
      socialMinutes,
      productivityMinutes,
      entertainmentMinutes,
      communicationMinutes,
      appSwitchFrequency,
      
      // 4. Stability
      sessionLengthVariance,
      avgInterSessionInterval,
      routineConsistencyScore,
      isWeekend,
      wakeTimeOffset,
      sleepTimeOffset,
      
      // 5. Cognitive
      fragmentationIndex,
      derivedDistractionScore,
      derivedFocusScore,
      circadianAlignmentScore,
      flowStateProbability,
      doomscrollingRisk,
    ];
  }
}
