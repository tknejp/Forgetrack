import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../nutrition/application/kaloricke_tabulky_provider.dart';
import 'onboarding_theme.dart';

/// Bottom-sheet KT login. Built per the welcome onboarding handoff and
/// designed to be reusable from Settings whenever a user reconnects.
///
/// Use via [KTLoginSheet.show]; the sheet is dismissed on success or
/// when the user taps the backdrop / drags down.
class KTLoginSheet extends StatefulWidget {
  const KTLoginSheet({super.key});

  /// Convenience helper. Returns `true` when login succeeded.
  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color.fromRGBO(0, 0, 0, 0.55),
      builder: (_) => const KTLoginSheet(),
    );
  }

  @override
  State<KTLoginSheet> createState() => _KTLoginSheetState();
}

class _KTLoginSheetState extends State<KTLoginSheet> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(_onChanged);
    _passwordCtrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  bool get _ready =>
      _emailCtrl.text.contains('@') && _passwordCtrl.text.length >= 4;

  Future<void> _submit() async {
    if (!_ready) return;
    final kt = context.read<KalorickeTabulkyProvider>();
    await kt.login(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (!mounted) return;
    if (kt.isLoggedIn) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final kt = context.watch<KalorickeTabulkyProvider>();
    final l10n = context.l10n;
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: OnboardingTheme.sheetGradient,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Color.fromRGBO(167, 139, 250, 0.25)),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          28 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Image.asset(
                  'assets/icons/kt/kaloricke_tabulky.png',
                  width: 44,
                  height: 44,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    width: 44,
                    height: 44,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.welcomeKtSheetTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: OnboardingTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.welcomeKtSheetSubtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color.fromRGBO(245, 243, 255, 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            KTField(
              controller: _emailCtrl,
              hint: l10n.welcomeKtSheetEmailHint,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: 8),
            KTField(
              controller: _passwordCtrl,
              hint: l10n.welcomeKtSheetPasswordHint,
              obscure: _obscure,
              autofillHints: const [AutofillHints.password],
              trailing: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 18,
                  color: const Color.fromRGBO(245, 243, 255, 0.45),
                ),
              ),
            ),
            if (kt.authError != null) ...[
              const SizedBox(height: 8),
              Text(
                kt.authError!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 14),
            _SubmitButton(
              ready: _ready && !kt.isLoading,
              busy: kt.isLoading,
              label: l10n.welcomeKtSheetSubmit,
              onTap: _submit,
            ),
            const SizedBox(height: 10),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  l10n.welcomeKtSheetFootnote,
                  textAlign: TextAlign.center,
                  style: OnboardingTheme.footnote.copyWith(
                    color: OnboardingTheme.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.ready,
    required this.busy,
    required this.label,
    required this.onTap,
  });

  final bool ready;
  final bool busy;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 50,
      decoration: BoxDecoration(
        gradient: ready ? OnboardingTheme.ktCtaGradient : null,
        color: ready ? null : OnboardingTheme.ktTint.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        boxShadow: ready ? OnboardingTheme.ktCtaShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: ready ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: ready
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Styled dark text field used inside the KT login sheet. Border
/// transitions from purple-soft to KT-green on focus.
class KTField extends StatefulWidget {
  const KTField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.obscure = false,
    this.trailing,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? trailing;
  final Iterable<String>? autofillHints;

  @override
  State<KTField> createState() => _KTFieldState();
}

class _KTFieldState extends State<KTField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(11, 15, 30, 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: focused
              ? const Color.fromRGBO(143, 190, 61, 0.55)
              : OnboardingTheme.borderSoft,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              keyboardType: widget.keyboardType,
              obscureText: widget.obscure,
              autofillHints: widget.autofillHints,
              style: const TextStyle(
                fontSize: 14,
                color: OnboardingTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: Color.fromRGBO(245, 243, 255, 0.45),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                isDense: true,
                border: InputBorder.none,
              ),
            ),
          ),
          if (widget.trailing != null) widget.trailing!,
        ],
      ),
    );
  }
}
