import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/screen_header.dart';

class NotConnectedState extends StatelessWidget {
  const NotConnectedState({super.key, required this.onConnect});

  final VoidCallback onConnect;

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
                  Text(
                    l10n.ktLoginPrompt,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Tokens.onSurfaceMuted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: Tokens.space2xl),
                  GestureDetector(
                    onTap: onConnect,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Tokens.accent,
                        borderRadius: BorderRadius.circular(Tokens.radiusInner),
                      ),
                      child: Text(
                        l10n.ktGoToSettings,
                        style: const TextStyle(
                          fontSize: Tokens.fontSizeBody,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
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
