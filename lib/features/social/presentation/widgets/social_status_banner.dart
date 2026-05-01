import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';

class SocialStatusBanner extends StatelessWidget {
  const SocialStatusBanner({
    super.key,
    required this.backendReady,
    required this.sessionReady,
    required this.signedIn,
    required this.isSigningIn,
    required this.error,
    this.onSignIn,
  });

  final bool backendReady;
  final bool sessionReady;
  final bool signedIn;
  final bool isSigningIn;
  final String error;
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final String message;
    final Color color;

    if (!signedIn) {
      message = l10n.socialStatusSignInRequired;
      color = const Color(0xFFF59E0B);
    } else if (!backendReady) {
      message = l10n.socialStatusBackendUnavailable(error);
      color = const Color(0xFFEF4444);
    } else if (!sessionReady) {
      message = l10n.socialStatusConnecting;
      color = const Color(0xFF6B7280);
    } else {
      message = l10n.socialStatusError(error);
      color = const Color(0xFFEF4444);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color.withValues(alpha: 0.15),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!signedIn)
            TextButton(
              onPressed: onSignIn,
              style: TextButton.styleFrom(
                foregroundColor: color,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                isSigningIn
                    ? l10n.authSigningIn
                    : l10n.profileContinueWithGoogle,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
