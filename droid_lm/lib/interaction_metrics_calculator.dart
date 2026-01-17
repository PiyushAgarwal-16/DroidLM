import 'package:droid_lm/usage_metrics_calculator.dart'; // For AppSession

/// Output container for interaction features.
class InteractionMetrics {
  final int uniqueAppsCount;
  final double appDiversityRatio; // Unique Apps / Total Sessions
  final int appSwitchCount;
  final double appSwitchRate; // Switches per hour of usage
  final double reopenRate; // Ratio of re-opening same app < 1 min
  final double topAppReentryRate; // Ratio of returning to top app
  final double launcherUsageRatio; // Ratio of launcher usage (if detected)

  InteractionMetrics({
    required this.uniqueAppsCount,
    required this.appDiversityRatio,
    required this.appSwitchCount,
    required this.appSwitchRate,
    required this.reopenRate,
    required this.topAppReentryRate,
    required this.launcherUsageRatio,
  });

  @override
  String toString() {
    return 'InteractionMetrics(diversity: ${appDiversityRatio.toStringAsFixed(2)}, re-opens: ${(reopenRate * 100).toStringAsFixed(1)}%)';
  }
}

class InteractionMetricsCalculator {
  static const double REOPEN_THRESHOLD_SECONDS = 60.0;
  
  // Common launcher package substrings to attempt detection
  static const List<String> LAUNCHER_KEYWORDS = [
    'launcher', 'home', 'nexuslauncher', 'pixellauncher', 'trebuchet', 'quickstep'
  ];

  static InteractionMetrics compute(List<AppSession> sessions) {
    if (sessions.isEmpty) {
      return InteractionMetrics(
        uniqueAppsCount: 0,
        appDiversityRatio: 0.0,
        appSwitchCount: 0,
        appSwitchRate: 0.0,
        reopenRate: 0.0,
        topAppReentryRate: 0.0,
        launcherUsageRatio: 0.0,
      );
    }

    // 1. Sort Chronologically (Critical for interaction analysis)
    // We create a copy to avoid mutating original list order if it matters elsewhere
    List<AppSession> timeline = List.from(sessions);
    timeline.sort((a, b) => a.startTime.compareTo(b.startTime));

    // 2. Identify Top App (by Duration)
    Map<String, double> durations = {};
    for (var s in timeline) {
       durations[s.appName] = (durations[s.appName] ?? 0) + s.durationMinutes;
    }
    String topApp = "";
    double maxDur = -1;
    durations.forEach((app, dur) {
      if (dur > maxDur) {
        maxDur = dur;
        topApp = app;
      }
    });

    // 3. Analyze Sequence
    Set<String> uniqueApps = {};
    int totalSwitches = 0;
    int reopens = 0;
    int topAppReentries = 0;
    double launcherDuration = 0.0;
    double totalDuration = 0.0; // Minutes

    for (int i = 0; i < timeline.length; i++) {
      final current = timeline[i];
      uniqueApps.add(current.appName);
      totalDuration += current.durationMinutes;

      // Check Launcher
      if (_isLauncher(current.appName)) {
        launcherDuration += current.durationMinutes;
      }

      // Look back for switches/reopens
      if (i > 0) {
        final prev = timeline[i - 1];
        
        // App Switch?
        if (current.appName != prev.appName) {
          totalSwitches++;
          
          // Re-entry to Top App?
          if (current.appName == topApp) {
            topAppReentries++;
          }
        } else {
          // Same app sequence (could be split by screen off or just log artifacts)
          // Check gap
          double gapSeconds = current.startTime.difference(prev.endTime).inSeconds.toDouble();
          
          // If gap is significant but short, it's a "Re-open" behavior (closed and opened again quickly).
          // If gap is 0, it's just a log split.
          if (gapSeconds > 0 && gapSeconds < REOPEN_THRESHOLD_SECONDS) {
            reopens++;
          }
        }
      }
    }

    // 4. Compute Metrics
    int sessionCount = timeline.length;
    double diversityRatio = sessionCount > 0 ? uniqueApps.length / sessionCount : 0.0;
    
    // Switch Rate: Switches per Hour of Screen Time
    double totalHours = totalDuration / 60.0;
    double switchRate = totalHours > 0 ? totalSwitches / totalHours : 0.0;
    
    // Reopen Rate: Fraction of sessions that are quick reopens
    double reopenRatio = sessionCount > 1 ? reopens / (sessionCount - 1) : 0.0;
    
    // Top Reentry: Fraction of switches that go back to Top App
    double reentryRatio = totalSwitches > 0 ? topAppReentries / totalSwitches : 0.0;
    
    // Launcher Ratio
    double launcherRatio = totalDuration > 0 ? launcherDuration / totalDuration : 0.0;

    return InteractionMetrics(
      uniqueAppsCount: uniqueApps.length,
      appDiversityRatio: diversityRatio.clamp(0.0, 1.0),
      appSwitchCount: totalSwitches,
      appSwitchRate: switchRate,
      reopenRate: reopenRatio.clamp(0.0, 1.0),
      topAppReentryRate: reentryRatio.clamp(0.0, 1.0),
      launcherUsageRatio: launcherRatio.clamp(0.0, 1.0),
    );
  }

  static bool _isLauncher(String appName) {
    String lower = appName.toLowerCase();
    for (var key in LAUNCHER_KEYWORDS) {
      if (lower.contains(key)) return true;
    }
    return false;
  }
}
