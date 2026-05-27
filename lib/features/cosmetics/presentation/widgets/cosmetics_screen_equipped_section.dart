import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/cosmetic_models.dart';
import 'cosmetics_screen_card.dart';
import 'cosmetics_screen_chrome.dart';

class CosmeticsScreenEquippedSection extends StatelessWidget {
  const CosmeticsScreenEquippedSection({
    super.key,
    required this.definitions,
    required this.state,
    required this.l10n,
    required this.onTap,
  });

  final List<Cosmetic> definitions;
  final UserCosmeticsState state;
  final AppLocalizations l10n;
  final ValueChanged<Cosmetic> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CosmeticsScreenSectionHead(
          label: l10n.cosmeticsEquippedSectionLabel,
          caption: l10n.cosmeticsEquippedSectionCaption,
        ),
        const SizedBox(height: 10),
        if (definitions.isEmpty)
          CosmeticsScreenEmptyLine(
            title: l10n.cosmeticsEquippedEmptyTitle,
            caption: l10n.cosmeticsEquippedEmptyCaption,
          )
        else
          // Horizontal scroll so a new equipped slot (e.g. banner)
          // doesn't squish the fixed tiles. Width per tile (~110 px)
          // matches the previous 3-Expanded layout on a 360-wide
          // phone; ListView centralises padding + clipping.
          SizedBox(
            height: 148,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: definitions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => SizedBox(
                width: 124,
                child: CosmeticsScreenCard(
                  definition: definitions[i],
                  isEquipped: true,
                  l10n: l10n,
                  onTap: () => onTap(definitions[i]),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
