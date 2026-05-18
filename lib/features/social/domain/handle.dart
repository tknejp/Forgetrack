/// Free helpers for normalising / generating social handles.
///
/// Phase 17 of the domain refactor extracts these out of the monolithic
/// `social_models.dart` so handle logic lives next to other Social
/// per-entity files. Pure-Dart, no IO.
library;

String normalizeSocialHandle(String value) {
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return normalized;
}

String buildDefaultSocialHandle({
  required String uid,
  required String email,
  String? displayName,
}) {
  final candidates = <String>[
    if (displayName != null && displayName.trim().isNotEmpty) displayName,
    email.split('@').first,
    'user_$uid',
  ];

  for (final candidate in candidates) {
    final handle = normalizeSocialHandle(candidate);
    if (handle.isNotEmpty) return handle;
  }

  return 'user';
}

String buildNumberedSocialHandle({
  required String baseHandle,
  required int suffix,
}) {
  final normalized = normalizeSocialHandle(baseHandle);
  final fallback = normalized.isNotEmpty ? normalized : 'user';
  if (suffix <= 0) return fallback;
  return '${fallback}_$suffix';
}

List<String> buildSocialHandleSearchTokens(String handle) {
  final normalized = normalizeSocialHandle(handle);
  if (normalized.isEmpty) return const [];

  final tokens = <String>{};
  for (var i = 1; i <= normalized.length; i++) {
    tokens.add(normalized.substring(0, i));
  }

  final ordered = tokens.toList()..sort((a, b) => a.length.compareTo(b.length));
  return ordered;
}

String buildSocialFriendshipId(String firstUid, String secondUid) {
  final sorted = [firstUid, secondUid]..sort();
  return '${sorted[0]}__${sorted[1]}';
}

String buildSocialParticipantsKey(String firstUid, String secondUid) {
  final sorted = [firstUid, secondUid]..sort();
  return '${sorted[0]}:${sorted[1]}';
}
