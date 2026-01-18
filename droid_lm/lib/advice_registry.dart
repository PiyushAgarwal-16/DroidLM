import 'package:droid_lm/advice_category.dart';
import 'package:droid_lm/advice_template.dart';
import 'package:droid_lm/advice_narrative_builder.dart';

/// Registry of all available Advice Templates in the system.
///
/// This class acts as the central repository for static advice content.
/// It intentionally separates the *content* (what to say) from the *logic*
/// (when to say it).
///
/// Templates defined here are evaluated by the Advice Engine against current
/// user data to determine which ones are relevant at any given moment.
class AdviceRegistry {
  
  /// Returns a list of all defined advice templates.
  static List<AdviceTemplate> getAllTemplates() {
    return [
      // 1. Morning Ritual
      AdviceTemplate(
        id: 'habit_morning_ritual',
        category: AdviceCategory.habit,
        title: 'Morning Ritual Detected',
        bodyTemplate: AdviceNarrativeBuilder.build(
          insight: "You {qualifier} check {app} around {timeWindow} in the morning.",
          why: "Repetitive actions early in the day often set the tone for your productivity.",
          suggestion: "Is this how you intend to start your day?",
        ),
        placeholders: ['app', 'timeWindow', 'qualifier'],
        confidenceWeight: 0.8,
      ),

      // 2. Evening Pattern
      AdviceTemplate(
        id: 'habit_evening_pattern',
        category: AdviceCategory.habit,
        title: 'Evening Consistency',
        bodyTemplate: AdviceNarrativeBuilder.build(
          insight: "You {qualifier} use {app} during the evenings.",
          why: "Regular patterns can help you unwind, but screen usage before bed affects sleep quality.",
          suggestion: "Consider if this aligns with your wind-down goals.",
        ),
        placeholders: ['app', 'qualifier'],
        confidenceWeight: 0.7,
      ),

      // 3. Frequent Checks
      AdviceTemplate(
        id: 'habit_frequent_checks',
        category: AdviceCategory.habit,
        title: 'High Frequency Access',
        bodyTemplate: AdviceNarrativeBuilder.build(
          insight: "We noticed you opened {app} {count} times today.",
          why: "Frequent checking often happens automatically when we seek small dopamine hits.",
          suggestion: "Try pausing for a moment before the next launch.",
        ),
        placeholders: ['app', 'count'],
        confidenceWeight: 0.85,
      ),

      // 4. Stable Usage
      AdviceTemplate(
        id: 'habit_stable_usage',
        category: AdviceCategory.habit,
        title: 'Steady Baseline',
        bodyTemplate: AdviceNarrativeBuilder.build(
          insight: "Your time on {app} is consistent, averaging about {minutes} minutes daily.",
          why: "Consistency is key to forming habits, whether positive or negative.",
          suggestion: "Reflect on whether this habit serves your long-term goals.",
        ),
        placeholders: ['app', 'minutes'],
        confidenceWeight: 0.65,
      ),

      // --- DISTRACTION CATEGORY ---

      // 5. Focus Fragmentation
      AdviceTemplate(
        id: 'distraction_focus_fragmentation',
        category: AdviceCategory.distraction,
        title: 'Attention Switching',
        bodyTemplate: AdviceNarrativeBuilder.build(
          insight: "Rapidly switching between {app1} and {app2} can fragment your attention span.",
          why: "Constant context switching increases cognitive load and drains mental energy.",
          suggestion: "{suggestionPrefix} grouping your usage into dedicated blocks.",
        ),
        placeholders: ['app1', 'app2', 'suggestionPrefix'],
        confidenceWeight: 0.85,
      ),

      // 6. Dominant App Impact
      AdviceTemplate(
        id: 'distraction_dominant_app',
        category: AdviceCategory.distraction,
        title: 'High Concentration',
        bodyTemplate: AdviceNarrativeBuilder.build(
          insight: "{app} accounted for {percentage}% of your active screen time today.",
          why: "High concentration here might be displacing other intentions or rest.",
          suggestion: "{suggestionPrefix} reflecting if this aligns with your plans.",
        ),
        placeholders: ['app', 'percentage', 'suggestionPrefix'],
        confidenceWeight: 0.8,
      ),

      // 7. Deep Dive / Autopilot
      AdviceTemplate(
        id: 'distraction_deep_dive',
        category: AdviceCategory.distraction,
        title: 'Extended Session',
        bodyTemplate: AdviceNarrativeBuilder.build(
          insight: "You spent {minutes} minutes in {app} without a break.",
          why: "Long, continuous sessions can sometimes blur into 'autopilot' mode.",
          suggestion: "{suggestionPrefix} taking a short stretch break to reset.",
        ),
        placeholders: ['app', 'minutes', 'suggestionPrefix'],
        confidenceWeight: 0.75,
      ),

      // 8. Rapid Checking
      AdviceTemplate(
        id: 'distraction_rapid_checking',
        category: AdviceCategory.distraction,
        title: 'Micro-Interactions',
        bodyTemplate: AdviceNarrativeBuilder.build(
          insight: "We detected {count} short sessions in {app} recently.",
          why: "Frequent micro-interactions often happen subconsciously.",
          suggestion: "{suggestionPrefix} leaving the phone out of reach for 20 minutes.",
        ),
        placeholders: ['app', 'count', 'suggestionPrefix'],
        confidenceWeight: 0.9,
      ),

      // --- POSITIVE CATEGORY ---
      // Positive Feedback Psychology:
      // Acknowledging "good" behavior (stability, balance) is crucial for retention.
      // It validates the user's effort and prevents the app from feeling like a "nag".

      // 9. Balanced Usage
      AdviceTemplate(
        id: 'positive_balanced_diet',
        category: AdviceCategory.positive,
        title: 'Balanced Diet',
        bodyTemplate: AdviceNarrativeBuilder.build(
          insight: "Your digital usage today looks quite balanced, with no single app dominating your attention.",
          why: "A varied digital diet helps reduce cognitive fatigue.",
          suggestion: "Keep enjoying this variety.",
        ),
        placeholders: [],
        confidenceWeight: 0.7,
      ),

      // 10. Focus Flow
      AdviceTemplate(
        id: 'positive_focus_flow',
        category: AdviceCategory.positive,
        title: 'Good Focus Flow',
        bodyTemplate: AdviceNarrativeBuilder.build(
          insight: "You've maintained good focus intervals today without excessive context switching.",
          why: "Uninterrupted time allows for deeper thinking and better problem solving.",
          suggestion: "This is a great flow to maintain.",
        ),
        placeholders: [],
        confidenceWeight: 0.8,
      ),

      // 11. Intentional Checks
      AdviceTemplate(
        id: 'positive_intentional_checks',
        category: AdviceCategory.positive,
        title: 'Intentional Access',
        bodyTemplate: AdviceNarrativeBuilder.build(
          insight: "Your app launches have been purposeful today, avoiding the trap of rapid checking.",
          why: "Intentionality puts you back in control of your device.",
          suggestion: "Great job staying in charge.",
        ),
        placeholders: [],
        confidenceWeight: 0.65,
      ),
    ];
  }
}

