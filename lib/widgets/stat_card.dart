import 'package:flutter/material.dart';
import '../core/theme.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
    required this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ParakhColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ParakhColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: ParakhColors.textTertiary,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              count,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: ParakhColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: ParakhColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
