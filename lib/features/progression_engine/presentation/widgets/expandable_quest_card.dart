import 'package:flutter/material.dart';

import '../../../../shared/theme/design_tokens.dart';
import 'expanded_quest_scope.dart';

/// Card shell shared by every "engine card" variant on the quests
/// screen — [EngineQuestCard], [EngineChapterCard], [EngineLongTermCard]
/// and [EngineCompletedQuestCard].
///
/// The four cards used to repeat the same animated container + border
/// interpolation + drop shadow + AnimatedSize body + RepaintBoundary
/// scaffolding inline; Phase 1 of the UI refactor collects all of it
/// here. Per-card variation lives in the slot widgets ([header],
/// [chainPreview], [progressRow], [expandedBody]) the caller composes.
///
/// **Performance invariants baked in by Phase 0–0.3 + the hero-pattern
/// follow-up — keep them.**
///
/// 1. The template self-subscribes to [ExpandedQuestScope] via
///    [nodeId]. Callers pass the same nodeId; never a constructor
///    `isExpanded`. This is what makes a card toggle invalidate only
///    the two affected cards instead of the whole quest screen.
/// 2. Wraps everything in a top-level [RepaintBoundary] so scroll
///    becomes a GPU translate of the cached layer and a sibling card's
///    expand animation doesn't re-rasterize this card.
/// 3. The expanded body sits inside an [AnimatedSize] with an inner
///    [RepaintBoundary] around the body — the parent scroll viewport
///    stays clean while the body's silhouette interpolates.
/// 4. **No conditional shadows. No animated shadow params.** Phase 0.2
///    proved a 22 px Gaussian blur on a growing silhouette blows the
///    120 Hz raster budget. Pass static [shadows] only.
/// 5. **Border colour interpolation is the expand affordance.** The
///    [AnimatedContainer]'s 180 ms border tween between
///    [collapsedBorderColor] and [expandedBorderColor] is cheap and is
///    the only animation on the outer container.
/// 6. **`backgroundDecoration` lives on a static inner DecoratedBox.**
///    The outer [AnimatedContainer]'s `decoration` carries only color,
///    border, shadow, radius — never an image. Per-frame `BoxDecoration`
///    lerps don't touch any [DecorationImage] hash, and a static
///    `DecoratedBox` just re-paints its image as a textured quad at
///    the new size (near-constant GPU cost — exactly what
///    [HeroProgressionHeader] does).
class ExpandableQuestCard extends StatelessWidget {
  const ExpandableQuestCard({
    super.key,
    required this.nodeId,
    required this.header,
    this.onToggle,
    this.canExpand = true,
    this.chainPreview,
    this.progressRow,
    this.expandedBody,
    this.backgroundDecoration,
    this.collapsedBorderColor,
    this.expandedBorderColor,
    this.shadows,
  });

  /// Identifies this card inside [ExpandedQuestScope]. The template
  /// only repaints when the scope's expanded id transitions into or
  /// out of this value.
  final String nodeId;

  /// Tap handler for the entire card. Null (or [canExpand] false)
  /// makes the gesture detector inert — taps fall through to the
  /// underlying surface.
  final VoidCallback? onToggle;

  /// When false the card never reacts to taps and never reveals the
  /// expanded body. Cards use this to disable expansion on XP-only
  /// quests / level-locked chapters.
  final bool canExpand;

  /// Top row of the card — leading asset / icon, title + description
  /// column, trailing XP pill + secondary pill / chevron. Always
  /// rendered.
  final Widget header;

  /// Optional row between [header] and [progressRow]. Used by chapter,
  /// long-term and combo-daily cards for the chain-dot preview.
  final Widget? chainPreview;

  /// Optional progress bar + label row. Cards that don't show
  /// progress (completed entries, level-locked chapters) leave it
  /// null.
  final Widget? progressRow;

  /// Body revealed when the scope reports this card as expanded.
  /// Wrapped by the template in [RepaintBoundary] + top padding.
  final Widget? expandedBody;

  /// Optional decoration applied to a STATIC [DecoratedBox] inside the
  /// card's [ClipRRect], between the outer animated shell and the
  /// padded content. Use this for background images (with `opacity`)
  /// or static gradients that should cover the entire card without
  /// being re-lerped per frame.
  ///
  /// The outer [AnimatedContainer] keeps only color + border + shadow
  /// + radius in its own decoration. Anything image-bearing belongs
  /// here so it doesn't take the per-tick [BoxDecoration.lerp] hit —
  /// the same pattern [HeroProgressionHeader] uses to animate its
  /// expand smoothly with a bg image present.
  ///
  /// Prefer `DecorationImage.opacity` over
  /// `colorFilter: ColorFilter.mode(black, BlendMode.darken)`: opacity
  /// is a single shader multiply, blend modes are pipeline ops, and
  /// hero header has proven opacity is enough for "darkened backdrop"
  /// readability.
  final BoxDecoration? backgroundDecoration;

  /// Border colour when the card is collapsed. Defaults to a low-alpha
  /// white hairline matching the quest / long-term cards.
  final Color? collapsedBorderColor;

  /// Border colour when the card is expanded. Defaults to the app
  /// accent at 42% alpha matching the quest / long-term cards.
  final Color? expandedBorderColor;

  /// Static drop shadow(s) on the outer container. Defaults to the
  /// single black-26% drop shadow shared by quest / long-term cards.
  /// Phase 0.2 rule: never animate these params; never use
  /// [Tokens.glowXl] blur on a card-sized silhouette.
  final List<BoxShadow>? shadows;

  static const _defaultCollapsedBorder = Color(0x0FFFFFFF); // white 6%
  static final _defaultExpandedBorder =
      Tokens.accent.withValues(alpha: 0.42);
  static const _defaultShadow = BoxShadow(
    color: Color(0x42000000), // black 26%
    blurRadius: 10,
    offset: Offset(0, 4),
  );

  @override
  Widget build(BuildContext context) {
    final isExpanded = ExpandedQuestScope.isExpanded(context, nodeId);
    final tapTarget = canExpand ? onToggle : null;

    // Slot widgets own their leading whitespace — the template only
    // stacks them. Per-card vertical rhythm (e.g. the quest card's
    // 4 px-above / 12 px-below combo chain row vs. chapter / long-term
    // cards' uniform 8 px) is preserved by letting the caller wrap
    // each slot in the Padding it needs.
    final stackedContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        if (chainPreview != null) chainPreview!,
        if (progressRow != null) progressRow!,
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: (isExpanded && expandedBody != null)
              ? RepaintBoundary(
                  child: Padding(
                    padding: const EdgeInsets.only(top: Tokens.spaceSm),
                    child: expandedBody!,
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );

    final padded = Padding(
      padding: const EdgeInsets.all(Tokens.questCardPadding),
      child: stackedContent,
    );

    // Static `DecoratedBox` carries any optional bg image / gradient.
    // The outer `AnimatedContainer` only animates color + border +
    // shadow — image-bearing decoration on the animated container
    // would force a per-tick `DecorationImage` re-evaluation that the
    // chapter card's pre-refactor jank traced to. By contrast a
    // static `DecoratedBox` whose size grows with `AnimatedSize` just
    // re-paints its image as a textured quad on the GPU (near-constant
    // cost regardless of size change).
    final decorated = backgroundDecoration == null
        ? padded
        : DecoratedBox(
            decoration: backgroundDecoration!,
            child: padded,
          );

    return RepaintBoundary(
      child: GestureDetector(
        onTap: tapTarget,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: const Color(0xFF111423),
            borderRadius: BorderRadius.circular(Tokens.questCardRadius),
            border: Border.all(
              color: isExpanded
                  ? (expandedBorderColor ?? _defaultExpandedBorder)
                  : (collapsedBorderColor ?? _defaultCollapsedBorder),
            ),
            boxShadow: shadows ?? const [_defaultShadow],
          ),
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(Tokens.questCardRadius),
            child: decorated,
          ),
        ),
      ),
    );
  }
}
