/// Soft presence states — Space never shows harsh online/offline.
enum Presence {
  here,
  recent,
  away;

  String get label => switch (this) {
        Presence.here => 'Here, quietly.',
        Presence.recent => 'active recently',
        Presence.away => 'away',
      };

  static Presence fromId(String? id) => Presence.values.firstWhere(
        (p) => p.name == id,
        orElse: () => Presence.away,
      );
}
