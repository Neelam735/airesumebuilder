import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api.dart';
import '../services/billing.dart';
import '../services/pdf_export.dart';
import '../state/resume_provider.dart';
import '../theme.dart';
import '../widgets/apply_dialog.dart' show ApplyDialog; // unused but explicit
import '../widgets/forms.dart';
import '../widgets/improve_dialog.dart';
import '../widgets/jobs_panel.dart';
import '../widgets/preview_widget.dart';

class BuilderScreen extends StatefulWidget {
  const BuilderScreen({super.key});

  @override
  State<BuilderScreen> createState() => _BuilderScreenState();
}

class _BuilderScreenState extends State<BuilderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late ResumeApi _api;
  late BillingService _billing;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _api = ResumeApi();
    _billing = BillingService(_api);
    // Best-effort load. If Play isn't reachable (e.g. running on emulator
    // without Play Services), the Improve dialog will surface the error.
    _billing.load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _billing.dispose();
    super.dispose();
  }

  Future<void> _download() async {
    final resume = context.read<ResumeProvider>().data;
    setState(() => _exporting = true);
    try {
      await PdfExport.shareOrSave(resume);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not export PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _improve() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ImproveDialog(api: _api, billing: _billing),
    );
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset resume?'),
        content: const Text(
            'Your current data will be replaced with the example resume.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      context.read<ResumeProvider>().resetToSample();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.brand.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(
              child: Text('R',
                  style: TextStyle(
                      color: AppColors.brand, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Resume Forge AI',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              Text('Build · Improve · Apply',
                  style: TextStyle(fontSize: 10, color: AppColors.inkMuted)),
            ],
          ),
        ]),
        actions: [
          IconButton(
            tooltip: 'Reset',
            icon: const Icon(Icons.refresh, color: AppColors.inkMuted),
            onPressed: _confirmReset,
          ),
          IconButton(
            tooltip: 'Download PDF',
            icon: _exporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.ink),
                  )
                : const Icon(Icons.ios_share, color: AppColors.ink),
            onPressed: _exporting ? null : _download,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.brand,
          unselectedLabelColor: AppColors.inkMuted,
          indicatorColor: AppColors.brand,
          tabs: const [
            Tab(icon: Icon(Icons.edit_note, size: 20), text: 'Edit'),
            Tab(icon: Icon(Icons.preview, size: 20), text: 'Preview'),
            Tab(icon: Icon(Icons.work_outline, size: 20), text: 'Jobs'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _improve,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Improve'),
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _editTab(),
          const ResumePreview(),
          SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: JobsPanel(api: _api),
          ),
        ],
      ),
    );
  }

  Widget _editTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: const [
        CustomizationCard(),
        PersonalInfoForm(),
        SkillsForm(),
        ExperienceForm(),
        EducationForm(),
        ProjectsForm(),
        LanguagesForm(),
        SizedBox(height: 80), // breathing room for FAB
      ],
    );
  }
}
