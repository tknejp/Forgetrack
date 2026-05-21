import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import 'sentry_bootstrap.dart';
import 'sentry_consent_provider.dart';

/// First-run gate that shows the crash-reporting consent dialog exactly once
/// per install, then defers to its [child] forever after.
///
/// Skipped entirely on dev builds (`SentryBootstrap.isAvailable == false`) so
/// developers never see the prompt. The toggle in Settings remains the way
/// users change their mind later.
class SentryConsentGate extends StatefulWidget {
  const SentryConsentGate({super.key, required this.child});

  final Widget child;

  @override
  State<SentryConsentGate> createState() => _SentryConsentGateState();
}

class _SentryConsentGateState extends State<SentryConsentGate> {
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;

    final consent = context.read<SentryConsentProvider>();
    if (consent.hasSeenDialog || !SentryBootstrap.isAvailable) return;

    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_show(context, consent));
    });
  }

  Future<void> _show(
    BuildContext context,
    SentryConsentProvider consent,
  ) async {
    final l10n = context.l10n;
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.sentryConsentTitle),
          content: Text(l10n.sentryConsentBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.sentryConsentDecline),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.sentryConsentAccept),
            ),
          ],
        );
      },
    );

    await consent.markDialogSeen();
    // Default ON: only act on an explicit "No thanks" — silent dismissal
    // (shouldn't happen with barrierDismissible: false, but defensive) keeps
    // the pre-selected opt-in.
    if (accepted == false) {
      await consent.setEnabled(false);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
