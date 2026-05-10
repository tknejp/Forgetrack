/// When does counting toward the objective start for a [QuestNode]?
enum ProgressStartPolicy {
  /// Player lifetime — counts from the very beginning.
  lifetime,

  /// Counts from the moment the chapter the quest belongs to became
  /// active. Lets chapter quests measure progress *during the
  /// chapter*, not retroactively.
  chapterStartedAt,
}
