import 'package:flutter/material.dart';

import '../../../../shared/theme/design_tokens.dart';

/// Outline style shared by the close / dev-tools close buttons in the
/// cosmetic details sheet. Lifted out of `_CosmeticDetailsSheetState`
/// during the Phase 3 split so the standard-body widget can reuse it
/// without depending on the state class.
ButtonStyle detailsSheetOutlineStyle(Color color) =>
    OutlinedButton.styleFrom(
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

class DevButton extends StatelessWidget {
  const DevButton({
    super.key,
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

class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
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
