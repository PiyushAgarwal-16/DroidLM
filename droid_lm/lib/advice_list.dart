import 'package:flutter/material.dart';
import 'package:droid_lm/advice_card.dart';
import 'package:droid_lm/generated_advice.dart';

/// A widget that renders a vertical list of [AdviceCard]s.
///
/// Layout Logic:
/// - Handles the empty state gracefully with a friendly message.
/// - Uses a [Column] instead of a ListView assuming this widget is likely
///   embedded within a larger scrollable screen (e.g., WeeklyInsightsScreen).
///   This prevents scroll conflics.
class AdviceList extends StatelessWidget {
  final List<GeneratedAdvice> advices;

  const AdviceList({
    Key? key,
    required this.advices,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (advices.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Section
        const Text(
          "Your Weekly Insights",
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          "Based on your recent usage patterns",
          style: TextStyle(
            fontSize: 14.0,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16.0), // Spacing before the cards
        
        // Render the list of cards
        ...advices.map((advice) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0), // Spacing between cards
          child: AdviceCard(advice: advice),
        )).toList(),
      ],
    );
  }

  Widget _buildEmptyState() {
    // Empty State Psychology:
    // Absence of advice shouldn't feel like a failure or "missing data".
    // Instead, it implies Stability and Balance. If the system has nothing
    // urgent to say, it means the user is doing well!
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline, // Positive confirmation
              size: 48,
              color: Colors.green.withOpacity(0.5), // Gentle gentle green
            ),
            const SizedBox(height: 16),
            Text(
              "Your usage looks balanced",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "No urgent insights this week. Keep it up!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
