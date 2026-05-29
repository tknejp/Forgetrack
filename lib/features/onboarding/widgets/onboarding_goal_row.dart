import 'package:flutter/material.dart';

import 'kt_login_sheet.dart' show KTField;
import 'onboarding_theme.dart';

/// Grouped goal-editing card for the onboarding steps (#135 / #98).
///
/// Renders a list of [OnboardingGoalRow]s inside a single dark
/// surface-card with hairline dividers — the compact counterpart to the
/// Settings goals section, themed for the dark welcome flow rather than
/// the light Material settings screen.
class OnboardingGoalGroup extends StatelessWidget {
  const OnboardingGoalGroup({super.key, required this.rows});

  final List<OnboardingGoalRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: OnboardingTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OnboardingTheme.borderSoft),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: 14,
                endIndent: 14,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            rows[i],
          ],
        ],
      ),
    );
  }
}

/// Tap-to-edit goal row. Mirrors `_ChildGoalTile` from the settings goals
/// section (icon + label + value pill + edit affordance) but uses the
/// dark [OnboardingTheme] palette. The trailing pill picks up [tint] so a
/// group of rows scans the same way as the home dashboard accents.
class OnboardingGoalRow extends StatelessWidget {
  const OnboardingGoalRow({
    super.key,
    required this.icon,
    required this.tint,
    required this.label,
    required this.valueText,
    required this.unit,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final Color tint;
  final String label;
  final String valueText;
  final String unit;
  final VoidCallback onTap;

  /// When false the row is dimmed and non-interactive — used when the
  /// nutrition source is KT, so the local fields read as informational.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tint.withValues(alpha: 0.28)),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 17, color: tint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: OnboardingTheme.toggleTitle,
            ),
          ),
          const SizedBox(width: 10),
          _ValuePill(text: '$valueText $unit', tint: tint, enabled: enabled),
        ],
      ),
    );

    final opacity = enabled ? 1.0 : 0.45;
    return Opacity(
      opacity: opacity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: content,
        ),
      ),
    );
  }
}

class _ValuePill extends StatelessWidget {
  const _ValuePill({
    required this.text,
    required this.tint,
    required this.enabled,
  });

  final String text;
  final Color tint;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: tint,
          ),
        ),
        if (enabled) ...[
          const SizedBox(width: 5),
          Icon(
            Icons.edit_outlined,
            size: 14,
            color: OnboardingTheme.textMuted,
          ),
        ],
      ],
    );
  }
}

/// Dark-themed numeric value editor presented as a bottom sheet — the
/// onboarding counterpart to `showGoalValueDialog` (which is a light
/// Material `AlertDialog` and clashes on the dark steps). Returns the
/// trimmed entered text, or null when dismissed.
class OnboardingValueSheet extends StatefulWidget {
  const OnboardingValueSheet({
    super.key,
    required this.title,
    required this.initialText,
    required this.unit,
    required this.isDecimal,
    required this.saveLabel,
  });

  final String title;
  final String initialText;
  final String unit;
  final bool isDecimal;
  final String saveLabel;

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String initialText,
    required String unit,
    required bool isDecimal,
    required String saveLabel,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color.fromRGBO(0, 0, 0, 0.55),
      builder: (_) => OnboardingValueSheet(
        title: title,
        initialText: initialText,
        unit: unit,
        isDecimal: isDecimal,
        saveLabel: saveLabel,
      ),
    );
  }

  @override
  State<OnboardingValueSheet> createState() => _OnboardingValueSheetState();
}

class _OnboardingValueSheetState extends State<OnboardingValueSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: OnboardingTheme.sheetGradient,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Color.fromRGBO(167, 139, 250, 0.25)),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          28 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: OnboardingTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            KTField(
              controller: _controller,
              hint: widget.unit,
              keyboardType: TextInputType.numberWithOptions(
                decimal: widget.isDecimal,
              ),
              trailing: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  widget.unit,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: OnboardingTheme.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SaveButton(label: widget.saveLabel, onTap: _submit),
          ],
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: OnboardingTheme.primaryCtaGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: OnboardingTheme.primaryCtaShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
