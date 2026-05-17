import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/logging/app_log.dart';
import 'progression_engine_local_models.dart';

/// Owns the Isar instance backing the new engine's ledger.
///
/// Lives beside (and outside of) the legacy `ProgressionDatabase`
/// so V1 + V2 ledgers coexist cleanly during migration. Phase 9
/// drops the legacy database; this one stays.
class ProgressionEngineDatabase {
  Isar? _isar;
  bool _opened = false;

  static const _isarName = 'progression_engine';

  Future<void> open() async {
    if (_opened) {
      AppLog.app.debug('ProgressionEngineDatabase: open() skipped — already open');
      return;
    }
    _opened = true;

    try {
      final dir = await getApplicationDocumentsDirectory();
      AppLog.app.info(
        'ProgressionEngineDatabase: opening Isar store',
        payload: dir.path,
      );

      _isar = await Isar.open(
        [
          EngineObjectiveCompletionRecordSchema,
          EngineNodeCompletionRecordSchema,
          EngineNodeClaimRecordSchema,
          EngineNodeAnnouncementRecordSchema,
          EngineRewardGrantRecordSchema,
          EngineQuestOfferingRecordSchema,
          EngineActiveSelectionRecordSchema,
        ],
        directory: dir.path,
        name: _isarName,
      );

      AppLog.app.info('ProgressionEngineDatabase: ready');
    } catch (_) {
      _opened = false;
      _isar = null;
      rethrow;
    }
  }

  Isar get isar {
    final value = _isar;
    if (value == null) {
      throw StateError(
        'ProgressionEngineDatabase must be opened before use.',
      );
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
      AppLog.app.debug('ProgressionEngineDatabase: closed');
    } catch (e, st) {
      AppLog.app.error(
        'ProgressionEngineDatabase: close() failed',
        err: e,
        stackTrace: st,
      );
    } finally {
      _isar = null;
      _opened = false;
    }
  }
}
