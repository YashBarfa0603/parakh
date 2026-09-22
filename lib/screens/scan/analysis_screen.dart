import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../services/inspection_service.dart';
import '../../widgets/ashoka_emblem.dart';

// Step data
class _Step {
  final String title;
  final String detail;
  const _Step(this.title, this.detail);
}

const List<_Step> _kSteps = [
  _Step('Verifying Image Integrity',
      'Checking SHA-256 digital integrity fingerprint...'),
  _Step('Running NVIDIA Nemotron OCR',
      'Extracting text tokens from all package face images...'),
  _Step('NER / Context Extraction',
      'Identifying product entities — MRP, net quantity, manufacturer, dates...'),
  _Step('Extracting Statutory Declarations',
      'Mapping extracted entities to Legal Metrology declaration fields...'),
  _Step('Evaluating Legal Metrology Rules',
      'Checking applicable statutory requirements (PC Rules, 2011)...'),
  _Step('Preparing Verification Result',
      'Compiling findings for inspector review...'),
];

class AnalysisScreen extends StatefulWidget {
  final int inspectionId;
  const AnalysisScreen({super.key, required this.inspectionId});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  bool _isFinished = false;
  String? _errorMessage;
  Timer? _stepTimer;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _startAnalysisPipeline();
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _startAnalysisPipeline() {
    setState(() {
      _currentStep = 0;
      _errorMessage = null;
      _isFinished = false;
    });

    _stepTimer = Timer.periodic(const Duration(milliseconds: 1400), (timer) {
      if (_currentStep < _kSteps.length - 1 && !_isFinished) {
        setState(() => _currentStep++);
      } else {
        timer.cancel();
      }
    });

    _executeBackendAnalysis();
  }

  Future<void> _executeBackendAnalysis() async {
    try {
      await InspectionService().analyzeInspection(widget.inspectionId);
      _stepTimer?.cancel();
      if (!mounted) return;

      setState(() {
        _currentStep = _kSteps.length - 1;
        _isFinished = true;
      });

      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed(
        AppRoutes.inspectionResult,
        arguments: widget.inspectionId,
      );
    } catch (e) {
      _stepTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  double get _progressFraction =>
      _isFinished ? 1.0 : _currentStep / _kSteps.length;

  int get _completedSteps => _isFinished ? _kSteps.length : _currentStep;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParakhColors.background,
      appBar: AppBar(
        backgroundColor: ParakhColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: ParakhColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Statutory Verification',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: ParakhColors.textPrimary,
                )),
            Text(
              'Inspection ${InspectionService().getDisplayId(widget.inspectionId)}',
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: ParakhColors.textSecondary),
            ),
          ],
        ),
        actions: [
          _StatusPill(
              error: _errorMessage != null, finished: _isFinished),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: ParakhColors.border),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBrandingCard(),
              const SizedBox(height: 20),
              _buildIllustration(),
              const SizedBox(height: 20),
              _buildHeading(),
              const SizedBox(height: 20),
              _buildProgressCard(),
              const SizedBox(height: 20),
              _buildTimeline(),
              const SizedBox(height: 20),
              _buildRulesCard(),
              const SizedBox(height: 16),
              _buildIntegrityBadge(),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                _buildErrorCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Branding card
  Widget _buildBrandingCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ParakhColors.surface,
        borderRadius: BorderRadius.circular(ParakhRadius.lg),
        border: Border.all(color: ParakhColors.border),
      ),
      child: Row(
        children: [
          AshokaEmblem(size: 34, color: ParakhColors.accent),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PARAKH',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8,
                    color: ParakhColors.textPrimary,
                  )),
              Text('Legal Metrology Inspection Platform',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: ParakhColors.textSecondary,
                  )),
              Text('Government of India',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    color: ParakhColors.textTertiary,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  // Illustration
  Widget _buildIllustration() {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, child) => Transform.scale(
          scale: _isFinished ? 1.0 : _pulseAnim.value,
          child: child,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ParakhColors.softBlue.withValues(alpha: 0.4),
              ),
            ),
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ParakhColors.softBlue.withValues(alpha: 0.65),
              ),
            ),
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ParakhColors.surface,
                border: Border.all(
                    color: ParakhColors.accent.withValues(alpha: 0.3),
                    width: 2),
                boxShadow: [
                  BoxShadow(
                    color: ParakhColors.accent.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _isFinished
                    ? Icons.check_circle_rounded
                    : Icons.document_scanner_outlined,
                size: 32,
                color: _isFinished
                    ? ParakhColors.compliant
                    : ParakhColors.accent,
              ),
            ),
            SizedBox(
              width: 110,
              height: 110,
              child: CircularProgressIndicator(
                value: _progressFraction,
                strokeWidth: 3,
                backgroundColor: ParakhColors.softBlue,
                valueColor: AlwaysStoppedAnimation<Color>(
                    _isFinished ? ParakhColors.compliant : ParakhColors.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Heading
  Widget _buildHeading() {
    return Column(
      children: [
        const Text(
          'AI-ASSISTED COMPLIANCE VERIFICATION',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: ParakhColors.accent,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Legal Metrology Rules Engine',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: ParakhColors.textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Checking product information against applicable Legal\nMetrology (Packaged Commodities) Rules, 2011.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: ParakhColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: ParakhColors.veryLightBlue,
            borderRadius: BorderRadius.circular(ParakhRadius.md),
            border: Border.all(color: ParakhColors.softBlue),
          ),
          child: const Text(
            'AI extracts data  ·  Rules Engine determines compliance',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: ParakhColors.accent,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Progress card
  Widget _buildProgressCard() {
    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Verification Progress',
                  style: ParakhTypography.sectionTitle),
              Text(
                '$_completedSteps of ${_kSteps.length} completed',
                style: ParakhTypography.caption,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(ParakhRadius.sm),
            child: LinearProgressIndicator(
              value: _progressFraction,
              minHeight: 8,
              backgroundColor: ParakhColors.softBlue,
              valueColor: AlwaysStoppedAnimation<Color>(
                  _errorMessage != null
                      ? ParakhColors.nonCompliant
                      : ParakhColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  // Timeline
  Widget _buildTimeline() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ParakhColors.surface,
        borderRadius: BorderRadius.circular(ParakhRadius.card),
        border: Border.all(color: ParakhColors.border),
        boxShadow: [
          BoxShadow(
              color: ParakhColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Processing Timeline',
              style: ParakhTypography.sectionTitle),
          const SizedBox(height: 14),
          ...List.generate(_kSteps.length, (index) {
            final isDone = index < _currentStep || _isFinished;
            final isCurrent = index == _currentStep && !_isFinished;
            final isLast = index == _kSteps.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dot + connector
                  Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone
                              ? ParakhColors.compliantLight
                              : (isCurrent
                                  ? ParakhColors.veryLightBlue
                                  : ParakhColors.surfaceLight),
                          border: Border.all(
                            color: isDone
                                ? ParakhColors.compliant
                                : (isCurrent
                                    ? ParakhColors.accent
                                    : ParakhColors.border),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: isDone
                              ? const Icon(Icons.check_rounded,
                                  size: 14, color: ParakhColors.compliant)
                              : isCurrent
                                  ? const SizedBox(
                                      width: 13,
                                      height: 13,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                ParakhColors.accent),
                                      ),
                                    )
                                  : Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: ParakhColors.textTertiary,
                                      ),
                                    ),
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 1.5,
                            color: isDone
                                ? ParakhColors.compliant.withValues(alpha: 0.3)
                                : ParakhColors.border,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Text content
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _kSteps[index].title,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: isCurrent
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isDone
                                  ? ParakhColors.textSecondary
                                  : (isCurrent
                                      ? ParakhColors.textPrimary
                                      : ParakhColors.textTertiary),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _kSteps[index].detail,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: isDone
                                  ? ParakhColors.textTertiary
                                  : (isCurrent
                                      ? ParakhColors.textSecondary
                                      : ParakhColors.borderLight),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isDone
                                ? 'Completed'
                                : (isCurrent ? 'In Progress' : 'Pending'),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isDone
                                  ? ParakhColors.compliant
                                  : (isCurrent
                                      ? ParakhColors.accent
                                      : ParakhColors.textTertiary),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Rules card
  Widget _buildRulesCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ParakhColors.veryLightBlue,
        borderRadius: BorderRadius.circular(ParakhRadius.lg),
        border: Border.all(color: ParakhColors.softBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gavel_rounded,
                  size: 16, color: ParakhColors.accent),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Rules Being Applied',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ParakhColors.textPrimary,
                    )),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Legal Metrology (Packaged Commodities) Rules, 2011'),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: ParakhColors.accent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
                child: const Text('View Details'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Legal Metrology (Packaged Commodities) Rules, 2011',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ParakhColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Applicable declarations and mandatory labelling requirements',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: ParakhColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // SHA-256 integrity badge
  Widget _buildIntegrityBadge() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ParakhColors.surface,
        borderRadius: BorderRadius.circular(ParakhRadius.lg),
        border: Border.all(color: ParakhColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: ParakhColors.compliantLight,
              borderRadius: BorderRadius.circular(ParakhRadius.md),
            ),
            child: const Icon(Icons.fingerprint_rounded,
                size: 20, color: ParakhColors.compliant),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Image Integrity Recorded',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: ParakhColors.compliant,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.check_circle_rounded,
                        size: 14, color: ParakhColors.compliant),
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  'SHA-256 fingerprint recorded for the uploaded image. '
                  'This verifies digital artifact integrity only — not physical authenticity.',
                  style: ParakhTypography.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Error card
  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ParakhColors.nonCompliantLight,
        borderRadius: BorderRadius.circular(ParakhRadius.card),
        border: Border.all(
            color: ParakhColors.nonCompliant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 20, color: ParakhColors.nonCompliant),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Verification could not be completed',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ParakhColors.nonCompliant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'An unexpected error occurred.',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: ParakhColors.nonCompliant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'The inspection will be moved to Review status. '
            'No compliance result will be auto-assigned.',
            style: ParakhTypography.caption,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startAnalysisPipeline,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry Verification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ParakhColors.nonCompliant,
                foregroundColor: ParakhColors.textOnPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ParakhRadius.button),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Status pill widget
class _StatusPill extends StatelessWidget {
  final bool error;
  final bool finished;
  const _StatusPill({required this.error, required this.finished});

  @override
  Widget build(BuildContext context) {
    final Color dotColor;
    final Color bgColor;
    final Color borderColor;
    final String label;

    if (error) {
      dotColor = ParakhColors.nonCompliant;
      bgColor = ParakhColors.nonCompliantLight;
      borderColor = ParakhColors.nonCompliant.withValues(alpha: 0.3);
      label = 'Failed';
    } else if (finished) {
      dotColor = ParakhColors.compliant;
      bgColor = ParakhColors.compliantLight;
      borderColor = ParakhColors.compliant.withValues(alpha: 0.3);
      label = 'Complete';
    } else {
      dotColor = ParakhColors.accent;
      bgColor = ParakhColors.veryLightBlue;
      borderColor = ParakhColors.accent.withValues(alpha: 0.3);
      label = 'In Progress';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(ParakhRadius.full),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: dotColor,
            ),
          ),
        ],
      ),
    );
  }
}
