import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// A calm, minimal bottom sheet that offers sharing or copying of exported data.
///
/// This component keeps the export UI modular and easy to reuse from
/// different parts of the app without duplicating the share/copy logic.
class ExportOptionsSheet extends StatelessWidget {
  final File file;
  final String content;

  const ExportOptionsSheet({super.key, required this.file, required this.content});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Export ready', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('You can share the file or copy its contents to the clipboard.', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                await Share.shareXFiles([XFile(file.path)], text: 'FocusLog export');
                if (context.mounted) Navigator.of(context).pop();
              },
              icon: const Icon(Icons.share),
              label: const Text('Share file'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: content));
                if (context.mounted) Navigator.of(context).pop();
                if (context.mounted) {
                  final messenger = ScaffoldMessenger.maybeOf(context);
                  if (messenger != null) {
                    messenger.showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
                  }
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy contents'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
