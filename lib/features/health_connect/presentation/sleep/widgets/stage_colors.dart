import 'package:flutter/material.dart';

import '../../../domain/sleep_record.dart';

// Picked to read at a glance: deep = dark blue, light = mid, REM = cyan accent,
// awake = warm so it stands out from the cool-toned sleep palette.
class StageColors {
  const StageColors._();

  static const deep = Color(0xFF1F3F8A);
  static const light = Color(0xFF4F7BD9);
  static const rem = Color(0xFF66C2E0);
  static const awake = Color(0xFFFF8A4C);

  static Color of(SleepStage stage) => switch (stage) {
        SleepStage.deep => deep,
        SleepStage.light => light,
        SleepStage.rem => rem,
        SleepStage.awake => awake,
      };
}
