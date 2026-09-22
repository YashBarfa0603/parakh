import 'package:flutter/material.dart';
import '../core/date_utils.dart';
import '../core/theme.dart';
import '../model/inspection_model.dart';
import 'status_badge.dart';

class InspectionListTile extends StatelessWidget {
  final InspectionModel inspection;
  final VoidCallback onTap;

  const InspectionListTile({
    super.key,
    required this.inspection,
    required this.onTap,
  });

  String _formatDate(String? rawDate) {
    return AppDateUtils.formatDateTime(rawDate, fallback: 'Recent');
  }

  @override
  Widget build(BuildContext context) {
    final title = inspection.productName?.isNotEmpty == true
        ? inspection.productName!
        : 'Inspection ${inspection.displayId}';
    final subtitle = [
      if (inspection.brand != null && inspection.brand!.isNotEmpty) inspection.brand,
      if (inspection.category != null && inspection.category!.isNotEmpty) inspection.category,
    ].join(' • ');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: ParakhColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: ParakhColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: ParakhColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(
                    status: inspection.complianceStatus,
                    isCompact: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: ParakhColors.divider),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: ParakhColors.textTertiary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(inspection.createdAt),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: ParakhColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (inspection.declarationsCount > 0) ...[
                        Text(
                          '${inspection.declarationsCount} fields',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: ParakhColors.accent,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 13,
                        color: ParakhColors.textTertiary,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
