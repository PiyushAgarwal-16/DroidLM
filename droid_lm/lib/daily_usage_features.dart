import 'package:flutter/foundation.dart';

/// Data model representing high-level usage features for a single day.
/// Optimized for consumption by ML models (e.g., standardizing types to int/double/String).
class DailyUsageFeatures {
  /// Date of the usage record (YYYY-MM-DD)
  final String date;

  /// Total usage time in minutes across all apps
  final int totalMinutes;

  /// List of package names for the top 3 most used apps
  final List<String> topApps;

  /// List of usage minutes corresponding to [topApps]
  final List<int> topAppMinutes;

  /// Usage minutes in the morning (6AM - 12PM)
  /// Note: Currently defaults to 0 as native API only provides daily totals.
  final int morningMinutes;

  /// Usage minutes in the afternoon (12PM - 6PM)
  /// Note: Currently defaults to 0 as native API only provides daily totals.
  final int afternoonMinutes;

  /// Usage minutes in the evening (6PM - 12AM)
  /// Note: Currently defaults to 0 as native API only provides daily totals.
  final int eveningMinutes;

  /// Usage minutes in the night (12AM - 6AM)
  /// Note: Currently defaults to 0 as native API only provides daily totals.
  final int nightMinutes;

  /// Total number of unique apps used that day (with >0 minutes)
  final int numberOfActiveApps;

  /// The single most used app package name
  final String dominantApp;

  /// The time window with the highest usage (Morning/Afternoon/Evening/Night)
  final String dominantTimeWindow;

  DailyUsageFeatures({
    required this.date,
    required this.totalMinutes,
    required this.topApps,
    required this.topAppMinutes,
    this.morningMinutes = 0,
    this.afternoonMinutes = 0,
    this.eveningMinutes = 0,
    this.nightMinutes = 0,
    this.numberOfActiveApps = 0,
    required this.dominantApp,
    this.dominantTimeWindow = 'Unknown',
  });

  /// Factory constructor to create features from raw JSON returned by [DailyUsageInfo].
  ///
  /// Expected [json] format:
  /// ```json
  /// {
  ///   "date": "YYYY-MM-DD",
  ///   "apps": [
  ///     {"package": "com.example", "minutes": 120.0},
  ///     ...
  ///   ]
  /// }
  /// ```
  factory DailyUsageFeatures.fromRawUsageJson(Map<String, dynamic> json) {
    final String date = json['date'] as String? ?? 'Unknown Date';
    final List<dynamic> appsList = json['apps'] as List<dynamic>? ?? [];

    // 1. Parse apps and calculate Total Screen Time
    List<_AppItem> parsedApps = appsList.map((item) {
      return _AppItem(
        packageName: item['package'] as String? ?? 'unknown',
        minutes: (item['minutes'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();

    double totalMinutesDouble = 0.0;
    for (var app in parsedApps) {
      totalMinutesDouble += app.minutes;
    }
    int totalMinutes = totalMinutesDouble.round();
    
    // Count active apps (minutes > 0)
    int numberOfActiveApps = parsedApps.where((a) => a.minutes > 0).length;

    // 2. Top 3 Apps by Minutes
    // Sort descending by usage
    parsedApps.sort((a, b) => b.minutes.compareTo(a.minutes));

    List<String> topApps = [];
    List<int> topAppMinutes = [];
    
    // Extract up to 3
    final int count = parsedApps.length < 3 ? parsedApps.length : 3;
    for (int i = 0; i < count; i++) {
      topApps.add(parsedApps[i].packageName);
      topAppMinutes.add(parsedApps[i].minutes.round());
    }

    // Pad with placeholders if less than 3 to maintain fixed feature vector size for ML
    while (topApps.length < 3) {
      topApps.add('None');
      topAppMinutes.add(0);
    }

    // 3. Assign Usage to Time Windows
    // Assumption: Because the input data is a daily aggregate without hourly timestamps,
    // we approximate the distribution by splitting the Total Minutes evenly across the 4 windows.
    // In a real hourly-data scenario, we would sum specific buckets.
    //
    // Windows:
    // - Night (00:00 - 06:00)
    // - Morning (06:00 - 12:00)
    // - Afternoon (12:00 - 18:00)
    // - Evening (18:00 - 24:00)
    
    int approxWindowUsage = totalMinutes ~/ 4; // Integer division
    int remainder = totalMinutes % 4;

    int nightMinutes = approxWindowUsage;
    int morningMinutes = approxWindowUsage;
    int afternoonMinutes = approxWindowUsage;
    int eveningMinutes = approxWindowUsage;

    // Distribute remainder minutes sequentially (arbitrary decision to ensure sum equals total)
    if (remainder > 0) eveningMinutes++;
    if (remainder > 1) afternoonMinutes++;
    if (remainder > 2) morningMinutes++;

    // 4. Dominant Factors
    String dominantApp = parsedApps.isNotEmpty ? parsedApps.first.packageName : 'None';
    
    // Since we approximated evenly, this is somewhat artificial, but we implement the logic:
    // Compare the 4 windows to find the largest.
    Map<String, int> windows = {
      'Night': nightMinutes,
      'Morning': morningMinutes,
      'Afternoon': afternoonMinutes,
      'Evening': eveningMinutes,
    };
    
    // Simple sort to find max
    var sortedWindows = windows.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    String dominantTimeWindow = sortedWindows.first.key;
    // If usage is 0, set to None
    if (totalMinutes == 0) {
      dominantTimeWindow = 'None';
    } else if (nightMinutes == morningMinutes && morningMinutes == afternoonMinutes) {
       // If perfectly even (and not 0), we might label it 'Balanced' or just keep the first one (Night).
       // We'll leave it as the sort result (which is stable) or 'Balanced' if desired, 
       // but typically ML prefers categorical consistency.
       dominantTimeWindow = 'Balanced';
    }

    return DailyUsageFeatures(
      date: date,
      totalMinutes: totalMinutes,
      topApps: topApps,
      topAppMinutes: topAppMinutes,
      morningMinutes: morningMinutes,
      afternoonMinutes: afternoonMinutes,
      eveningMinutes: eveningMinutes,
      nightMinutes: nightMinutes,
      numberOfActiveApps: numberOfActiveApps,
      dominantApp: dominantApp,
      dominantTimeWindow: dominantTimeWindow,
    );
  }

  /// Converts the features to a Map, suitable for ML model input or JSON serialization.
  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'totalMinutes': totalMinutes,
      'topApps': topApps,
      'topAppMinutes': topAppMinutes,
      'morningMinutes': morningMinutes,
      'afternoonMinutes': afternoonMinutes,
      'eveningMinutes': eveningMinutes,
      'nightMinutes': nightMinutes,
      'numberOfActiveApps': numberOfActiveApps,
      'dominantApp': dominantApp,
      'dominantTimeWindow': dominantTimeWindow,
    };
  }

  /// Converts the features into a numeric List<double> vector for ML model input.
  /// 
  /// Normalized Feature Vector Definition:
  /// 1. [0] Total Minutes (0.0 - 1.0) -> Normalized assuming max 600 mins.
  /// 2. [1] Morning Minutes Ratio (0.0 - 1.0) -> morningMinutes / totalMinutes
  /// 3. [2] Afternoon Minutes Ratio (0.0 - 1.0) -> afternoonMinutes / totalMinutes
  /// 4. [3] Evening Minutes Ratio (0.0 - 1.0) -> eveningMinutes / totalMinutes
  /// 5. [4] Night Minutes Ratio (0.0 - 1.0) -> nightMinutes / totalMinutes
  /// 6. [5] Top App 1 Ratio (0.0 - 1.0) -> topApp1Minutes / totalMinutes
  /// 7. [6] Top App 2 Ratio (0.0 - 1.0) -> topApp2Minutes / totalMinutes
  /// 8. [7] Top App 3 Ratio (0.0 - 1.0) -> topApp3Minutes / totalMinutes
  /// 9. [8] Active Apps Count (0.0 - 1.0) -> Normalized assuming max 20 apps.
  /// 10. [9] Usage Concentration (0.0 - 1.0) -> topApp1Minutes / totalMinutes (Same as #6, but explicitly requested)
  List<double> toMLVector() {
    // Avoid division by zero
    double safeTotal = totalMinutes > 0 ? totalMinutes.toDouble() : 1.0; 

    // 1. Total Minutes normalized (Max 600)
    double normTotal = (totalMinutes / 600.0).clamp(0.0, 1.0);

    // 2-5. Time Window Ratios
    double morningRatio = morningMinutes / safeTotal;
    double afternoonRatio = afternoonMinutes / safeTotal;
    double eveningRatio = eveningMinutes / safeTotal;
    double nightRatio = nightMinutes / safeTotal;

    // 6-8. Top Apps Ratios
    double top1Ratio = topAppMinutes.isNotEmpty ? topAppMinutes[0] / safeTotal : 0.0;
    double top2Ratio = topAppMinutes.length > 1 ? topAppMinutes[1] / safeTotal : 0.0;
    double top3Ratio = topAppMinutes.length > 2 ? topAppMinutes[2] / safeTotal : 0.0;

    // 9. Number of Active Apps normalized (Max 20)
    double normActiveApps = (numberOfActiveApps / 20.0).clamp(0.0, 1.0);

    // 10. Usage Concentration (Top 1 Ratio)
    double usageConcentration = top1Ratio;

    // Base 10 Features
    List<double> baseFeatures = [
      normTotal,
      morningRatio.clamp(0.0, 1.0),
      afternoonRatio.clamp(0.0, 1.0),
      eveningRatio.clamp(0.0, 1.0),
      nightRatio.clamp(0.0, 1.0),
      top1Ratio.clamp(0.0, 1.0),
      top2Ratio.clamp(0.0, 1.0),
      top3Ratio.clamp(0.0, 1.0),
      normActiveApps,
      usageConcentration.clamp(0.0, 1.0),
    ];

    // PAD TO 34 FEATURES
    // The ML model expects 34 features per day (to support future expansion).
    // Currently, we only have 10 defined. We pad the remaining 24 with zeros.
    int paddingSize = 34 - baseFeatures.length;
    List<double> padding = List.filled(paddingSize, 0.0);

    return [...baseFeatures, ...padding];
  }
  /// Computes a pseudo-label (0.0 - 1.0) for self-supervised training.
  /// 
  /// Formula: label = 0.6 * usageConcentration + 0.4 * topApp1Ratio
  /// 
  /// SELF-SUPERVISION EXPLANATION:
  /// We assume that high "Habituality" correlates strongly with "Usage Concentration".
  /// If a user spends most of their time in just 1 app (high concentration), 
  /// it is likely a habitual behavior rather than a diverse/exploratory session.
  /// By generating this target automatically, we can pre-train the model without
  /// asking the user to manually tag every day.
  double computePseudoLabel() {
    if (totalMinutes == 0) return 0.0;
    
    // Safety check for empty lists
    if (topAppMinutes.isEmpty) return 0.0;

    double safeTotal = totalMinutes.toDouble();
    
    // Ratio of time spent in the #1 most used app
    double topApp1Ratio = topAppMinutes[0] / safeTotal;
    
    // Usage Concentration implies how "focused" the usage is.
    // simpler definition for now: same as topApp1Ratio.
    double usageConcentration = topApp1Ratio;

    // Combined metric
    double label = (0.6 * usageConcentration) + (0.4 * topApp1Ratio);
    
    return label.clamp(0.0, 1.0);
  }

  /// Computes a heuristic Distraction Score (0.0 - 1.0) for the second target.
  /// 
  /// Logic: High distraction is correlated with high number of active apps (switching)
  /// and high morning usage (often non-productive scrolling).
  double computeDistractionScore() {
    double safeTotal = totalMinutes > 0 ? totalMinutes.toDouble() : 1.0;
    
    // Normalized Active Apps (Max 20)
    double normActiveApps = (numberOfActiveApps / 20.0).clamp(0.0, 1.0);
    
    // Morning Ratio
    double morningRatio = morningMinutes / safeTotal;
    
    // Heuristic Formula
    double score = (normActiveApps * 0.5) + (morningRatio * 0.3);
    
    return score.clamp(0.0, 1.0);
  }
}

/// Helper class for internal sorting
class _AppItem {
  final String packageName;
  final double minutes;

  _AppItem({required this.packageName, required this.minutes});
}
