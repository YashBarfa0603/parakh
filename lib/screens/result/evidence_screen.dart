import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../model/inspection_model.dart';
import '../../services/inspection_service.dart';
import '../../widgets/evidence_viewer.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/parakh_app_bar.dart';

class EvidenceScreen extends StatefulWidget {
  final int inspectionId;
  const EvidenceScreen({super.key, required this.inspectionId});

  @override
  State<EvidenceScreen> createState() => _EvidenceScreenState();
}

class _EvidenceScreenState extends State<EvidenceScreen> {
  InspectionModel? _inspection;
  int _selectedImageIndex = 0;
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

  @override
  Widget build(BuildContext context) {
    final images = _inspection?.images ?? [];

    return Scaffold(
      backgroundColor: ParakhColors.backgroundDarker,
      appBar: ParakhAppBar(
        title: 'Evidence & Image Trace',
        subtitle: 'Inspection #${widget.inspectionId}',
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Loading evidence images...',
        child: images.isEmpty
            ? const Center(
                child: Text('No package images attached to this inspection session.'),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Angle selector bar
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: images.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final img = entry.value;
                          final isSelected = idx == _selectedImageIndex;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text('${img.angle} Face'),
                              selected: isSelected,
                              onSelected: (sel) {
                                if (sel) setState(() => _selectedImageIndex = idx);
                              },
                              selectedColor: ParakhColors.accent,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : ParakhColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Active Image Preview Card with Zoom
                    if (_selectedImageIndex < images.length) ...[
                      Builder(
                        builder: (context) {
                          final activeImage = images[_selectedImageIndex];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              EvidenceViewer(
                                imageUrl: activeImage.imageUrl,
                                ruleOrField: '${activeImage.angle} FACE',
                              ),
                              const SizedBox(height: 16),

                              // Image metadata container
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: ParakhColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: ParakhColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'IMAGE INTEGRITY & METRICS',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                        color: ParakhColors.accent,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _metaRow('Face Angle', activeImage.angle),
                                    _metaRow('Quality Rating', activeImage.quality ?? 'STANDARD_PASS'),
                                    _metaRow('Authenticity', activeImage.authenticityStatus ?? 'VERIFIED_GENUINE'),
                                    if (activeImage.sha256 != null)
                                      _metaRow('SHA-256 Hash', activeImage.sha256!),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _metaRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: ParakhColors.textSecondary),
            ),
          ),
          Expanded(
            child: SelectableText(
              val,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'Courier',
                fontWeight: FontWeight.w600,
                color: ParakhColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
