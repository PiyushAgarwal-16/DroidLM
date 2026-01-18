import 'package:droid_lm/advice_category.dart';
import 'package:droid_lm/advice_template.dart';

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
      const AdviceTemplate(
        id: 'habit_morning_ritual',
        category: AdviceCategory.habit,
        title: 'Morning Ritual Detected',
        bodyTemplate: "It looks like checking {app} is part of your morning flow around {timeWindow}. Is this intentional?",
        placeholders: ['app', 'timeWindow'],
        confidenceWeight: 0.8,
      ),

      // 2. Evening Pattern
      const AdviceTemplate(
        id: 'habit_evening_pattern',
        category: AdviceCategory.habit,
        title: 'Evening Consistency',
        bodyTemplate: "You tend to use {app} quite regularly during the evenings. Regular patterns can often build strong habits.",
        placeholders: ['app'],
        confidenceWeight: 0.7,
      ),

      // 3. Frequent Checks
      const AdviceTemplate(
        id: 'habit_frequent_checks',
        category: AdviceCategory.habit,
        title: 'High Frequency Access',
        bodyTemplate: "We noticed you opened {app} {count} times today. Frequent checking can sometimes become automatic.",
        placeholders: ['app', 'count'],
        confidenceWeight: 0.85,
      ),

      // 4. Stable Usage
      const AdviceTemplate(
        id: 'habit_stable_usage',
        category: AdviceCategory.habit,
        title: 'Steady Baseline',
        bodyTemplate: "Your time spent on {app} is remarkably consistent, averaging about {minutes} minutes daily. This suggests a well-formed habit.",
        placeholders: ['app', 'minutes'],
        confidenceWeight: 0.65,
      ),

      // --- DISTRACTION CATEGORY ---

      // 5. Focus Fragmentation
      const AdviceTemplate(
        id: 'distraction_focus_fragmentation',
        category: AdviceCategory.distraction,
        title: 'Attention Switching',
        bodyTemplate: "Rapidly switching between {app1} and {app2} can fragment your attention span, making it harder to return to deep focus.",
        placeholders: ['app1', 'app2'],
        confidenceWeight: 0.85,
      ),

      // 6. Dominant App Impact
      const AdviceTemplate(
        id: 'distraction_dominant_app',
        category: AdviceCategory.distraction,
        title: 'High Concentration',
        bodyTemplate: "{app} accounted for {percentage}% of your active screen time today. Such high concentration might be displacing other intentions.",
        placeholders: ['app', 'percentage'],
        confidenceWeight: 0.8,
      ),

      // 7. Deep Dive / Autopilot
      const AdviceTemplate(
        id: 'distraction_deep_dive',
        category: AdviceCategory.distraction,
        title: 'Extended Session',
        bodyTemplate: "You spent {minutes} minutes in {app} without a break. Long, uninterrupted sessions can sometimes blur into autopilot mode.",
        placeholders: ['app', 'minutes'],
        confidenceWeight: 0.75,
      ),

      // 8. Rapid Checking
      const AdviceTemplate(
        id: 'distraction_rapid_checking',
        category: AdviceCategory.distraction,
        title: 'Micro-Interactions',
        bodyTemplate: "We detected {count} short sessions in {app} recently. Frequent micro-interactions can inadvertently increase cognitive load.",
        placeholders: ['app', 'count'],
        confidenceWeight: 0.9,
      ),

      // --- POSITIVE CATEGORY ---

      // 9. Balanced Usage
      const AdviceTemplate(
        id: 'positive_balanced_diet',
        category: AdviceCategory.positive,
        title: 'Balanced Diet',
        bodyTemplate: "Your digital usage today looks quite balanced, with no single app dominating your attention.",
        placeholders: [],
        confidenceWeight: 0.7,
      ),

      // 10. Focus Flow
      const AdviceTemplate(
        id: 'positive_focus_flow',
        category: AdviceCategory.positive,
        title: 'Good Focus Flow',
        bodyTemplate: "You've maintained good focus intervals today without excessive context switching.",
        placeholders: [],
        confidenceWeight: 0.8,
      ),

      // 11. Intentional Checks
      const AdviceTemplate(
        id: 'positive_intentional_checks',
        category: AdviceCategory.positive,
        title: 'Intentional Access',
        bodyTemplate: "Your app launches have been purposeful today, avoiding the trap of rapid checking.",
        placeholders: [],
        confidenceWeight: 0.65,
      ),
    ];
  }
}

