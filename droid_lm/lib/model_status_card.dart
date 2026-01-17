import 'package:flutter/material.dart';

enum ModelStatus { idle, training, trained }

/// A reusable card widget to display ML Model status and trigger training Actions.
class ModelStatusCard extends StatelessWidget {
  final ModelStatus status;
  final int sampleCount;
  final String? lastTrainingTime;
  final VoidCallback onActionPressed;

  const ModelStatusCard({
    super.key,
    required this.status,
    required this.sampleCount,
    this.lastTrainingTime,
    required this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool isTraining = status == ModelStatus.training;

    return Card(
      elevation: 6,
      shadowColor: Colors.deepPurple.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade800, Colors.deepPurple.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER: On-Device Label & Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.memory, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text("On-device ML", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(
                  status == ModelStatus.trained ? Icons.check_circle : Icons.analytics,
                  color: Colors.lightGreenAccent,
                  size: 28,
                ),
              ],
            ),
            
            const SizedBox(height: 24),

            // 2. MAIN STATUS TEXT
            Text(
              _getStatusTitle(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Ready to learn from your habits.",
              style: TextStyle(color: Colors.deepPurple.shade100, fontSize: 14),
            ),

            const SizedBox(height: 24),

            // 3. STATS ROW
            Row(
              children: [
                _buildStatItem(
                  "${sampleCount}d", 
                  "Samples Data"
                ),
                const SizedBox(width: 24),
                _buildStatItem(
                  lastTrainingTime ?? "Never", 
                  "Last Update"
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 4. ACTION BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: isTraining ? null : onActionPressed,
                icon: isTraining 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepPurple)) 
                    : Icon(_getActionIcon(), color: Colors.deepPurple.shade800),
                label: Text(
                  isTraining ? "Training in progress..." : _getActionLabel(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.deepPurple.shade800,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusTitle() {
    switch (status) {
      case ModelStatus.training: return "Training Model...";
      case ModelStatus.trained: return "Model Active";
      default: return "Model Idle";
    }
  }

  String _getActionLabel() {
    switch (status) {
      case ModelStatus.trained: return "Retrain Model";
      default: return "Train Model";
    }
  }

  IconData _getActionIcon() {
     switch (status) {
      case ModelStatus.trained: return Icons.refresh;
      default: return Icons.model_training;
    }
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.deepPurple.shade200,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
