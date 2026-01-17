import 'dart:math';
import 'package:droid_lm/usage_metrics_calculator.dart'; // For AppSession

/// Output container for temporal features.
class TemporalMetrics {
  // Buckets
  final double morningMinutes;   // 05:00 - 12:00
  final double afternoonMinutes; // 12:00 - 17:00
  final double eveningMinutes;   // 17:00 - 22:00
  final double nightMinutes;     // 22:00 - 05:00 (Includes 00-05 and 22-24)

  // Ratios (0.0 - 1.0)
  final double morningRatio;
  final double afternoonRatio;
  final double eveningRatio;
  final double nightRatio;

  // Analysis
  final int dominantWindowIndex; // 0=Morning, 1=Afternoon, 2=Evening, 3=Night
  final double peakWindowRatio;
  final double offPeakWindowRatio; // Radius of smallest window
  final double timeWindowEntropy; // Normalized 0-1

  TemporalMetrics({
    required this.morningMinutes,
    required this.afternoonMinutes,
    required this.eveningMinutes,
    required this.nightMinutes,
    required this.morningRatio,
    required this.afternoonRatio,
    required this.eveningRatio,
    required this.nightRatio,
    required this.dominantWindowIndex,
    required this.peakWindowRatio,
    required this.offPeakWindowRatio,
    required this.timeWindowEntropy,
  });

  @override
  String toString() {
    return 'TemporalMetrics(Entropy: ${timeWindowEntropy.toStringAsFixed(2)}, Peak: ${peakWindowRatio.toStringAsFixed(2)})';
  }
}

class TemporalMetricsCalculator {
  
  /// Computes temporal metrics for a specific reference [date].
  /// [date] is needed to construct the absolute time windows for that day.
  static TemporalMetrics compute(List<AppSession> sessions, DateTime date) {
    if (sessions.isEmpty) {
      return _emptyMetrics();
    }

    // 1. Define Windows for the specific Date
    // Using start of day to construct limits
    final dayStart = DateTime(date.year, date.month, date.day);
    
    // Night Part 1: 00:00 - 05:00
    final night1Start = dayStart;
    final night1End = dayStart.add(const Duration(hours: 5));
    
    // Morning: 05:00 - 12:00
    final morningStart = night1End; // 05:00
    final morningEnd = dayStart.add(const Duration(hours: 12));
    
    // Afternoon: 12:00 - 17:00
    final afternoonStart = morningEnd; // 12:00
    final afternoonEnd = dayStart.add(const Duration(hours: 17));
    
    // Evening: 17:00 - 22:00
    final eveningStart = afternoonEnd; // 17:00
    final eveningEnd = dayStart.add(const Duration(hours: 22));
    
    // Night Part 2: 22:00 - 24:00 (End of day)
    final night2Start = eveningEnd; // 22:00
    final night2End = dayStart.add(const Duration(hours: 24));

    double mMinutes = 0;
    double aMinutes = 0;
    double eMinutes = 0;
    double nMinutes = 0;

    // 2. Accumulate Minutes per Window
    // We split sessions that cross boundaries.
    for (var session in sessions) {
       mMinutes += _getOverlapMinutes(session, morningStart, morningEnd);
       aMinutes += _getOverlapMinutes(session, afternoonStart, afternoonEnd);
       eMinutes += _getOverlapMinutes(session, eveningStart, eveningEnd);
       // Night is sum of early morning and late night
       nMinutes += _getOverlapMinutes(session, night1Start, night1End);
       nMinutes += _getOverlapMinutes(session, night2Start, night2End);
    }

    double totalMinutes = mMinutes + aMinutes + eMinutes + nMinutes;

    if (totalMinutes == 0) {
      return _emptyMetrics();
    }

    // 3. Compute Ratios
    double mRatio = mMinutes / totalMinutes;
    double aRatio = aMinutes / totalMinutes;
    double eRatio = eMinutes / totalMinutes;
    double nRatio = nMinutes / totalMinutes;

    List<double> ratios = [mRatio, aRatio, eRatio, nRatio];

    // 4. Find Dominant and Peak
    int dominantIndex = 0;
    double peakRatio = ratios[0];
    double minRatio = ratios[0];

    for (int i = 1; i < ratios.length; i++) {
       if (ratios[i] > peakRatio) {
         peakRatio = ratios[i];
         dominantIndex = i;
       }
       if (ratios[i] < minRatio) {
         minRatio = ratios[i];
       }
    }

    // 5. Compute Entropy (Normalized)
    // Formula: H(X) = - sum(p(x) * log2(p(x)))
    // Max entropy for 4 buckets is log2(4) = 2.0.
    // Normalized = H / 2.0.
    //
    // Why it matters?
    // Low Entropy (near 0): Usage is highly concentrated in one time (e.g., only at night).
    // High Entropy (near 1): Usage is spread evenly throughout the day (constant connected state).
    
    double entropySum = 0.0;
    for (var p in ratios) {
      if (p > 0) {
        entropySum -= p * (log(p) / log(2)); // log2(p)
      }
    }
    double normalizedEntropy = (entropySum / 2.0).clamp(0.0, 1.0);

    return TemporalMetrics(
      morningMinutes: mMinutes,
      afternoonMinutes: aMinutes,
      eveningMinutes: eMinutes,
      nightMinutes: nMinutes,
      morningRatio: mRatio,
      afternoonRatio: aRatio,
      eveningRatio: eRatio,
      nightRatio: nRatio,
      dominantWindowIndex: dominantIndex,
      peakWindowRatio: peakRatio,
      offPeakWindowRatio: minRatio,
      timeWindowEntropy: normalizedEntropy,
    );
  }

  /// Calculates intersection of session duration with a specific window.
  static double _getOverlapMinutes(AppSession session, DateTime windowStart, DateTime windowEnd) {
    if (session.endTime.isBefore(windowStart) || session.startTime.isAfter(windowEnd)) {
      return 0.0;
    }
    
    DateTime overlapStart = session.startTime.isAfter(windowStart) ? session.startTime : windowStart;
    DateTime overlapEnd = session.endTime.isBefore(windowEnd) ? session.endTime : windowEnd;
    
    if (overlapEnd.isBefore(overlapStart)) return 0.0;

    return overlapEnd.difference(overlapStart).inSeconds / 60.0;
  }

  static TemporalMetrics _emptyMetrics() {
    return TemporalMetrics(
      morningMinutes: 0, afternoonMinutes: 0, eveningMinutes: 0, nightMinutes: 0,
      morningRatio: 0, afternoonRatio: 0, eveningRatio: 0, nightRatio: 0,
      dominantWindowIndex: 0, peakWindowRatio: 0, offPeakWindowRatio: 0, timeWindowEntropy: 0,
    );
  }
}
