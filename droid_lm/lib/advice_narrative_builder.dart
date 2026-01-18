/// A utility to construct richer, narrative-style advice content.
///
/// checks the "What -> Why -> How" narrative structure:
/// 1. Insight (What happened?)
/// 2. Context/Why (Why does it matter?)
/// 3. Suggestion (How to improve?)
///
/// This builder ensures that these components flow together naturally into a single
/// readable block of text, rather than a disjointed list.
class AdviceNarrativeBuilder {
  
  /// Builds a cohesive narrative string from component parts.
  ///
  /// [insight]: The core observation (Required).
  /// [why]: The reason this observation is relevant (Optional).
  /// [suggestion]: A concrete step to take (Optional).
  static String build({
    required String insight,
    String? why,
    String? suggestion,
  }) {
    final buffer = StringBuffer();

    // 1. The Hook: What did we find?
    buffer.write(insight);

    // 2. The Context: Why is this important?
    if (why != null && why.isNotEmpty) {
      if (!insight.endsWith('.')) buffer.write('.'); // Ensure punctuation
      buffer.write(' ');
      buffer.write(why);
    }

    // 3. The Call to Action: What can I do?
    if (suggestion != null && suggestion.isNotEmpty) {
      // Ensure previous sentence ended properly
      String current = buffer.toString();
      if (!current.endsWith('.') && !current.endsWith('!')) {
         buffer.write('.');
      }
      buffer.write(' ');
      buffer.write(suggestion);
    }

    return buffer.toString().trim();
  }
}
