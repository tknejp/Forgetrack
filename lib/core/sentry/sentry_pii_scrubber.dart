/// Strict PII denylist applied to every Sentry event and breadcrumb.
///
/// Policy (decided 2026-05-21 with the user): NO user content reaches Sentry.
/// Only technical metadata (HTTP status, error type, build version, flavor,
/// opaque UID). This module is the last line of defense if a log call slips
/// through with a sensitive payload.
abstract final class SentryPiiScrubber {
  /// Email-like substrings. Replaced with `[email]` rather than dropped so the
  /// surrounding message context survives.
  static final _emailRegex = RegExp(
    r'[\w\-.+]+@[\w\-]+\.[\w\-.]+',
    caseSensitive: false,
  );

  /// Long opaque token-like substrings (FCM tokens, JWTs, MD5/SHA hex).
  /// Matches runs of 24+ chars from `[A-Za-z0-9_\-:.]`.
  static final _tokenRegex = RegExp(r'[A-Za-z0-9_\-:.]{24,}');

  /// Breadcrumb / event data keys that NEVER reach Sentry — even when the
  /// upstream caller passed them in a structured payload.
  static const Set<String> _denylistKeys = {
    'email',
    'username',
    'password',
    'password_hash',
    'passwordhash',
    'fcm_token',
    'fcmtoken',
    'token',
    'cookie',
    'session',
    'weight',
    'weight_kg',
    'food',
    'food_name',
    'kcal',
    'calories',
    'meal',
    'note',
    'comment',
  };

  /// Scrub a free-text message. Returns a copy with email-likes / long tokens
  /// replaced. Cheap and called on every breadcrumb / event message.
  static String scrubMessage(String input) {
    return input
        .replaceAll(_emailRegex, '[email]')
        .replaceAll(_tokenRegex, '[token]');
  }

  /// Drop denylisted keys from a structured map (case-insensitive). Returns
  /// `null` if input was null or empty after scrubbing.
  static Map<String, dynamic>? scrubMap(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return null;
    final out = <String, dynamic>{};
    for (final entry in data.entries) {
      final key = entry.key.toLowerCase();
      if (_denylistKeys.contains(key)) continue;
      final v = entry.value;
      if (v is String) {
        out[entry.key] = scrubMessage(v);
      } else if (v is Map<String, dynamic>) {
        final scrubbed = scrubMap(v);
        if (scrubbed != null) out[entry.key] = scrubbed;
      } else {
        out[entry.key] = v;
      }
    }
    return out.isEmpty ? null : out;
  }
}
