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

    // Parse apps into a temporary list for sorting
    List<_AppItem> parsedApps = appsList.map((item) {
      return _AppItem(
        packageName: item['package'] as String? ?? 'unknown',
        minutes: (item['minutes'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();

    // Calculate totals
    double totalMinutesDouble = 0.0;
    for (var app in parsedApps) {
      totalMinutesDouble += app.minutes;
    }
    int totalMinutes = totalMinutesDouble.round();

    // Sort descending by usage
    parsedApps.sort((a, b) => b.minutes.compareTo(a.minutes));

    // Extract Top 3 Apps
    List<String> topApps = [];
    List<int> topAppMinutes = [];
    
    // We take up to 3
    final int count = parsedApps.length < 3 ? parsedApps.length : 3;
    for (int i = 0; i < count; i++) {
      topApps.add(parsedApps[i].packageName);
      topAppMinutes.add(parsedApps[i].minutes.round());
    }

    // Pad with empty/zero if less than 3 (optional, but good for ML consistency)
    while (topApps.length < 3) {
      topApps.add('');
      topAppMinutes.add(0);
    }

    // Determine Dominant App
    String dominantApp = parsedApps.isNotEmpty ? parsedApps.first.packageName : 'None';

    // TODO: Current Native API does not provide time-of-day breakdown.
    // These fields are placeholders until we implement hourly querying in MainActivity.kt.
    int morningMinutes = 0;
    int afternoonMinutes = 0;
    int eveningMinutes = 0;
    int nightMinutes = 0;
    String dominantTimeWindow = 'Unknown';

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
