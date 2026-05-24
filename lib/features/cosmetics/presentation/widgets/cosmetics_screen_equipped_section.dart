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
        const CosmeticsScreenSectionHead(
          label: 'Vybaveno',
          caption: 'Aktuální vzhled profilu a cesty',
        ),
        const SizedBox(height: 10),
        if (definitions.isEmpty)
          const CosmeticsScreenEmptyLine(
            title: 'Zatím nic není vybavené.',
            caption: 'Klepni na odemčenou kosmetiku níže a vyber Vybavit.',
          )
        else
          SizedBox(
            height: 128,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < definitions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: CosmeticsScreenCard(
                      definition: definitions[i],
                      isEquipped: true,
                      l10n: l10n,
                      onTap: () => onTap(definitions[i]),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
