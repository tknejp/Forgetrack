import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../domain/social_models.dart';

class EditHandleSheet extends StatefulWidget {
  const EditHandleSheet({super.key, required this.initialHandle});

  final String initialHandle;

  @override
  State<EditHandleSheet> createState() => _EditHandleSheetState();
}

class _EditHandleSheetState extends State<EditHandleSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialHandle);
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  void _save() {
    final normalized = normalizeSocialHandle(_controller.text);
    if (normalized.isEmpty) return;
    Navigator.of(context).pop(normalized);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;
    final normalized = normalizeSocialHandle(_controller.text);
    final canSave = normalized.isNotEmpty;
    final l10n = context.l10n;

    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPad),
        child: Container(
          decoration: BoxDecoration(
            color: Tokens.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.socialEditHandleTitle,
                style: const TextStyle(
                  color: Tokens.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.socialEditHandleDescription,
                style: const TextStyle(
                  color: Tokens.onSurfaceMuted,
                  fontSize: Tokens.fontSizeSmall,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: Tokens.spaceLg),
              TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
                cursorColor: Tokens.accent,
                style: const TextStyle(
                  color: Tokens.onSurface,
                  fontWeight: FontWeight.w800,
                ),
                decoration: InputDecoration(
                  prefixText: '@',
                  prefixStyle: const TextStyle(
                    color: Tokens.accent,
                    fontWeight: FontWeight.w900,
                  ),
                  hintText: 'moje_id',
                  hintStyle: const TextStyle(color: Tokens.onSurfaceFaint),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.045),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Tokens.radiusTile),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Tokens.radiusTile),
                    borderSide: const BorderSide(color: Tokens.accent),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                canSave ? '@$normalized' : l10n.socialEditHandleValidation,
                style: TextStyle(
                  color: canSave ? Tokens.accent : Tokens.onSurfaceFaint,
                  fontSize: Tokens.fontSizeSmall,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _SheetGhostButton(
                      label: l10n.socialCancel,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SheetPrimaryButton(
                      label: l10n.socialSave,
                      enabled: canSave,
                      onTap: _save,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetGhostButton extends StatelessWidget {
  const _SheetGhostButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Tokens.radiusTile),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(Tokens.radiusTile),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Tokens.onSurfaceMuted,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetPrimaryButton extends StatelessWidget {
  const _SheetPrimaryButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(Tokens.radiusTile),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 44,
        decoration: BoxDecoration(
          gradient: enabled
              ? LinearGradient(
                  colors: [
                    Tokens.accent.withValues(alpha: 0.88),
                    Tokens.accent.withValues(alpha: 0.58),
                  ],
                )
              : null,
          color: enabled ? null : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(Tokens.radiusTile),
          border: Border.all(
            color: enabled
                ? Tokens.accent.withValues(alpha: 0.42)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: enabled ? Colors.white : Tokens.onSurfaceFaint,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
