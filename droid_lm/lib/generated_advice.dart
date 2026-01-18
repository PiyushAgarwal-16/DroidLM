import 'package:droid_lm/advice_category.dart';

/// Represents a fully resolved piece of advice shown to the user.
///
/// Unlike [AdviceTemplate], this class contains the final, formatted text
/// ready for display, along with metadata about when and why it was generated.
class GeneratedAdvice {
  /// The main headline of the advice card.
  final String title;

  /// The detailed body text, with all placeholders replaced by actual data.
  final String body;

  /// The category this advice belongs to (e.g., habit, distraction).
  /// Used for UI styling such as icons and colors.
  final AdviceCategory category;

  /// The timestamp when this advice was generated.
  /// Useful for showing "Fresh" advice vs. older insights.
  final DateTime generatedAt;

  /// A score (0.0 - 1.0) representing the strength of the signal that
  /// triggered this advice.
  ///
  /// Higher scores indicate stronger evidence or higher relevance.
  final double confidenceScore;

  const GeneratedAdvice({
    required this.title,
    required this.body,
    required this.category,
    required this.generatedAt,
    required this.confidenceScore,
  });

  /// Helper to convert to Map for storage or debugging.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'category': category.index, // Store as int index
      'generatedAt': generatedAt.toIso8601String(),
      'confidenceScore': confidenceScore,
    };
  }

  /// Helper to load from Map (e.g., from local storage).
  factory GeneratedAdvice.fromMap(Map<String, dynamic> map) {
    return GeneratedAdvice(
      title: map['title'] as String,
      body: map['body'] as String,
      category: AdviceCategory.values[map['category'] as int],
      generatedAt: DateTime.parse(map['generatedAt'] as String),
      confidenceScore: (map['confidenceScore'] as num).toDouble(),
    );
  }
}
