/// Where a [Quest] surfaces in the quest screen.
enum QuestDisplayBucket {
  /// Daily-rotating slots — refresh every day.
  daily,

  /// Weekly-rotating slots — refresh every week.
  weekly,

  /// Chapter quests — grouped under the active chapter.
  chapter,

  /// Daily combo chains — themed sequential chains gated by
  /// `prerequisiteNodeIds` and rotated via `ContentUnlock`
  /// bridges between chain finales. Lives in its own quest-screen
  /// section so combo content doesn't compete with the 2-per-day
  /// daily rotation.
  combo,

  /// Daily challenge — one rotating themed bonus quest per day
  /// (deterministic hash pick from a pool of templates). Higher
  /// XP than the simple daily goals; uses existing metric kinds
  /// (TodayCompletionsAmongMetric) so no new engine plumbing.
  /// Lives in its own quest-screen section "DENNÍ QUEST" between
  /// chapters and combo.
  dailyChallenge,

  /// Chapter-themed daily side quest — narrative bonus content
  /// tied to the currently-active chapter via the
  /// `ChapterActive(chapterId)` unlock condition. Several per
  /// chapter; the side quest pool retires when the chapter
  /// finale completes and the next chapter's pool takes over.
  /// Lives in its own quest-screen section just below the chapter
  /// card, so it reads as "extras" attached to the chapter
  /// narrative.
  chapterSideQuest,

  /// Long-term goals — lifetime / multi-week objectives.
  longTerm,

  /// Hidden from the quest screen — reserved for nodes that exist
  /// only to gate other nodes. Validator allows missing display
  /// metadata for these.
  hidden,
}
