import 'package:intl/intl.dart';

class WeightRecord {
  final DateTime date;
  final double weight;
  final double? bodyFat;

  const WeightRecord({
    required this.date,
    required this.weight,
    this.bodyFat,
  });

  List<Object?> toSheetRow() => [
        DateFormat('yyyy-MM-dd').format(date),
        weight,
        bodyFat,
      ];
}
