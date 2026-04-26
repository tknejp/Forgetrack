class DevToolsSyncEvent {
  const DevToolsSyncEvent({
    required this.timestamp,
    required this.source,
    required this.feature,
    required this.result,
    this.durationMs,
    this.errorMessage,
    this.extra,
  });

  /// Where the sync was triggered from.
  /// Values: 'manual' | 'foreground' | 'background' | 'appStart'
  final String source;

  /// Which data domain was synced.
  /// Values: 'health' | 'nutrition' | 'progression' | 'social' | 'all'
  final String feature;

  /// Outcome of this sync entry.
  /// Values: 'started' | 'success' | 'failure'
  final String result;

  final DateTime timestamp;
  final int? durationMs;
  final String? errorMessage;

  /// Arbitrary key/value pairs — used for diagnostics (e.g. stepsBefore/After).
  final Map<String, dynamic>? extra;

  DevToolsSyncEvent copyWith({
    DateTime? timestamp,
    String? source,
    String? feature,
    String? result,
    int? durationMs,
    String? errorMessage,
    Map<String, dynamic>? extra,
  }) {
    return DevToolsSyncEvent(
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
      feature: feature ?? this.feature,
      result: result ?? this.result,
      durationMs: durationMs ?? this.durationMs,
      errorMessage: errorMessage ?? this.errorMessage,
      extra: extra ?? this.extra,
    );
  }

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'source': source,
        'feature': feature,
        'result': result,
        if (durationMs != null) 'durationMs': durationMs,
        if (errorMessage != null) 'errorMessage': errorMessage,
        if (extra != null) 'extra': extra,
      };

  factory DevToolsSyncEvent.fromJson(Map<String, dynamic> json) {
    return DevToolsSyncEvent(
      timestamp: DateTime.parse(json['timestamp'] as String),
      source: json['source'] as String,
      feature: json['feature'] as String,
      result: json['result'] as String,
      durationMs: json['durationMs'] as int?,
      errorMessage: json['errorMessage'] as String?,
      extra: json['extra'] != null
          ? Map<String, dynamic>.from(json['extra'] as Map)
          : null,
    );
  }
}
