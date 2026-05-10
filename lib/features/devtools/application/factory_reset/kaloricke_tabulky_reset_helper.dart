import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/logging/app_log.dart';
import '../../../nutrition/application/kaloricke_tabulky_provider.dart';

/// Logs out from Kaloricke Tabulky and removes every locally-cached
/// credential.
///
/// `KalorickeTabulkyProvider.logout()` already invokes the session
/// client's `logout()` (which clears `kt_email` + `kt_pwd_hash` from
/// `FlutterSecureStorage`) and wipes the KT Isar cache. We still call
/// the secure-storage delete defensively so the reset succeeds even if a
/// malformed provider state would otherwise short-circuit the logout.
class KalorickeTabulkyResetHelper {
  KalorickeTabulkyResetHelper({
    required KalorickeTabulkyProvider provider,
    FlutterSecureStorage? secureStorage,
  })  : _provider = provider,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _kKtEmailKey = 'kt_email';
  static const _kKtPwdHashKey = 'kt_pwd_hash';

  final KalorickeTabulkyProvider _provider;
  final FlutterSecureStorage _secureStorage;

  /// Performs the KT logout flow + clears stored credentials.
  /// Returns a short note for the reset progress UI.
  Future<String> logoutAndClear() async {
    AppLog.reset.info('kt: logout start');
    Object? logoutError;
    try {
      await _provider.logout();
      AppLog.reset.success('kt: provider.logout ok');
    } catch (e, st) {
      logoutError = e;
      AppLog.reset.warn(
        'kt: provider.logout failed (continuing with secure-storage clear)',
        payload: e,
      );
      AppLog.reset.debug('kt: logout stack', payload: st);
    }

    // Defensive: wipe credentials directly even if the provider call
    // succeeded — secure-storage deletes are no-ops for missing keys.
    await _secureStorage.delete(key: _kKtEmailKey);
    await _secureStorage.delete(key: _kKtPwdHashKey);
    AppLog.reset.success('kt: secure storage cleared');

    if (logoutError != null) {
      return 'logged out (best-effort: provider error)';
    }
    return 'logged out + credentials cleared';
  }
}
