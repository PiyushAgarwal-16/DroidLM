import 'package:flutter/material.dart';
import 'package:droid_lm/advice_visual_style.dart';
import 'package:droid_lm/generated_advice.dart';
import 'package:droid_lm/advice_category.dart';

/// A card widget to display personalized advice with a supportive visual design.
///
/// Design Goals:
/// - Friendly and non-intrusive: Uses soft background colors and rounded corners.
/// - Scannable: Icon and Title give immediate context (Category/Topic).
/// - Actionable: Clear body text without overwhelming details.
class AdviceCard extends StatelessWidget {
  final GeneratedAdvice advice;

  const AdviceCard({
    Key? key,
    required this.advice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Retrieve the specific visual theme for this advice category.
    // This allows us to keep the UI logic clean and consistent.
    final style = AdviceVisualStyle.forCategory(advice.category);

    // Confidence Logic:
    // We use the confidence score (0.0 - 1.0) to subtly adjust visual weight.
    // Higher confidence = slightly thicker border & specific opacity adjustments.
    // This provides a subconscious signal of importance without using loud badges.
    final double confidence = advice.confidenceScore.clamp(0.0, 1.0);
    final double borderWidth = 1.0 + (confidence * 1.5); // Range: 1.0 to 2.5
    final double iconOpacity = 0.5 + (confidence * 0.4); // Range: 0.5 to 0.9

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      // We use a Container with decoration instead of a standard Card to have
      // finer control over the border and shadow transparency, creating a "softer" feel.
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(16.0), // Generous rounding for friendliness
        border: Border.all(
          // Border opacity also scales slightly with confidence
          color: style.accentColor.withOpacity(0.3 + (confidence * 0.2)),
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), // Very soft shadow
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Icon + Title
            Row(
              children: [
                // Icon container
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(iconOpacity),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    style.icon,
                    color: style.accentColor,
                    size: 24.0,
                  ),
                ),
                const SizedBox(width: 12.0),
                // Title Text
                Expanded(
                  child: Text(
                    advice.title,
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600, // Semi-bold for hierarchy
                      color: Colors.black87, // High contrast for readability
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            // Body Text
            Text(
              advice.body,
              style: const TextStyle(
                fontSize: 14.0,
                height: 1.5, // Improved line height for readability
                color: Colors.black87,
                fontWeight: FontWeight.normal,
              ),
            ),
            // Optional Action Hint
            // Only displayed for 'Action' category to subtly encourage behavior change.
            if (advice.category == AdviceCategory.action) ...[
              const SizedBox(height: 12.0),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "Suggested Action", // Simple, non-commanding hint
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    color: style.accentColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
