import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../services/inspection_service.dart';
import '../../widgets/loading_overlay.dart';

// Floating nav height constant
/// Height reserved at the bottom so camera controls never go under the
/// floating nav pill (approx 56 content + 14 top padding + 14 bottom padding).
const double _kFloatingNavReserved = 88.0;

// Captured face record
class _CapturedFace {
  final ImageAngle angle;
  final String imagePath;
  bool uploaded;

  _CapturedFace({
    required this.angle,
    required this.imagePath,
    this.uploaded = false,
  });
}

// Camera permission / init state
enum _CameraState {
  loading,        // Initialising
  ready,          // Live feed available
  permissionDenied,
  permissionPermanentlyDenied,
  unavailable,    // Hardware not available
  error,          // Unknown error
}

// Camera Screen
/// Multi-face image collection for a single inspection.
///
/// WORKFLOW:
///  1. Camera preview → inspector taps CAPTURE → CaptureReviewScreen
///  2. CaptureReviewScreen: SHA-256 + angle confirm + upload → returns accepted face
///  3. Face marked ✓ in the tab strip
///  4. When FRONT captured → "Review Images" CTA appears
///  5. "Review Images" → Collection Review page (inline, same screen)
///  6. "Start Analysis" (on Collection Review) → AnalysisScreen
///
/// OCR/analysis NEVER starts automatically.
class CameraScreen extends StatefulWidget {
  final int? existingInspectionId;
  const CameraScreen({super.key, this.existingInspectionId});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  // Camera
  CameraController? _controller;
  _CameraState _camState = _CameraState.loading;
  String _cameraError = '';
  FlashMode _flashMode = FlashMode.off;

  // UI page
  // false = capture page; true = collection review page
  bool _showCollectionReview = false;

  // Inspection
  int? _activeInspectionId;
  bool _isCreatingInspection = false;
  String _inspectionError = '';

  // Multi-face state
  static const List<ImageAngle> _requiredFaces = [
    ImageAngle.front,
    ImageAngle.back,
    ImageAngle.top,
    ImageAngle.bottom,
  ];
  ImageAngle _selectedFace = ImageAngle.front;
  final Map<ImageAngle, _CapturedFace> _capturedFaces = {};
  bool _isProcessingCapture = false;

  final ImagePicker _picker = ImagePicker();

  // Init
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _activeInspectionId = widget.existingInspectionId;
    _initCamera();
    _preCreateInspection();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _controller;
    if (state == AppLifecycleState.inactive) {
      ctrl?.dispose();
      if (mounted) setState(() => _camState = _CameraState.loading);
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  // Camera initialisation with full error handling
  Future<void> _initCamera() async {
    if (!mounted) return;
    setState(() => _camState = _CameraState.loading);

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _camState = _CameraState.unavailable);
        return;
      }

      // Pick the first back-facing camera (index 0 = standard lens on iOS & Android).
      // Ultra-wide is typically index 1+, so we avoid it by taking the lowest index.
      final backCameras = cameras
          .where((c) => c.lensDirection == CameraLensDirection.back)
          .toList();
      final backCamera = backCameras.isNotEmpty ? backCameras.first : cameras.first;

      final controller = CameraController(
        backCamera,
        ResolutionPreset.max,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      // Dispose any previous controller
      await _controller?.dispose();
      _controller = controller;

      await controller.initialize();

      if (!mounted) return;

      // Set initial flash
      try {
        await controller.setFlashMode(_flashMode);
      } catch (_) {}

      setState(() => _camState = _CameraState.ready);
    } on CameraException catch (e) {
      debugPrint('CameraException: ${e.code} — ${e.description}');
      if (!mounted) return;

      if (e.code == 'CameraAccessDenied' ||
          e.code == 'cameraPermission' ||
          e.code == 'permissionDenied') {
        setState(() => _camState = _CameraState.permissionDenied);
      } else if (e.code == 'CameraAccessDeniedWithoutPrompt' ||
          e.code == 'CameraAccessRestricted') {
        setState(() => _camState = _CameraState.permissionPermanentlyDenied);
      } else {
        setState(() {
          _camState = _CameraState.error;
          _cameraError = e.description ?? e.code;
        });
      }
    } on PlatformException catch (e) {
      debugPrint('PlatformException: ${e.code} — ${e.message}');
      if (!mounted) return;
      if (e.code.toLowerCase().contains('permission') ||
          e.code.toLowerCase().contains('denied')) {
        setState(() => _camState = _CameraState.permissionDenied);
      } else {
        setState(() {
          _camState = _CameraState.error;
          _cameraError = e.message ?? e.code;
        });
      }
    } catch (e) {
      debugPrint('Camera unknown error: $e');
      if (!mounted) return;
      setState(() {
        _camState = _CameraState.error;
        _cameraError = e.toString();
      });
    }
  }

  // Pre-create inspection
  Future<void> _preCreateInspection() async {
    if (_activeInspectionId != null) return;
    try {
      final insp = await InspectionService().createInspection();
      if (mounted) setState(() => _activeInspectionId = insp.id);
    } catch (e) {
      debugPrint('Pre-create deferred: $e');
    }
  }

  Future<int> _ensureInspectionId() async {
    if (_activeInspectionId != null) return _activeInspectionId!;
    if (!mounted) throw Exception('Screen disposed');

    setState(() {
      _isCreatingInspection = true;
      _inspectionError = '';
    });

    Exception? lastErr;
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final insp = await InspectionService().createInspection();
        _activeInspectionId = insp.id;
        if (mounted) setState(() => _isCreatingInspection = false);
        return insp.id;
      } catch (e) {
        lastErr = e is Exception ? e : Exception(e.toString());
        if (attempt < 2) {
          await Future.delayed(Duration(seconds: attempt + 1));
        }
      }
    }
    if (mounted) {
      setState(() {
        _isCreatingInspection = false;
        _inspectionError =
            'Failed to create inspection session. Check server connection.';
      });
    }
    throw lastErr ?? Exception('Failed to create inspection');
  }

  // Capture
  Future<void> _takePicture() async {
    if (_isProcessingCapture) return;
    if (_camState != _CameraState.ready) return;
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (ctrl.value.isTakingPicture) return;

    setState(() => _isProcessingCapture = true);
    try {
      final xfile = await ctrl.takePicture();
      await _navigateToReview(xfile.path, CaptureSource.camera);
    } on CameraException catch (e) {
      _showSnack('Camera error: ${e.description ?? e.code}');
    } catch (e) {
      _showSnack('Capture failed: $e');
    } finally {
      if (mounted) setState(() => _isProcessingCapture = false);
    }
  }

  // Gallery
  Future<void> _pickFromGallery() async {
    try {
      final xfile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
      if (xfile == null) return;
      await _navigateToReview(xfile.path, CaptureSource.gallery);
    } catch (e) {
      _showSnack('Failed to select image: $e');
    }
  }

  // Navigate to CaptureReviewScreen
  Future<void> _navigateToReview(
      String imagePath, CaptureSource source) async {
    try {
      final inspId = await _ensureInspectionId();
      if (!mounted) return;

      final result = await Navigator.of(context).pushNamed(
        AppRoutes.captureReview,
        arguments: {
          'imagePath': imagePath,
          'angle': _selectedFace,
          'source': source,
          'inspectionId': inspId,
        },
      );

      if (result != null && result is Map && result['accepted'] == true) {
        final returnedAngle =
            result['angle'] as ImageAngle? ?? _selectedFace;
        final returnedPath =
            result['imagePath'] as String? ?? imagePath;
        if (mounted) {
          setState(() {
            _capturedFaces[returnedAngle] = _CapturedFace(
              angle: returnedAngle,
              imagePath: returnedPath,
              uploaded: true,
            );
            // Auto-advance to next uncaptured required face
            final next = _requiredFaces.firstWhere(
              (f) => !_capturedFaces.containsKey(f),
              orElse: () => returnedAngle,
            );
            _selectedFace = next;
          });
        }
      }
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Flash
  Future<void> _toggleFlash() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    try {
      final next =
          _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
      await ctrl.setFlashMode(next);
      if (mounted) setState(() => _flashMode = next);
    } catch (_) {}
  }

  // Retake / Delete
  void _retakeFace(ImageAngle angle) {
    setState(() {
      _capturedFaces.remove(angle);
      _selectedFace = angle;
      _showCollectionReview = false;
    });
  }

  void _deleteFace(ImageAngle angle) {
    setState(() => _capturedFaces.remove(angle));
  }

  // Start Analysis
  void _startAnalysis() {
    final inspId = _activeInspectionId;
    if (inspId == null) return;
    Navigator.of(context).pushNamed(
      AppRoutes.analysis,
      arguments: inspId,
    );
  }

  // Helpers
  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  bool get _hasFront => _capturedFaces.containsKey(ImageAngle.front);
  int get _capturedCount => _capturedFaces.length;

  String _faceName(ImageAngle a) {
    switch (a) {
      case ImageAngle.front: return 'Front';
      case ImageAngle.back:  return 'Back';
      case ImageAngle.top:   return 'Top';
      case ImageAngle.bottom: return 'Bottom';
      case ImageAngle.left:  return 'Left';
      case ImageAngle.right: return 'Right';
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isCreatingInspection,
      message: 'Initialising inspection session...',
      child: _showCollectionReview
          ? _CollectionReviewPage(
              capturedFaces: Map.unmodifiable(_capturedFaces),
              requiredFaces: _requiredFaces,
              inspectionId: _activeInspectionId,
              hasFront: _hasFront,
              faceName: _faceName,
              onBack: () => setState(() => _showCollectionReview = false),
              onRetake: _retakeFace,
              onDelete: _deleteFace,
              onStartAnalysis: _startAnalysis,
              onAddMore: () => setState(() => _showCollectionReview = false),
            )
          : _CapturePage(
              camState: _camState,
              cameraError: _cameraError,
              controller: _controller,
              flashMode: _flashMode,
              selectedFace: _selectedFace,
              capturedFaces: Map.unmodifiable(_capturedFaces),
              requiredFaces: _requiredFaces,
              capturedCount: _capturedCount,
              isProcessingCapture: _isProcessingCapture,
              hasFront: _hasFront,
              inspectionError: _inspectionError,
              faceName: _faceName,
              onSelectFace: (f) => setState(() => _selectedFace = f),
              onTakePicture: _takePicture,
              onPickGallery: _pickFromGallery,
              onToggleFlash: _toggleFlash,
              onRetakeFace: _retakeFace,
              onShowReview: () => setState(() => _showCollectionReview = true),
              onRetryCamera: _initCamera,
              onBack: () => Navigator.of(context).maybePop(),
            ),
    );
  }
}

//
// CAPTURE PAGE  (stateless — all state managed by CameraScreen)
//
class _CapturePage extends StatelessWidget {
  final _CameraState camState;
  final String cameraError;
  final CameraController? controller;
  final FlashMode flashMode;
  final ImageAngle selectedFace;
  final Map<ImageAngle, _CapturedFace> capturedFaces;
  final List<ImageAngle> requiredFaces;
  final int capturedCount;
  final bool isProcessingCapture;
  final bool hasFront;
  final String inspectionError;
  final String Function(ImageAngle) faceName;
  final ValueChanged<ImageAngle> onSelectFace;
  final VoidCallback onTakePicture;
  final VoidCallback onPickGallery;
  final VoidCallback onToggleFlash;
  final ValueChanged<ImageAngle> onRetakeFace;
  final VoidCallback onShowReview;
  final VoidCallback onRetryCamera;
  final VoidCallback onBack;

  const _CapturePage({
    required this.camState,
    required this.cameraError,
    required this.controller,
    required this.flashMode,
    required this.selectedFace,
    required this.capturedFaces,
    required this.requiredFaces,
    required this.capturedCount,
    required this.isProcessingCapture,
    required this.hasFront,
    required this.inspectionError,
    required this.faceName,
    required this.onSelectFace,
    required this.onTakePicture,
    required this.onPickGallery,
    required this.onToggleFlash,
    required this.onRetakeFace,
    required this.onShowReview,
    required this.onRetryCamera,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    // Total reserved = floating nav + system nav area
    final controlsBottomPad = _kFloatingNavReserved + bottomPad;

    return Scaffold(
      backgroundColor: ParakhColors.background,
      body: SafeArea(
        bottom: false, // We handle bottom padding manually
        child: Column(
          children: [
            // Header bar
            _buildHeader(context),

            // Face selector tabs
            _buildFaceTabs(),

            // Camera preview — takes all remaining vertical space
            Expanded(
              child: _buildCameraViewfinder(context),
            ),

            // Thumbnail strip
            if (capturedFaces.isNotEmpty) _buildThumbnailStrip(),

            // Inspection error
            if (inspectionError.isNotEmpty) _buildInspectionError(),

            // Camera controls
            // Padding at bottom clears the floating nav bar
            Container(
              color: ParakhColors.surface,
              padding: EdgeInsets.only(bottom: controlsBottomPad),
              child: _buildControls(context),
            ),
          ],
        ),
      ),
    );
  }

  // Header
  Widget _buildHeader(BuildContext context) {
    return Container(
      color: ParakhColors.surface,
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: ParakhColors.textPrimary, size: 18),
                onPressed: onBack,
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Capture Package',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: ParakhColors.textPrimary,
                      ),
                    ),
                    Text(
                      'PARAKH · Legal Metrology Inspection',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: ParakhColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              // Progress pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: capturedCount > 0
                      ? ParakhColors.compliantLight
                      : ParakhColors.surfaceLight,
                  borderRadius: BorderRadius.circular(ParakhRadius.full),
                  border: Border.all(
                    color: capturedCount > 0
                        ? ParakhColors.compliant.withValues(alpha: 0.4)
                        : ParakhColors.border,
                  ),
                ),
                child: Text(
                  '$capturedCount / ${requiredFaces.length} captured',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: capturedCount > 0
                        ? ParakhColors.compliant
                        : ParakhColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          Container(height: 1, color: ParakhColors.border),
        ],
      ),
    );
  }

  // Face selector tabs
  Widget _buildFaceTabs() {
    return Container(
      color: ParakhColors.surface,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: requiredFaces.map((face) {
            final isSelected = selectedFace == face;
            final hasFace = capturedFaces.containsKey(face);
            return GestureDetector(
              onTap: () => onSelectFace(face),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? ParakhColors.accent
                      : (hasFace
                          ? ParakhColors.compliantLight
                          : ParakhColors.surfaceLight),
                  borderRadius:
                      BorderRadius.circular(ParakhRadius.full),
                  border: Border.all(
                    color: isSelected
                        ? ParakhColors.accent
                        : (hasFace
                            ? ParakhColors.compliant.withValues(alpha: 0.4)
                            : ParakhColors.border),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasFace
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 12,
                      color: hasFace
                          ? (isSelected ? Colors.white : ParakhColors.compliant)
                          : (isSelected ? Colors.white : ParakhColors.textTertiary),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      faceName(face),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : (hasFace
                                ? ParakhColors.compliant
                                : ParakhColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Camera viewfinder
  Widget _buildCameraViewfinder(BuildContext context) {
    Widget previewContent;

    switch (camState) {
      case _CameraState.loading:
        previewContent = const _CameraStatusPanel(
          icon: Icons.camera_alt_outlined,
          title: 'Starting Camera...',
          subtitle: 'Initialising camera hardware',
          showSpinner: true,
        );
        break;

      case _CameraState.ready:
        final ctrl = controller;
        if (ctrl == null || !ctrl.value.isInitialized) {
          previewContent = const _CameraStatusPanel(
            icon: Icons.camera_alt_outlined,
            title: 'Starting Camera...',
            subtitle: 'Preparing live feed',
            showSpinner: true,
          );
        } else {
          previewContent = Stack(
            fit: StackFit.expand,
            children: [
              // Live camera feed
              CameraPreview(ctrl),
              // Alignment reticle overlay
              const Center(
                child: CustomPaint(
                  size: Size(200, 200),
                  painter: _ReticlePainter(),
                ),
              ),
              // Face label top pill
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: _OverlayPill(
                    label: 'Capture ${faceName(selectedFace)} Face',
                    icon: Icons.layers_outlined,
                  ),
                ),
              ),
              // Bottom hint
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: _OverlayPill(
                    label: 'Align package within the frame',
                    icon: Icons.crop_free_rounded,
                  ),
                ),
              ),
            ],
          );
        }
        break;

      case _CameraState.permissionDenied:
        previewContent = _PermissionPanel(
          permanent: false,
          onAllow: () => onRetryCamera(),
          onGallery: () => onPickGallery(),
        );
        break;

      case _CameraState.permissionPermanentlyDenied:
        previewContent = _PermissionPanel(
          permanent: true,
          onAllow: () => onRetryCamera(),
          onGallery: () => onPickGallery(),
        );
        break;

      case _CameraState.unavailable:
        previewContent = _CameraStatusPanel(
          icon: Icons.videocam_off_outlined,
          title: 'No Camera Found',
          subtitle: 'No camera hardware detected on this device.',
          action: _StatusAction(
            label: 'Use Gallery Instead',
            onTap: onPickGallery,
          ),
        );
        break;

      case _CameraState.error:
        previewContent = _CameraStatusPanel(
          icon: Icons.error_outline_rounded,
          title: 'Camera Error',
          subtitle: cameraError.isNotEmpty ? cameraError : 'An unexpected camera error occurred.',
          action: _StatusAction(label: 'Retry Camera', onTap: onRetryCamera),
        );
        break;
    }

    return Container(
      color: ParakhColors.cameraDark,
      child: previewContent,
    );
  }

  // Thumbnail strip
  Widget _buildThumbnailStrip() {
    return Container(
      height: 80,
      color: ParakhColors.surfaceLight,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: capturedFaces.values.map((face) {
          final isSelected = face.angle == selectedFace;
          return GestureDetector(
            onTap: () => onSelectFace(face.angle),
            onLongPress: () => onRetakeFace(face.angle),
            child: Container(
              width: 60,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ParakhRadius.md),
                border: Border.all(
                  color: isSelected
                      ? ParakhColors.accent
                      : ParakhColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(ParakhRadius.md - 1),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(face.imagePath), fit: BoxFit.cover),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        color: ParakhColors.cameraOverlay,
                        child: Text(
                          faceName(face.angle),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 3,
                      right: 3,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: ParakhColors.compliant,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            size: 8, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Inspection error
  Widget _buildInspectionError() {
    return Container(
      color: ParakhColors.nonCompliantLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded,
              size: 16, color: ParakhColors.nonCompliant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              inspectionError,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: ParakhColors.nonCompliant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Camera controls
  Widget _buildControls(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // "Review Images" CTA — visible as soon as FRONT is captured
        if (hasFront) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onShowReview,
                icon: const Icon(Icons.fact_check_outlined, size: 18),
                label: Text(
                  'Review Captured Images  ($capturedCount / ${requiredFaces.length})',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ParakhColors.accent,
                  foregroundColor: ParakhColors.textOnPrimary,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(ParakhRadius.button),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],

        // Shutter row — gallery | shutter | flash
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Gallery
              _ControlButton(
                icon: Icons.photo_library_outlined,
                label: 'Gallery',
                color: ParakhColors.textSecondary,
                onTap: onPickGallery,
              ),

              // Shutter — centered, 68px circle
              _ShutterButton(
                isCapturing: isProcessingCapture,
                enabled: camState == _CameraState.ready,
                onTap: onTakePicture,
              ),

              // Flash
              _ControlButton(
                icon: flashMode == FlashMode.torch
                    ? Icons.flash_on_rounded
                    : Icons.flash_off_rounded,
                label: flashMode == FlashMode.torch ? 'On' : 'Flash',
                color: flashMode == FlashMode.torch
                    ? ParakhColors.needsReview
                    : ParakhColors.textSecondary,
                onTap: onToggleFlash,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

//
// COLLECTION REVIEW PAGE  (shown when inspector taps "Review Captured Images")
// This is the ONLY place "Start Analysis" appears.
//
class _CollectionReviewPage extends StatelessWidget {
  final Map<ImageAngle, _CapturedFace> capturedFaces;
  final List<ImageAngle> requiredFaces;
  final int? inspectionId;
  final bool hasFront;
  final String Function(ImageAngle) faceName;
  final VoidCallback onBack;
  final ValueChanged<ImageAngle> onRetake;
  final ValueChanged<ImageAngle> onDelete;
  final VoidCallback onStartAnalysis;
  final VoidCallback onAddMore;

  const _CollectionReviewPage({
    required this.capturedFaces,
    required this.requiredFaces,
    required this.inspectionId,
    required this.hasFront,
    required this.faceName,
    required this.onBack,
    required this.onRetake,
    required this.onDelete,
    required this.onStartAnalysis,
    required this.onAddMore,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final capturedCount = capturedFaces.length;

    return Scaffold(
      backgroundColor: ParakhColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Container(
              color: ParakhColors.surface,
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: ParakhColors.textPrimary),
                    onPressed: onBack,
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Review Captured Images',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: ParakhColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Review all faces before starting analysis',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: ParakhColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: capturedCount >= requiredFaces.length
                          ? ParakhColors.compliantLight
                          : ParakhColors.needsReviewLight,
                      borderRadius:
                          BorderRadius.circular(ParakhRadius.full),
                      border: Border.all(
                        color: capturedCount >= requiredFaces.length
                            ? ParakhColors.compliant.withValues(alpha: 0.4)
                            : ParakhColors.needsReview
                                .withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '$capturedCount / ${requiredFaces.length}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: capturedCount >= requiredFaces.length
                            ? ParakhColors.compliant
                            : ParakhColors.needsReview,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: ParakhColors.border),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    16, 16, 16, _kFloatingNavReserved + bottomPad + 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Info notice
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ParakhColors.veryLightBlue,
                        borderRadius:
                            BorderRadius.circular(ParakhRadius.lg),
                        border:
                            Border.all(color: ParakhColors.softBlue),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 14, color: ParakhColors.accent),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'OCR and compliance evaluation begin ONLY after you tap '
                              '"Start Analysis". Review all images first.',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: ParakhColors.accent,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (inspectionId != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Inspection #$inspectionId',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: ParakhColors.textTertiary,
                          ),
                        ),
                      ),

                    // Face cards
                    ...requiredFaces.map((face) {
                      final captured = capturedFaces[face];
                      return _FaceReviewCard(
                        face: face,
                        captured: captured,
                        faceName: faceName(face),
                        onCapture: () => onRetake(face), // goes back to camera for this face
                        onRetake: () => onRetake(face),
                        onDelete: captured != null
                            ? () => onDelete(face)
                            : null,
                      );
                    }),

                    const SizedBox(height: 20),

                    // Start Analysis — ONLY analysis trigger
                    if (hasFront) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: onStartAnalysis,
                          icon: const Icon(
                              Icons.play_circle_outline_rounded,
                              size: 20),
                          label: const Text('Start Analysis'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ParakhColors.accent,
                            foregroundColor: ParakhColors.textOnPrimary,
                            minimumSize: const Size(0, 54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  ParakhRadius.button),
                            ),
                            textStyle: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Center(
                        child: Text(
                          'OCR extraction and compliance evaluation will begin.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: ParakhColors.textTertiary,
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ParakhColors.needsReviewLight,
                          borderRadius:
                              BorderRadius.circular(ParakhRadius.lg),
                          border: Border.all(
                              color: ParakhColors.needsReview
                                  .withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: ParakhColors.needsReview,
                                size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Capture at least the Front face before starting analysis.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: ParakhColors.needsReview,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: onAddMore,
                      icon: const Icon(Icons.add_a_photo_outlined,
                          size: 17),
                      label: const Text('Add More Faces'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ParakhColors.textPrimary,
                        side: const BorderSide(color: ParakhColors.border),
                        minimumSize: const Size(0, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(ParakhRadius.button),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Face review card
class _FaceReviewCard extends StatelessWidget {
  final ImageAngle face;
  final _CapturedFace? captured;
  final String faceName;
  final VoidCallback onCapture;
  final VoidCallback onRetake;
  final VoidCallback? onDelete;

  const _FaceReviewCard({
    required this.face,
    required this.captured,
    required this.faceName,
    required this.onCapture,
    required this.onRetake,
    this.onDelete,
  });

  String get _faceLabel {
    switch (face) {
      case ImageAngle.front:  return 'Front Face';
      case ImageAngle.back:   return 'Back / Nutrition Label';
      case ImageAngle.top:    return 'Top Lid / Seal';
      case ImageAngle.bottom: return 'Bottom / Expiry / MRP';
      case ImageAngle.left:   return 'Left Side';
      case ImageAngle.right:  return 'Right Side';
    }
  }

  bool get _isRequired =>
      face == ImageAngle.front || face == ImageAngle.back;

  @override
  Widget build(BuildContext context) {
    final hasFace = captured != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ParakhColors.surface,
        borderRadius: BorderRadius.circular(ParakhRadius.card),
        border: Border.all(
          color: hasFace
              ? ParakhColors.compliant.withValues(alpha: 0.3)
              : ParakhColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Thumbnail or placeholder
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: hasFace ? null : ParakhColors.surfaceLight,
              borderRadius: BorderRadius.circular(ParakhRadius.md),
              border: Border.all(
                color: hasFace
                    ? ParakhColors.compliant.withValues(alpha: 0.25)
                    : ParakhColors.border,
              ),
            ),
            child: hasFace
                ? ClipRRect(
                    borderRadius:
                        BorderRadius.circular(ParakhRadius.md - 1),
                    child: Image.file(
                      File(captured!.imagePath),
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(Icons.add_photo_alternate_outlined,
                    color: ParakhColors.textTertiary, size: 24),
          ),
          const SizedBox(width: 12),

          // Label + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _faceLabel,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: ParakhColors.textPrimary,
                        ),
                      ),
                    ),
                    if (_isRequired) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: ParakhColors.needsReviewLight,
                          borderRadius:
                              BorderRadius.circular(ParakhRadius.xs),
                        ),
                        child: const Text(
                          'Required',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: ParakhColors.needsReview,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  hasFace ? '✓ Captured' : 'Not captured',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight:
                        hasFace ? FontWeight.w600 : FontWeight.w400,
                    color: hasFace
                        ? ParakhColors.compliant
                        : ParakhColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),

          // Actions
          if (hasFace) ...[
            IconButton(
              icon: const Icon(Icons.refresh_rounded,
                  color: ParakhColors.accent, size: 20),
              onPressed: onRetake,
              tooltip: 'Retake',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: ParakhColors.nonCompliant, size: 20),
                onPressed: onDelete,
                tooltip: 'Remove',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ] else
            GestureDetector(
              onTap: onCapture,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: ParakhColors.veryLightBlue,
                  borderRadius:
                      BorderRadius.circular(ParakhRadius.full),
                  border: Border.all(
                      color:
                          ParakhColors.accent.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  '+ Add',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ParakhColors.accent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Sub-widgets

class _ShutterButton extends StatelessWidget {
  final bool isCapturing;
  final bool enabled;
  final VoidCallback onTap;

  const _ShutterButton({
    required this.isCapturing,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: SizedBox(
          width: 74,
          height: 74,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: enabled
                        ? ParakhColors.accent.withValues(alpha: 0.35)
                        : ParakhColors.border,
                    width: 3,
                  ),
                ),
              ),
              // Inner button
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCapturing
                      ? ParakhColors.accent.withValues(alpha: 0.7)
                      : ParakhColors.accent,
                  boxShadow: [
                    BoxShadow(
                      color:
                          ParakhColors.accent.withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: isCapturing
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? ParakhColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: c),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: c,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Camera status overlay panel (loading / error / unavailable)
class _CameraStatusPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool showSpinner;
  final _StatusAction? action;

  const _CameraStatusPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.showSpinner = false,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showSpinner)
              const CircularProgressIndicator(
                color: Colors.white54,
                strokeWidth: 2,
              )
            else
              Icon(icon,
                  size: 52, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.55),
                height: 1.4,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: action!.onTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(ParakhRadius.button),
                  ),
                ),
                child: Text(action!.label),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusAction {
  final String label;
  final VoidCallback onTap;
  const _StatusAction({required this.label, required this.onTap});
}

/// Permission denied panel
class _PermissionPanel extends StatelessWidget {
  final bool permanent;
  final VoidCallback onAllow;
  final VoidCallback onGallery;

  const _PermissionPanel({
    required this.permanent,
    required this.onAllow,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined,
                size: 52,
                color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 20),
            const Text(
              'Camera Access Required',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              permanent
                  ? 'Camera permission was permanently denied.\nPlease enable it in Settings to capture package images.'
                  : 'PARAKH needs camera access to photograph package labels for Legal Metrology inspection.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAllow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ParakhColors.accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(ParakhRadius.button),
                  ),
                ),
                child: Text(
                  permanent ? 'Open Settings' : 'Allow Camera Access',
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onGallery,
                icon: const Icon(Icons.photo_library_outlined, size: 17),
                label: const Text('Use Gallery Instead'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                  minimumSize: const Size(0, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(ParakhRadius.button),
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

/// Camera corner reticle
class _ReticlePainter extends CustomPainter {
  const _ReticlePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 28.0;
    const r = 10.0;
    final w = size.width;
    final h = size.height;

    void corner(double ox, double oy, double dx, double dy) {
      canvas.drawLine(
        Offset(ox, oy + dy * len),
        Offset(ox, oy + dy * r),
        paint,
      );
      canvas.drawLine(
        Offset(ox + dx * r, oy),
        Offset(ox + dx * len, oy),
        paint,
      );
      // Arc
      final rect = Rect.fromCircle(
        center: Offset(ox + dx * r, oy + dy * r),
        radius: r,
      );
      double startAngle;
      if (dx == 1 && dy == 1) {
        startAngle = 3.14159;
      } else if (dx == -1 && dy == 1) {
        startAngle = 0;
      } else if (dx == 1 && dy == -1) {
        startAngle = 3.14159 / 2 * 3;
      } else {
        startAngle = 3.14159 / 2;
      }
      canvas.drawArc(rect, startAngle, 3.14159 / 2, false, paint);
    }

    corner(0, 0, 1, 1);        // TL
    corner(w, 0, -1, 1);       // TR
    corner(0, h, 1, -1);       // BL
    corner(w, h, -1, -1);      // BR
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

/// Overlay pill label on camera feed
class _OverlayPill extends StatelessWidget {
  final String label;
  final IconData icon;

  const _OverlayPill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ParakhColors.cameraOverlay,
        borderRadius: BorderRadius.circular(ParakhRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
