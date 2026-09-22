import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/date_utils.dart';
import '../../core/theme.dart';
import '../../model/inspection_model.dart';
import '../../services/inspection_service.dart';
import '../../widgets/loading_overlay.dart';

class InspectionResultScreen extends StatefulWidget {
  final int inspectionId;
  const InspectionResultScreen({super.key, required this.inspectionId});

  @override
  State<InspectionResultScreen> createState() => _InspectionResultScreenState();
}

class _InspectionResultScreenState extends State<InspectionResultScreen> {
  InspectionModel? _inspection;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInspection();
  }

  Future<void> _loadInspection() async {
    setState(() => _isLoading = true);
    try {
      final data = await InspectionService().getInspection(widget.inspectionId);
      if (mounted) {
        setState(() {
          _inspection = data;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  String _formatDate(String? raw) {
    return AppDateUtils.formatDateTime(raw);
  }

  @override
  Widget build(BuildContext context) {
    final item = _inspection;
    final isNonCompliant = item?.complianceStatus == ComplianceStatus.nonCompliant;

    Color heroBg;
    Color iconCircleBg;
    IconData heroIcon;
    String statusTitle;
    String statusSubtitle;

    if (isNonCompliant) {
      heroBg = ParakhColors.nonCompliantLight;
      iconCircleBg = ParakhColors.nonCompliant;
      heroIcon = Icons.close_rounded;
      statusTitle = 'NON-COMPLIANT';
      statusSubtitle = 'One or more statutory declarations violate Legal Metrology requirements.';
    } else if (item?.complianceStatus == ComplianceStatus.needsReview) {
      heroBg = ParakhColors.needsReviewLight;
      iconCircleBg = ParakhColors.needsReview;
      heroIcon = Icons.priority_high_rounded;
      statusTitle = 'NEEDS REVIEW';
      statusSubtitle = 'Borderline or unverified declarations require officer discretion.';
    } else {
      heroBg = ParakhColors.compliantLight;
      iconCircleBg = ParakhColors.compliant;
      heroIcon = Icons.check_rounded;
      statusTitle = 'COMPLIANT';
      statusSubtitle = 'This product meets all applicable Legal Metrology requirements.';
    }

    final productName = item?.productName?.isNotEmpty == true
        ? item!.productName!
        : 'Unknown Product';
    final dateStr = _formatDate(item?.createdAt);
    final inspectionIdStr =
        'INSP-${(item?.id ?? widget.inspectionId).toString().padLeft(5, "0")}';
    final declCount = item?.declarationsCount ?? 0;
    final declarationsCount = '$declCount declaration${declCount == 1 ? '' : 's'} extracted';
    final imgCount = item?.images.length ?? 0;
    final imagesCount = '$imgCount image${imgCount == 1 ? '' : 's'} captured';

    return Scaffold(
      backgroundColor: ParakhColors.surface,
      appBar: AppBar(
        backgroundColor: ParakhColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ParakhColors.accent),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          'Inspection Result',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: ParakhColors.accent,
          ),
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Loading inspection result...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Status Card matching mockup
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: BoxDecoration(
                  color: heroBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: iconCircleBg,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(heroIcon, color: ParakhColors.textOnPrimary, size: 28),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      statusTitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: ParakhColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      statusSubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: ParakhColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Row 1: Extracted Declarations
              _buildNavigationCard(
                icon: Icons.article_outlined,
                iconColor: ParakhColors.compliant,
                title: 'Extracted Declarations',
                subtitle: declarationsCount,
                onTap: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.declarationsReview,
                    arguments: widget.inspectionId,
                  ).then((_) => _loadInspection());
                },
              ),
              const SizedBox(height: 12),

              // Action Row 2: Evidence Images
              _buildNavigationCard(
                icon: Icons.image_outlined,
                iconColor: ParakhColors.accent,
                title: 'Evidence Images',
                subtitle: imagesCount,
                onTap: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.evidenceViewer,
                    arguments: widget.inspectionId,
                  );
                },
              ),
              const SizedBox(height: 24),

              // Product Metadata Box matching mockup
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ParakhColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ParakhColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _metaText('Product', productName),
                    const SizedBox(height: 6),
                    _metaText('Date', dateStr),
                    const SizedBox(height: 6),
                    _metaText('Inspection ID', inspectionIdStr),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Bottom Primary Button: "View Full Report"
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.viewReport,
                      arguments: widget.inspectionId,
                    );
                  },
                  icon: const Icon(Icons.description_outlined, size: 20),
                  label: const Text(
                    'View Full Report',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ParakhColors.accent,
                    foregroundColor: ParakhColors.textOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Bottom Secondary Button: "Back to Home"
              SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.shell,
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ParakhColors.accent,
                    side: const BorderSide(color: ParakhColors.border, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: ParakhColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ParakhColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: ParakhColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: ParakhColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: ParakhColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaText(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: ParakhColors.textSecondary,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600, color: ParakhColors.textPrimary),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}
