import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/ft_back_button.dart';
import '../../../shared/widgets/screen_header.dart';
import '../domain/cosmetic_models.dart';
import 'widgets/cosmetics_inventory_view.dart';

class CosmeticsScreen extends StatelessWidget {
  const CosmeticsScreen({
    super.key,
    this.initialType,
    this.initialFocusId,
    this.devToolsMode = false,
  });

  final CosmeticType? initialType;

  /// Cosmetic id to land on. When set, the screen auto-jumps to the
  /// matching tab and pops the details sheet on first build. Used by
  /// the celebration "Vyzvedni společníka →" CTA so a companion-
  /// availability celebration goes straight to its claim sheet rather
  /// than dropping the player on a generic inventory grid.
  final String? initialFocusId;

  /// When true: shows every catalog item (locked + unlocked), asset-missing
  /// indicators, and passes unlock conditions to the details sheet.
  final bool devToolsMode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Tokens.bg,
      ),
      child: Scaffold(
        backgroundColor: Tokens.bg,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                14,
                MediaQuery.of(context).padding.top + 12,
                14,
                0,
              ),
              child: ScreenHeader(
                greeting: '',
                title: l10n.cosmeticsScreenTitle,
                leading: const FtBackButton(),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: CosmeticsInventoryView(
                initialType: initialType,
                initialFocusId: initialFocusId,
                devToolsMode: devToolsMode,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
