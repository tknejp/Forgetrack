/// Deterministic identifier for a single journal event.
///
/// Re-running the engine over the same inputs produces the same
/// [EventKey] for every event, so persistence layers (Isar + Firestore)
/// dedupe at the storage layer (`set()` is idempotent on the same
/// document id, Isar's composite unique index drops duplicate rows).
///
/// Wrapping a raw [String] in an extension type costs nothing at
/// runtime — the value is still a String — but the compiler refuses
/// to pass an [EventKey] where a `NodeId` is expected and vice versa.
/// This catches typo bugs that previously slipped through Dart's
/// stringly-typed identifier conventions (see proposal §7.3).
///
/// **Construction discipline:** every event subtype computes its key
/// from its semantic identity (node id + period + event verb). Never
/// generate keys from timestamps — that defeats idempotency. Key
/// shapes are documented per event subtype in
/// [JournalEvent] subclasses.
extension type const EventKey(String value) implements Object {
  /// Stable serialisation form for persistence. Returns the underlying
  /// raw string. Used by Isar / Firestore mappers at the data-layer
  /// boundary.
  ///
  /// Note: extension types are erased at runtime to their representation
  /// type ([String]), so `eventKey.toString()` calls the underlying
  /// String's toString directly. There is no class identity to print.
  String get raw => value;
}
