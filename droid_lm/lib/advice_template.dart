import 'package:droid_lm/advice_category.dart';

/// Represents a template for generating personalized advice to the user.
///
/// This class holds the static structure of an advice piece, including its
/// category, title, and a body text with placeholders that are dynamically
/// replaced at runtime.
class AdviceTemplate {
  /// Unique identifier for this advice template.
  final String id;

  /// The category this advice helps with (e.g., habit, distraction).
  final AdviceCategory category;

  /// A short, punchy header for the advice card.
  final String title;

  /// The main content of the advice.
  ///
  /// May contain placeholders defined in [placeholders] like `"{app}"` or `"{timeWindow}"`.
  final String bodyTemplate;

  /// List of placeholder keys expected in [bodyTemplate].
  ///
  /// Example: `['app', 'minutes']` for a body like "You spent {minutes} on {app}."
  final List<String> placeholders;

  /// A base weight (0.0 - 1.0) indicating how "confident" or impactful
  /// this advice generally is.
  ///
  /// Higher weights make this advice more likely to be shown if the
  /// triggering conditions are met.
  final double confidenceWeight;

  const AdviceTemplate({
    required this.id,
    required this.category,
    required this.title,
    required this.bodyTemplate,
    this.placeholders = const [],
    this.confidenceWeight = 0.5,
  }) : assert(confidenceWeight >= 0.0 && confidenceWeight <= 1.0, 
             'Confidence weight must be between 0 and 1');

  /// Helper to format the body with actual values.
  String formatBody(Map<String, String> values) {
    String formatted = bodyTemplate;
    for (var key in placeholders) {
      if (values.containsKey(key)) {
        formatted = formatted.replaceAll('{$key}', values[key]!);
      }
    }
    return formatted;
  }
}
