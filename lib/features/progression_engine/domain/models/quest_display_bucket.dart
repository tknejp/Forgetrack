/// Where a [QuestNode] surfaces in the quest screen.
enum QuestDisplayBucket {
  /// Daily-rotating slots — refresh every day.
  daily,

  /// Weekly-rotating slots — refresh every week.
  weekly,

  /// Chapter quests — grouped under the active chapter.
  chapter,

  /// Long-term goals — lifetime / multi-week objectives.
  longTerm,

  /// Hidden from the quest screen — reserved for nodes that exist
  /// only to gate other nodes. Validator allows missing display
  /// metadata for these.
  hidden,
}
