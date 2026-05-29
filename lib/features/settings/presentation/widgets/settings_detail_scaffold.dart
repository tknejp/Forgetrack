import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/ft_back_button.dart';
import '../../../../shared/widgets/screen_header.dart';

/// Shared chrome for a single settings category page reached from the settings
/// hub. Mirrors the export screens: transparent status bar, [Tokens.bg]
/// background, a [ScreenHeader] with a back button, then the category content.
class SettingsDetailScaffold extends StatelessWidget {
  const SettingsDetailScaffold({
    super.key,
    required this.title,
    required this.children,
  });

  /// Category title shown in the header (reuses the section title strings).
  final String title;

  /// Body content below the header — typically a single settings section.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Tokens.bg,
      ),
      child: Scaffold(
        backgroundColor: Tokens.bg,
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            14,
            MediaQuery.of(context).padding.top + 12,
            14,
            32,
          ),
          children: [
            ScreenHeader(
              greeting: l10n.settingsSection,
              title: title,
              leading: const FtBackButton(),
            ),
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }
}
