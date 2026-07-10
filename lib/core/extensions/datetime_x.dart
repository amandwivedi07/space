extension DateTimeX on DateTime {
  /// Soft relative label: "just now", "4m ago", "2h ago", "3d ago".
  String get agoLabel {
    final diff = DateTime.now().difference(this);
    if (diff.inSeconds < 45) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// Compact mono badge like the web app: "8M", "2H", "4D".
  String get compactAgo {
    final diff = DateTime.now().difference(this);
    if (diff.inMinutes < 1) return 'NOW';
    if (diff.inMinutes < 60) return '${diff.inMinutes}M';
    if (diff.inHours < 24) return '${diff.inHours}H';
    return '${diff.inDays}D';
  }

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
}
