import 'package:droid_lm/daily_behavior_features.dart';

/// Strategy for converting a chronological sequence of daily features into 
/// sliding window samples for temporal sequence modeling.
///
/// **Why Sliding Windows?**
/// Human behavior is rarely isolated to a single day. It often follows multi-day
/// patterns such as:
/// - **Accumulation**: Sleep deprivation (late night usage) on Day 1 & 2 causes distraction on Day 3.
/// - **Momentum**: High productivity on Day 1 often leads to "flow" on Day 2.
/// - **Weekly Cycles**: Workdays (Mon-Fri) vs Weekends create 7-day dependencies.
///
/// By looking at a window of $N$ days (e.g., `[t-2, t-1, t]`), the model can learn these
/// 2nd and 3rd order dependencies instead of treating each day as an independent i.i.d. sample.
class TemporalWindowStrategy {
  
  /// The size of the sliding window ($N$).
  /// Default is 3 days (Today + Yesterday + Day Before).
  final int windowSize;

  const TemporalWindowStrategy({this.windowSize = 3});

  /// Generates sliding window samples from a chronological list of features.
  ///
  /// **Input:**
  /// - [chronologicalFeatures]: List of DailyBehaviorFeatures sorted by date (Oldest -> Newest).
  ///   Size = $D$ days.
  ///
  /// **Output:**
  /// - A list of "Windows". Each Window is a list of [windowSize] feature vectors.
  /// - Total Samples Generated = $D - N + 1$ (where $N$ is [windowSize]).
  ///
  /// **Handling Insufficient Data:**
  /// - If the input size $D < N$, this method returns an empty list.
  /// - We strictly enforce full windows to ensure the model always receives consistent input shapes.
  /// - Padding (e.g. with zeros) is avoided here to prevent the model from learning artifacts.
  List<List<DailyBehaviorFeatures>> generateWindows(List<DailyBehaviorFeatures> chronologicalFeatures) {
    if (chronologicalFeatures.length < windowSize) {
      // Not enough history to form even a single window.
      // E.g., Window=3, we have only 2 days of data.
      return [];
    }

    List<List<DailyBehaviorFeatures>> samples = [];

    // Sliding logic:
    // Window 1: indexes [0, 1, 2]
    // Window 2: indexes [1, 2, 3]
    // ...
    // Last Window starts at index [length - windowSize]
    
    // Total iterations: D - N + 1
    for (int i = 0; i <= chronologicalFeatures.length - windowSize; i++) {
        // Extract the sub-list of length N
        List<DailyBehaviorFeatures> window = chronologicalFeatures.sublist(i, i + windowSize);
        samples.add(window);
    }

    return samples;
  }
}
