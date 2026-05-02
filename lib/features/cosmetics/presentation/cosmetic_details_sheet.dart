import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../shared/theme/design_tokens.dart';
import '../application/cosmetics_provider.dart';
import '../domain/cosmetic_models.dart';
import '../domain/cosmetic_unlock_rule.dart';
import 'cosmetics_l10n.dart';
import 'cosmetics_screen_internals.dart';

class CosmeticDetailsSheet extends StatefulWidget {
  const CosmeticDetailsSheet({
    super.key,
    required this.definition,
    required this.state,
    required this.l10n,
    this.isLocked = false,
    this.devToolsUnlockRules,
    this.devToolsMode = false,
  });

  final CosmeticDefinition definition;
  final UserCosmeticsState state;
  final CosmeticsL10n l10n;
  final bool isLocked;
  final List<CosmeticUnlockRule>? devToolsUnlockRules;
  final bool devToolsMode;

  @override
  State<CosmeticDetailsSheet> createState() => _CosmeticDetailsSheetState();
}

class _CosmeticDetailsSheetState extends State<CosmeticDetailsSheet> {
  bool _equipBusy = false;
  bool _devBusy = false;

  Future<void> _toggleEquipped() async {
    if (_equipBusy || _devBusy) return;
    setState(() => _equipBusy = true);
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

  Future<void> _devGrant() async {
    if (_devBusy || _equipBusy) return;
    setState(() => _devBusy = true);
    await context
        .read<CosmeticsProvider>()
        .debugGrantCosmetic(widget.definition.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _devRevoke() async {
    if (_devBusy || _equipBusy) return;
    setState(() => _devBusy = true);
    await context
        .read<CosmeticsProvider>()
        .debugRevokeCosmetic(widget.definition.id);
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
    final isLocked = widget.isLocked;
    final devTools = widget.devToolsMode;
    final rules = widget.devToolsUnlockRules;
    final anyBusy = _equipBusy || _devBusy;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Tokens.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(18, 12, 18, bottomPad + 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // drag handle
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
              const SizedBox(height: 18),

              // header: badge + name + pills
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
                              color: color,
                            ),
                            _TinyPill(
                              label: cosmeticRarityLabel(definition.rarity),
                              color: color,
                            ),
                            if (isEquipped)
                              _TinyPill(
                                label: l10n.equippedBadge,
                                color: color,
                              ),
                            if (isLocked)
                              _TinyPill(
                                label: 'ZAMČENO',
                                color: Theme.of(context).colorScheme.error,
                              ),
                            if (devTools && definition.assetKey == null)
                              _TinyPill(
                                label: 'NO ASSET',
                                color: Colors.orange,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // description
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

              // unlock info
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

              // unlock conditions (devtools)
              if (rules != null && rules.isNotEmpty) ...[
                const SizedBox(height: 18),
                _UnlockConditionsSection(rules: rules, color: color),
              ] else if (definition.unlockHintKey != null && isLocked) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 13, color: color.withValues(alpha: 0.7)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        definition.unlockHintKey!,
                        style: TextStyle(
                          color: color.withValues(alpha: 0.7),
                          fontSize: Tokens.fontSizeCaption,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // debug details section
              if (devTools) ...[
                const SizedBox(height: 18),
                _DebugDetailsSection(
                  definition: definition,
                  unlock: unlock,
                  color: color,
                ),
              ],

              const SizedBox(height: 20),

              // action buttons
              if (devTools) ...[
                // devtools mode: grant/revoke + equip row
                if (isLocked)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: anyBusy
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: _outlineStyle(color),
                          child: const Text('Zavřít'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DevButton(
                          label: 'Grant',
                          icon: Icons.lock_open_rounded,
                          color: Colors.greenAccent,
                          busy: _devBusy,
                          onTap: anyBusy ? null : _devGrant,
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _ActionButton(
                        label: isEquipped ? 'Odebrat z výbavy' : 'Vybavit',
                        icon: isEquipped
                            ? Icons.remove_circle_outline_rounded
                            : Icons.check_circle_rounded,
                        color: color,
                        busy: _equipBusy,
                        onTap: anyBusy ? null : _toggleEquipped,
                      ),
                      const SizedBox(height: 8),
                      _DevButton(
                        label: 'Revoke',
                        icon: Icons.lock_rounded,
                        color: Theme.of(context).colorScheme.error,
                        busy: _devBusy,
                        onTap: anyBusy ? null : _devRevoke,
                      ),
                    ],
                  ),
              ] else if (isLocked)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: _outlineStyle(color),
                    child: const Text('Zavřít'),
                  ),
                )
              else
                _ActionButton(
                  label: isEquipped ? 'Odebrat z výbavy' : 'Vybavit',
                  icon: isEquipped
                      ? Icons.remove_circle_outline_rounded
                      : Icons.check_circle_rounded,
                  color: color,
                  busy: _equipBusy,
                  onTap: anyBusy ? null : _toggleEquipped,
                ),
            ],
          ),
        ),
      ),
    );
  }

  static ButtonStyle _outlineStyle(Color color) => OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.34)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusInner),
        ),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Debug details
// ─────────────────────────────────────────────────────────────────────────────

class _DebugDetailsSection extends StatelessWidget {
  const _DebugDetailsSection({
    required this.definition,
    required this.unlock,
    required this.color,
  });

  final CosmeticDefinition definition;
  final UnlockedCosmetic? unlock;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(Tokens.radiusInner),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Row(
            children: [
              Icon(Icons.bug_report_outlined,
                  size: 13, color: color.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              Text(
                'DEBUG DETAILS',
                style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: Tokens.fontSizeCaption,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          children: [
            _DebugRow('id', definition.id, copyable: true),
            _DebugRow('type', definition.type.name),
            _DebugRow('rarity', definition.rarity.name),
            _DebugRow('region', definition.region.name),
            _DebugRow(
              'assetKey',
              definition.assetKey ?? '— missing',
              warn: definition.assetKey == null,
              copyable: definition.assetKey != null,
            ),
            if (definition.previewAssetKey != null &&
                definition.previewAssetKey != definition.assetKey)
              _DebugRow('previewAssetKey', definition.previewAssetKey!,
                  copyable: true),
            _DebugRow('nameKey', definition.nameKey, copyable: true),
            _DebugRow('descriptionKey', definition.descriptionKey,
                copyable: true),
            if (definition.unlockHintKey != null)
              _DebugRow('unlockHintKey', definition.unlockHintKey!,
                  copyable: true),
            _DebugRow('sortOrder', '${definition.sortOrder}'),
            _DebugRow(
              'isPremium',
              '${definition.isPremium}',
              warn: definition.isPremium,
            ),
            _DebugRow(
              'isEnabled',
              '${definition.isEnabled}',
              warn: !definition.isEnabled,
            ),
            if (definition.metadata.isNotEmpty)
              _DebugRow('metadata', _fmtMap(definition.metadata)),
            if (unlock != null) ...[
              const Divider(height: 14, thickness: 1),
              _DebugRow(
                'unlockedAt',
                unlock!.unlockedAt.toIso8601String(),
              ),
              if (unlock!.sourceType != null)
                _DebugRow('sourceType', unlock!.sourceType!),
              if (unlock!.sourceId != null)
                _DebugRow('sourceId', unlock!.sourceId!),
            ],
          ],
        ),
      ),
    );
  }

  static String _fmtMap(Map<String, Object?> map) {
    if (map.isEmpty) return '{}';
    final entries =
        map.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    return '{ $entries }';
  }
}

class _DebugRow extends StatelessWidget {
  const _DebugRow(
    this.label,
    this.value, {
    this.warn = false,
    this.copyable = false,
  });

  final String label;
  final String value;
  final bool warn;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final valueColor = warn
        ? Colors.orange.withValues(alpha: 0.9)
        : cs.onSurfaceVariant.withValues(alpha: 0.75);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: TextStyle(
                color: cs.onSurfaceVariant.withValues(alpha: 0.45),
                fontSize: 10,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onLongPress: copyable
                  ? () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Zkopírováno: $value'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  : null,
              child: Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 10,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (copyable)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Zkopírováno: $value'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.copy_rounded,
                  size: 10,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Unlock conditions
// ─────────────────────────────────────────────────────────────────────────────

class _UnlockConditionsSection extends StatelessWidget {
  const _UnlockConditionsSection({
    required this.rules,
    required this.color,
  });

  final List<CosmeticUnlockRule> rules;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lock_open_rounded,
                size: 13, color: color.withValues(alpha: 0.8)),
            const SizedBox(width: 5),
            Text(
              'PODMÍNKY ODEMČENÍ',
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: Tokens.fontSizeCaption,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (int i = 0; i < rules.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '— nebo —',
                style: tt.bodySmall?.copyWith(
                  color: color.withValues(alpha: 0.4),
                  fontSize: Tokens.fontSizeMicro,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          _RuleBlock(rule: rules[i], color: color),
        ],
      ],
    );
  }
}

class _RuleBlock extends StatelessWidget {
  const _RuleBlock({required this.rule, required this.color});

  final CosmeticUnlockRule rule;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'source: ${rule.sourceType} / ${rule.sourceId}',
            style: tt.bodySmall?.copyWith(
              color: color.withValues(alpha: 0.6),
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 6),
          for (final cond in rule.conditions)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_box_outline_blank_rounded,
                      size: 11,
                      color: color.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      cond.id
                          .replaceAll('_at_least_', ' ≥ ')
                          .replaceAll('_', ' '),
                      style: tt.bodySmall?.copyWith(
                        color: color.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared button widgets
// ─────────────────────────────────────────────────────────────────────────────

class _DevButton extends StatelessWidget {
  const _DevButton({
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
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: busy
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              )
            : Icon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
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
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
