import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../features/devtools/presentation/devtools_screen.dart';
import '../widgets/settings_widgets.dart';

class SettingsDevToolsSection extends StatelessWidget {
  const SettingsDevToolsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      children: [
        SettingsTile(
          icon: Icons.developer_mode_outlined,
          label: context.l10n.devtoolsTitle,
          showChevron: true,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DevToolsScreen()),
          ),
        ),
      ],
    );
  }
}
