import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/logging/app_log.dart';
import 'progression_local_models.dart';

class ProgressionDatabase {
  Isar? _isar;
  bool _opened = false;

  static const _isarName = 'progression';

  Future<void> open() async {
    if (_opened) {
      AppLog.app.debug('ProgressionDatabase: open() skipped — already open');
      return;
    }

    _opened = true;

    try {
      final dir = await getApplicationDocumentsDirectory();

      AppLog.app.info(
        'ProgressionDatabase: opening Isar store',
        payload: dir.path,
      );

      _isar = await Isar.open(
        [
          ProgressionEvaluationRecordSchema,
          ProgressionRewardGrantRecordSchema,
          ProgressionQuestRewardGrantRecordSchema,
          ProgressionActiveQuestRecordSchema,
          ProgressionAchievementUnlockRecordSchema,
        ],
        directory: dir.path,
        name: _isarName,
      );

      AppLog.app.info('ProgressionDatabase: ready');
    } catch (_) {
      _opened = false;
      _isar = null;
      rethrow;
    }
  }

  Isar get isar {
    final value = _isar;

    if (value == null) {
      throw StateError('ProgressionDatabase must be opened before use.');
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

      AppLog.app.debug('ProgressionDatabase: closed');
    } catch (e, st) {
      AppLog.app.error(
        'ProgressionDatabase: close() failed',
        err: e,
        stackTrace: st,
      );
    } finally {
      _isar = null;
      _opened = false;
    }
  }
}
