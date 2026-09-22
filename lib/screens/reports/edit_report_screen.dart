import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/inspection_service.dart';
import '../../widgets/parakh_app_bar.dart';

class EditReportScreen extends StatefulWidget {
  final int inspectionId;
  const EditReportScreen({super.key, required this.inspectionId});

  @override
  State<EditReportScreen> createState() => _EditReportScreenState();
}

class _EditReportScreenState extends State<EditReportScreen> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _saveNotes() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report notes updated successfully.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParakhColors.backgroundDarker,
      appBar: ParakhAppBar(
        title: 'Edit Report Notes',
        subtitle: 'Inspection ${InspectionService().getDisplayId(widget.inspectionId)}',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                    'Inspector Field Observations & Directives',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: ParakhColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      hintText: 'Enter observation details to attach to the official inspection record...',
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveNotes,
                      child: const Text('Save Observations'),
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
}
