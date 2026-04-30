import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/logging/app_log.dart';
import 'cosmetics_local_models.dart';

/// Owns the Isar instance for the cosmetics feature.
///
/// Lifecycle mirrors `ProgressionDatabase`: open once at app startup before
/// `runApp`, hand the instance to the repository, close on shutdown if
/// needed.
class CosmeticsDatabase {
  Isar? _isar;
  bool _opened = false;

  static const _isarName = 'cosmetics';

  Future<void> open() async {
    if (_opened) {
      AppLog.app.debug('CosmeticsDatabase: open() skipped — already open');
      return;
    }

    _opened = true;

    try {
      final dir = await getApplicationDocumentsDirectory();

      AppLog.app.info(
        'CosmeticsDatabase: opening Isar store',
        payload: dir.path,
      );

      _isar = await Isar.open(
        [
          CosmeticsUserStateRecordSchema,
          CosmeticsUnlockRecordSchema,
        ],
        directory: dir.path,
        name: _isarName,
      );

      AppLog.app.info('CosmeticsDatabase: ready');
    } catch (_) {
      _opened = false;
      _isar = null;
      rethrow;
    }
  }

  Isar get isar {
    final value = _isar;
    if (value == null) {
      throw StateError('CosmeticsDatabase must be opened before use.');
    }
    return value;
  }

  Future<void> close() async {
    final value = _isar;
    if (value == null) {
      _opened = false;
      return;
    }
    try {
      await value.close();
      AppLog.app.debug('CosmeticsDatabase: closed');
    } catch (e, st) {
      AppLog.app.error(
        'CosmeticsDatabase: close() failed',
        err: e,
        stackTrace: st,
      );
    } finally {
      _isar = null;
      _opened = false;
    }
  }
}
