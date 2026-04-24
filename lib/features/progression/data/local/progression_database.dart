import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'progression_local_models.dart';

class ProgressionDatabase {
  Isar? _isar;
  bool _opened = false;

  Future<void> open() async {
    if (_opened) return;
    _opened = true;

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        ProgressionEvaluationRecordSchema,
        ProgressionRewardGrantRecordSchema,
        ProgressionQuestRewardGrantRecordSchema,
        ProgressionActiveQuestRecordSchema,
      ],
      directory: dir.path,
      name: 'progression',
    );
  }

  Isar get isar {
    final value = _isar;
    if (value == null) {
      throw StateError('ProgressionDatabase must be opened before use.');
    }
    return value;
  }
}
