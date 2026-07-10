extension StringX on String {
  /// First grapheme, uppercased — used for avatar initials.
  String get initial => trim().isEmpty ? '·' : trim()[0].toUpperCase();

  /// "elena russo" -> "Elena Russo"
  String get titleCase => split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');

  /// Slug used for ids: "Sunday Supper" -> "sunday-supper".
  String get slug => trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');

  bool get isBlank => trim().isEmpty;

  /// Digits only — for phone links.
  String get digitsOnly => replaceAll(RegExp(r'\D'), '');
}
