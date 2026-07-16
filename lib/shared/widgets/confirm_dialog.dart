import 'package:flutter/material.dart';

/// Shows an "Are you sure?" confirmation dialog.
///
/// Returns `true` when the user taps the confirm action, `false` otherwise
/// (cancel or dismiss). Uses [confirmLabel] for the confirm button text and
/// [isDestructive] to color it red (e.g. for logout/delete actions).
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String content,
  String confirmLabel = 'Confirm',
  bool isDestructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final confirmColor = isDestructive ? Colors.red : null;
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: confirmColor != null
                ? TextButton.styleFrom(foregroundColor: confirmColor)
                : null,
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
