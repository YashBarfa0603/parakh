import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../model/inspection_model.dart';
import '../../services/inspection_service.dart';

class ReportsListScreen extends StatefulWidget {
  const ReportsListScreen({super.key});

  @override
  State<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _activeFilter = 'All'; // All | Pass | Fail | Review
  bool _isRefreshing = false;

  static const List<String> _filters = ['All', 'Pass', 'Fail', 'Review'];

  List<InspectionModel> get _filtered {
    var list = InspectionService().cachedInspections;

    // Status filter
    if (_activeFilter != 'All') {
      list = list.where((i) {
        final s = i.complianceResult?.toUpperCase() ?? '';
        return s == _activeFilter.toUpperCase();
      }).toList();
    }

    // Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((i) {
        final name = (i.productName ?? '').toLowerCase();
        final brand = (i.brand ?? '').toLowerCase();
        final id = i.id.toString();
        return name.contains(q) || brand.contains(q) || id.contains(q);
      }).toList();
    }
    return list;
  }

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    await InspectionService().fetchMyInspections();
    if (mounted) setState(() => _isRefreshing = false);
  }

  String _shortDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Scaffold(
      backgroundColor: ParakhColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilterRow(),
            Expanded(
              child: _isRefreshing
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: ParakhColors.accent,
                        strokeWidth: 2,
                      ),
                    )
                  : items.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _refresh,
                          color: ParakhColors.accent,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: items.length,
                            itemBuilder: (ctx, i) =>
                                _ReportCard(
                                  inspection: items[i],
                                  shortDate: _shortDate(
                                      items[i].finalizedAt ?? items[i].createdAt),
                                  onTap: () => Navigator.of(context).pushNamed(
                                    AppRoutes.viewReport,
                                    arguments: items[i].id,
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

  // Header
  Widget _buildHeader() {
    return Container(
      color: ParakhColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Inspection Reports',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: ParakhColors.textPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${InspectionService().cachedInspections.length} records  ·  Review compliance findings',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: ParakhColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: ParakhColors.accent, size: 22),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  // Search
  Widget _buildSearchBar() {
    return Container(
      color: ParakhColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v.trim()),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: ParakhColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Search by product, brand, or ID...',
          hintStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: ParakhColors.textTertiary,
          ),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 19, color: ParakhColors.textTertiary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      size: 17, color: ParakhColors.textTertiary),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: ParakhColors.surfaceLight,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ParakhRadius.full),
            borderSide: const BorderSide(color: ParakhColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ParakhRadius.full),
            borderSide: const BorderSide(color: ParakhColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ParakhRadius.full),
            borderSide:
                const BorderSide(color: ParakhColors.accent, width: 1.5),
          ),
        ),
      ),
    );
  }

  // Filter pills
  Widget _buildFilterRow() {
    return Container(
      color: ParakhColors.surface,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: _filters.map((f) {
                final isActive = _activeFilter == f;
                Color bg, fg, border;
                if (!isActive) {
                  bg = ParakhColors.surfaceLight;
                  fg = ParakhColors.textSecondary;
                  border = ParakhColors.border;
                } else {
                  switch (f) {
                    case 'Pass':
                      bg = ParakhColors.compliantLight;
                      fg = ParakhColors.compliant;
                      border = ParakhColors.compliant;
                      break;
                    case 'Fail':
                      bg = ParakhColors.nonCompliantLight;
                      fg = ParakhColors.nonCompliant;
                      border = ParakhColors.nonCompliant;
                      break;
                    case 'Review':
                      bg = ParakhColors.needsReviewLight;
                      fg = ParakhColors.needsReview;
                      border = ParakhColors.needsReview;
                      break;
                    default:
                      bg = ParakhColors.veryLightBlue;
                      fg = ParakhColors.accent;
                      border = ParakhColors.accent;
                  }
                }
                return GestureDetector(
                  onTap: () => setState(() => _activeFilter = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(ParakhRadius.full),
                      border: Border.all(
                          color: border.withValues(alpha: isActive ? 0.7 : 0.5),
                          width: isActive ? 1.5 : 1.0),
                    ),
                    child: Text(
                      f,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Container(height: 1, color: ParakhColors.border),
        ],
      ),
    );
  }

  // Empty state
  Widget _buildEmptyState() {
    final isSearchOrFilter =
        _searchQuery.isNotEmpty || _activeFilter != 'All';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: ParakhColors.surfaceLight,
                borderRadius: BorderRadius.circular(ParakhRadius.xl),
              ),
              child: const Icon(Icons.article_outlined,
                  size: 36, color: ParakhColors.textTertiary),
            ),
            const SizedBox(height: 18),
            Text(
              isSearchOrFilter ? 'No matching reports' : 'No Reports Yet',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ParakhColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSearchOrFilter
                  ? 'Try adjusting your search or filters.'
                  : 'Finalize an inspection to generate an official sealed report.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: ParakhColors.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

// Report card
class _ReportCard extends StatelessWidget {
  final InspectionModel inspection;
  final String shortDate;
  final VoidCallback onTap;

  const _ReportCard({
    required this.inspection,
    required this.shortDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = inspection.complianceStatus;
    final hasFail = inspection.findings.any((f) => f.isFail);
    final failCount = inspection.findings.where((f) => f.isFail).length;
    final reviewCount = inspection.findings.where((f) => f.isReview).length;
    final passCount = inspection.findings.where((f) => f.isPass).length;
    final title = inspection.productName?.isNotEmpty == true
        ? inspection.productName!
        : 'Report #${inspection.id}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: ParakhColors.surface,
          borderRadius: BorderRadius.circular(ParakhRadius.card),
          border: Border.all(
            color: hasFail
                ? ParakhColors.nonCompliant.withValues(alpha: 0.3)
                : ParakhColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status icon
                  _StatusIcon(status: status),
                  const SizedBox(width: 12),
                  // Title + meta
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: ParakhColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (inspection.brand != null) ...[
                              Text(
                                inspection.brand!,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: ParakhColors.textSecondary,
                                ),
                              ),
                              const Text(' · ',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: ParakhColors.textTertiary)),
                            ],
                            Text(
                              '#${inspection.id}',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: ParakhColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _StatusPill(status: status),
                ],
              ),
            ),

            // Findings summary bar
            if (inspection.findings.isNotEmpty) ...[
              Container(height: 1, color: ParakhColors.border),
              _FindingsSummaryBar(
                  fail: failCount, review: reviewCount, pass: passCount),
              Container(height: 1, color: ParakhColors.border),
            ],

            // Missing declarations highlight
            if (hasFail) _MissingDeclarationsRow(inspection: inspection),

            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 12, color: ParakhColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    shortDate,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: ParakhColors.textTertiary,
                    ),
                  ),
                  if (inspection.canonicalHash != null) ...[
                    const SizedBox(width: 10),
                    const Icon(Icons.shield_outlined,
                        size: 12, color: ParakhColors.compliant),
                    const SizedBox(width: 3),
                    const Text(
                      'Integrity Recorded',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: ParakhColors.compliant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const Spacer(),
                  const Text(
                    'View Report',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: ParakhColors.accent,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 12, color: ParakhColors.accent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Status icon circle
class _StatusIcon extends StatelessWidget {
  final ComplianceStatus status;
  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color icon;
    IconData icn;
    switch (status) {
      case ComplianceStatus.compliant:
        bg = ParakhColors.compliantLight;
        icon = ParakhColors.compliant;
        icn = Icons.check_circle_outline_rounded;
        break;
      case ComplianceStatus.nonCompliant:
        bg = ParakhColors.nonCompliantLight;
        icon = ParakhColors.nonCompliant;
        icn = Icons.cancel_outlined;
        break;
      case ComplianceStatus.needsReview:
        bg = ParakhColors.needsReviewLight;
        icon = ParakhColors.needsReview;
        icn = Icons.warning_amber_outlined;
        break;
      default:
        bg = ParakhColors.surfaceLight;
        icon = ParakhColors.textTertiary;
        icn = Icons.hourglass_empty_rounded;
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(ParakhRadius.md)),
      child: Icon(icn, size: 22, color: icon),
    );
  }
}

// Status pill label
class _StatusPill extends StatelessWidget {
  final ComplianceStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    String label;
    Color bg, fg;
    switch (status) {
      case ComplianceStatus.compliant:
        label = 'PASS';
        bg = ParakhColors.compliantLight;
        fg = ParakhColors.compliant;
        break;
      case ComplianceStatus.nonCompliant:
        label = 'FAIL';
        bg = ParakhColors.nonCompliantLight;
        fg = ParakhColors.nonCompliant;
        break;
      case ComplianceStatus.needsReview:
        label = 'REVIEW';
        bg = ParakhColors.needsReviewLight;
        fg = ParakhColors.needsReview;
        break;
      default:
        label = 'PENDING';
        bg = ParakhColors.surfaceLight;
        fg = ParakhColors.textTertiary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(ParakhRadius.full),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// Findings summary bar
class _FindingsSummaryBar extends StatelessWidget {
  final int fail;
  final int review;
  final int pass;

  const _FindingsSummaryBar(
      {required this.fail, required this.review, required this.pass});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        children: [
          const Text(
            'Findings:',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ParakhColors.textTertiary,
            ),
          ),
          const SizedBox(width: 8),
          if (fail > 0) ...[
            _Chip(
              label: '$fail Failed',
              color: ParakhColors.nonCompliant,
              bg: ParakhColors.nonCompliantLight,
            ),
            const SizedBox(width: 6),
          ],
          if (review > 0) ...[
            _Chip(
              label: '$review Review',
              color: ParakhColors.needsReview,
              bg: ParakhColors.needsReviewLight,
            ),
            const SizedBox(width: 6),
          ],
          if (pass > 0)
            _Chip(
              label: '$pass Passed',
              color: ParakhColors.compliant,
              bg: ParakhColors.compliantLight,
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _Chip({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(ParakhRadius.full),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// Missing declarations highlight row
class _MissingDeclarationsRow extends StatelessWidget {
  final InspectionModel inspection;
  const _MissingDeclarationsRow({required this.inspection});

  @override
  Widget build(BuildContext context) {
    final failed =
        inspection.findings.where((f) => f.isFail).take(3).toList();
    if (failed.isEmpty) return const SizedBox.shrink();

    return Container(
      color: ParakhColors.nonCompliantLight.withValues(alpha: 0.6),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cancel_outlined,
                  size: 13, color: ParakhColors.nonCompliant),
              const SizedBox(width: 5),
              Text(
                '${inspection.findings.where((f) => f.isFail).length} issue'
                '${inspection.findings.where((f) => f.isFail).length > 1 ? "s" : ""} detected',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ParakhColors.nonCompliant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ...failed.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('✕  ',
                        style: TextStyle(
                          fontSize: 11,
                          color: ParakhColors.nonCompliant,
                          fontWeight: FontWeight.w700,
                        )),
                    Expanded(
                      child: Text(
                        f.requirement,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: ParakhColors.nonCompliant,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
