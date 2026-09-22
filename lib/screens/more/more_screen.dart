import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../model/inspector_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/parakh_app_bar.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  InspectorModel? _inspector;

  @override
  void initState() {
    super.initState();
    _loadInspector();
  }

  Future<void> _loadInspector() async {
    final data = await AuthServices().getCurrentInspector();
    if (mounted) {
      setState(() => _inspector = data);
    }
  }

  void _showConfigDialog() {
    final textController = TextEditingController(text: AppConfig.apiBaseUrl);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Server Configuration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Backend API URL:',
              style: TextStyle(fontSize: 13, color: ParakhColors.textSecondary),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: textController,
              decoration: const InputDecoration(hintText: 'http://10.0.2.2:8000/api'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              AppConfig.resetApiBaseUrl();
              Navigator.pop(dialogContext);
              setState(() {});
            },
            child: const Text('Reset Default'),
          ),
          ElevatedButton(
            onPressed: () async {
              await AppConfig.setApiBaseUrl(textController.text);
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                setState(() {});
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to end your current officer session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ParakhColors.nonCompliant,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthServices().logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParakhColors.backgroundDarker,
      appBar: const ParakhAppBar(
        title: 'Settings & Reference',
        subtitle: 'Government of India • Legal Metrology',
        showBackButton: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Inspector Mini Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: ParakhColors.border),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ParakhColors.accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: ParakhColors.accent),
              ),
              title: Text(
                _inspector?.name ?? 'Inspector Officer',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              subtitle: Text(
                'Badge: ${_inspector?.inspectorId ?? "LM-OFFICER"}\n${_inspector?.designation ?? "Legal Metrology Inspector"}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.profile),
            ),
          ),
          const SizedBox(height: 16),

          // Menu Section 1: Official Tools
          _buildSectionHeader('OFFICIAL TOOLS & STATUTORY REFERENCES'),
          _buildMenuTile(
            icon: Icons.auto_stories_outlined,
            title: 'Legal Metrology Rules Assistant',
            subtitle: 'Interactive PCR 2011 rulebook and statutory clauses',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.assistant),
          ),
          _buildMenuTile(
            icon: Icons.qr_code_scanner_rounded,
            title: 'Barcode & QR Identifier',
            subtitle: 'Scan commodity barcodes for registration lookup',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.qrScan),
          ),
          _buildMenuTile(
            icon: Icons.tune_rounded,
            title: 'API Server Endpoint',
            subtitle: AppConfig.apiBaseUrl,
            onTap: _showConfigDialog,
          ),

          const SizedBox(height: 16),

          // Menu Section 2: Account & Security
          _buildSectionHeader('SESSION & ACCOUNT'),
          _buildMenuTile(
            icon: Icons.badge_outlined,
            title: 'Officer Profile Details',
            subtitle: 'Jurisdiction, state, and official email',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.profile),
          ),
          _buildMenuTile(
            icon: Icons.logout_rounded,
            title: 'Sign Out',
            subtitle: 'End secure inspection session',
            textColor: ParakhColors.nonCompliant,
            iconColor: ParakhColors.nonCompliant,
            onTap: _handleLogout,
          ),

          const SizedBox(height: 24),
          const Center(
            child: Text(
              'PARAKH Mobile v1.0.0\nNational Informatics Centre / Legal Metrology',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: ParakhColors.textTertiary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: ParakhColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: ParakhColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: iconColor ?? ParakhColors.accent),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: textColor ?? ParakhColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: ParakhColors.textSecondary),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: ParakhColors.textTertiary),
      ),
    );
  }
}
