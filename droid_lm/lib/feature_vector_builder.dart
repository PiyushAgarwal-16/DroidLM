import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:droid_lm/daily_behavior_features.dart';
import 'package:droid_lm/temporal_windowing_strategy.dart';

/// Builds flattened feature vectors suitable for ML model input.
class FeatureVectorBuilder {
  final TemporalWindowStrategy _strategy;

  FeatureVectorBuilder({int windowSize = 3}) : _strategy = TemporalWindowStrategy(windowSize: windowSize);

  /// Converts a list of daily features into a dataset of flattened temporal vectors.
  ///
  /// **Process:**
  /// 1. Uses [TemporalWindowStrategy] to create sliding windows of $N$ days.
  /// 2. Flattens each window into a single 1D vector by concatenation.
  ///    $V_{window} = [V_{day1}, V_{day2}, ..., V_{dayN}]$
  ///
  /// **Why Flatten?**
  /// Basic Dense Neural Networks (MLP) require flat inputs.
  /// (Convolutional/Recursive models would keep the structure, but flat is safer for basic TFLite).
  List<List<double>> buildTemporalVectors(List<DailyBehaviorFeatures> chronologicalFeatures) {
    if (chronologicalFeatures.isEmpty) {
      if (kDebugMode) print("FeatureVectorBuilder: Input is empty.");
      return [];
    }

    // 1. Generate Windows
    List<List<DailyBehaviorFeatures>> windows = _strategy.generateWindows(chronologicalFeatures);
    
    if (windows.isEmpty) {
      if (kDebugMode) print("FeatureVectorBuilder: Not enough data for window size ${_strategy.windowSize}.");
      return [];
    }

    List<List<double>> flattenedDataset = [];

    // 2. Flatten Each Window
    for (int i = 0; i < windows.length; i++) {
        var window = windows[i];
        List<double> flattenedVector = [];
        
        for (var dayFeatures in window) {
           // Concatenate daily vector
           flattenedVector.addAll(dayFeatures.toList());
        }

        flattenedDataset.add(flattenedVector);
    }

    if (kDebugMode) {
      print("FeatureVectorBuilder: Generated ${flattenedDataset.length} sequence samples.");
      if (flattenedDataset.isNotEmpty) {
        print("FeatureVectorBuilder: Vector Dimension = ${flattenedDataset.first.length}");
      }
    }

    return flattenedDataset;
  }
}
