import 'package:flutter/material.dart';

import 'onboarding_theme.dart';

/// Tap-and-toggle row used on Step 4 for KT and Notifications.
///
/// Tap behaviour is defined by the caller via [onTap]: KT opens a bottom
/// sheet (or disconnects when on); Notifications flips the OS preference.
/// The row itself only renders state.
class IntegrationToggleRow extends StatelessWidget {
  const IntegrationToggleRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.active,
    required this.onTap,
    this.icon,
    this.iconAsset,
    this.busy = false,
  }) : assert(icon != null || iconAsset != null,
            'IntegrationToggleRow needs either icon or iconAsset');

  final String title;
  final String subtitle;
  final Color tint;
  final bool active;
  final VoidCallback onTap;
  final String? icon;
  final String? iconAsset;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.linear,
      decoration: BoxDecoration(
        gradient: active
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tint.withValues(alpha: 0.13),
                  tint.withValues(alpha: 0.05),
                ],
              )
            : null,
        color: active ? null : OnboardingTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              active ? tint.withValues(alpha: 0.4) : OnboardingTheme.borderSoft,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: busy ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _IconBox(
                  tint: tint,
                  active: active,
                  icon: icon,
                  iconAsset: iconAsset,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: OnboardingTheme.toggleTitle,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: OnboardingTheme.toggleSubtitle.copyWith(
                          color: OnboardingTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (busy)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  _IosToggle(active: active, tint: tint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({
    required this.tint,
    required this.active,
    required this.icon,
    required this.iconAsset,
  });

  final Color tint;
  final bool active;
  final String? icon;
  final String? iconAsset;

  @override
  Widget build(BuildContext context) {
    // Asset icons (brand logos like Kalorické Tabulky) render edge-to-edge
    // with no box outline / fill — the logo carries its own shape. Emoji
    // icons keep the tinted box so they read as a deliberate badge.
    final hasAsset = iconAsset != null;
    return Container(
      width: 38,
      height: 38,
      decoration: hasAsset
          ? null
          : BoxDecoration(
              color: active
                  ? tint.withValues(alpha: 0.13)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active
                    ? tint.withValues(alpha: 0.33)
                    : Colors.white.withValues(alpha: 0.06),
              ),
            ),
      alignment: Alignment.center,
      child: hasAsset
          ? Image.asset(iconAsset!, fit: BoxFit.contain)
          : Text(
              icon!,
              style: const TextStyle(fontSize: 18, height: 1),
            ),
    );
  }
}

/// 42×24 iOS-style switch. Animated 200ms linear on the thumb's left
/// position and the track colour, per the design spec.
class _IosToggle extends StatelessWidget {
  const _IosToggle({required this.active, required this.tint});

  final bool active;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: active ? tint : const Color.fromRGBO(255, 255, 255, 0.10),
        boxShadow: active
            ? [
                BoxShadow(
                  color: tint.withValues(alpha: 0.4),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.linear,
            top: 2,
            left: active ? 20 : 2,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
