/// Form validators used across the app.
class Validators {
  Validators._();

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'A name helps people find you';
    if (v.length < 2) return 'A little longer, perhaps';
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Your email opens the door';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
      return "That email doesn't look right";
    }
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'A password keeps it yours';
    if (v.length < 8) return 'At least 8 characters';
    return null;
  }

  static String? handle(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null; // optional
    if (!RegExp(r'^@?[a-z0-9_.]{2,24}$', caseSensitive: false).hasMatch(v)) {
      return 'Letters, numbers, dots and underscores only';
    }
    return null;
  }

  static String? url(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Paste a link first';
    final candidate = v.startsWith('http') ? v : 'https://$v';
    final uri = Uri.tryParse(candidate);
    if (uri == null || !uri.host.contains('.')) return "That link doesn't look right";
    return null;
  }

  static String? notEmpty(String? value, {String message = 'Required'}) =>
      (value?.trim().isEmpty ?? true) ? message : null;
}
