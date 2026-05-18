import 'package:http/http.dart' show ClientException;

import '../../features/nutrition/data/kaloricke_tabulky_service.dart'
    show KtApiException, KtAuthException;
import 'app_error.dart';

/// Maps a caught exception from a [KalorickeTabulkyService] call into
/// an [AppError] subtype, preserving the original error + stack trace.
///
/// Phase 18 of the domain refactor (`docs/domain_model/migration_plan.md`
/// §Phase 18) plumbs this through KT-touching boundaries so consumers
/// can pattern-match on severity instead of catching `Object`.
///
/// **Categorisation:**
///   - [KtAuthException] → [NetworkError] (`isTransient: true`) so the
///     KT provider's session refresh / re-login retry kicks in. The
///     plan calls this out explicitly: "401 → NetworkError(isTransient:
///     true) triggers re-login retry".
///   - [KtApiException] → [UpstreamError] (`isTransient: true`)
///     because KT's backend returns the same generic "API error"
///     payload for both temporary outages + genuine 5xx; treating it
///     as transient lets background sync retry without burning the
///     user's session.
///   - [ClientException] / `SocketException` / other network IO →
///     [NetworkError].
///   - Anything else → [UpstreamError] (`isTransient: true`).
AppError classifyKtError(
  Object error,
  StackTrace stackTrace, {
  String? endpoint,
}) {
  if (error is KtAuthException) {
    return NetworkError(
      originalError: error,
      stackTrace: stackTrace,
      isTransient: true,
      statusCode: 401,
      endpoint: endpoint ?? 'kt.auth',
    );
  }
  if (error is KtApiException) {
    return UpstreamError(
      originalError: error,
      stackTrace: stackTrace,
      isTransient: true,
      context: endpoint == null ? 'kt' : 'kt.$endpoint',
    );
  }
  if (error is ClientException) {
    return NetworkError(
      originalError: error,
      stackTrace: stackTrace,
      endpoint: endpoint == null ? 'kt' : 'kt.$endpoint',
    );
  }
  return UpstreamError(
    originalError: error,
    stackTrace: stackTrace,
    context: endpoint == null ? 'kt' : 'kt.$endpoint',
  );
}
