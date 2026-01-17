import 'package:flutter/foundation.dart';
import 'package:droid_lm/daily_behavior_features.dart';

/// A robust windowing strategy that handles gaps and missing data.
///
/// **Edge Case Policy for Demo:**
/// 1. **Insufficient Data**: Return empty. We need distinct samples to train.
/// 2. **Gaps (Missing Dates)**: SKIP. We only train on contiguous sequences.
///    - *Why?* Synthesizing fake "zero usage" days for gaps might confuse the model
///      if the gap was actually due to the phone being off or logging disabled.
///      Better to be conservative and only use proven sequential data.
/// 3. **Zero Usage**: Valid. If the logs exist but usage is 0, that's a signal.
class GapAwareWindowStrategy {
  final int windowSize;

  const GapAwareWindowStrategy({this.windowSize = 3});

  /// Generates windows only from strictly contiguous dates.
  /// 
  /// [featuresMap]: Map<DateTime, DailyBehaviorFeatures>. 
  /// Keys must be normalized (midnight) dates.
  List<List<DailyBehaviorFeatures>> generateContiguousWindows(Map<DateTime, DailyBehaviorFeatures> featuresMap) {
    if (featuresMap.length < windowSize) {
      if (kDebugMode) print("GapAwareStrategy: Not enough total days (${featuresMap.length} < $windowSize).");
      return [];
    }

    // 1. Sort dates
    List<DateTime> sortedDates = featuresMap.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    List<List<DailyBehaviorFeatures>> validWindows = [];

    // 2. Scan for contiguous blocks
    for (int i = 0; i <= sortedDates.length - windowSize; i++) {
        // Candidate start
        bool isContiguous = true;
        List<DailyBehaviorFeatures> currentWindow = [];

        for (int offset = 0; offset < windowSize; offset++) {
             DateTime expectedDate = sortedDates[i].add(Duration(days: offset));
             DateTime actualDate = sortedDates[i + offset];

             // Check strict day equality (ignoring time if keys are midnight)
             if (!_isSameDay(expectedDate, actualDate)) {
               isContiguous = false;
               break; // Break inner loop, move to next start index
             }
             
             currentWindow.add(featuresMap[actualDate]!);
        }

        if (isContiguous) {
          validWindows.add(currentWindow);
        } else {
           // Skip. The fact that sortedDates[i] and sortedDates[i+1] aren't contiguous
           // means any window starting at `i` is invalid.
           // We continue loop `i++` which tries the next date as start.
        }
    }

    if (kDebugMode && validWindows.isEmpty) {
      print("GapAwareStrategy: Found 0 contiguous windows of size $windowSize.");
    }

    return validWindows;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
