import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../model/image_upload_response.dart';
import '../../services/inspection_service.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/parakh_app_bar.dart';

/// Capture Review Screen
///
/// IMPORTANT — WORKFLOW:
/// This screen is shown AFTER capturing/selecting a single package face.
/// It allows the inspector to:
///   1. Review the captured image
///   2. Confirm/change the face angle
///   3. View SHA-256 image integrity fingerprint
///   4. Upload the image to the backend
///
/// After upload, the inspector returns to the Camera screen to capture more faces.
///
/// OCR / NER / Analysis does NOT start here.
/// Analysis is only triggered when the inspector explicitly taps
/// "Start Analysis" from the image collection review in the Camera screen.
class CaptureReviewScreen extends StatefulWidget {
  final String imagePath;
  final ImageAngle angle;
  final CaptureSource source;
  final int inspectionId;

  const CaptureReviewScreen({
    super.key,
    required this.imagePath,
    required this.angle,
    required this.source,
    required this.inspectionId,
  });

  @override
  State<CaptureReviewScreen> createState() => _CaptureReviewScreenState();
}

class _CaptureReviewScreenState extends State<CaptureReviewScreen> {
  late ImageAngle _selectedAngle;
  bool _isLoading = false;
  String _loadingMessage = '';
  ImageUploadResponse? _uploadResult;
  String? _errorMessage;
  String? _localImageHash;

  @override
  void initState() {
    super.initState();
    _selectedAngle = widget.angle;
    _computeImageHash();
  }

  // SHA-256 from raw bytes
  Future<void> _computeImageHash() async {
    try {
      final file = File(widget.imagePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final digest = sha256.convert(bytes);
        if (mounted) setState(() => _localImageHash = digest.toString());
      }
    } catch (e) {
      debugPrint('SHA-256 computation error: $e');
    }
  }

  // Upload image (SHA-256 already computed above)
  Future<void> _uploadImage() async {
    setState(() {
      _isLoading = true;
      _loadingMessage =
          'Uploading ${_selectedAngle.label} image & recording integrity fingerprint...';
      _errorMessage = null;
    });

    try {
      final res = await InspectionService().uploadImage(
        inspectionId: widget.inspectionId,
        imagePath: widget.imagePath,
        angle: _selectedAngle,
        source: widget.source,
      );
      if (!mounted) return;
      setState(() => _uploadResult = res);
    } catch (e) {
      if (!mounted) return;
      setState(
          () => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Accept face and return to camera
  void _acceptFace() {
    Navigator.of(context).pop({
      'accepted': true,
      'imagePath': widget.imagePath,
      'angle': _selectedAngle,
    });
  }

  // Retake
  void _retake() => Navigator.of(context).pop({'accepted': false});

  @override
  Widget build(BuildContext context) {
    final activeHash = _uploadResult?.sha256 ?? _localImageHash;
    final isUploaded = _uploadResult != null;

    return Scaffold(
      backgroundColor: ParakhColors.background,
      appBar: ParakhAppBar(
        title: 'Review Capture',
        subtitle: '${_selectedAngle.label}  ·  Inspection #${widget.inspectionId}',
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: _loadingMessage,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ParakhSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Preview
              _buildImagePreview(),
              const SizedBox(height: 14),

              // SHA-256 Integrity Banner
              if (activeHash != null) _buildIntegrityBanner(activeHash),
              const SizedBox(height: 12),

              // Upload Error
              if (_errorMessage != null) _buildErrorBanner(),

              // Upload Success Info
              if (isUploaded) _buildUploadedInfo(),

              // Angle Selector (before upload only)
              if (!isUploaded) ...[
                _buildAngleSelector(),
                const SizedBox(height: 16),
              ],

              // Info notice
              _buildWorkflowNotice(),
              const SizedBox(height: 20),

              // Primary Actions
              if (!isUploaded) ...[
                _PrimaryButton(
                  label: 'Confirm & Upload Image',
                  icon: Icons.cloud_upload_outlined,
                  onTap: _uploadImage,
                ),
                const SizedBox(height: 10),
                _SecondaryButton(
                  label: 'Retake / Pick Different Image',
                  icon: Icons.refresh_rounded,
                  onTap: _retake,
                ),
              ] else ...[
                _PrimaryButton(
                  label: 'Accept — Back to Capture',
                  icon: Icons.check_circle_outline_rounded,
                  onTap: _acceptFace,
                  color: ParakhColors.compliant,
                ),
                const SizedBox(height: 10),
                _SecondaryButton(
                  label: 'Retake This Face',
                  icon: Icons.refresh_rounded,
                  onTap: _retake,
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Sub-widgets

  Widget _buildImagePreview() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: ParakhColors.cameraDark,
        borderRadius: BorderRadius.circular(ParakhRadius.xl),
        border: Border.all(color: ParakhColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ParakhRadius.xl),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(widget.imagePath),
              fit: BoxFit.contain,
            ),
            // Source tag
            Positioned(
              top: 10,
              left: 10,
              child: _OverlayPill(
                  label: widget.source.value, icon: Icons.camera_alt_outlined),
            ),
            // Angle tag
            Positioned(
              top: 10,
              right: 10,
              child: _OverlayPill(
                label: _selectedAngle.label,
                icon: Icons.layers_outlined,
                color: ParakhColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntegrityBanner(String hash) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ParakhColors.veryLightBlue,
        borderRadius: BorderRadius.circular(ParakhRadius.lg),
        border: Border.all(color: ParakhColors.softBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_outlined,
                  size: 15, color: ParakhColors.accent),
              SizedBox(width: 6),
              Text(
                '✓  Image Integrity Recorded',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: ParakhColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          SelectableText(
            'SHA-256: $hash',
            style: const TextStyle(
              fontFamily: 'Courier',
              fontSize: 11,
              color: ParakhColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'SHA-256 verifies digital artifact integrity. '
            'It does not determine physical product authenticity.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: ParakhColors.textTertiary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ParakhColors.nonCompliantLight,
          borderRadius: BorderRadius.circular(ParakhRadius.lg),
          border: Border.all(
              color: ParakhColors.nonCompliant.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.error_outline_rounded,
                    color: ParakhColors.nonCompliant, size: 18),
                SizedBox(width: 8),
                Text(
                  'Upload Failed',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ParakhColors.nonCompliant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _errorMessage ?? 'An unexpected error occurred.',
              style: const TextStyle(
                  fontSize: 12, color: ParakhColors.nonCompliant, height: 1.4),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _uploadImage,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded,
                      size: 14, color: ParakhColors.nonCompliant),
                  SizedBox(width: 4),
                  Text(
                    'Retry Upload',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: ParakhColors.nonCompliant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadedInfo() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: ParakhColors.compliantLight,
          borderRadius: BorderRadius.circular(ParakhRadius.lg),
          border: Border.all(
              color: ParakhColors.compliant.withValues(alpha: 0.35)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_rounded,
                color: ParakhColors.compliant, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Image uploaded and integrity fingerprint recorded.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ParakhColors.compliant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAngleSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ParakhColors.surface,
        borderRadius: BorderRadius.circular(ParakhRadius.card),
        border: Border.all(color: ParakhColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Confirm Package Face',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: ParakhColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Select the correct face / angle for this image.',
            style: TextStyle(
                fontSize: 12, color: ParakhColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ImageAngle.front,
              ImageAngle.back,
              ImageAngle.top,
              ImageAngle.bottom,
            ].map((angle) {
              final isSelected = _selectedAngle == angle;
              return GestureDetector(
                onTap: () => setState(() => _selectedAngle = angle),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ParakhColors.accent
                        : ParakhColors.surfaceLight,
                    borderRadius:
                        BorderRadius.circular(ParakhRadius.full),
                    border: Border.all(
                      color: isSelected
                          ? ParakhColors.accent
                          : ParakhColors.border,
                    ),
                  ),
                  child: Text(
                    angle.label.split(' ').first, // "Front", "Back", etc.
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? ParakhColors.textOnPrimary
                          : ParakhColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ParakhColors.surfaceLight,
        borderRadius: BorderRadius.circular(ParakhRadius.lg),
        border: Border.all(color: ParakhColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 15, color: ParakhColors.textTertiary),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'After accepting this face, you will return to the capture screen '
              'to add more package faces. Analysis starts only after you review '
              'all images and tap "Start Analysis".',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: ParakhColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Reusable button widgets

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? ParakhColors.accent,
          foregroundColor: ParakhColors.textOnPrimary,
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
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 17),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: ParakhColors.textPrimary,
          side: const BorderSide(color: ParakhColors.border),
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
    );
  }
}

class _OverlayPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;

  const _OverlayPill(
      {required this.label, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (color ?? ParakhColors.cameraDark).withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(ParakhRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
