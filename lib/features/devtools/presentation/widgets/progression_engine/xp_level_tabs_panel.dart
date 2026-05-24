import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/theme/design_tokens.dart';
import '../../../../progression_engine/application/progression_engine_provider.dart';

/// Tabbed shell that replaces the three separate XP/Level panels.
/// Behaviour is unchanged per tab — the user wanted them grouped
/// because they're conceptually one knob ("override the profile").
class XpLevelTabsPanel extends StatefulWidget {
  const XpLevelTabsPanel({super.key, required this.isBusy});

  final bool isBusy;

  @override
  State<XpLevelTabsPanel> createState() => _XpLevelTabsPanelState();
}

class _XpLevelTabsPanelState extends State<XpLevelTabsPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        TabBar(
          controller: _tab,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Tokens.cardBorder,
          tabs: const [
            Tab(text: 'Set total'),
            Tab(text: 'Add'),
            Tab(text: 'Set level'),
          ],
        ),
        AnimatedBuilder(
          animation: _tab,
          builder: (_, __) {
            switch (_tab.index) {
              case 0:
                return _SetTotalXpForm(isBusy: widget.isBusy);
              case 1:
                return _AddXpForm(isBusy: widget.isBusy);
              case 2:
              default:
                return _SetLevelForm(isBusy: widget.isBusy);
            }
          },
        ),
      ],
    );
  }
}

class _SetTotalXpForm extends StatefulWidget {
  const _SetTotalXpForm({required this.isBusy});
  final bool isBusy;

  @override
  State<_SetTotalXpForm> createState() => _SetTotalXpFormState();
}

class _SetTotalXpFormState extends State<_SetTotalXpForm> {
  final _controller = TextEditingController();
  bool _applying = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? _parse() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return null;
    final n = int.tryParse(raw);
    return (n == null || n < 0) ? null : n;
  }

  Future<void> _apply() async {
    final xp = _parse();
    if (xp == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ProgressionEngineProvider>();
    setState(() => _applying = true);
    try {
      await provider.devToolsSetTotalXp(xp);
      if (!mounted) return;
      messenger
          .showSnackBar(SnackBar(content: Text('V2 totalXp set to $xp')));
      _controller.clear();
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canApply = !widget.isBusy && !_applying && _parse() != null;
    return _NumericApplyRow(
      hint: 'Wipes ledger, inserts one synthetic XP grant so '
          'profile.totalXp == value.',
      labelText: 'Total XP',
      hintText: 'e.g. 25000',
      buttonText: 'Apply',
      controller: _controller,
      isApplying: _applying,
      canApply: canApply,
      onChanged: () => setState(() {}),
      onApply: _apply,
      enabled: !widget.isBusy && !_applying,
    );
  }
}

class _AddXpForm extends StatefulWidget {
  const _AddXpForm({required this.isBusy});
  final bool isBusy;

  @override
  State<_AddXpForm> createState() => _AddXpFormState();
}

class _AddXpFormState extends State<_AddXpForm> {
  final _controller = TextEditingController();
  bool _applying = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? _parse() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return null;
    final n = int.tryParse(raw);
    return (n == null || n <= 0) ? null : n;
  }

  Future<void> _apply() async {
    final xp = _parse();
    if (xp == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ProgressionEngineProvider>();
    setState(() => _applying = true);
    try {
      await provider.devToolsAddXp(xp);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Granted +$xp XP')));
      _controller.clear();
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canApply = !widget.isBusy && !_applying && _parse() != null;
    return _NumericApplyRow(
      hint: 'Appends a synthetic XP grant on top of the existing '
          'ledger. Triggers a re-evaluation so level-ups fire.',
      labelText: 'XP to add',
      hintText: 'e.g. 500',
      buttonText: 'Add',
      controller: _controller,
      isApplying: _applying,
      canApply: canApply,
      onChanged: () => setState(() {}),
      onApply: _apply,
      enabled: !widget.isBusy && !_applying,
    );
  }
}

class _SetLevelForm extends StatefulWidget {
  const _SetLevelForm({required this.isBusy});
  final bool isBusy;

  @override
  State<_SetLevelForm> createState() => _SetLevelFormState();
}

class _SetLevelFormState extends State<_SetLevelForm> {
  final _controller = TextEditingController();
  bool _applying = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? _parse() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return null;
    final n = int.tryParse(raw);
    return (n == null || n < 1) ? null : n;
  }

  Future<void> _apply() async {
    final level = _parse();
    if (level == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ProgressionEngineProvider>();
    setState(() => _applying = true);
    try {
      await provider.devToolsSetLevel(level);
      if (!mounted) return;
      messenger
          .showSnackBar(SnackBar(content: Text('Set level to $level')));
      _controller.clear();
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canApply = !widget.isBusy && !_applying && _parse() != null;
    return _NumericApplyRow(
      hint: 'Wipes ledger, inserts a synthetic grant equal to '
          'xpRequiredForLevel(level). Lands at the level floor.',
      labelText: 'Target level',
      hintText: 'e.g. 25',
      buttonText: 'Apply',
      controller: _controller,
      isApplying: _applying,
      canApply: canApply,
      onChanged: () => setState(() {}),
      onApply: _apply,
      enabled: !widget.isBusy && !_applying,
    );
  }
}

class _NumericApplyRow extends StatelessWidget {
  const _NumericApplyRow({
    required this.hint,
    required this.labelText,
    required this.hintText,
    required this.buttonText,
    required this.controller,
    required this.isApplying,
    required this.canApply,
    required this.onChanged,
    required this.onApply,
    required this.enabled,
  });

  final String hint;
  final String labelText;
  final String hintText;
  final String buttonText;
  final TextEditingController controller;
  final bool isApplying;
  final bool canApply;
  final VoidCallback onChanged;
  final Future<void> Function() onApply;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hint,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: labelText,
                    hintText: hintText,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: canApply ? onApply : null,
                child: isApplying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(buttonText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
