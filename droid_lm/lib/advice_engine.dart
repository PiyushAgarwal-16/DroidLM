import 'dart:math';

import 'package:droid_lm/advice_category.dart';
import 'package:droid_lm/advice_registry.dart';
import 'package:droid_lm/advice_template.dart';
import 'package:droid_lm/advice_trigger_context.dart';
import 'package:droid_lm/advice_trigger_rule.dart';
import 'package:droid_lm/generated_advice.dart';
import 'package:droid_lm/advice_wording_helper.dart';

/// The core engine responsible for evaluating user behavior and selecting
/// appropriate advice.
///
/// This class acts as the orchestrator:
/// 1. Accepts the current [AdviceTriggerContext] (behavioral metrics).
/// 2. Iterates through a set of [AdviceTriggerRule]s logic.
/// 3. Selects relevant [AdviceTemplate]s from the [AdviceRegistry].
/// 4. Resolves placeholders and returns a list of [GeneratedAdvice].
class AdviceEngine {
  final List<AdviceTriggerRule> rules;

  AdviceEngine({required this.rules});

  /// Evaluates the current context against all rules and returns a list
  /// of prioritized advice.
  ///
  /// Constraints:
  /// - Returns at most 3 advice items.
  /// - Returns at most 1 item per [AdviceCategory].
  /// - Prioritizes rules with higher confidence scores.
  /// Evaluates the current context against all rules and returns a list
  /// of prioritized advice.
  ///
  /// Constraints:
  /// - Returns at most 3 advice items.
  /// - Returns at most 1 item per [AdviceCategory].
  /// - Prioritizes rules with higher confidence scores.
  List<GeneratedAdvice> evaluate(AdviceTriggerContext context) {
    print("AdviceEngine: Evaluating rules for context...");
    List<GeneratedAdvice> candidates = [];
    Set<AdviceCategory> usedCategories = {};

    // 1. Evaluate all rules
    // We first collect all matching rules and their confidence scores.
    List<_RuleMatch> matches = [];
    for (var rule in rules) {
      if (rule.matches(context)) {
        double score = rule.confidenceScore(context);
        print("AdviceEngine: Rule matched: ${rule.category} with score: $score");
        matches.add(_RuleMatch(rule, score));
      }
    }

    // 2. Sort by confidence (descending)
    matches.sort((a, b) => b.score.compareTo(a.score));

    // 3. Generate Advice for top matches
    for (var match in matches) {
      if (candidates.length >= 3) break;
      
      // Category Limiting:
      // We ensure that only ONE advice piece is generated per category.
      // Since 'matches' is sorted by confidence score (descending), the first
      // time we encounter a category, it represents the strongest signal for that type.
      // Subsequent rules for the same category are skipped to prevent repetitive feedback.
      if (usedCategories.contains(match.rule.category)) continue;

      // Find templates for this category
      List<AdviceTemplate> templates = AdviceRegistry.getAllTemplates()
          .where((t) => t.category == match.rule.category)
          .toList();

      if (templates.isNotEmpty) {
        // Selection Strategy:
        // 1. Sort templates by their intrinsic confidenceWeight (descending).
        templates.sort((a, b) => b.confidenceWeight.compareTo(a.confidenceWeight));

        // 2. Take the top candidates (e.g., Top 3) to ensure high quality.
        int topK = min(3, templates.length);
        List<AdviceTemplate> topCandidates = templates.sublist(0, topK);

        // 3. Randomly select one from the top candidates.
        // This hybrid approach ensures we favor "better" advice while still
        // maintaining variety so the user doesn't see the exact same card every time.
        topCandidates.shuffle();
        AdviceTemplate selectedTemplate = topCandidates.first;

        print("AdviceEngine: Selected template '${selectedTemplate.id}' for ${match.rule.category}");

        candidates.add(_resolveTemplate(selectedTemplate, context, match.score));
        usedCategories.add(match.rule.category);
      }
    }

    // 4. Sort final candidates by their combined score (descending)
    candidates.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));
    
    return candidates;
  }

  /// Helper to hydrate a template with actual data from the context.
  GeneratedAdvice _resolveTemplate(
      AdviceTemplate template, AdviceTriggerContext context, double ruleScore) {
    
    // Calculate a confidence qualifier (e.g., "often", "occasionally") 
    // to make the advice sound natural and honest about its certainty.
    String qualifier = AdviceWordingHelper.confidenceQualifier(ruleScore);
    String suggestionPrefix = AdviceWordingHelper.suggestionPrefix(ruleScore);

    // Prepare values for placeholders.
    // We map keys used in AdviceTemplate (e.g., {app}) to the actual context data.
    // If specific data is missing (e.g., dominantApp is empty), we use safe fallbacks.
    Map<String, String> values = {
      // 1. App Name
      'app': context.dominantApp.isNotEmpty ? context.dominantApp : 'this app',
      'app1': context.dominantApp.isNotEmpty ? context.dominantApp : 'primary app',
      
      // 2. Time Window (e.g., "Morning", "Late Night")
      'timeWindow': context.dominantTimeWindow.isNotEmpty ? context.dominantTimeWindow : 'the day',
      
      // 3. Trend Direction (e.g., "Increasing", "Stable")
      'trend': context.habitTrend.isNotEmpty ? context.habitTrend : 'stable',
      
      // 4. Dynamic Qualifiers
      'qualifier': qualifier,
      'suggestionPrefix': suggestionPrefix,
      
      // 5. Fallbacks for other potential keys
      'app2': 'other apps', 
      'count': 'multiple', 
      'minutes': 'several', 
      'percentage': 'significant', 
    };

    // Replace placeholders in the body text.
    // The formatBody method in AdviceTemplate handles the string replacement.
    String resolvedBody = template.formatBody(values);

    // Calculate final score: Rule Confidence * Template Weight
    double finalScore = ruleScore * template.confidenceWeight;

    return GeneratedAdvice(
      title: template.title,
      body: resolvedBody,
      category: template.category,
      generatedAt: DateTime.now(),
      confidenceScore: finalScore, 
    );
  }
}

/// Private helper class to store rule evaluation results.
class _RuleMatch {
  final AdviceTriggerRule rule;
  final double score;

  _RuleMatch(this.rule, this.score);
}
