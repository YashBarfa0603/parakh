import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';

class StatusBadge extends StatelessWidget {
  final ComplianceStatus status;
  final bool isCompact;

  const StatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    String label = status.label;

    switch (status) {
      case ComplianceStatus.compliant:
        bg = ParakhColors.compliantLight;
        fg = ParakhColors.compliant;
        icon = Icons.check_circle_rounded;
        break;
      case ComplianceStatus.nonCompliant:
        bg = ParakhColors.nonCompliantLight;
        fg = ParakhColors.nonCompliant;
        icon = Icons.cancel_rounded;
        break;
      case ComplianceStatus.needsReview:
        bg = ParakhColors.needsReviewLight;
        fg = ParakhColors.needsReview;
        icon = Icons.warning_amber_rounded;
        break;
      case ComplianceStatus.pending:
        bg = ParakhColors.pendingLight;
        fg = ParakhColors.textSecondary;
        icon = Icons.hourglass_top_rounded;
        break;
    }

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: fg.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
