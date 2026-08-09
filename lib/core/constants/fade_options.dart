/// Fade timers a card can carry. Durations count from the moment the
/// recipient sees the card ("It fades 1 minute after they see it").
enum FadeOption {
  s10('10 seconds', Duration(seconds: 10)),
  s30('30 seconds', Duration(seconds: 30)),
  m1('1 minute', Duration(minutes: 1)),
  m5('5 minutes', Duration(minutes: 5)),
  m15('15 minutes', Duration(minutes: 15)),
  m30('30 minutes', Duration(minutes: 30)),
  m45('45 minutes', Duration(minutes: 45)),
  m60('60 minutes', Duration(minutes: 60)),
  afterSeen('After seen', Duration(seconds: 8)),
  viewOnce('View once', Duration.zero);

  const FadeOption(this.label, this.duration);

  final String label;
  final Duration duration;

  bool get isViewOnce => this == FadeOption.viewOnce;

  String get sentenceLabel => switch (this) {
        FadeOption.afterSeen => 'Fades after seen',
        FadeOption.viewOnce => 'View once · then gone',
        _ => 'Fades $label after seen',
      };

  /// The compact form for the composer chip, where there is room for a
  /// glance and nothing more.
  String get chipLabel => switch (this) {
        FadeOption.afterSeen => 'SEEN',
        FadeOption.viewOnce => 'ONCE',
        FadeOption.s10 => '10S',
        FadeOption.s30 => '30S',
        FadeOption.m1 => '1M',
        FadeOption.m5 => '5M',
        FadeOption.m15 => '15M',
        FadeOption.m30 => '30M',
        FadeOption.m45 => '45M',
        FadeOption.m60 => '60M',
      };

  /// Completes the sentence "CARDS …" in an empty room. It lives here beside
  /// [sentenceLabel] because the two special cases already carry "after seen"
  /// (and "once") in their own labels — pasting a suffix on at the call site
  /// printed "CARDS FADE AFTER SEEN AFTER SEEN".
  String get roomClause => switch (this) {
        FadeOption.afterSeen => 'FADE AFTER SEEN',
        FadeOption.viewOnce => 'ARE SEEN ONCE, THEN GONE',
        _ => 'FADE ${label.toUpperCase()} AFTER SEEN',
      };

  static FadeOption fromId(String? id) => FadeOption.values.firstWhere(
        (o) => o.name == id,
        orElse: () => FadeOption.m1,
      );
}
