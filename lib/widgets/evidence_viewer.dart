import 'package:flutter/material.dart';
import '../core/theme.dart';

class EvidenceViewer extends StatelessWidget {
  final String? imageUrl;
  final String? evidenceText;
  final String? ruleOrField;

  const EvidenceViewer({
    super.key,
    this.imageUrl,
    this.evidenceText,
    this.ruleOrField,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ParakhColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ParakhColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: ParakhColors.backgroundDarker,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.document_scanner_rounded,
                  size: 16,
                  color: ParakhColors.accent,
                ),
                const SizedBox(width: 8),
                Text(
                  ruleOrField != null ? 'EVIDENCE: $ruleOrField' : 'LABEL EVIDENCE & OCR TRACE',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: ParakhColors.accent,
                  ),
                ),
              ],
            ),
          ),

          // Evidence Image if available
          if (imageUrl != null && imageUrl!.isNotEmpty)
            ClipRRect(
              child: SizedBox(
                height: 220,
                width: double.infinity,
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: ParakhColors.borderLight,
                      alignment: Alignment.center,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image_rounded, size: 36, color: ParakhColors.textTertiary),
                          SizedBox(height: 8),
                          Text(
                            'Package image preview unavailable',
                            style: TextStyle(fontSize: 12, color: ParakhColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Extracted text box
          if (evidenceText != null && evidenceText!.isNotEmpty) ...[
            const Divider(height: 1, color: ParakhColors.divider),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Extracted OCR / Raw Text Snippet:',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: ParakhColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ParakhColors.backgroundDarker,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ParakhColors.border),
                    ),
                    child: SelectableText(
                      evidenceText!,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 12,
                        color: ParakhColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
