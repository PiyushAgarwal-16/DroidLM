import 'package:flutter/material.dart';
import 'package:droid_lm/advice_category.dart';

/// Defines the visual styling for advice cards based on their category.
///
/// The design philosophy is "Supportive, Not Judgmental".
/// - We avoid aggressive reds or warning signs even for distraction.
/// - We use calm, cool tones for habits and insights.
/// - We use warm, gentle tones for potential issues.
class AdviceVisualStyle {
  final Color backgroundColor;
  final Color accentColor;
  final IconData icon;

  const AdviceVisualStyle({
    required this.backgroundColor,
    required this.accentColor,
    required this.icon,
  });

  /// Returns the appropriate visual style for a given advice category.
  static AdviceVisualStyle forCategory(AdviceCategory category) {
    switch (category) {
      case AdviceCategory.habit:
        // Calm Teal/Blue: Represents stability, routine, and insight.
        // Used for observational patterns ("Morning routine detected").
        return const AdviceVisualStyle(
          backgroundColor: Color(0xFFE0F2F1), // Teal 50
          accentColor: Color(0xFF009688),     // Teal 500
          icon: Icons.lightbulb_outline,
        );

      case AdviceCategory.distraction:
        // Soft Amber: Represents caution or awareness, but not "Danger".
        // Used to gently nudge the user about high usage without shaming.
        // We explicitly avoid Red to prevent anxiety or defensive reactions.
        return const AdviceVisualStyle(
          backgroundColor: Color(0xFFFFF8E1), // Amber 50
          accentColor: Color(0xFFFFC107),     // Amber 500
          icon: Icons.notifications_paused_outlined,
        );

      case AdviceCategory.positive:
        // Gentle Green: Represents success, balance, and health.
        // Used for positive reinforcement ("Balanced diet", "Good focus").
        return const AdviceVisualStyle(
          backgroundColor: Color(0xFFE8F5E9), // Green 50
          accentColor: Color(0xFF4CAF50),     // Green 500
          icon: Icons.check_circle_outline, // Or sentiment_satisfied
        );

      case AdviceCategory.timePattern:
        // Indigo/Purple: Represents time, cycles, and deep/late hours.
        // Used for time-based insights ("Late night scrolling").
        return const AdviceVisualStyle(
          backgroundColor: Color(0xFFE8EAF6), // Indigo 50
          accentColor: Color(0xFF3F51B5),     // Indigo 500
          icon: Icons.access_time,
        );

      case AdviceCategory.trend:
        // Blue Grey: Represents neutrality, data, and long-term analysis.
        // Used for trend reports ("Usage increasing").
        return const AdviceVisualStyle(
          backgroundColor: Color(0xFFECEFF1), // Blue Grey 50
          accentColor: Color(0xFF607D8B),     // Blue Grey 500
          icon: Icons.trending_up,
        );

      case AdviceCategory.action:
        // Deep Orange/Accent: Represents energy and call to action.
        // Used for specific suggestions ("Try enabling focus mode").
        return const AdviceVisualStyle(
          backgroundColor: Color(0xFFFBE9E7), // Deep Orange 50
          accentColor: Color(0xFFFF5722),     // Deep Orange 500
          icon: Icons.bolt, // Energy/Action
        );
    }
  }
}
