import 'package:flutter/material.dart';

/// A compact card to display a preview of weekly insights.
class WeeklyInsightsCard extends StatelessWidget {
  final List<String> insightPreviews; // Max 2 recommended
  final String trend; // "Increasing", "Decreasing", "Flat"
  final VoidCallback onTap;

  const WeeklyInsightsCard({
    super.key,
    required this.insightPreviews,
    required this.trend,
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER ROW with Trend Icon
              Row(
                children: [
                   Container(
                     padding: const EdgeInsets.all(8),
                     decoration: BoxDecoration(
                       color: Colors.teal.shade50,
                       shape: BoxShape.circle,
                     ),
                     child: const Icon(Icons.lightbulb_outline, color: Colors.teal, size: 24),
                   ),
                   const SizedBox(width: 12),
                   const Expanded(
                     child: Text(
                       "Weekly Insights",
                       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                     ),
                   ),
                   _buildTrendIndicator(),
                ],
              ),
              const SizedBox(height: 16),
              
              // 2. INSIGHT PREVIEWS
              if (insightPreviews.isEmpty)
                const Text("No insights available yet.", style: TextStyle(color: Colors.grey))
              else
                ...insightPreviews.take(2).map((text) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 6.0),
                        child: Icon(Icons.circle, size: 6, color: Colors.grey),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          text,
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
                
               const SizedBox(height: 12),
               
               // 3. ACTION BUTTON (Text style)
               Align(
                 alignment: Alignment.centerRight,
                 child: TextButton(
                   onPressed: onTap, 
                   child: const Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       Text("View Weekly Report"),
                       SizedBox(width: 4),
                       Icon(Icons.arrow_forward_ios, size: 12),
                     ],
                   )
                 ),
               )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendIndicator() {
    IconData icon;
    Color color;
    
    switch (trend) {
      case "Increasing":
        icon = Icons.trending_up;
        color = Colors.amber; // Assuming "Habit" increasing is neutral/warning
        break;
      case "Decreasing":
        icon = Icons.trending_down;
        color = Colors.green; // Less habit = good?
        break;
      case "Flat":
        icon = Icons.trending_flat;
        color = Colors.grey;
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey.shade300;
    }

    return Tooltip(
      message: "Trend: $trend",
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 4),
            Text(trend, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12))
          ],
        ),
      ),
    );
  }
}
