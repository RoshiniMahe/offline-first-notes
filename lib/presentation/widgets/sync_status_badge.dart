import 'package:flutter/material.dart';
import 'package:offline_first/domain/entities/note.dart';

class SyncStatusBadge extends StatelessWidget {
  final SyncStatus status;

  const SyncStatusBadge({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String text;
    IconData icon;

    switch (status) {
      case SyncStatus.synced:
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        text = 'Synced';
        icon = Icons.check_circle_outline;
        break;
      case SyncStatus.pendingSync:
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        text = 'Pending';
        icon = Icons.sync;
        break;
      case SyncStatus.conflict:
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        text = 'Conflict';
        icon = Icons.error_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
