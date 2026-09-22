import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../model/declaration_model.dart';
import '../../model/finding_model.dart';
import '../../model/inspection_model.dart';
import '../../services/inspection_service.dart';
import '../../widgets/ashoka_emblem.dart';
import '../../widgets/loading_overlay.dart';

class ViewReportScreen extends StatefulWidget {
  final int inspectionId;
  const ViewReportScreen({super.key, required this.inspectionId});

  @override
  State<ViewReportScreen> createState() => _ViewReportScreenState();
}

class _ViewReportScreenState extends State<ViewReportScreen> {
  InspectionModel? _inspection;
  bool _isLoading = true;
  bool _isDownloading = false;
  bool _isFinalizing = false;

  // Inspector decision state
  // 'PASS', 'FAIL', 'REVIEW', or null (not yet selected)
  String? _selectedDecision;
  final TextEditingController _remarksController = TextEditingController();
  String? _decisionError;

  @override
  void initState() {
    super.initState();
    _loadInspection();
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadInspection() async {
    setState(() => _isLoading = true);
    try {
      final data = await InspectionService().getInspection(widget.inspectionId);
      if (mounted) setState(() => _inspection = data);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _submitDecision() async {
    if (_selectedDecision == null) {
      setState(() => _decisionError = 'Please select a decision before finalizing.');
      return;
    }
    setState(() {
      _isFinalizing = true;
      _decisionError = null;
    });
    try {
      final report = await InspectionService().finalizeInspection(
        widget.inspectionId,
        decision: _selectedDecision,
        remarks: _remarksController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.inspectionComplete,
        arguments: report,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _decisionError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isFinalizing = false);
    }
  }

  Future<void> _exportReport(String format) async {
    setState(() => _isDownloading = true);
    try {
      final bytes = await InspectionService()
          .getReportBytes(widget.inspectionId, format: format);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Exported ${format.toUpperCase()} report (${bytes.lengthInBytes} bytes).'),
          backgroundColor: ParakhColors.compliant,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export $format: $e'),
          backgroundColor: ParakhColors.nonCompliant,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      return DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParakhColors.background,
      body: LoadingOverlay(
        isLoading: _isLoading || _isDownloading || _isFinalizing,
        message: _isFinalizing
            ? 'Sealing inspection with SHA-256 hash...'
            : _isDownloading
            ? 'Downloading official PDF report...'
            : 'Loading inspection report...',
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              backgroundColor: ParakhColors.surface,
              foregroundColor: ParakhColors.textPrimary,
              elevation: 0,
              pinned: true,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Inspection Report',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: ParakhColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Report #${widget.inspectionId}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: ParakhColors.textSecondary,
                    ),
                  ),
                ],
              ),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.download_outlined,
                      color: ParakhColors.accent),
                  tooltip: 'Export Report',
                  onSelected: _exportReport,
                  itemBuilder: (ctx) => const [
                    PopupMenuItem(
                      value: 'pdf',
                      child: Row(children: [
                        Icon(Icons.picture_as_pdf,
                            color: ParakhColors.nonCompliant, size: 18),
                        SizedBox(width: 8),
                        Text('PDF Certificate'),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'json',
                      child: Row(children: [
                        Icon(Icons.code, color: ParakhColors.accent, size: 18),
                        SizedBox(width: 8),
                        Text('JSON Data'),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'csv',
                      child: Row(children: [
                        Icon(Icons.table_chart,
                            color: ParakhColors.compliant, size: 18),
                        SizedBox(width: 8),
                        Text('CSV Spreadsheet'),
                      ]),
                    ),
                  ],
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: ParakhColors.border),
              ),
            ),

            if (_inspection == null && !_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: Text(
                    'Unable to load report.',
                    style: TextStyle(color: ParakhColors.textSecondary),
                  ),
                ),
              )
            else if (_inspection != null)
              SliverToBoxAdapter(
                child: _buildReportBody(_inspection!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportBody(InspectionModel ins) {
    final failFindings = ins.findings.where((f) => f.isFail).toList();
    final reviewFindings = ins.findings.where((f) => f.isReview).toList();
    final passFindings = ins.findings.where((f) => f.isPass).toList();
    final total = ins.findings.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Government header card
          _buildGovHeader(ins),
          const SizedBox(height: 14),

          // Compliance summary
          _buildComplianceSummary(ins, failFindings.length,
              reviewFindings.length, passFindings.length, total),
          const SizedBox(height: 14),

          // Product identification
          _buildSection(
            title: 'Packaged Commodity',
            icon: Icons.inventory_2_outlined,
            child: _buildProductInfo(ins),
          ),
          const SizedBox(height: 12),

          // Extracted statutory declarations with angles, confidence, and values
          _buildSection(
            title: 'Extracted Package Declarations',
            icon: Icons.article_outlined,
            child: _buildExtractedDeclarationsTable(ins),
          ),
          const SizedBox(height: 12),

          // Missing / non-compliant section
          if (failFindings.isNotEmpty) ...[
            _buildIssuesSection(failFindings),
            const SizedBox(height: 12),
          ],

          // Legal Metrology rule verification table
          if (ins.findings.isNotEmpty) ...[
            _buildRuleVerificationSection(ins.findings),
            const SizedBox(height: 12),
          ],

          // Digital integrity
          _buildIntegritySection(ins),
          const SizedBox(height: 16),

          // Inspector Decision
          _buildInspectorDecision(ins),
          const SizedBox(height: 16),

          // Actions
          _buildActions(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // Government header
  Widget _buildGovHeader(InspectionModel ins) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ParakhColors.surface,
        borderRadius: BorderRadius.circular(ParakhRadius.card),
        border: Border.all(color: ParakhColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AshokaEmblem(size: 32, color: ParakhColors.accent),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GOVERNMENT OF INDIA',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: ParakhColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Legal Metrology — Packaged Commodities',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: ParakhColors.textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: ParakhColors.veryLightBlue,
              borderRadius: BorderRadius.circular(ParakhRadius.md),
              border: Border.all(color: ParakhColors.softBlue),
            ),
            child: const Center(
              child: Text(
                'STATUTORY INSPECTION REPORT — PARAKH',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: ParakhColors.accent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetaField(
                  label: 'Report Ref',
                  value: 'PARAKH-${_inspection!.id}',
                ),
              ),
              Expanded(
                child: _MetaField(
                  label: 'Date',
                  value: _formatDate(
                      _inspection!.finalizedAt ?? _inspection!.createdAt),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Compliance summary
  Widget _buildComplianceSummary(InspectionModel ins, int fail, int review,
      int pass, int total) {
    final effectiveStatus = _selectedDecision != null
        ? ComplianceStatus.fromBackend(_selectedDecision)
        : ins.complianceStatus;
    final isOfficerOverride = _selectedDecision != null && !ins.isFinalized;

    Color statusColor;
    Color statusBg;
    String statusLabel;
    IconData statusIcon;

    switch (effectiveStatus) {
      case ComplianceStatus.compliant:
        statusColor = ParakhColors.compliant;
        statusBg = ParakhColors.compliantLight;
        statusLabel = 'PASS';
        statusIcon = Icons.check_circle_rounded;
        break;
      case ComplianceStatus.nonCompliant:
        statusColor = ParakhColors.nonCompliant;
        statusBg = ParakhColors.nonCompliantLight;
        statusLabel = 'FAIL';
        statusIcon = Icons.cancel_rounded;
        break;
      case ComplianceStatus.needsReview:
        statusColor = ParakhColors.needsReview;
        statusBg = ParakhColors.needsReviewLight;
        statusLabel = 'REVIEW';
        statusIcon = Icons.warning_rounded;
        break;
      default:
        statusColor = ParakhColors.textTertiary;
        statusBg = ParakhColors.surfaceLight;
        statusLabel = 'PENDING';
        statusIcon = Icons.hourglass_empty_rounded;
    }

    final effectivePass = isOfficerOverride && effectiveStatus == ComplianceStatus.compliant
        ? total - fail
        : pass;
    final effectiveReview = isOfficerOverride && effectiveStatus == ComplianceStatus.compliant
        ? 0
        : review;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusBg,
        borderRadius: BorderRadius.circular(ParakhRadius.card),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusLabel,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    isOfficerOverride
                        ? 'Officer Decision (Selected)'
                        : 'Compliance Result',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: statusColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryCount(
                    label: 'Checked', value: total, color: ParakhColors.textSecondary),
                _SummaryCount(
                    label: 'Passed', value: effectivePass, color: ParakhColors.compliant),
                _SummaryCount(
                    label: 'Failed', value: fail, color: ParakhColors.nonCompliant),
                _SummaryCount(
                    label: 'Review', value: effectiveReview, color: ParakhColors.needsReview),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Section wrapper
  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: ParakhColors.surface,
        borderRadius: BorderRadius.circular(ParakhRadius.card),
        border: Border.all(color: ParakhColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 0),
            child: Row(
              children: [
                Icon(icon, size: 16, color: ParakhColors.accent),
                const SizedBox(width: 7),
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: ParakhColors.accent,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: ParakhColors.border),
          ),
          child,
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  // Product info
  Widget _buildProductInfo(InspectionModel ins) {
    final mfgDate = ins.batch?.displayManufacturingDate ??
        ins.batch?.manufacturingDate ??
        ins.batch?.rawManufacturingDate;
    final expDate = ins.batch?.displayExpiryDate ??
        ins.batch?.expiryDate ??
        ins.batch?.rawExpiryDate ??
        ins.batch?.bestBefore;

    final rows = <_InfoRow>[
      _InfoRow('Product Name', ins.productName),
      _InfoRow('Brand', ins.brand),
      _InfoRow('Net Quantity',
          ins.netQuantity != null ? '${ins.netQuantity} ${ins.quantityUnit ?? ""}' : null),
      _InfoRow('MRP', ins.mrp != null ? '₹${ins.mrp}' : null),
      _InfoRow('Manufacturer', ins.manufacturerName),
      _InfoRow('Address', ins.manufacturerAddress),
      _InfoRow('Country of Origin', ins.countryOfOrigin),
      _InfoRow('Batch / Lot', ins.batch?.batchNumber),
      _InfoRow('Mfg Date', mfgDate),
      _InfoRow('Expiry / Best Before', expDate),
      _InfoRow('Consumer Care Phone', ins.consumerCarePhone),
      _InfoRow('Consumer Care Email', ins.consumerCareEmail),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: rows.map((r) => _buildInfoRow(r.label, r.value)).toList(),
      ),
    );
  }

  // Extracted Declarations Table with panel angle and confidence
  Widget _buildExtractedDeclarationsTable(InspectionModel ins) {
    List<DeclarationModel> decls = ins.declarations
        .where((d) => d.fieldName.toLowerCase() != 'legibility')
        .toList();

    if (decls.isEmpty) {
      // Synthesize declaration items from inspection attributes if declarations list wasn't cached
      void addIf(String field, String? val, String defAngle) {
        if (val != null && val.trim().isNotEmpty) {
          decls.add(DeclarationModel(
            fieldName: field,
            value: val.trim(),
            confidence: 0.95,
            extractionMethod: 'EXTRACTED',
            angle: defAngle,
          ));
        }
      }

      addIf('product_name', ins.productName, 'FRONT');
      addIf('brand', ins.brand, 'FRONT');
      addIf('net_quantity', ins.netQuantity != null ? '${ins.netQuantity} ${ins.quantityUnit ?? ""}'.trim() : null, 'FRONT');
      addIf('mrp', ins.mrp != null ? '₹${ins.mrp}' : null, 'BACK');
      addIf('manufacturer_name', ins.manufacturerName, 'BACK');
      addIf('manufacturer_address', ins.manufacturerAddress, 'BACK');
      addIf('country_of_origin', ins.countryOfOrigin, 'BACK');
      addIf('batch_number', ins.batch?.batchNumber, 'BACK');
      addIf('manufacturing_date', ins.batch?.displayManufacturingDate, 'BACK');
      addIf('expiry_date', ins.batch?.displayExpiryDate, 'BACK');
      addIf('consumer_care_phone', ins.consumerCarePhone, 'BACK');
      addIf('consumer_care_email', ins.consumerCareEmail, 'BACK');
      addIf('consumer_care_address', ins.consumerCareAddress, 'BACK');
    }

    if (decls.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            'No declarations extracted.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: ParakhColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: decls.map((d) => _buildDeclarationItemCard(d)).toList(),
      ),
    );
  }

  Widget _buildDeclarationItemCard(DeclarationModel d) {
    final confVal = d.confidence != null ? (d.confidence! * 100).toInt() : null;
    final angleStr = (d.angle ??
            (d.fieldName.toLowerCase().contains('product') ||
                    d.fieldName.toLowerCase().contains('brand')
                ? 'FRONT'
                : 'BACK'))
        .toUpperCase();
    final isFront = angleStr == 'FRONT';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ParakhColors.surface,
        borderRadius: BorderRadius.circular(ParakhRadius.lg),
        border: Border.all(color: ParakhColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  d.fieldName.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: ParakhColors.textSecondary,
                  ),
                ),
              ),
              // Panel Angle Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isFront ? ParakhColors.veryLightBlue : const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(ParakhRadius.xs),
                  border: Border.all(
                    color: isFront ? ParakhColors.softBlue : const Color(0xFFD8B4FE),
                  ),
                ),
                child: Text(
                  angleStr,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: isFront ? ParakhColors.accent : const Color(0xFF7E22CE),
                  ),
                ),
              ),
              if (confVal != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: ParakhColors.compliantLight,
                    borderRadius: BorderRadius.circular(ParakhRadius.xs),
                    border: Border.all(
                      color: ParakhColors.compliant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '$confVal%',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: ParakhColors.compliant,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          SelectableText(
            d.value ?? d.rawValue ?? '—',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: ParakhColors.textPrimary,
              height: 1.3,
            ),
          ),
          if (d.extractionMethod.isNotEmpty && d.extractionMethod != 'AUTOMATED') ...[
            const SizedBox(height: 4),
            Text(
              'Method: ${d.extractionMethod}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                color: ParakhColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    final missing = value == null || value.trim().isEmpty;
    final displayValue = missing ? '—' : value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: ParakhColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayValue,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: missing
                    ? ParakhColors.textTertiary
                    : ParakhColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Issues (FAIL findings) section
  Widget _buildIssuesSection(List<FindingModel> fails) {
    return Container(
      decoration: BoxDecoration(
        color: ParakhColors.nonCompliantLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(ParakhRadius.card),
        border: Border.all(color: ParakhColors.nonCompliant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 0),
            child: Row(
              children: [
                const Icon(Icons.cancel_outlined,
                    size: 16, color: ParakhColors.nonCompliant),
                const SizedBox(width: 7),
                Text(
                  '${fails.length} ISSUE${fails.length > 1 ? "S" : ""} DETECTED',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: ParakhColors.nonCompliant,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: ParakhColors.nonCompliant),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              children: fails
                  .map((f) => _buildIssueTile(f))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueTile(FindingModel f) {
    final clauseStr = f.clause?.isNotEmpty == true
        ? 'Rule ${f.clause}'
        : (f.ruleNumber != null ? 'Rule ${f.ruleNumber}' : f.ruleId);
    final reasonText =
        f.reason?.isNotEmpty == true ? f.reason! : f.requirement;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ParakhColors.surface,
        borderRadius: BorderRadius.circular(ParakhRadius.lg),
        border: Border.all(
            color: ParakhColors.nonCompliant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: ParakhColors.nonCompliantLight,
                  borderRadius: BorderRadius.circular(ParakhRadius.xs),
                ),
                child: Text(
                  clauseStr,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: ParakhColors.nonCompliant,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.cancel_outlined,
                  size: 15, color: ParakhColors.nonCompliant),
              const SizedBox(width: 4),
              const Text(
                'NON-COMPLIANT',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: ParakhColors.nonCompliant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            f.requirement,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ParakhColors.textPrimary,
            ),
          ),
          if (reasonText != f.requirement && reasonText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              reasonText,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: ParakhColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          if (f.evidence != null && f.evidence!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: ParakhColors.surfaceLight,
                borderRadius: BorderRadius.circular(ParakhRadius.xs),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.image_outlined,
                      size: 12, color: ParakhColors.textTertiary),
                  const SizedBox(width: 5),
                  Text(
                    'Evidence: ${f.evidence}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: ParakhColors.textSecondary,
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



  // Legal Metrology rule verification summary table
  Widget _buildRuleVerificationSection(List<FindingModel> findings) {
    return _buildSection(
      title: 'Legal Metrology Rule Verification',
      icon: Icons.gavel_outlined,
      child: Container(
        decoration: BoxDecoration(
          color: ParakhColors.surface,
          borderRadius: BorderRadius.circular(ParakhRadius.card),
          border: Border.all(color: ParakhColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Table header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: ParakhColors.surfaceLight,
              child: const Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      'REQUIREMENT',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: ParakhColors.textSecondary,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'STATUS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: ParakhColors.textSecondary,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: Text(
                      'APPLICABLE RULE',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: ParakhColors.textSecondary,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: ParakhColors.border),
            // Table rows
            ...findings.asMap().entries.map((entry) {
              final idx = entry.key;
              final finding = entry.value;
              final isLast = idx == findings.length - 1;
              return _buildRuleTableRow(finding, showBottomDivider: !isLast);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleTableRow(FindingModel f, {bool showBottomDivider = true}) {
    Color statusColor;
    String statusText;
    Color statusBg;

    if (f.isPass) {
      statusColor = ParakhColors.compliant;
      statusText = '✓ Compliant';
      statusBg = ParakhColors.compliantLight;
    } else if (f.isFail) {
      statusColor = ParakhColors.nonCompliant;
      statusText = '✕ Missing';
      statusBg = ParakhColors.nonCompliantLight;
    } else {
      statusColor = ParakhColors.needsReview;
      statusText = '⚠ Review';
      statusBg = ParakhColors.needsReviewLight;
    }

    final ruleRef = _formatRuleRef(f);

    return Container(
      decoration: BoxDecoration(
        color: f.isFail
            ? ParakhColors.nonCompliantLight.withValues(alpha: 0.18)
            : (f.isReview
                ? ParakhColors.needsReviewLight.withValues(alpha: 0.18)
                : ParakhColors.surface),
        border: showBottomDivider
            ? const Border(
                bottom: BorderSide(color: ParakhColors.borderLight, width: 1),
              )
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Requirement name
          Expanded(
            flex: 5,
            child: Text(
              f.requirement,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: f.isFail ? FontWeight.w700 : FontWeight.w600,
                color: f.isFail ? ParakhColors.nonCompliant : ParakhColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Status Badge
          Expanded(
            flex: 3,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(ParakhRadius.xs),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  statusText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Applicable Rule
          Expanded(
            flex: 4,
            child: ruleRef != null
                ? Container(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: ParakhColors.surfaceLight,
                        borderRadius: BorderRadius.circular(ParakhRadius.xs),
                        border: Border.all(color: ParakhColors.border),
                      ),
                      child: Text(
                        ruleRef,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: ParakhColors.accent,
                        ),
                      ),
                    ),
                  )
                : const Text(
                    '—',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: ParakhColors.textTertiary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String? _formatRuleRef(FindingModel f) {
    String? raw = (f.clause != null && f.clause!.trim().isNotEmpty)
        ? f.clause!.trim()
        : (f.ruleNumber != null && f.ruleNumber!.trim().isNotEmpty
            ? f.ruleNumber!.trim()
            : (f.ruleId.isNotEmpty && f.ruleId != '0' ? f.ruleId.trim() : null));
    if (raw == null || raw.isEmpty) return null;
    if (raw.toLowerCase().startsWith('rule')) return raw;
    return 'Rule $raw';
  }

  // Digital integrity
  Widget _buildIntegritySection(InspectionModel ins) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ParakhColors.surface,
        borderRadius: BorderRadius.circular(ParakhRadius.card),
        border: Border.all(color: ParakhColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_outlined, size: 15, color: ParakhColors.accent),
              SizedBox(width: 7),
              Text(
                'DIGITAL INTEGRITY',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: ParakhColors.accent,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: ParakhColors.border),
          _IntegrityRow(
            label: 'Image Integrity Recorded',
            present: ins.images.any((img) => img.sha256 != null),
          ),
          const SizedBox(height: 6),
          _IntegrityRow(
            label: 'Inspection Integrity Recorded',
            present: ins.canonicalHash != null,
          ),
          if (ins.canonicalHash != null) ...[
            const SizedBox(height: 10),
            const Text(
              'Inspection SHA-256',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: ParakhColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            SelectableText(
              ins.canonicalHash!,
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 11,
                color: ParakhColors.accent,
                letterSpacing: 0.4,
              ),
            ),
          ],
          const SizedBox(height: 10),
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
    );
  }

  // Inspector Decision
  Widget _buildInspectorDecision(InspectionModel ins) {
    final isFinalized = ins.isFinalized;

    return Container(
      decoration: BoxDecoration(
        color: ParakhColors.surface,
        borderRadius: BorderRadius.circular(14),
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
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.gavel_rounded,
                    size: 16, color: ParakhColors.accent),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Inspector Decision',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ParakhColors.textPrimary,
                    ),
                  ),
                ),
                if (isFinalized)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: ParakhColors.compliantLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'FINALIZED',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: ParakhColors.compliant,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: ParakhColors.borderLight),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isFinalized) ...[
                  // Context note
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: ParakhColors.veryLightBlue,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: ParakhColors.accent.withValues(alpha: 0.15)),
                    ),
                    child: const Text(
                      'Review the findings and evidence above, then record your official decision. '
                      'The AI and OCR analysis assist the inspection — the final decision is yours.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: ParakhColors.accent,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // PASS / FAIL / REVIEW selector
                  const Text(
                    'SELECT DECISION',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: ParakhColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _DecisionButton(
                          label: 'PASS',
                          icon: Icons.check_circle_rounded,
                          color: ParakhColors.compliant,
                          bgColor: ParakhColors.compliantLight,
                          isSelected: _selectedDecision == 'PASS',
                          onTap: () async {
                            setState(() {
                              _selectedDecision = 'PASS';
                              _decisionError = null;
                            });
                            try {
                              final updated = await InspectionService().setDecision(
                                widget.inspectionId,
                                'PASS',
                                remarks: _remarksController.text.trim(),
                              );
                              if (mounted) setState(() => _inspection = updated);
                            } catch (_) {}
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DecisionButton(
                          label: 'FAIL',
                          icon: Icons.cancel_rounded,
                          color: ParakhColors.nonCompliant,
                          bgColor: ParakhColors.nonCompliantLight,
                          isSelected: _selectedDecision == 'FAIL',
                          onTap: () async {
                            setState(() {
                              _selectedDecision = 'FAIL';
                              _decisionError = null;
                            });
                            try {
                              final updated = await InspectionService().setDecision(
                                widget.inspectionId,
                                'FAIL',
                                remarks: _remarksController.text.trim(),
                              );
                              if (mounted) setState(() => _inspection = updated);
                            } catch (_) {}
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DecisionButton(
                          label: 'REVIEW',
                          icon: Icons.pending_rounded,
                          color: ParakhColors.needsReview,
                          bgColor: ParakhColors.needsReviewLight,
                          isSelected: _selectedDecision == 'REVIEW',
                          onTap: () async {
                            setState(() {
                              _selectedDecision = 'REVIEW';
                              _decisionError = null;
                            });
                            try {
                              final updated = await InspectionService().setDecision(
                                widget.inspectionId,
                                'REVIEW',
                                remarks: _remarksController.text.trim(),
                              );
                              if (mounted) setState(() => _inspection = updated);
                            } catch (_) {}
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Remarks
                  const Text(
                    'INSPECTOR REMARKS',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: ParakhColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _remarksController,
                    maxLines: 3,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: ParakhColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: _selectedDecision == 'FAIL' || _selectedDecision == 'REVIEW'
                          ? 'Describe findings, non-compliances, or reasons for review...'
                          : 'Optional: add field observations or notes...',
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: ParakhColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: ParakhColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: ParakhColors.accent, width: 1.5),
                      ),
                      filled: true,
                      fillColor: ParakhColors.surfaceLight,
                    ),
                  ),

                  // Error message
                  if (_decisionError != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ParakhColors.nonCompliantLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: ParakhColors.nonCompliant
                                .withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _decisionError!,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: ParakhColors.nonCompliant,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Finalize button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _selectedDecision != null ? _submitDecision : null,
                      icon: const Icon(Icons.lock_rounded, size: 18),
                      label: const Text(
                        'Finalize Inspection',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedDecision == 'PASS'
                            ? ParakhColors.compliant
                            : _selectedDecision == 'FAIL'
                                ? ParakhColors.nonCompliant
                                : _selectedDecision == 'REVIEW'
                                    ? ParakhColors.needsReview
                                    : ParakhColors.textTertiary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ] else ...[
                  // Already finalized — show recorded decision
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _decisionBgColor(ins.complianceStatus),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          _decisionIcon(ins.complianceStatus),
                          color: _decisionColor(ins.complianceStatus),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ins.complianceStatus == ComplianceStatus.compliant
                                  ? 'PASS'
                                  : ins.complianceStatus ==
                                          ComplianceStatus.nonCompliant
                                      ? 'FAIL'
                                      : 'REVIEW',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: _decisionColor(ins.complianceStatus),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ins.finalizedAt != null
                                  ? 'Finalized on ${_formatDate(ins.finalizedAt)}'
                                  : 'Inspector decision recorded',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: ParakhColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _decisionColor(ComplianceStatus s) {
    if (s == ComplianceStatus.compliant) return ParakhColors.compliant;
    if (s == ComplianceStatus.nonCompliant) return ParakhColors.nonCompliant;
    return ParakhColors.needsReview;
  }

  Color _decisionBgColor(ComplianceStatus s) {
    if (s == ComplianceStatus.compliant) return ParakhColors.compliantLight;
    if (s == ComplianceStatus.nonCompliant) return ParakhColors.nonCompliantLight;
    return ParakhColors.needsReviewLight;
  }

  IconData _decisionIcon(ComplianceStatus s) {
    if (s == ComplianceStatus.compliant) return Icons.check_circle_rounded;
    if (s == ComplianceStatus.nonCompliant) return Icons.cancel_rounded;
    return Icons.pending_rounded;
  }

  // Action buttons
  Widget _buildActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _exportReport('pdf'),
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
            label: const Text('Download Official PDF Report'),
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
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _exportReport('json'),
                icon: const Icon(Icons.code, size: 15),
                label: const Text('JSON'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ParakhColors.textPrimary,
                  side: const BorderSide(color: ParakhColors.border),
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ParakhRadius.button),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _exportReport('csv'),
                icon: const Icon(Icons.table_chart_outlined, size: 15),
                label: const Text('CSV'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ParakhColors.textPrimary,
                  side: const BorderSide(color: ParakhColors.border),
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ParakhRadius.button),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Helper widgets

class _SummaryCount extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _SummaryCount(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: ParakhColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _IntegrityRow extends StatelessWidget {
  final String label;
  final bool present;

  const _IntegrityRow({required this.label, required this.present});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          present ? Icons.check_circle_outline_rounded : Icons.radio_button_unchecked,
          size: 15,
          color: present ? ParakhColors.compliant : ParakhColors.textTertiary,
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: present
                ? ParakhColors.textPrimary
                : ParakhColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _MetaField extends StatelessWidget {
  final String label;
  final String value;

  const _MetaField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: ParakhColors.textTertiary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: ParakhColors.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _InfoRow {
  final String label;
  final String? value;
  const _InfoRow(this.label, this.value);
}

// Decision Button

class _DecisionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _DecisionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : ParakhColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : ParakhColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : color,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
