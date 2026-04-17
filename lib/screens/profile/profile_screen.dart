import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../l10n/l10n.dart';
import '../../providers/auth_provider.dart';
import '../../providers/kaloricke_tabulky_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';

// ─── Main screen ──────────────────────────────────────────────────────────────

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.screenProfile)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // ── Auth header ────────────────────────────────────────────────────
          _ProfileHeaderCard(auth: auth),
          const SizedBox(height: 24),

          // ── Preferences ───────────────────────────────────────────────────
          _SectionHeader(l10n.sectionPreferences),
          const SizedBox(height: 6),
          _SettingsCard(children: [
            _LanguageTile(),
            const _TileDivider(),
            _ThemeTile(),
          ]),
          const SizedBox(height: 20),

          // ── Data ──────────────────────────────────────────────────────────
          _SectionHeader(l10n.sectionData),
          const SizedBox(height: 6),
          _SettingsCard(children: [
            _SettingsTile(
              icon: Icons.table_chart_outlined,
              label: l10n.profileExportToSheets,
              showChevron: true,
              onTap: () {}, // TODO: wire up export
            ),
            const _TileDivider(),
            _SettingsTile(
              icon: Icons.delete_sweep_outlined,
              label: l10n.settingsClearCache,
              showChevron: true,
              onTap: () {}, // TODO: clear local data
            ),
          ]),
          const SizedBox(height: 20),

          // ── Kalorické Tabulky ─────────────────────────────────────────────
          _SectionHeader(l10n.ktSectionTitle),
          const SizedBox(height: 6),
          const _KtLoginSection(),
          const SizedBox(height: 20),

          // ── About ─────────────────────────────────────────────────────────
          _SectionHeader(l10n.sectionAbout),
          const SizedBox(height: 6),
          _SettingsCard(children: [
            _SettingsTile(
              icon: Icons.info_outline,
              label: l10n.settingsAppVersion,
              trailingLabel: '1.0.0',
            ),
            const _TileDivider(),
            _SettingsTile(
              icon: Icons.privacy_tip_outlined,
              label: l10n.settingsPrivacy,
              showChevron: true,
              onTap: () {}, // TODO: open URL
            ),
            const _TileDivider(),
            _SettingsTile(
              icon: Icons.article_outlined,
              label: l10n.settingsTerms,
              showChevron: true,
              onTap: () {}, // TODO: open URL
            ),
            const _TileDivider(),
            _SettingsTile(
              icon: Icons.feedback_outlined,
              label: l10n.settingsFeedback,
              showChevron: true,
              onTap: () {}, // TODO: open feedback
            ),
          ]),

          // ── Account / danger zone (signed-in only) ────────────────────────
          if (auth.isSignedIn) ...[
            const SizedBox(height: 20),
            _SectionHeader(l10n.sectionAccount),
            const SizedBox(height: 6),
            _SettingsCard(children: [
              _SignOutTile(),
            ]),
          ],
        ],
      ),
    );
  }
}

// ─── Profile header card ──────────────────────────────────────────────────────

class _ProfileHeaderCard extends StatelessWidget {
  final AuthProvider auth;
  const _ProfileHeaderCard({required this.auth});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (auth.isLoading) return const _HeaderLoading();
    if (auth.isSignedIn) return _HeaderSignedIn(auth: auth);
    return _HeaderSignedOut(auth: auth);
  }
}

// ─── Header: loading ─────────────────────────────────────────────────────────

class _HeaderLoading extends StatelessWidget {
  const _HeaderLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 140,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

// ─── Header: signed in ───────────────────────────────────────────────────────

class _HeaderSignedIn extends StatelessWidget {
  final AuthProvider auth;
  const _HeaderSignedIn({required this.auth});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final user = auth.user!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final badgeBg = isDark ? const Color(0xFF1B3A1B) : const Color(0xFFE8F5E9);
    final badgeBorder = isDark ? const Color(0xFF388E3C) : const Color(0xFFA5D6A7);
    final badgeText = isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);

    return Column(
      children: [
        // Avatar
        CircleAvatar(
          radius: 44,
          backgroundImage:
              user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
          backgroundColor: cs.primaryContainer,
          child: user.photoUrl == null
              ? Icon(Icons.person, size: 44, color: cs.onPrimaryContainer)
              : null,
        ),
        const SizedBox(height: 16),

        // Display name
        Text(
          user.displayName ?? user.email,
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),

        // Email (only if different from display name)
        if (user.displayName != null && user.email.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            user.email,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],

        const SizedBox(height: 14),

        // "Connected with Google" badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: badgeBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _GoogleMark(size: 16),
              const SizedBox(width: 6),
              Text(
                l10n.profileConnectedGoogle,
                style: tt.labelMedium?.copyWith(color: badgeText),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Header: signed out ──────────────────────────────────────────────────────

class _HeaderSignedOut extends StatelessWidget {
  final AuthProvider auth;
  const _HeaderSignedOut({required this.auth});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return Column(
      children: [
        // Placeholder avatar
        CircleAvatar(
          radius: 44,
          backgroundColor: cs.surfaceContainerHigh,
          child: Icon(
            Icons.person_outline,
            size: 44,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),

        Text(
          l10n.profileNotSignedIn,
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        Text(
          l10n.profileSignInBenefit,
          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),

        // Inline error message
        if (auth.error != null) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 15, color: cs.error),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  'Sign-in failed. Please try again.',
                  style: tt.bodySmall?.copyWith(color: cs.error),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 20),

        // Google CTA
        _GoogleSignInButton(
          isLoading: auth.isLoading,
          onPressed:
              auth.isLoading ? null : () => context.read<AuthProvider>().signIn(),
        ),
      ],
    );
  }
}

// ─── Google sign-in button ───────────────────────────────────────────────────

class _GoogleSignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  const _GoogleSignInButton({required this.isLoading, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Theme.of(context).colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        onPressed: onPressed,
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GoogleMark(size: 20),
                  const SizedBox(width: 10),
                  Text(
                    l10n.profileContinueWithGoogle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Google "G" mark ─────────────────────────────────────────────────────────

class _GoogleMark extends StatelessWidget {
  final double size;
  const _GoogleMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleMarkPainter()),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final cx = r, cy = r;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    final paint = Paint()..style = PaintingStyle.fill;

    // Blue — top-right quadrant + right half of top
    paint.color = _blue;
    canvas.drawArc(rect, -1.57, 3.14, true, paint); // right half (−90° → 90°)

    // Red — top-left
    paint.color = _red;
    canvas.drawArc(rect, -2.62, 1.05, true, paint); // ~−150° → −90°

    // Yellow — bottom-left
    paint.color = _yellow;
    canvas.drawArc(rect, 2.09, 1.05, true, paint); // ~120° → 180°

    // Green — bottom-right
    paint.color = _green;
    canvas.drawArc(rect, 1.05, 1.05, true, paint); // ~60° → 120°

    // White circle cut-out (donut hole)
    final holePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r * 0.58, holePaint);

    // Blue horizontal bar for the "G" crossbar
    paint.color = _blue;
    final barTop = cy - r * 0.14;
    final barBottom = cy + r * 0.14;
    canvas.drawRect(
      Rect.fromLTRB(cx - r * 0.04, barTop, cx + r * 0.96, barBottom),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}

// ─── Settings card (grouped tile container) ───────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

// ─── Divider between tiles ────────────────────────────────────────────────────

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 56,
      endIndent: 0,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
    );
  }
}

// ─── Generic settings tile ────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailingLabel;
  final bool showChevron;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailingLabel,
    this.showChevron = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget? trailing;
    if (trailingLabel != null) {
      trailing = Text(
        trailingLabel!,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: cs.onSurfaceVariant),
      );
    } else if (showChevron) {
      trailing = Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant);
    }

    return ListTile(
      leading: Icon(icon, size: 22, color: cs.onSurfaceVariant),
      title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}

// ─── Language selector tile ───────────────────────────────────────────────────

class _LanguageTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final currentCode = localeProvider.locale?.languageCode;

    final options = [
      (null, l10n.languageSystemDefault),
      ('en', l10n.languageEnglish),
      ('cs', l10n.languageCzech),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.language_outlined, size: 22, color: cs.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              l10n.settingsLanguage,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: currentCode,
              isDense: true,
              borderRadius: BorderRadius.circular(12),
              items: options
                  .map((o) => DropdownMenuItem<String?>(
                        value: o.$1,
                        child: Text(o.$2),
                      ))
                  .toList(),
              onChanged: (code) {
                final newLocale = code == null ? null : Locale(code);
                context.read<LocaleProvider>().setLocale(newLocale);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Theme selector tile ──────────────────────────────────────────────────────

class _ThemeTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;

    final options = [
      (ThemeMode.system, l10n.themeSystem),
      (ThemeMode.light, l10n.themeLight),
      (ThemeMode.dark, l10n.themeDark),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.brightness_6_outlined, size: 22, color: cs.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              l10n.settingsTheme,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<ThemeMode>(
              value: themeProvider.mode,
              isDense: true,
              borderRadius: BorderRadius.circular(12),
              items: options
                  .map((o) => DropdownMenuItem<ThemeMode>(
                        value: o.$1,
                        child: Text(o.$2),
                      ))
                  .toList(),
              onChanged: (mode) {
                if (mode != null) context.read<ThemeProvider>().setMode(mode);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Kalorické Tabulky login / connected card ─────────────────────────────────

class _KtLoginSection extends StatefulWidget {
  const _KtLoginSection();

  @override
  State<_KtLoginSection> createState() => _KtLoginSectionState();
}

class _KtLoginSectionState extends State<_KtLoginSection> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kt = context.watch<KalorickeTabulkyProvider>();
    return kt.isLoggedIn ? _buildConnected(context, kt) : _buildLoginForm(context, kt);
  }

  Widget _buildConnected(BuildContext context, KalorickeTabulkyProvider kt) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
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
            // Connected badge row
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

            // Email
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

            // Last synced timestamp
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

            // Sync error
            if (kt.syncError != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.warning_amber_outlined, color: cs.error, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.ktSyncError,
                      style: tt.bodySmall?.copyWith(color: cs.error),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: cs.error,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(48, 32),
                    ),
                    onPressed: () => kt.refresh(),
                    child: Text(l10n.ktRetry, style: tt.labelSmall),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 4),

            // Disconnect button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: cs.error,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                icon: const Icon(Icons.link_off, size: 18),
                label: Text(l10n.ktDisconnectButton),
                onPressed: () => _confirmDisconnect(context, kt),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, KalorickeTabulkyProvider kt) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
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

            // Email field
            TextField(
              controller: _emailCtrl,
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

            // Password field
            TextField(
              controller: _passwordCtrl,
              enabled: !kt.isLoading,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(kt),
              decoration: InputDecoration(
                labelText: l10n.ktPasswordHint,
                border: const OutlineInputBorder(),
                isDense: true,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),

            // Auth error
            if (kt.authError != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.error_outline, color: cs.error, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.ktAuthError,
                      style: tt.bodySmall?.copyWith(color: cs.error),
                    ),
                  ),
                ],
              ),
            ],

            // Network error (distinct from auth error)
            if (kt.syncError != null && kt.authError == null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.error_outline, color: cs.error, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.ktSyncError,
                      style: tt.bodySmall?.copyWith(color: cs.error),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // Login button
            FilledButton(
              onPressed: kt.isLoading ? null : () => _submit(kt),
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

  void _submit(KalorickeTabulkyProvider kt) {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) return;
    kt.login(email, password);
  }

  Future<void> _confirmDisconnect(
    BuildContext context,
    KalorickeTabulkyProvider kt,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.ktDisconnectConfirmTitle),
        content: Text(l10n.ktDisconnectConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.dialogCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.ktDisconnectButton),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await kt.logout();
    }
  }
}

// ─── Sign-out tile with confirmation dialog ───────────────────────────────────

class _SignOutTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return ListTile(
      leading: Icon(Icons.logout, size: 22, color: cs.error),
      title: Text(
        l10n.profileSignOut,
        style: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(color: cs.error, fontWeight: FontWeight.w500),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: () => _confirmSignOut(context),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.profileSignOutConfirmTitle),
        content: Text(l10n.profileSignOutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.dialogCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.profileSignOut),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().signOut();
    }
  }
}
