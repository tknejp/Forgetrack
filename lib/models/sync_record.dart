enum SyncStatus { idle, running, success, error }

class SyncRecord {
  final DateTime timestamp;
  final SyncStatus status;
  final int rowsSynced;
  final String? errorMessage;

  const SyncRecord({
    required this.timestamp,
    required this.status,
    this.rowsSynced = 0,
    this.errorMessage,
  });

  bool get isSuccess => status == SyncStatus.success;
  bool get hasError => status == SyncStatus.error;
}
