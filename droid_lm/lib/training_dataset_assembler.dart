import 'package:flutter/foundation.dart';
import 'package:droid_lm/daily_behavior_features.dart';
import 'package:droid_lm/gap_aware_window_strategy.dart';
import 'package:droid_lm/target_extractor.dart';

/// Container for a complete, training-ready dataset.
class TrainingDataset {
  final List<List<double>> inputs; // Shape: [Samples, WindowSize * FeatureDim]
  final List<List<double>> targets; // Shape: [Samples, TargetDim]
  final int windowSize;
  final int featureDimension;
  final int sampleCount;

  TrainingDataset({
    required this.inputs,
    required this.targets,
    required this.windowSize,
    required this.featureDimension,
    required this.sampleCount,
  });

  @override
  String toString() {
    return 'Dataset(Samples: $sampleCount, Window: $windowSize, VectorDim: ${inputs.isNotEmpty ? inputs[0].length : 0})';
  }
}

/// Pipeline to create machine learning datasets from daily logs.
class TrainingDatasetAssembler {
  final int windowSize;
  final GapAwareWindowStrategy _windowStrategy;
  final TargetExtractor _targetExtractor;

  TrainingDatasetAssembler({this.windowSize = 3})
      : _windowStrategy = GapAwareWindowStrategy(windowSize: windowSize),
        _targetExtractor = TargetExtractor();

  /// Assemblies a training dataset from a raw map of daily features.
  /// 
  /// [featuresMap]: Keyed by date. Gaps in keys will be handled by splitting sequences.
  TrainingDataset assemble(Map<DateTime, DailyBehaviorFeatures> featuresMap) {
    if (kDebugMode) print("DatasetAssembler: Starting assembly from ${featuresMap.length} daily records.");

    // 1. Generate Contiguous Windows
    // Using GapAware strategy to ensure we don't train on missing days.
    List<List<DailyBehaviorFeatures>> rawWindows = _windowStrategy.generateContiguousWindows(featuresMap);
    
    if (rawWindows.isEmpty) {
      if (kDebugMode) print("DatasetAssembler: No valid contiguous windows found.");
      return _emptyDataset();
    }

    List<List<double>> inputVectors = [];
    List<List<double>> targetVectors = [];

    // 2. Process each window
    for (var window in rawWindows) {
        // A. Build Input Vector (Flattened)
        List<double> flattenedInput = [];
        for (var day in window) {
          flattenedInput.addAll(day.toList());
        }
        inputVectors.add(flattenedInput);

        // B. Build Target Vector (Aligned)
        List<double> target = _targetExtractor.extractTarget(window);
        targetVectors.add(target);
    }

    if (kDebugMode) {
      print("DatasetAssembler: --- DATASET SUMMARY ---");
      print("DatasetAssembler: Total Input Days: ${featuresMap.length}");
      print("DatasetAssembler: Window Size: $windowSize");
      print("DatasetAssembler: Generated Samples: ${inputVectors.length}");
      if (inputVectors.isNotEmpty) {
        print("DatasetAssembler: Input Vector Dim: ${inputVectors[0].length}");
        print("DatasetAssembler: Target Vector Dim: ${targetVectors[0].length}");
        print("DatasetAssembler: Example Target (First Sample): ${targetVectors[0]}");
      }
      print("DatasetAssembler: -------------------------");
    }
    
    // 3. Package
    return TrainingDataset(
      inputs: inputVectors,
      targets: targetVectors,
      windowSize: windowSize,
      featureDimension: 34, // Hardcoded for known DailyBehaviorFeatures size
      sampleCount: inputVectors.length,
    );
  }

  TrainingDataset _emptyDataset() {
    return TrainingDataset(
      inputs: [],
      targets: [],
      windowSize: windowSize,
      featureDimension: 34,
      sampleCount: 0,
    );
  }
}
