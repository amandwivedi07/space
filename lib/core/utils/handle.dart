/// Handle rules, mirroring the server's `normalizeHandle` / `validHandle` in
/// `internal/domain/auth/service/handles.go`.
///
/// Kept in step deliberately: the server is the authority, but checking here
/// first means an obviously malformed handle is refused under the field
/// instead of after a round trip. If these two ever disagree, the app either
/// blocks something the server would accept or promises something it will
/// refuse — the tests pin the same table on both sides.
library;

/// Folds a typed handle into the form the server stores: no leading "@", no
/// surrounding whitespace, lowercase.
String normalizeHandle(String raw) =>
    raw.trim().replaceFirst(RegExp(r'^@+'), '').trim().toLowerCase();

/// 3–30 characters, starting and ending alphanumeric, with dots, underscores
/// and hyphens allowed in between.
final _shape = RegExp(r'^[a-z0-9][a-z0-9._-]{1,28}[a-z0-9]$');

bool isValidHandle(String normalized) => _shape.hasMatch(normalized);

/// The reason a handle is refused, or null when it is fine. Worded to match
/// the server's message so the two never contradict each other on screen.
String? handleProblem(String normalized) {
  if (normalized.isEmpty) return null; // nothing typed is not an error
  if (isValidHandle(normalized)) return null;
  return 'Handles are 3–30 characters of letters, numbers, dots, underscores '
      'or hyphens, starting and ending with a letter or number';
}
