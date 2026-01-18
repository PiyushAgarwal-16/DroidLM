/// Categorizes the type of advice or insight being provided to the user.
///
/// This enum is used to filter advice logic and determine UI styling elements
/// such as icons and background colors.
enum AdviceCategory {
  /// Advice related to habitual usage patterns, often focusing on
  /// reducing unconscious checking or high-frequency launches.
  habit,

  /// Advice focused on digital distraction, multitasking, or
  /// app usage that interrupts focus periods.
  distraction,

  /// Insights regarding the time of day usage occurs, such as
  /// late-night scrolling or morning routine interruptions.
  timePattern,

  /// Positive reinforcement for good digital wellbeing streaks,
  /// improved focus, or meeting goals.
  positive,

  /// Analysis of usage trends over time, such as increasing
  /// screen time or shifting app preferences.
  trend,

  /// Direct, actionable steps the user can take immediately,
  /// such as setting a timer or enabling specific modes.
  action,
}
