import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../model/inspector_model.dart';
import '../../services/auth_service.dart';
import '../../services/inspection_service.dart';
import '../../widgets/ashoka_emblem.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  InspectorModel? _inspector;
  bool _isLoading = true;

  // Inspection summary stats computed from cache
  int _totalInspections = 0;
  int _compliantCount = 0;
  int _nonCompliantCount = 0;
  int _needsReviewCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    // Load inspector profile (network with cache fallback)
    final inspector = await AuthServices().getCurrentInspector(forceRefresh: true);

    // Compute stats from locally cached inspections
    final inspections = InspectionService().cachedInspections;
    final total = inspections.length;
    final compliant = inspections
        .where((i) => i.complianceStatus == ComplianceStatus.compliant)
        .length;
    final nonCompliant = inspections
        .where((i) => i.complianceStatus == ComplianceStatus.nonCompliant)
        .length;
    final needsReview = inspections
        .where((i) => i.complianceStatus == ComplianceStatus.needsReview)
        .length;

    if (!mounted) return;
    setState(() {
      _inspector = inspector;
      _totalInspections = total;
      _compliantCount = compliant;
      _nonCompliantCount = nonCompliant;
      _needsReviewCount = needsReview;
      _isLoading = false;
    });
  }

  // Helpers

  String _getInitials() {
    final name = _inspector?.name.trim() ?? '';
    if (name.isEmpty) return 'IN';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  void _copyText(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        duration: const Duration(seconds: 2),
        backgroundColor: ParakhColors.accent,
      ),
    );
  }

  // Dialogs

  void _showConfigDialog() {
    final ctrl = TextEditingController(text: AppConfig.apiBaseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Server Configuration',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Backend API Base URL',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ParakhColors.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              style: const TextStyle(fontFamily: 'Courier', fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'http://192.168.1.4:8000/api',
                prefixIcon: Icon(Icons.link_rounded, size: 18),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Quick Presets',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ParakhColors.textSecondary,
                    letterSpacing: 0.4)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _presetChip('Mac Wi-Fi', 'http://192.168.1.4:8000/api', ctrl),
                _presetChip('Simulator', 'http://127.0.0.1:8000/api', ctrl),
                _presetChip('Android', 'http://10.0.2.2:8000/api', ctrl),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await AppConfig.resetApiBaseUrl();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                setState(() {});
              }
            },
            child: const Text('Reset'),
          ),
          ElevatedButton(
            onPressed: () async {
              await AppConfig.setApiBaseUrl(ctrl.text);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                setState(() {});
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _presetChip(String label, String url, TextEditingController ctrl) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
      onPressed: () => ctrl.text = url,
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text(
          'Are you sure you want to log out of your inspector session?',
          style: TextStyle(fontSize: 14, color: ParakhColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthServices().logout();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.login,
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ParakhColors.nonCompliant,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  // Build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParakhColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(ParakhColors.accent),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                color: ParakhColors.accent,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // App bar
                    SliverAppBar(
                      pinned: true,
                      floating: false,
                      backgroundColor: ParakhColors.surface,
                      elevation: 0,
                      scrolledUnderElevation: 0.5,
                      surfaceTintColor: Colors.transparent,
                      automaticallyImplyLeading: false,
                      toolbarHeight: 52,
                      title: const Text(
                        'My Profile',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: ParakhColors.textPrimary,
                        ),
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded,
                              size: 20, color: ParakhColors.textSecondary),
                          tooltip: 'Refresh',
                          onPressed: _loadData,
                        ),
                      ],
                      bottom: PreferredSize(
                        preferredSize: const Size.fromHeight(1),
                        child: Container(
                            height: 1, color: ParakhColors.border),
                      ),
                    ),

                    SliverPadding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 20, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // 1. Government Header
                          _buildGovHeader(),
                          const SizedBox(height: 20),

                          // 2. Inspector Profile Card
                          _buildProfileCard(),
                          const SizedBox(height: 16),

                          // 3. Account Status
                          _buildVerificationStatus(),
                          const SizedBox(height: 16),

                          // 4. Inspection Summary
                          _buildInspectionSummary(),
                          const SizedBox(height: 16),

                          // 5. Personal & Office Information
                          _buildPersonalInfoSection(),
                          const SizedBox(height: 16),

                          // 6. App & Security
                          _buildAppSecuritySection(),
                          const SizedBox(height: 16),


                          // 8. About PARAKH
                          _buildAboutSection(),
                          const SizedBox(height: 20),

                          // 9. Log Out
                          _buildLogoutButton(),
                          const SizedBox(height: 8),

                          // Gov Footer
                          _buildGovFooter(),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // 1. Government Header

  Widget _buildGovHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
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
      child: Row(
        children: [
          // Ashoka Stambh
          AshokaEmblem(size: 52, color: ParakhColors.accent),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'सत्यमेव जयते',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ParakhColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Government of India',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ParakhColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'PARAKH',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: ParakhColors.accent,
                  ),
                ),
                const SizedBox(height: 1),
                const Text(
                  'Legal Metrology Inspection Platform',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: ParakhColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. Inspector Profile Card

  Widget _buildProfileCard() {
    final name = _inspector?.name ?? 'Inspector Officer';
    final designation = _inspector?.designation ?? 'Legal Metrology Inspector';
    final inspectorId = _inspector?.inspectorId ?? '—';
    final department = _inspector?.department ?? 'Department of Consumer Affairs';
    final city = _inspector?.city ?? '';
    final state = _inspector?.state ?? '';
    final location = [city, state].where((s) => s.isNotEmpty).join(', ');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ParakhColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ParakhColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: ParakhColors.sectionBackground,
              shape: BoxShape.circle,
              border: Border.all(
                color: ParakhColors.accent.withValues(alpha: 0.25),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                _getInitials(),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: ParakhColors.accent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: ParakhColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  designation,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: ParakhColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                // Inspector ID chip (tappable to copy)
                GestureDetector(
                  onTap: () => _copyText(inspectorId, 'Inspector ID'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: ParakhColors.accent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.badge_outlined,
                            size: 13, color: Colors.white70),
                        const SizedBox(width: 5),
                        Text(
                          inspectorId,
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(Icons.copy_rounded,
                            size: 11, color: Colors.white54),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _profileDetailRow(
                    Icons.account_balance_outlined, department),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _profileDetailRow(Icons.location_on_outlined, location),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileDetailRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: ParakhColors.textTertiary),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: ParakhColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  // 3. Verification Status

  Widget _buildVerificationStatus() {
    final isApproved = _inspector?.isApproved ?? false;
    final isRejected = _inspector?.isRejected ?? false;

    final Color bgColor;
    final Color borderColor;
    final Color textColor;
    final IconData icon;
    final String statusLabel;
    final String statusDesc;

    if (isApproved) {
      bgColor = ParakhColors.compliantLight;
      borderColor = ParakhColors.compliant.withValues(alpha: 0.3);
      textColor = ParakhColors.compliant;
      icon = Icons.verified_rounded;
      statusLabel = 'Verified Inspector';
      statusDesc = 'Your account has been authorized by the State Controller.';
    } else if (isRejected) {
      bgColor = ParakhColors.nonCompliantLight;
      borderColor = ParakhColors.nonCompliant.withValues(alpha: 0.3);
      textColor = ParakhColors.nonCompliant;
      icon = Icons.block_rounded;
      statusLabel = 'Account Suspended';
      statusDesc = _inspector?.rejectionReason ??
          'Contact your State Controller for details.';
    } else {
      bgColor = ParakhColors.needsReviewLight;
      borderColor = ParakhColors.needsReview.withValues(alpha: 0.3);
      textColor = ParakhColors.needsReview;
      icon = Icons.hourglass_top_rounded;
      statusLabel = 'Pending Approval';
      statusDesc =
          'Your account is awaiting authorization by the State Controller.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: textColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Account Status',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textColor.withValues(alpha: 0.7),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusDesc,
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
    );
  }

  // 4. Inspection Summary

  Widget _buildInspectionSummary() {
    return _SectionCard(
      title: 'My Inspection Activity',
      icon: Icons.fact_check_outlined,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Row(
          children: [
            _ActivityStat(
              value: '$_totalInspections',
              label: 'Total',
              color: ParakhColors.accent,
            ),
            _ActivityStat(
              value: '$_compliantCount',
              label: 'Compliant',
              color: ParakhColors.compliant,
            ),
            _ActivityStat(
              value: '$_nonCompliantCount',
              label: 'Non-Compliant',
              color: ParakhColors.nonCompliant,
            ),
            _ActivityStat(
              value: '$_needsReviewCount',
              label: 'Needs Review',
              color: ParakhColors.needsReview,
            ),
          ],
        ),
      ),
    );
  }

  // 5. Personal & Office Information

  Widget _buildPersonalInfoSection() {
    final insp = _inspector;
    return _SectionCard(
      title: 'Personal & Office Information',
      icon: Icons.person_outline_rounded,
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: insp?.email ?? '—',
            onTap: insp?.email != null
                ? () => _copyText(insp!.email, 'Email')
                : null,
          ),
          _RowDivider(),
          _InfoRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: insp?.phone ?? '—',
            onTap: insp?.phone != null
                ? () => _copyText(insp!.phone, 'Phone')
                : null,
          ),
          _RowDivider(),
          _InfoRow(
            icon: Icons.account_balance_outlined,
            label: 'Department',
            value: insp?.department ?? '—',
          ),
          _RowDivider(),
          _InfoRow(
            icon: Icons.work_outline_rounded,
            label: 'Designation',
            value: insp?.designation ?? '—',
          ),
          _RowDivider(),
          _InfoRow(
            icon: Icons.business_outlined,
            label: 'Office',
            value: insp?.office ?? '—',
          ),
          _RowDivider(),
          _InfoRow(
            icon: Icons.flag_outlined,
            label: 'State',
            value: insp?.state ?? '—',
          ),
          _RowDivider(),
          _InfoRow(
            icon: Icons.location_city_outlined,
            label: 'District',
            value: insp?.district ?? '—',
          ),
          _RowDivider(),
          _InfoRow(
            icon: Icons.place_outlined,
            label: 'City',
            value: insp?.city ?? '—',
            isLast: true,
          ),
        ],
      ),
    );
  }

  // 6. App & Security

  Widget _buildAppSecuritySection() {
    return _SectionCard(
      title: 'App & Security',
      icon: Icons.security_outlined,
      child: Column(
        children: [
          _SettingsRow(
            icon: Icons.tune_rounded,
            label: 'Server Configuration',
            onTap: _showConfigDialog,
            trailing: SelectableText(
              AppConfig.apiBaseUrl.replaceFirst('http://', ''),
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 11,
                color: ParakhColors.textTertiary,
              ),
            ),
          ),
          _RowDivider(),
          _SettingsRow(
            icon: Icons.lock_outline_rounded,
            label: 'Change Password',
            onTap: null, // Not implemented in current phase
            comingSoon: true,
          ),
          _RowDivider(),
          _SettingsRow(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy & Data',
            onTap: null,
            comingSoon: true,
          ),
          _RowDivider(),
          _SettingsRow(
            icon: Icons.info_outline_rounded,
            label: 'About PARAKH',
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: const Text('About PARAKH',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PARAKH  ·  v1.0.0',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ParakhColors.accent),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '© 2026 Government of India\n'
                        'Department of Consumer Affairs\n'
                        'Legal Metrology Division\n\n'
                        'SIH 2026 Prototype',
                        style: TextStyle(
                            fontSize: 12,
                            color: ParakhColors.textSecondary,
                            height: 1.5),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'PARAKH is a field inspection tool for Legal Metrology Officers, enabling digital inspection, label validation, and SHA-256 secured reporting under the Legal Metrology (Packaged Commodities) Rules, 2011.',
                        style: TextStyle(
                            fontSize: 13,
                            color: ParakhColors.textSecondary,
                            height: 1.5),
                      ),
                    ],
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
            isLast: true,
          ),
        ],
      ),
    );
  }


  // 8. About PARAKH

  Widget _buildAboutSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ParakhColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ParakhColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: ParakhColors.accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'P',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PARAKH',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: ParakhColors.accent,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Legal Metrology Inspection Platform',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: ParakhColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildAboutChip('v1.0.0'),
                    const SizedBox(width: 6),
                    _buildAboutChip('SIH 2026'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: ParakhColors.surfaceLight,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: ParakhColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: ParakhColors.textSecondary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  // 9. Log Out

  Widget _buildLogoutButton() {
    return Material(
      color: ParakhColors.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _handleLogout,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: ParakhColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.logout_rounded,
                  size: 20, color: ParakhColors.nonCompliant),
              SizedBox(width: 12),
              Text(
                'Log Out',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: ParakhColors.nonCompliant,
                ),
              ),
              Spacer(),
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: ParakhColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  // Gov Footer

  Widget _buildGovFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          const Divider(color: ParakhColors.border, height: 1),
          const SizedBox(height: 16),
          AshokaEmblem(size: 32, color: ParakhColors.textTertiary),
          const SizedBox(height: 6),
          const Text(
            'GOVERNMENT OF INDIA',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
              color: ParakhColors.textTertiary,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Department of Consumer Affairs · Legal Metrology Division',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: ParakhColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// Reusable Section Card

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(icon, size: 16, color: ParakhColors.accent),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ParakhColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: ParakhColors.borderLight),
          child,
        ],
      ),
    );
  }
}

// Info Row (label → value)

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: isLast
          ? const BorderRadius.only(
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            )
          : BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 16, color: ParakhColors.textTertiary),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: ParakhColors.textSecondary,
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ParakhColors.textPrimary,
                ),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              const Icon(Icons.copy_outlined,
                  size: 13, color: ParakhColors.textTertiary),
            ],
          ],
        ),
      ),
    );
  }
}

// Settings Row

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool comingSoon;
  final bool isLast;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
    this.comingSoon = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: isLast
          ? const BorderRadius.only(
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            )
          : BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: onTap != null
                    ? ParakhColors.textSecondary
                    : ParakhColors.textTertiary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: onTap != null
                      ? ParakhColors.textPrimary
                      : ParakhColors.textTertiary,
                ),
              ),
            ),
            if (comingSoon)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: ParakhColors.surfaceLight,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: ParakhColors.border),
                ),
                child: const Text(
                  'Coming Soon',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    color: ParakhColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else if (trailing != null)
              Flexible(child: trailing!)
            else
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: ParakhColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

// Row Divider

class _RowDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: ParakhColors.borderLight),
    );
  }
}

// Activity Stat

class _ActivityStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _ActivityStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: ParakhColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
