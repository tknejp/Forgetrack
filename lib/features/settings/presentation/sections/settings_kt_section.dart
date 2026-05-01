import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../nutrition/application/kaloricke_tabulky_provider.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../dialogs/settings_dialogs.dart';
import '../widgets/settings_widgets.dart';

class SettingsKtSection extends StatefulWidget {
  const SettingsKtSection({super.key});

  @override
  State<SettingsKtSection> createState() => _SettingsKtSectionState();
}

class _SettingsKtSectionState extends State<SettingsKtSection> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kt = context.watch<KalorickeTabulkyProvider>();

    if (kt.isLoggedIn) {
      return _KtConnectedCard(
        kt: kt,
        onDisconnect: () => _confirmDisconnect(context, kt),
      );
    }

    return _KtLoginCard(
      kt: kt,
      emailController: _emailController,
      passwordController: _passwordController,
      obscurePassword: _obscurePassword,
      onTogglePasswordVisibility: () {
        setState(() => _obscurePassword = !_obscurePassword);
      },
      onSubmit: () => _submit(kt),
    );
  }

  void _submit(KalorickeTabulkyProvider kt) {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      return;
    }

    kt.login(email, password);
  }

  Future<void> _confirmDisconnect(
    BuildContext context,
    KalorickeTabulkyProvider kt,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showSettingsConfirmationDialog(
      context,
      title: l10n.ktDisconnectConfirmTitle,
      message: l10n.ktDisconnectConfirmMessage,
      confirmLabel: l10n.ktDisconnectButton,
      isDestructive: true,
    );

    if (!confirmed || !context.mounted) {
      return;
    }

    await kt.logout();
  }
}

class _KtConnectedCard extends StatelessWidget {
  final KalorickeTabulkyProvider kt;
  final VoidCallback onDisconnect;

  const _KtConnectedCard({
    required this.kt,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();

    final subtitleParts = <String>[
      if (kt.loggedInEmail != null && kt.loggedInEmail!.isNotEmpty)
        kt.loggedInEmail!,
      if (kt.lastSyncedAt != null)
        l10n.ktSyncedAt(DateFormat('HH:mm', locale).format(kt.lastSyncedAt!)),
    ];

    return SettingsCard(
      children: [
        _KtConnectedStatusTile(
          subtitle: subtitleParts.isEmpty ? null : subtitleParts.join('\n'),
          disconnectLabel: l10n.ktDisconnectButton,
          onDisconnect: onDisconnect,
        ),
        if (kt.syncError != null) ...[
          const SettingsTileDivider(indent: 0),
          _KtMessageBox(
            icon: Icons.warning_amber_rounded,
            color: cs.error,
            message: l10n.ktSyncError,
            trailing: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: cs.error,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => kt.refresh(),
              child: Text(
                l10n.ktRetry,
                style: tt.labelSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _KtConnectedStatusTile extends StatelessWidget {
  final String? subtitle;
  final String disconnectLabel;
  final VoidCallback onDisconnect;

  const _KtConnectedStatusTile({
    required this.subtitle,
    required this.disconnectLabel,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return SettingsTile(
      icon: Icons.sync_rounded,
      iconColor: cs.primary,
      iconBackgroundColor: cs.primaryContainer.withValues(alpha: 0.58),
      label: l10n.ktConnectedBadge,
      subtitle: subtitle,
      trailing: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: cs.error,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          minimumSize: const Size(0, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: onDisconnect,
        child: Text(
          disconnectLabel,
          style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _KtLoginCard extends StatelessWidget {
  final KalorickeTabulkyProvider kt;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onSubmit;

  const _KtLoginCard({
    required this.kt,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePasswordVisibility,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Tokens.calories.color.withValues(alpha: 0.11),
            Colors.white.withValues(alpha: 0.025),
          ],
        ),
        borderRadius: BorderRadius.circular(Tokens.radiusCard),
        border: Border.all(
          color: Tokens.calories.color.withValues(alpha: 0.22),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _KtLoginHeader(),
            const SizedBox(height: 14),
            _KtCredentialFields(
              kt: kt,
              emailController: emailController,
              passwordController: passwordController,
              obscurePassword: obscurePassword,
              onTogglePasswordVisibility: onTogglePasswordVisibility,
              onSubmit: onSubmit,
            ),
            if (kt.authError != null) ...[
              const SizedBox(height: 10),
              _KtMessageBox(
                icon: Icons.error_outline,
                color: cs.error,
                message: l10n.ktAuthError,
              ),
            ],
            if (kt.syncError != null && kt.authError == null) ...[
              const SizedBox(height: 10),
              _KtMessageBox(
                icon: Icons.error_outline,
                color: cs.error,
                message: l10n.ktSyncError,
              ),
            ],
            const SizedBox(height: 14),
            _KtLoginButton(
              isLoading: kt.isLoading,
              onSubmit: onSubmit,
              label: l10n.ktLoginButton,
            ),
          ],
        ),
      ),
    );
  }
}

class _KtLoginHeader extends StatelessWidget {
  const _KtLoginHeader();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Tokens.calories.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(Tokens.radiusInner),
            border: Border.all(
              color: Tokens.calories.color.withValues(alpha: 0.24),
            ),
          ),
          child: Icon(
            Icons.restaurant_menu_rounded,
            size: 18,
            color: Tokens.calories.color,
          ),
        ),
        const SizedBox(width: Tokens.spaceMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.ktSectionTitle,
                style: tt.bodyLarge?.copyWith(
                  color: Tokens.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                l10n.ktConnectBody,
                style: tt.bodySmall?.copyWith(
                  color: Tokens.onSurfaceMuted,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KtCredentialFields extends StatelessWidget {
  final KalorickeTabulkyProvider kt;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onSubmit;

  const _KtCredentialFields({
    required this.kt,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePasswordVisibility,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      children: [
        TextField(
          controller: emailController,
          enabled: !kt.isLoading,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: _ktFieldDecoration(
            context,
            label: l10n.ktEmailHint,
            icon: Icons.email_outlined,
          ),
        ),
        const SizedBox(height: Tokens.spaceMd),
        TextField(
          controller: passwordController,
          enabled: !kt.isLoading,
          obscureText: obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          decoration: _ktFieldDecoration(
            context,
            label: l10n.ktPasswordHint,
            icon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: onTogglePasswordVisibility,
            ),
          ),
        ),
      ],
    );
  }
}

class _KtLoginButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onSubmit;
  final String label;

  const _KtLoginButton({
    required this.isLoading,
    required this.onSubmit,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isLoading ? null : onSubmit,
        child: isLoading
            ? SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.onPrimary,
                ),
              )
            : Text(label),
      ),
    );
  }
}

InputDecoration _ktFieldDecoration(
  BuildContext context, {
  required String label,
  required IconData icon,
  Widget? suffixIcon,
}) {
  final cs = Theme.of(context).colorScheme;

  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: cs.surfaceContainerHigh.withValues(alpha: 0.42),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(Tokens.radiusTile),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(Tokens.radiusTile),
      borderSide: BorderSide(color: cs.outlineVariant),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(Tokens.radiusTile),
      borderSide: BorderSide(color: cs.primary),
    ),
    isDense: true,
    prefixIcon: Icon(icon),
    suffixIcon: suffixIcon,
  );
}

class _KtMessageBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;
  final Widget? trailing;

  const _KtMessageBox({
    required this.icon,
    required this.color,
    required this.message,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: color, height: 1.3);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cs.errorContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(Tokens.radiusTile),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: Tokens.spaceSm),
            Expanded(child: Text(message, style: textStyle)),
            if (trailing != null) ...[
              const SizedBox(width: Tokens.spaceSm),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
