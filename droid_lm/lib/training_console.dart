import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:droid_lm/daily_usage_features.dart';
import 'package:droid_lm/main.dart'; // For UsageStatsService

class TrainingConsolePage extends StatefulWidget {
  final List<DailyUsageFeatures> trainingData;

  const TrainingConsolePage({super.key, required this.trainingData});

  @override
  State<TrainingConsolePage> createState() => _TrainingConsolePageState();
}

class _TrainingConsolePageState extends State<TrainingConsolePage> {
  String _logs = "Ready to train.";
  bool _isTraining = false;
  List<FlSpot> _lossPoints = [];
  final ScrollController _logScrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("On-Device Training"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Status Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      _isTraining ? Icons.sync : Icons.check_circle,
                      color: _isTraining ? Colors.orange : Colors.green,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isTraining ? "Training in progress..." : "Status: Idle",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text("${widget.trainingData.length} samples available"),
                      ],
                    ),
                    const Spacer(),
                    if (!_isTraining)
                      ElevatedButton(
                        onPressed: _startTraining,
                        child: const Text("Start"),
                      )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Chart Section
            const Text("Training Loss", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              height: 200,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _lossPoints.isEmpty
                  ? Center(child: Text("Waiting for data...", style: TextStyle(color: Colors.grey.shade500)))
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true, drawVerticalLine: true),
                        titlesData: const FlTitlesData(
                          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1, reservedSize: 22)),
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: true, border: Border.all(color: Colors.white12)),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _lossPoints,
                            isCurved: false,
                            color: Colors.tealAccent,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                          ),
                        ],
                      ),
                    ),
            ),

            const SizedBox(height: 20),

            // Logs Section
            const Text("Logs", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  controller: _logScrollController,
                  child: Text(
                    _logs,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.greenAccent,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startTraining() async {
    setState(() {
      _isTraining = true;
      _logs = "Initializing Training...\n";
      _lossPoints = [];
    });

    try {
      // 1. Prepare Data
      final features = widget.trainingData.map((d) => d.toMLVector()).toList();
      final labels = widget.trainingData.map((d) => d.computePseudoLabel()).toList();

      setState(() => _logs += "Sent ${features.length} samples to Android layer...\n");

      // 2. Call Native Layer
      // Note: Current native impl is blocking and returns full string at end.
      // Future improvement: EventChannel for streaming.
      final result = await UsageStatsService.trainHabitModel(features, labels);

      setState(() {
        _logs += "\n$result";
        _isTraining = false;
        
        // 3. Parse result to update chart
        _parseLogsForChart(result);
      });

    } catch (e) {
      setState(() {
        _logs += "\nError: $e";
        _isTraining = false;
      });
    }
  }

  void _parseLogsForChart(String result) {
    // Expected format: "Epoch X Loss: Y.YYYY" 
    final regex = RegExp(r"Epoch (\d+) Loss: ([\d\.]+)");
    final matches = regex.allMatches(result);
    
    final points = <FlSpot>[];
    
    for (final match in matches) {
      final epoch = double.parse(match.group(1)!);
      final loss = double.parse(match.group(2)!);
      points.add(FlSpot(epoch, loss));
    }
    
    setState(() {
      _lossPoints = points;
    });
  }
}
