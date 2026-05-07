import 'package:flutter/foundation.dart';

// const instances are not possible at call sites because DateTime has no const
// constructor, but the declaration satisfies @immutable requirements.
@immutable
class BushidoDayRow {
  final DateTime date;
  final double? weightKg;
  final int? kcal;
  final int? proteinG;
  final int? carbsG;
  final int? fatG;
  final int? fiberG;
  final int? steps;

  const BushidoDayRow({
    required this.date,
    this.weightKg,
    this.kcal,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.fiberG,
    this.steps,
  });
}
