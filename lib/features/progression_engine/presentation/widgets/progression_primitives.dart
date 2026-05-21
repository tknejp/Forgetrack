import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/section_head.dart';
import 'package:forgetrack/domain/progression/catalog/progression_domain.dart';
import 'package:forgetrack/features/progression_engine/domain/progression_domain_chrome.dart';

export '../../../../shared/widgets/section_head.dart' show SectionHead;

/// Shared visual primitives for progression / hero / quest / journey
/// surfaces. Moved out of the legacy `progression/presentation/widgets/`
/// during Phase 9a so the V2 stack owns its own display chrome.

/// Square domain tile with a Material icon.
class ProgDomIco extends StatelessWidget {
  const ProgDomIco({
    super.key,
    required this.domain,
    this.size = 26,
  });

  final ProgressionDomain domain;
  final double size;

  @override
  Widget build(BuildContext context) {
    final token = domain.token;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: token.dim,
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: token.color.withValues(alpha: 0.28)),
      ),
      child: Icon(
        domain.icon,
        color: token.color,
        size: size * 0.55,
      ),
    );
  }
}

/// Backwards-compatible alias preserved for call sites that already
/// use this name. New code can call [SectionHead] directly.
typedef ProgSectionHead = SectionHead;

/// Page scaffold used by hero / quest / journey screens.
class ProgressionScaffold extends StatelessWidget {
  const ProgressionScaffold({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Tokens.bg,
      body: SafeArea(bottom: false, child: child),
    );
  }
}

/// Compact "nothing to show" line — title + caption — rendered inside
/// sections that have no data yet.
class ProgressionEmptyLine extends StatelessWidget {
  const ProgressionEmptyLine({
    super.key,
    required this.title,
    required this.caption,
  });
  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: Tokens.fontSizeSmall,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            caption,
            style: const TextStyle(
              fontSize: Tokens.fontSizeCaption,
              height: 1.4,
              color: Tokens.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline yellow banner used to surface progression evaluation errors
/// to the player without taking over the screen.
class ProgressionErrorBanner extends StatelessWidget {
  const ProgressionErrorBanner({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x22FBBF24),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: const Color(0x55FBBF24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFFBBF24), size: 18),
          const SizedBox(width: Tokens.spaceSm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: Tokens.fontSizeSmall,
                height: 1.4,
                color: Tokens.onSurfaceMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder block rendered while progression state is hydrating.
/// Sized via [height]; consumers stack a few of these to approximate
/// the post-load layout.
class ProgressionLoadingBlock extends StatelessWidget {
  const ProgressionLoadingBlock({super.key, required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(Tokens.radiusCard),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
    );
  }
}

/// "d MMM · HH:mm" formatter shared by hero / journey / quest views.
String progressionFormatDateTime(DateTime value, String locale) {
  return DateFormat('d MMM · HH:mm', locale).format(value);
}
