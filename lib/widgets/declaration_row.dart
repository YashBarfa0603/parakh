import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../model/declaration_model.dart';

class DeclarationRow extends StatelessWidget {
  final DeclarationModel declaration;
  final VoidCallback? onEdit;
  final VoidCallback? onViewEvidence;

  const DeclarationRow({
    super.key,
    required this.declaration,
    this.onEdit,
    this.onViewEvidence,
  });

  String _formatFieldName(String raw) {
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  Color _getConfidenceColor(double? conf) {
    if (conf == null) return ParakhColors.textSecondary;
    if (conf >= 0.85) return ParakhColors.compliant;
    if (conf >= 0.60) return ParakhColors.needsReview;
    return ParakhColors.nonCompliant;
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = declaration.value != null && declaration.value!.trim().isNotEmpty;
    final confPct = declaration.confidence != null
        ? '${(declaration.confidence! * 100).toInt()}%'
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ParakhColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: declaration.isEdited ? ParakhColors.accentGold : ParakhColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        _formatFieldName(declaration.fieldName),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ParakhColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (declaration.isEdited) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: ParakhColors.accentGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'MODIFIED',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: ParakhColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (confPct != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(declaration.confidence).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    confPct,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _getConfidenceColor(declaration.confidence),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  hasValue ? declaration.value! : 'Not Detected / Missing',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: hasValue ? ParakhColors.textPrimary : ParakhColors.nonCompliant,
                    fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ),
              if (onViewEvidence != null && declaration.evidenceText != null)
                IconButton(
                  icon: const Icon(Icons.search_rounded, size: 18, color: ParakhColors.accent),
                  onPressed: onViewEvidence,
                  tooltip: 'View Source Evidence',
                  visualDensity: VisualDensity.compact,
                ),
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: ParakhColors.textPrimary),
                  onPressed: onEdit,
                  tooltip: 'Edit Value',
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
