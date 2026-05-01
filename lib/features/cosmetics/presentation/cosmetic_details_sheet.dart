import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/theme/design_tokens.dart';
import '../application/cosmetics_provider.dart';
import '../domain/cosmetic_models.dart';
import 'cosmetics_l10n.dart';
import 'cosmetics_screen_internals.dart';

class CosmeticDetailsSheet extends StatefulWidget {
  const CosmeticDetailsSheet({
    super.key,
    required this.definition,
    required this.state,
    required this.l10n,
  });

  final CosmeticDefinition definition;
  final UserCosmeticsState state;
  final CosmeticsL10n l10n;

  @override
  State<CosmeticDetailsSheet> createState() => _CosmeticDetailsSheetState();
}

class _CosmeticDetailsSheetState extends State<CosmeticDetailsSheet> {
  bool _busy = false;

  Future<void> _toggleEquipped() async {
    if (_busy) return;
    setState(() => _busy = true);
    final provider = context.read<CosmeticsProvider>();
    final definition = widget.definition;
    final isEquipped =
        widget.state.equipped.slotId(definition.type) == definition.id;

    if (isEquipped) {
      await provider.unequip(definition.type);
    } else {
      await provider.equip(definition.id);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final definition = widget.definition;
    final l10n = widget.l10n;
    final color = cosmeticRarityColor(definition.rarity);
    final isEquipped =
        widget.state.equipped.slotId(definition.type) == definition.id;
    final assetPath = context
        .read<CosmeticsProvider>()
        .service
        .config
        .resolveAssetPath(definition.previewAssetKey ?? definition.assetKey);
    final description = l10n.description(definition);
    final unlock = widget.state.unlocked[definition.id];
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Tokens.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: EdgeInsets.fromLTRB(18, 12, 18, bottomPad + 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(Tokens.radiusProgress),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CosmeticBadge(
                definition: definition,
                assetPath: assetPath,
                color: color,
                size: 94,
              ),
              const SizedBox(width: Tokens.spaceLg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.name(definition),
                      style: const TextStyle(
                        color: Tokens.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _TinyPill(
                            label: cosmeticTypeLabel(definition.type),
                            color: color),
                        _TinyPill(
                          label: cosmeticRarityLabel(definition.rarity),
                          color: color,
                        ),
                        if (isEquipped)
                          _TinyPill(label: l10n.equippedBadge, color: color),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              description,
              style: const TextStyle(
                color: Tokens.onSurfaceMuted,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (unlock != null) ...[
            const SizedBox(height: 14),
            Text(
              'Odemčeno ${MaterialLocalizations.of(context).formatMediumDate(unlock.unlockedAt)}',
              style: TextStyle(
                color: color.withValues(alpha: 0.78),
                fontSize: Tokens.fontSizeCaption,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
          const SizedBox(height: 18),
          _ActionButton(
            label: isEquipped ? 'Odebrat z výbavy' : 'Vybavit',
            icon: isEquipped
                ? Icons.remove_circle_outline_rounded
                : Icons.check_circle_rounded,
            color: color,
            busy: _busy,
            onTap: _toggleEquipped,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: busy ? null : onTap,
        icon: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: color,
          foregroundColor: Tokens.bg,
          disabledBackgroundColor: color.withValues(alpha: 0.34),
          disabledForegroundColor: Tokens.onSurfaceMuted,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Tokens.radiusInner),
          ),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _TinyPill extends StatelessWidget {
  const _TinyPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(Tokens.radiusProgress),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: Tokens.fontSizeMicro,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
