import 'dart:math';

/// Represents a single continuous usage session of an app.
class AppSession {
  final String appName;
  final DateTime startTime;
  final DateTime endTime;

  AppSession({
    required this.appName,
    required this.startTime,
    required this.endTime,
  });

  double get durationMinutes {
    return endTime.difference(startTime).inSeconds / 60.0;
  }
}

/// Output container for volume and intensity features.
class UsageVolumeMetrics {
  final double totalScreenTimeMinutes;
  final int numberOfSessions;
  final double averageSessionLength;
  final double maxSessionLength;
  final double topAppMinutes;
  final double secondTopAppMinutes;
  final double topAppUsageRatio;
  final double usageConcentrationIndex; // HHI (Herfindahl-Hirschman Index)

  UsageVolumeMetrics({
    required this.totalScreenTimeMinutes,
    required this.numberOfSessions,
    required this.averageSessionLength,
    required this.maxSessionLength,
    required this.topAppMinutes,
    required this.secondTopAppMinutes,
    required this.topAppUsageRatio,
    required this.usageConcentrationIndex,
  });

  @override
  String toString() {
    return 'VolumeMetrics(total: ${totalScreenTimeMinutes.toStringAsFixed(1)}m, sessions: $numberOfSessions, top: ${topAppMinutes.toStringAsFixed(1)}m)';
  }
}

/// Helper to compute usage metrics from raw session logs.
class UsageMetricsCalculator {
  
  /// Computes volume and intensity metrics.
  /// Returns a [UsageVolumeMetrics] object with all fields calculated.
  static UsageVolumeMetrics compute(List<AppSession> sessions) {
    if (sessions.isEmpty) {
      return UsageVolumeMetrics(
        totalScreenTimeMinutes: 0.0,
        numberOfSessions: 0,
        averageSessionLength: 0.0,
        maxSessionLength: 0.0,
        topAppMinutes: 0.0,
        secondTopAppMinutes: 0.0,
        topAppUsageRatio: 0.0,
        usageConcentrationIndex: 0.0,
      );
    }

    // 1. Basic Volume
    double totalTime = 0.0;
    double maxSession = 0.0;
    
    // Aggregation map
    Map<String, double> appDurations = {};

    for (var session in sessions) {
      double duration = session.durationMinutes;
      if (duration < 0) duration = 0; // Guard against bad data
      
      totalTime += duration;
      if (duration > maxSession) {
        maxSession = duration;
      }

      appDurations[session.appName] = (appDurations[session.appName] ?? 0.0) + duration;
    }

    // 2. Averages
    double avgSession = totalTime / sessions.length;

    // 3. Top Apps & Concentration
    // Sort apps by duration descending
    var sortedApps = appDurations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    double topMinutes = 0.0;
    double secondMinutes = 0.0;
    
    if (sortedApps.isNotEmpty) {
      topMinutes = sortedApps[0].value;
    }
    if (sortedApps.length > 1) {
      secondMinutes = sortedApps[1].value;
    }

    // Guard against DivideByZero
    double topRatio = totalTime > 0 ? (topMinutes / totalTime) : 0.0;

    // 4. Usage Concentration Index (HHI)
    // Sum of squares of shares. Range 0.0 to 1.0 (1.0 = single app used entire time)
    double hhiSum = 0.0;
    if (totalTime > 0) {
      for (var entry in sortedApps) {
        double share = entry.value / totalTime;
        hhiSum += (share * share);
      }
    }

    return UsageVolumeMetrics(
      totalScreenTimeMinutes: totalTime,
      numberOfSessions: sessions.length,
      averageSessionLength: avgSession,
      maxSessionLength: maxSession,
      topAppMinutes: topMinutes,
      secondTopAppMinutes: secondMinutes,
      topAppUsageRatio: topRatio,
      usageConcentrationIndex: hhiSum,
    );
  }
}
