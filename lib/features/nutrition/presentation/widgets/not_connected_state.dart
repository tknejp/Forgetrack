import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/screen_header.dart';

/// Fullscreen empty state shown by [NutritionScreen] only when the user
/// has neither a live KT session nor any cached nutrition. CTA opens
/// the shared `KTLoginSheet` directly (consistent with the home prompt
/// card and the inline reauth banner) instead of routing through
/// Settings.
///
/// Reached in practice only via a corner case (logged-out user wipes
/// cache, then deep-links into the nutrition screen) — the normal home
/// path hides the nutrition slot's entry point when no cache exists,
/// so this widget is also a defensive fallback.
class NotConnectedState extends StatelessWidget {
  const NotConnectedState({super.key, required this.onConnect});

  /// Tapped on the primary CTA. Callers invoke `KTLoginSheet.show` so
  /// this widget stays free of feature-specific routing.
  final VoidCallback onConnect;

  static const Color _ktAccent = Color(0xFF7AB342);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Tokens.bg,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(greeting: '', title: l10n.screenNutrition),
            const SizedBox(height: 60),
            Center(
              child: Column(
                children: [
                  const Text('🍽', style: TextStyle(fontSize: 48)), // lint-ignore: l10n-literal — emoji symbol, locale-invariant
                  const SizedBox(height: Tokens.spaceLg),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      l10n.ktLoginPrompt,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Tokens.onSurfaceMuted,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: Tokens.space2xl),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onConnect,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: _ktAccent.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(Tokens.radiusInner),
                        border: Border.all(
                          color: _ktAccent.withValues(alpha: 0.55),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/icons/kt/kaloricke_tabulky.png',
                            width: 20,
                            height: 20,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.login_rounded,
                              size: 18,
                              color: _ktAccent,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            l10n.ktReauthCta,
                            style: const TextStyle(
                              fontSize: Tokens.fontSizeSmall,
                              fontWeight: FontWeight.w800,
                              color: _ktAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
