import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';

Future<bool> showProfileConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool isDestructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final l10n = dialogContext.l10n;
      final cs = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.dialogCancel),
          ),
          FilledButton(
            style: isDestructive
                ? FilledButton.styleFrom(
                    backgroundColor: cs.error,
                    foregroundColor: cs.onError,
                  )
                : null,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );

  return result ?? false;
}

/// Shows a dialog for editing a single numeric goal value.
///
/// Returns the raw text string entered by the user, or null if cancelled.
/// The [TextEditingController] is owned by the dialog's [State] and disposed
/// only after the dialog widget is fully unmounted — avoiding the
/// "used after dispose" assertion that occurs when disposing in a finally block
/// while the dialog exit animation is still running.
Future<String?> showGoalValueDialog(
  BuildContext context, {
  required String title,
  required String initialText,
  required String unit,
  required bool isDecimal,
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => _GoalValueDialog(
      title: title,
      initialText: initialText,
      unit: unit,
      isDecimal: isDecimal,
    ),
  );
}

// ─── Dialog widget ────────────────────────────────────────────────────────────

class _GoalValueDialog extends StatefulWidget {
  final String title;
  final String initialText;
  final String unit;
  final bool isDecimal;

  const _GoalValueDialog({
    required this.title,
    required this.initialText,
    required this.unit,
    required this.isDecimal,
  });

  @override
  State<_GoalValueDialog> createState() => _GoalValueDialogState();
}

class _GoalValueDialogState extends State<_GoalValueDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    // Disposing here guarantees the controller outlives the TextField — Flutter
    // calls State.dispose() only after the widget is fully removed from the tree,
    // including after any exit animations complete.
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    // Resolve l10n from the dialog's own context, not a captured parent context.
    // Calling dependOnInheritedWidgetOfExactType from outside build on a captured
    // context can corrupt Flutter's dependency tracking.
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(l10n.goalEditTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType:
                TextInputType.numberWithOptions(decimal: widget.isDecimal),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              suffix: Text(widget.unit),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.dialogCancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.goalSave),
        ),
      ],
    );
  }
}
