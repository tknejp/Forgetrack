import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../providers/kaloricke_tabulky_provider.dart';
import '../dialogs/profile_dialogs.dart';

class ProfileKtSection extends StatefulWidget {
  const ProfileKtSection({super.key});

  @override
  State<ProfileKtSection> createState() => _ProfileKtSectionState();
}

class _ProfileKtSectionState extends State<ProfileKtSection> {
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
    final confirmed = await showProfileConfirmationDialog(
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.ktConnectedBadge,
                    style: tt.bodyMedium?.copyWith(color: cs.primary),
                  ),
                ),
              ],
            ),
            if (kt.loggedInEmail != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Text(
                  kt.loggedInEmail!,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ],
            if (kt.lastSyncedAt != null) ...[
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Text(
                  l10n.ktSyncedAt(
                    DateFormat('HH:mm', locale).format(kt.lastSyncedAt!),
                  ),
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ],
            if (kt.syncError != null) ...[
              const SizedBox(height: 8),
              _KtInlineMessage(
                icon: Icons.warning_amber_outlined,
                color: cs.error,
                message: l10n.ktSyncError,
                trailing: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: cs.error,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(48, 32),
                  ),
                  onPressed: () => kt.refresh(),
                  child: Text(l10n.ktRetry, style: tt.labelSmall),
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: cs.error,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                icon: const Icon(Icons.link_off, size: 18),
                label: Text(l10n.ktDisconnectButton),
                onPressed: onDisconnect,
              ),
            ),
          ],
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final l10n = context.l10n;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.ktConnectBody,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              enabled: !kt.isLoading,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.ktEmailHint,
                border: const OutlineInputBorder(),
                isDense: true,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              enabled: !kt.isLoading,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                labelText: l10n.ktPasswordHint,
                border: const OutlineInputBorder(),
                isDense: true,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: onTogglePasswordVisibility,
                ),
              ),
            ),
            if (kt.authError != null) ...[
              const SizedBox(height: 8),
              _KtInlineMessage(
                icon: Icons.error_outline,
                color: cs.error,
                message: l10n.ktAuthError,
              ),
            ],
            if (kt.syncError != null && kt.authError == null) ...[
              const SizedBox(height: 8),
              _KtInlineMessage(
                icon: Icons.error_outline,
                color: cs.error,
                message: l10n.ktSyncError,
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: kt.isLoading ? null : onSubmit,
              child: kt.isLoading
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onPrimary,
                      ),
                    )
                  : Text(l10n.ktLoginButton),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _KtInlineMessage extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;
  final Widget? trailing;

  const _KtInlineMessage({
    required this.icon,
    required this.color,
    required this.message,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle =
        Theme.of(context).textTheme.bodySmall?.copyWith(color: color);

    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Expanded(child: Text(message, style: textStyle)),
        if (trailing != null) trailing!,
      ],
    );
  }
}
