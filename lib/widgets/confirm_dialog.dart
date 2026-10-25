// lib/widgets/confirm_dialog.dart
// Reusable confirmation dialog for delete/cancel actions.

import 'package:flutter/material.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String content,
  String confirmLabel = 'Ya',
  String cancelLabel = 'Batal',
  Color confirmColor = Colors.red,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          // PENTING: pop harus dari context DIALOG (bukan context halaman).
          // Dengan GoRouter + ShellRoute, `Navigator.of(context)` dari halaman
          // me-resolve ke inner navigator shell — mem-pop halaman aktif, bukan
          // dialognya, sehingga stack shell kosong -> assertion crash.
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(cancelLabel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel, style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
  return result ?? false;
}
