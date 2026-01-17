import 'package:flutter/material.dart';

/// A lightweight card to display high-level usage stats.
class AppUsageSummaryCard extends StatelessWidget {
  final String totalScreenTime; // e.g. "45h 12m"
  final String topAppName;
  final String peakWindow; // e.g. "Evening"
  final VoidCallback onTap;

  const AppUsageSummaryCard({
    super.key,
    required this.totalScreenTime,
    required this.topAppName,
    required this.peakWindow,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // 1. INTRO ROW
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.timelapse, color: Colors.blue.shade600, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Usage Snapshot",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. METRICS GRID
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   _buildMetric("Total Time", totalScreenTime, Icons.watch_later_outlined),
                   _buildMetric("Top App", topAppName, Icons.star_outline),
                   _buildMetric("Peak Time", peakWindow, Icons.wb_sunny_outlined),
                ],
              ),
              
              const SizedBox(height: 20),

              // 3. FOOTER ACTION
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade700,
                    side: BorderSide(color: Colors.blue.shade200),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("View Full App Usage"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade400),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
