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

  /// The single most used app package name
  final String dominantApp;

  /// The time window with the highest usage (Morning/Afternoon/Evening/Night)
  /// Note: Currently defaults to "Unknown" due to lack of hourly data.
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
      'dominantApp': dominantApp,
      'dominantTimeWindow': dominantTimeWindow,
    };
  }
}

/// Helper class for internal sorting
class _AppItem {
  final String packageName;
  final double minutes;

  _AppItem({required this.packageName, required this.minutes});
}
