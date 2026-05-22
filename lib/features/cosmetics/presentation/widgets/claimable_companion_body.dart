import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/logging/app_log.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../progression_engine/application/progression_engine_provider.dart';
import '../../domain/cosmetic_models.dart';
import '../../domain/consumed_relics.dart';
import 'companion_claim_flow.dart';

const _log = AppLogger('COSMETICS', scope: 'claimable_body');

/// Claim-flow body shown in place of the regular details layout when a
/// companion's `CompanionAvailability` is in `available` state.
class ClaimableCompanionBody extends StatelessWidget {
  const ClaimableCompanionBody({
    super.key,
    required this.definition,
    required this.l10n,
    required this.color,
    required this.bottomPad,
    required this.destSlotKey,
    required this.hideCompanion,
    required this.overlayHandle,
  });

  final Cosmetic definition;
  final AppLocalizations l10n;
  final Color color;
  final double bottomPad;
  final GlobalKey destSlotKey;
  final ValueNotifier<bool> hideCompanion;
  final ClaimOverlayHandle overlayHandle;

  @override
  Widget build(BuildContext context) {
    final relicIds = companionRelicGateIds(definition.id);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Tokens.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(26)),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(18, 12, 18, bottomPad + 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius:
                        BorderRadius.circular(Tokens.radiusProgress),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.cosmeticCompanionClaimableBadge,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.cosmeticCompanionClaimableHiddenName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Tokens.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.cosmeticCompanionClaimableHint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Tokens.onSurfaceMuted,
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              CompanionClaimFlow(
                companion: definition,
                relicIds: relicIds,
                color: color,
                onClaim: () => _runClaim(context),
                destSlotKey: destSlotKey,
                hideCompanion: hideCompanion,
                overlayHandle: overlayHandle,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _runClaim(BuildContext context) async {
    final progression = context.read<ProgressionEngineProvider>();
    _log.info('claim companion', payload: 'id=${definition.id}');
    await progression.claimNode(nodeId: definition.id);
  }
}
