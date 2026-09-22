import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../model/finding_model.dart';
import 'status_badge.dart';

class FindingCard extends StatelessWidget {
  final FindingModel finding;
  final VoidCallback? onViewEvidence;

  const FindingCard({
    super.key,
    required this.finding,
    this.onViewEvidence,
  });

  @override
  Widget build(BuildContext context) {
    Color leftBorderColor;
    switch (finding.status) {
      case ComplianceStatus.compliant:
        leftBorderColor = ParakhColors.compliant;
        break;
      case ComplianceStatus.nonCompliant:
        leftBorderColor = ParakhColors.nonCompliant;
        break;
      case ComplianceStatus.needsReview:
        leftBorderColor = ParakhColors.needsReview;
        break;
      default:
        leftBorderColor = ParakhColors.textSecondary;
    }

    final ruleTitle = [
      if (finding.ruleNumber != null && finding.ruleNumber!.isNotEmpty) 'Rule ${finding.ruleNumber}',
      if (finding.clause != null && finding.clause!.isNotEmpty) 'Clause ${finding.clause}',
    ].join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ParakhColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ParakhColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Colored status bar on left
              Container(
                width: 5,
                color: leftBorderColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              ruleTitle.isNotEmpty ? ruleTitle : finding.ruleId,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: ParakhColors.accent,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          StatusBadge(
                            status: finding.status,
                            isCompact: true,
                          ),
                        ],
                      ),
                      SelectableText(
                        finding.formattedLine,
                        style: TextStyle(
                          fontFamily: 'RobotoMono',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: finding.isFail
                              ? ParakhColors.nonCompliant
                              : (finding.isReview ? ParakhColors.needsReview : ParakhColors.accent),
                          height: 1.4,
                        ),
                      ),
                      if (finding.evidence != null && finding.evidence!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: ParakhColors.backgroundDarker,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: ParakhColors.border),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.format_quote_rounded,
                                size: 14,
                                color: ParakhColors.textTertiary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  finding.evidence!,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: ParakhColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (onViewEvidence != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: onViewEvidence,
                            icon: const Icon(Icons.search_rounded, size: 16),
                            label: const Text('View Evidence'),
                            style: TextButton.styleFrom(
                              foregroundColor: ParakhColors.accent,
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
