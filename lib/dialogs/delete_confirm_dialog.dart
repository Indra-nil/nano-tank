import 'package:flutter/material.dart';

/// âœ… DELETE CONFIRMATION DIALOG
class DeleteConfirmDialog extends StatelessWidget {
  final String tankName;
  final VoidCallback onConfirm;

  const DeleteConfirmDialog({
    Key? key,
    required this.tankName,
    required this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ðŸ—‘ï¸ Delete Tank?'),
      content: Text(
        'Are you sure you want to delete "$tankName"?\n\n'
        'This action cannot be undone.',
      ),
      actions: [
        /// âœ… CANCEL BUTTON
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        /// âœ… DELETE BUTTON (RED)
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('âœ… Tank "$tankName" deleted'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}