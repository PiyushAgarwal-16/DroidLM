/// A utility to adjust advice wording based on confidence levels.
///
/// Trust Psychology:
/// Using "soft qualifiers" (like "often" instead of "always", or "occasionally")
/// is crucial when the system isn't 100% sure.
///
/// If the AI says "You ALWAYS do X" and the user remembers one counter-example,
/// trust is broken.
/// If the AI says "You OFTEN do X", the user is much more likely to agree,
/// even if there are exceptions. This builds credibility.
class AdviceWordingHelper {
  
  /// Returns a frequency qualifier string based on the [confidence] score.
  ///
  /// [confidence] should be between 0.0 and 1.0.
  static String confidenceQualifier(double confidence) {
    if (confidence < 0.5) {
      return "occasionally";
    } else if (confidence < 0.75) {
      return "often";
    } else {
      return "consistently";
    }
  }

  /// Returns a gentle prefix for the suggestion/action part of the advice.
  ///
  /// Progressive Guidance:
  /// - Low Confidence: Very tentative ("you might consider").
  /// - Medium Confidence: Helpful but soft ("it could help to try").
  /// - High Confidence: Specific but humble ("a small change that may help is").
  ///
  /// This prevents the AI from sounding bossy, especially when it might be wrong.
  static String suggestionPrefix(double confidence) {
    if (confidence < 0.5) {
      return "you might consider";
    } else if (confidence < 0.75) {
      return "it could help to try";
    } else {
      return "a small change that may help is";
    }
  }
}
