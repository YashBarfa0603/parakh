import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../model/inspection_model.dart';
import '../../model/inspector_model.dart';
import '../../services/auth_service.dart';
import '../../services/inspection_service.dart';
import '../../widgets/ashoka_emblem.dart';
import '../../widgets/status_badge.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  InspectorModel? _inspector;
  List<InspectionModel> _inspections = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _inspector = await AuthServices().getCurrentInspector();
    if (mounted) {
      setState(() {
        _inspections = InspectionService().cachedInspections;
      });
    }
  }

  // Stats
  int get _total => _inspections.length;
  int get _compliantCount => _inspections
      .where((i) => i.complianceStatus == ComplianceStatus.compliant)
      .length;
  int get _nonCompliantCount => _inspections
      .where((i) => i.complianceStatus == ComplianceStatus.nonCompliant)
      .length;
  int get _needsReviewCount => _inspections
      .where((i) => i.complianceStatus == ComplianceStatus.needsReview)
      .length;

  // Today's activity
  List<InspectionModel> get _todayInspections {
    final today = DateTime.now();
    return _inspections.where((i) {
      if (i.createdAt == null) return false;
      try {
        final d = DateTime.parse(i.createdAt!);
        return d.year == today.year &&
            d.month == today.month &&
            d.day == today.day;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  String get _lastInspectionTime {
    if (_inspections.isEmpty) return '—';
    final latest = _inspections.first;
    if (latest.createdAt == null) return 'Recently';
    try {
      final d = DateTime.parse(latest.createdAt!).toLocal();
      final h = d.hour.toString().padLeft(2, '0');
      final m = d.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return 'Recently';
    }
  }

  // Greeting
  String get _greeting {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'Good Morning';
    if (h >= 12 && h < 17) return 'Good Afternoon';
    if (h >= 17 && h < 21) return 'Good Evening';
    return 'Good Night';
  }

  String get _firstName {
    final name = _inspector?.name.trim() ?? '';
    if (name.isEmpty) return 'Inspector';
    return name.split(RegExp(r'\s+')).first;
  }

  String get _formattedDate {
    final now = DateTime.now();
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May',
      'June', 'July', 'August', 'September', 'October',
      'November', 'December'
    ];
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  String get _initials {
    final name = _inspector?.name.trim() ?? '';
    if (name.isEmpty) return 'IN';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  void _startNewInspection() =>
      Navigator.of(context).pushNamed(AppRoutes.camera);

  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParakhColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: ParakhColors.accent,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Top App Bar
              SliverAppBar(
                pinned: true,
                floating: false,
                backgroundColor: ParakhColors.surface,
                elevation: 0,
                scrolledUnderElevation: 0.5,
                surfaceTintColor: Colors.transparent,
                automaticallyImplyLeading: false,
                toolbarHeight: 56,
                title: Row(
                  children: [
                    AshokaEmblem(size: 26, color: ParakhColors.accent),
                    const SizedBox(width: 8),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'PARAKH',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            color: ParakhColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Legal Metrology Inspection Platform',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 9,
                            color: ParakhColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined,
                          size: 22, color: ParakhColors.textSecondary),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No new alerts')),
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: ParakhColors.veryLightBlue,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: ParakhColors.accent.withValues(alpha: 0.25),
                              width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            _initials,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: ParakhColors.accent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(height: 1, color: ParakhColors.border),
                ),
              ),

              // Greeting + Date
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_greeting, $_firstName',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: ParakhColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Ready for today\'s inspections?',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: ParakhColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 13, color: ParakhColors.textTertiary),
                          const SizedBox(width: 5),
                          Text(
                            _formattedDate,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: ParakhColors.textTertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Primary CTA
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildPrimaryCTA(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Inspection Overview
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _sectionTitle('Inspection Overview'),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.65,
                  children: [
                    _StatCard(
                      label: 'Total Inspections',
                      value: '$_total',
                      icon: Icons.fact_check_outlined,
                      iconColor: ParakhColors.accent,
                      bgColor: ParakhColors.veryLightBlue,
                      onTap: () => Navigator.of(context)
                          .pushNamed(AppRoutes.scannedProducts),
                    ),
                    _StatCard(
                      label: 'Compliant',
                      value: '$_compliantCount',
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: ParakhColors.compliant,
                      bgColor: ParakhColors.compliantLight,
                      onTap: () => Navigator.of(context)
                          .pushNamed(AppRoutes.compliantProducts),
                    ),
                    _StatCard(
                      label: 'Non-Compliant',
                      value: '$_nonCompliantCount',
                      icon: Icons.cancel_outlined,
                      iconColor: ParakhColors.nonCompliant,
                      bgColor: ParakhColors.nonCompliantLight,
                      onTap: () => Navigator.of(context)
                          .pushNamed(AppRoutes.nonCompliantProducts),
                    ),
                    _StatCard(
                      label: 'Needs Review',
                      value: '$_needsReviewCount',
                      icon: Icons.pending_outlined,
                      iconColor: ParakhColors.needsReview,
                      bgColor: ParakhColors.needsReviewLight,
                      onTap: () => Navigator.of(context)
                          .pushNamed(AppRoutes.scannedProducts),
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Quick Actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _sectionTitle('Quick Actions'),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.photo_camera_outlined,
                          label: 'Scan Product',
                          iconColor: ParakhColors.accent,
                          iconBg: ParakhColors.veryLightBlue,
                          onTap: () =>
                              Navigator.of(context).pushNamed(AppRoutes.camera),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.upload_file_outlined,
                          label: 'Upload Image',
                          iconColor: ParakhColors.compliant,
                          iconBg: ParakhColors.compliantLight,
                          onTap: () =>
                              Navigator.of(context).pushNamed(AppRoutes.camera),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.description_outlined,
                          label: 'View Reports',
                          iconColor: ParakhColors.needsReview,
                          iconBg: ParakhColors.needsReviewLight,
                          onTap: () => Navigator.of(context)
                              .pushNamed(AppRoutes.reportsList),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Today's Activity
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildTodayActivity(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Recent Inspections
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionTitle('Recent Inspections'),
                      TextButton(
                        onPressed: () => Navigator.of(context)
                            .pushNamed(AppRoutes.scannedProducts),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    _buildRecentItems(),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  // Widgets

  Widget _sectionTitle(String title) => Text(
        title,
        style: ParakhTypography.sectionTitle,
      );

  Widget _buildPrimaryCTA() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _startNewInspection,
        borderRadius: BorderRadius.circular(ParakhRadius.xl),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ParakhColors.accent,
            borderRadius: BorderRadius.circular(ParakhRadius.xl),
            boxShadow: [
              BoxShadow(
                color: ParakhColors.accent.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: ParakhColors.textOnPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.document_scanner_outlined,
                    color: ParakhColors.textOnPrimary, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'START NEW INSPECTION',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: ParakhColors.textOnPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Scan or upload a product package to begin verification.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: ParakhColors.textOnPrimary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: ParakhColors.textOnPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.arrow_forward_rounded,
                    color: ParakhColors.textOnPrimary, size: 17),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayActivity() {
    final todayCompleted = _todayInspections.where((i) => i.isFinalized).length;
    final todayReview = _todayInspections
        .where((i) => i.complianceStatus == ComplianceStatus.needsReview)
        .length;

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
          const Text("Today's Activity", style: ParakhTypography.sectionTitle),
          const SizedBox(height: 12),
          Row(
            children: [
              _ActivityCell(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Completed',
                  value: '$todayCompleted',
                  color: ParakhColors.compliant),
              const SizedBox(width: 6),
              Container(width: 1, height: 36, color: ParakhColors.border),
              const SizedBox(width: 6),
              _ActivityCell(
                  icon: Icons.pending_outlined,
                  label: 'Need Review',
                  value: '$todayReview',
                  color: ParakhColors.needsReview),
              const SizedBox(width: 6),
              Container(width: 1, height: 36, color: ParakhColors.border),
              const SizedBox(width: 6),
              _ActivityCell(
                  icon: Icons.access_time_rounded,
                  label: 'Last Inspection',
                  value: _lastInspectionTime,
                  color: ParakhColors.accent),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRecentItems() {
    if (_inspections.isNotEmpty) {
      return _inspections.take(5).map((item) {
        return _InspectionRow(
          title: item.productName ?? 'Inspection #${item.id}',
          subtitle: 'ID: #${item.id}  ·  ${_formatDate(item.createdAt)}',
          status: item.complianceStatus,
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.inspectionResult,
            arguments: item.id,
          ),
        );
      }).toList();
    }
    // Placeholder when empty
    return [
      _InspectionRow(
        title: 'Britannia Biscuit Pack',
        subtitle: 'ID: #1021  ·  Today, 10:30 AM',
        status: ComplianceStatus.compliant,
        onTap: _startNewInspection,
      ),
      _InspectionRow(
        title: 'Fortune Cooking Oil',
        subtitle: 'ID: #1020  ·  Today, 09:15 AM',
        status: ComplianceStatus.nonCompliant,
        onTap: _startNewInspection,
      ),
      _InspectionRow(
        title: 'Amul Milk Packet',
        subtitle: 'ID: #1019  ·  Yesterday, 04:20 PM',
        status: ComplianceStatus.needsReview,
        onTap: _startNewInspection,
      ),
    ];
  }

  String _formatDate(String? raw) {
    if (raw == null) return 'Recent';
    try {
      final d = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      final isToday = d.year == now.year && d.month == now.month && d.day == now.day;
      final prefix = isToday ? 'Today' : '${d.day}/${d.month}/${d.year}';
      return '$prefix, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'Recent';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Sub-widgets — all using ParakhColors, no local Color() definitions
// ═══════════════════════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ParakhColors.surface,
      borderRadius: BorderRadius.circular(ParakhRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: ParakhColors.border),
            borderRadius: BorderRadius.circular(ParakhRadius.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(ParakhRadius.md),
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: ParakhColors.textPrimary,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(label, style: ParakhTypography.caption),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.iconBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ParakhColors.surface,
      borderRadius: BorderRadius.circular(ParakhRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: ParakhColors.border),
            borderRadius: BorderRadius.circular(ParakhRadius.lg),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(ParakhRadius.md),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: ParakhColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ActivityCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: ParakhTypography.caption,
          ),
        ],
      ),
    );
  }
}

class _InspectionRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final ComplianceStatus status;
  final VoidCallback onTap;

  const _InspectionRow({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color iconBg;
    Color iconColor;
    IconData icon;

    switch (status) {
      case ComplianceStatus.compliant:
        iconBg = ParakhColors.compliantLight;
        iconColor = ParakhColors.compliant;
        icon = Icons.check_circle_outline_rounded;
        break;
      case ComplianceStatus.nonCompliant:
        iconBg = ParakhColors.nonCompliantLight;
        iconColor = ParakhColors.nonCompliant;
        icon = Icons.cancel_outlined;
        break;
      case ComplianceStatus.needsReview:
        iconBg = ParakhColors.needsReviewLight;
        iconColor = ParakhColors.needsReview;
        icon = Icons.pending_outlined;
        break;
      case ComplianceStatus.pending:
        iconBg = ParakhColors.pendingLight;
        iconColor = ParakhColors.pending;
        icon = Icons.hourglass_top_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: ParakhColors.surface,
        borderRadius: BorderRadius.circular(ParakhRadius.card),
        border: Border.all(color: ParakhColors.border),
        boxShadow: [
          BoxShadow(
            color: ParakhColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ParakhRadius.card),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(ParakhRadius.md),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 12),
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
                      Text(subtitle, style: ParakhTypography.caption),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(status: status, isCompact: true),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: ParakhColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
