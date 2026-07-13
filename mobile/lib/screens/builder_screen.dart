import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api.dart';
import '../services/billing.dart';
import '../services/pdf_export.dart';
import '../state/resume_provider.dart';
import '../theme.dart';
import '../widgets/enhance_dialog.dart';
import '../widgets/forms.dart';
import '../widgets/payment_dialog.dart';
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
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    // Track the active tab so we can hide the Enhance FAB on the Preview tab
    // (where it would otherwise overlap the Download bar).
    _tabs.addListener(() {
      if (mounted && _tabs.index != _tab) setState(() => _tab = _tabs.index);
    });
    _api = ResumeApi();
    _billing = BillingService(_api);
    // Best-effort load of the in-app product so the price renders in the
    // payment dialog. Silent if Play Services isn't available (emulator).
    _billing.load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _billing.dispose();
    super.dispose();
  }

  /// Entry point for every "Download" tap in the app. Routes through the
  /// Google Play paywall if the resume has been AI-enhanced and not paid
  /// for yet. Otherwise the system Share/Save sheet opens directly.
  Future<void> _download() async {
    final provider = context.read<ResumeProvider>();
    final mustPay = provider.aiEnhanced && !provider.hasPaidForAi;

    if (mustPay) {
      final paid = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PaymentDialog(billing: _billing),
      );
      if (paid != true) return;
    }

    setState(() => _exporting = true);
    try {
      await PdfExport.shareOrSave(provider.data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not export PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _enhance() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => EnhanceDialog(api: _api),
    );
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset resume?'),
        content: const Text(
            'Your current data and any AI-enhancement unlock will be replaced '
            'with the example resume.'),
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
    final provider = context.watch<ResumeProvider>();
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
              Text('Build · Enhance',
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
            tooltip: provider.aiEnhanced && !provider.hasPaidForAi
                ? 'Download (paid for AI version)'
                : 'Download',
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
          ],
        ),
      ),
      // Hide the Enhance FAB on the Preview tab so it never covers the
      // Download bar. Enhance stays available from the Edit tab.
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              onPressed: _enhance,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Enhance Resume using AI'),
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
            )
          : null,
      body: TabBarView(
        controller: _tabs,
        children: [
          _editTab(),
          _previewTab(provider),
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

  Widget _previewTab(ResumeProvider provider) {
    return Stack(
      children: [
        const ResumePreview(),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: SafeArea(
            child: _DownloadBar(
              busy: _exporting,
              aiEnhanced: provider.aiEnhanced,
              paid: provider.hasPaidForAi,
              price: _billing.product?.price ?? '₹29',
              onPressed: _exporting ? null : _download,
            ),
          ),
        ),
      ],
    );
  }
}

class _DownloadBar extends StatelessWidget {
  final bool busy;
  final bool aiEnhanced;
  final bool paid;
  final String price;
  final VoidCallback? onPressed;

  const _DownloadBar({
    required this.busy,
    required this.aiEnhanced,
    required this.paid,
    required this.price,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final mustPay = aiEnhanced && !paid;
    final label = busy
        ? 'Preparing…'
        : mustPay
            ? 'Download (Pay $price)'
            : 'Download Resume';

    return Material(
      color: AppColors.card,
      elevation: 8,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (aiEnhanced)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  const Icon(Icons.auto_awesome,
                      size: 14, color: AppColors.brand),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      paid
                          ? 'AI-enhanced version unlocked. Re-download anytime.'
                          : 'AI-enhanced version. Pay $price to download the polished PDF.',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.inkMuted),
                    ),
                  ),
                ]),
              ),
            ElevatedButton.icon(
              icon: Icon(mustPay ? Icons.lock_open : Icons.download_rounded),
              label: Text(label),
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
