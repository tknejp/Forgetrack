import 'package:isar/isar.dart';

part 'progression_local_models.g.dart';

@Collection()
class ProgressionEvaluationRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String evaluationKey;

  late String rewardKey;
  late String ruleId;
  late String ruleVersion;
  late String domainName;
  late String periodKindName;

  @Index()
  late DateTime periodStart;

  late DateTime periodEnd;
  late String comparatorName;
  late double actualValue;
  late double targetValue;
  double? upperTargetValue;
  late double toleranceRatio;
  late double progress;
  late bool achieved;
  String? statusName;
  String? missReasonName;
  late int rewardXp;
  late String title;
  late String description;
  late String explanation;

  @Index()
  late DateTime evaluatedAt;
}

@Collection()
class ProgressionRewardGrantRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: false)
  late String rewardKey;

  late String ruleId;
  late String ruleVersion;
  late String domainName;
  late String periodKindName;

  @Index()
  late DateTime periodStart;

  late DateTime periodEnd;
  late int xpGranted;
  late double targetValue;
  late double actualValue;
  double? upperTargetValue;
  late double toleranceRatio;
  late String rewardStatusName;

  @Index()
  late DateTime unlockedAt;

  @Index()
  DateTime? claimedAt;
}

@Collection()
class ProgressionActiveQuestRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String questId;

  @Index()
  late DateTime assignedAt;
}
