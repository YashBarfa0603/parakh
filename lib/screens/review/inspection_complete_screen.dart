import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../model/report_model.dart';

class InspectionCompleteScreen extends StatelessWidget {
  final ReportModel report;
  const InspectionCompleteScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParakhColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),

              // Success icon
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: ParakhColors.compliantLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: ParakhColors.compliant.withValues(alpha: 0.4),
                        width: 2),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 52,
                      color: ParakhColors.compliant,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Heading
              const Text(
                'INSPECTION FINALIZED',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: ParakhColors.compliant,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Report Sealed & Recorded',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: ParakhColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Inspection ${report.displayId} has been finalized with a '
                'canonical integrity fingerprint under Legal Metrology standards.',
                textAlign: TextAlign.center,
                style: ParakhTypography.body2,
              ),
              const SizedBox(height: 28),

              // Inspection Integrity card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ParakhColors.surface,
                  borderRadius: BorderRadius.circular(ParakhRadius.card),
                  border: Border.all(color: ParakhColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: ParakhColors.shadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: ParakhColors.compliantLight,
                            borderRadius: BorderRadius.circular(ParakhRadius.md),
                          ),
                          child: const Icon(Icons.fingerprint_rounded,
                              size: 18, color: ParakhColors.compliant),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Inspection Integrity',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: ParakhColors.textPrimary,
                              ),
                            ),
                            Text(
                              'SHA-256 digital fingerprint recorded',
                              style: ParakhTypography.caption,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 14),

                    // Inspection SHA-256
                    const Text(
                      'Inspection Canonical SHA-256',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: ParakhColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      report.canonicalHash ?? 'Generated upon finalization',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11,
                        color: ParakhColors.accent,
                        letterSpacing: 0.5,
                      ),
                    ),

                    // Report SHA-256
                    if (report.reportHash != null) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Report PDF SHA-256',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: ParakhColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        report.reportHash!,
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 11,
                          color: ParakhColors.accent,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ParakhColors.veryLightBlue,
                        borderRadius: BorderRadius.circular(ParakhRadius.md),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 13, color: ParakhColors.accent),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'SHA-256 verifies digital artifact integrity. '
                              'It does not determine physical product authenticity.',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: ParakhColors.accent,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Actions
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.viewReport,
                    arguments: report.inspectionId,
                  );
                },
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                label: const Text('View Official PDF Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ParakhColors.accent,
                  foregroundColor: ParakhColors.textOnPrimary,
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ParakhRadius.button),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.shell,
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.home_outlined, size: 18),
                label: const Text('Return to Dashboard'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ParakhColors.textPrimary,
                  side: const BorderSide(color: ParakhColors.border),
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ParakhRadius.button),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
