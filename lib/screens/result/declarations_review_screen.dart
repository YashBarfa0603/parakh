import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../model/declaration_model.dart';
import '../../services/inspection_service.dart';
import '../../widgets/declaration_row.dart';
import '../../widgets/evidence_viewer.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/parakh_app_bar.dart';

class DeclarationsReviewScreen extends StatefulWidget {
  final int inspectionId;
  const DeclarationsReviewScreen({super.key, required this.inspectionId});

  @override
  State<DeclarationsReviewScreen> createState() => _DeclarationsReviewScreenState();
}

class _DeclarationsReviewScreenState extends State<DeclarationsReviewScreen> {
  List<DeclarationModel> _declarations = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDeclarations();
  }

  Future<void> _loadDeclarations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await InspectionService().getDeclarations(widget.inspectionId);
      if (mounted) {
        setState(() {
          _declarations = list
              .where((d) => d.fieldName.toLowerCase() != 'legibility')
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openEditDialog(DeclarationModel item, int index) {
    final controller = TextEditingController(text: item.value ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${item.fieldName.replaceAll('_', ' ').toUpperCase()}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Correct the statutory value if misread by OCR:',
              style: TextStyle(fontSize: 13, color: ParakhColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Verified Value',
              ),
              autofocus: true,
            ),
            if (item.rawValue != null) ...[
              const SizedBox(height: 10),
              Text(
                'Original OCR Raw Text: "${item.rawValue}"',
                style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: ParakhColors.textTertiary,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newVal = controller.text.trim();
              setState(() {
                _declarations[index] = item.copyWith(
                  value: newVal,
                  extractionMethod: 'MANUAL_OVERRIDE',
                  status: 'VERIFIED',
                );
                _hasChanges = true;
              });
              Navigator.pop(context);
            },
            child: const Text('Apply Edit'),
          ),
        ],
      ),
    );
  }

  void _showEvidenceModal(DeclarationModel item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OCR Evidence: ${item.fieldName.replaceAll('_', ' ').toUpperCase()}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ParakhColors.accent,
              ),
            ),
            const SizedBox(height: 12),
            EvidenceViewer(
              evidenceText: item.evidenceText ?? item.rawValue ?? 'No OCR text available',
              ruleOrField: item.fieldName,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      await InspectionService().updateDeclarations(widget.inspectionId, _declarations);
      if (!mounted) return;
      setState(() => _hasChanges = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Statutory declarations saved and updated successfully.'),
          backgroundColor: ParakhColors.compliant,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save changes: $e'),
          backgroundColor: ParakhColors.nonCompliant,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParakhColors.backgroundDarker,
      appBar: ParakhAppBar(
        title: 'Review Declarations',
        subtitle: 'Rule 6 Verification • Inspection ${InspectionService().getDisplayId(widget.inspectionId)}',
      ),
      body: LoadingOverlay(
        isLoading: _isLoading || _isSaving,
        message: _isSaving ? 'Updating statutory declarations on server...' : 'Loading declarations...',
        child: Column(
          children: [
            // Instructions banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: ParakhColors.surface,
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: ParakhColors.accent),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Tap any declaration to manually correct OCR misreads before final sign-off.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: ParakhColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: ParakhColors.nonCompliantLight,
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: ParakhColors.nonCompliant,
                    fontSize: 13,
                  ),
                ),
              ),

            // Declarations List
            Expanded(
              child: _declarations.isEmpty && !_isLoading
                  ? const Center(
                      child: Text('No declarations extracted for this inspection.'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _declarations.length,
                      itemBuilder: (context, index) {
                        final item = _declarations[index];
                        return DeclarationRow(
                          declaration: item,
                          onEdit: () => _openEditDialog(item, index),
                          onViewEvidence: item.evidenceText != null
                              ? () => _showEvidenceModal(item)
                              : null,
                        );
                      },
                    ),
            ),

            // Bottom Save Bar
            if (_hasChanges)
              Container(
                padding: const EdgeInsets.all(16),
                color: ParakhColors.surface,
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _saveChanges,
                      icon: const Icon(Icons.save_rounded, size: 20),
                      label: const Text('Save Verified Declarations'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ParakhColors.accent,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
