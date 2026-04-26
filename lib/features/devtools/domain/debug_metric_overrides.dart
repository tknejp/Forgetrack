class DebugMetricOverrides {
  const DebugMetricOverrides({
    this.stepsOverride,
    this.stepOffset,
    this.caloriesOverride,
    this.weightOverride,
  });

  final int? stepsOverride;
  final int? stepOffset;
  final double? caloriesOverride;
  final double? weightOverride;

  bool get isEmpty =>
      stepsOverride == null &&
      stepOffset == null &&
      caloriesOverride == null &&
      weightOverride == null;

  DebugMetricOverrides copyWith({
    int? stepsOverride,
    int? stepOffset,
    double? caloriesOverride,
    double? weightOverride,
    bool clearStepsOverride = false,
    bool clearStepOffset = false,
    bool clearCaloriesOverride = false,
    bool clearWeightOverride = false,
  }) {
    return DebugMetricOverrides(
      stepsOverride: clearStepsOverride ? null : (stepsOverride ?? this.stepsOverride),
      stepOffset: clearStepOffset ? null : (stepOffset ?? this.stepOffset),
      caloriesOverride: clearCaloriesOverride ? null : (caloriesOverride ?? this.caloriesOverride),
      weightOverride: clearWeightOverride ? null : (weightOverride ?? this.weightOverride),
    );
  }

  Map<String, dynamic> toJson() => {
        if (stepsOverride != null) 'stepsOverride': stepsOverride,
        if (stepOffset != null) 'stepOffset': stepOffset,
        if (caloriesOverride != null) 'caloriesOverride': caloriesOverride,
        if (weightOverride != null) 'weightOverride': weightOverride,
      };

  factory DebugMetricOverrides.fromJson(Map<String, dynamic> json) {
    return DebugMetricOverrides(
      stepsOverride: json['stepsOverride'] as int?,
      stepOffset: json['stepOffset'] as int?,
      caloriesOverride: (json['caloriesOverride'] as num?)?.toDouble(),
      weightOverride: (json['weightOverride'] as num?)?.toDouble(),
    );
  }

  static const empty = DebugMetricOverrides();
}
