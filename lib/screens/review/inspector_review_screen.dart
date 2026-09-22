import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../model/inspection_model.dart';
import '../../services/inspection_service.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/parakh_app_bar.dart';

class InspectorReviewScreen extends StatefulWidget {
  final int inspectionId;
  const InspectorReviewScreen({super.key, required this.inspectionId});

  @override
  State<InspectorReviewScreen> createState() => _InspectorReviewScreenState();
}

class _InspectorReviewScreenState extends State<InspectorReviewScreen> {
  InspectionModel? _inspection;
  bool _isLoading = true;
  bool _isFinalizing = false;
  String? _errorMessage;

  bool _chkSampleExamined = true;
  bool _chkDeclarationsVerified = true;
  bool _chkRulesReviewed = true;
  final _remarksController = TextEditingController();

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
      if (mounted) {
        setState(() {
          _inspection = data;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _finalize() async {
    if (!_chkSampleExamined || !_chkDeclarationsVerified || !_chkRulesReviewed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify all inspection checklist affirmations before signing.'),
          backgroundColor: ParakhColors.nonCompliant,
        ),
      );
      return;
    }

    setState(() {
      _isFinalizing = true;
      _errorMessage = null;
    });

    try {
      final report = await InspectionService().finalizeInspection(widget.inspectionId);

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.inspectionComplete,
        arguments: report,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isFinalizing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParakhColors.backgroundDarker,
      appBar: ParakhAppBar(
        title: 'Inspector Sign-Off',
        subtitle: 'Final Decision • Inspection #${widget.inspectionId}',
      ),
      body: LoadingOverlay(
        isLoading: _isLoading || _isFinalizing,
        message: _isFinalizing
            ? 'Generating cryptographic canonical report and sealing document...'
            : 'Loading inspection overview...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Notice Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ParakhColors.veryLightBlue,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ParakhColors.softBlue),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LEGAL METROLOGY ACT, 2009',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: ParakhColors.accent,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Inspector Sign-Off & Finalization',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: ParakhColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'AI assists the inspection; the inspector performs final verification. Finalizing generates a tamper-evident, cryptographically hashed inspection record and PDF report.',
                      style: TextStyle(fontSize: 12, color: ParakhColors.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_inspection != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ParakhColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ParakhColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined, color: ParakhColors.accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _inspection!.productName ?? 'Product #${_inspection!.id}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            if (_inspection!.brand != null)
                              Text(
                                _inspection!.brand!,
                                style: const TextStyle(fontSize: 12, color: ParakhColors.textSecondary),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        _inspection!.complianceStatus.label,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: ParakhColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ParakhColors.nonCompliantLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ParakhColors.nonCompliant.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: ParakhColors.nonCompliant, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Checklist Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ParakhColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ParakhColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'STATUTORY INSPECTION AFFIRMATIONS',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: ParakhColors.accent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: _chkSampleExamined,
                      onChanged: (val) => setState(() => _chkSampleExamined = val ?? false),
                      title: const Text(
                        'Packaged commodity physical sample examined in field',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: _chkDeclarationsVerified,
                      onChanged: (val) => setState(() => _chkDeclarationsVerified = val ?? false),
                      title: const Text(
                        'Statutory label declarations (MRP, Net Qty, Mfg Date) verified',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: _chkRulesReviewed,
                      onChanged: (val) => setState(() => _chkRulesReviewed = val ?? false),
                      title: const Text(
                        'PCR 2011 rule findings reviewed and validated by officer',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Remarks
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ParakhColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ParakhColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'INSPECTOR REMARKS / FIELD NOTES',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: ParakhColors.accent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _remarksController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Enter any additional field observations, seizure details, or notice recommendations...',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Finalize Button
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _finalize,
                  icon: const Icon(Icons.lock_rounded, size: 20),
                  label: const Text(
                    'Lock & Finalize Inspection Report',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ParakhColors.accent,
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
