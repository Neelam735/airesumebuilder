import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/analytics.dart';
import '../services/api.dart';
import '../services/billing.dart';
import '../services/docx_export.dart';
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
  late Analytics _analytics;
  bool _exporting = false;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    // Track the active tab so we can hide the Enhance FAB on the Preview tab
    // (where it would otherwise overlap the Download bar).
    _tabs.addListener(() {
      if (mounted && _tabs.index != _tab) {
        setState(() => _tab = _tabs.index);
        _analytics.log('tab_view', _tab == 0 ? 'edit' : 'preview');
      }
    });
    _api = ResumeApi();
    _billing = BillingService(_api);
    _analytics = Analytics(_api);
    _analytics.log('app_open');
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
  /// for yet, then exports as PDF or Word (.docx) via the system share sheet.
  Future<void> _download({bool word = false}) async {
    final provider = context.read<ResumeProvider>();
    final format = word ? 'word' : 'pdf';
    _analytics.log('download_tap', format);
    // Skip the Google Play paywall in debug builds — billing doesn't work on
    // debug/local builds anyway, so this lets you test downloads freely.
    // Release builds keep the paywall.
    final mustPay =
        !kDebugMode && provider.aiEnhanced && !provider.hasPaidForAi;

    if (mustPay) {
      _analytics.log('payment_shown');
      final paid = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PaymentDialog(billing: _billing),
      );
      if (paid != true) {
        _analytics.log('payment_cancelled');
        return;
      }
      _analytics.log('payment_success');
    }

    setState(() => _exporting = true);
    try {
      if (word) {
        await DocxExport.shareOrSave(provider.data);
      } else {
        await PdfExport.shareOrSave(provider.data);
      }
      _analytics.log('download_success', format);
    } catch (e) {
      _analytics.log('download_error', format);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not export ${word ? 'Word' : 'PDF'}: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _enhance() async {
    _analytics.log('enhance_opened');
    final enhanced = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EnhanceDialog(api: _api, analytics: _analytics),
    );
    // On a successful enhancement, jump to the Preview tab so the user can
    // review and download right away.
    if (enhanced == true && mounted) {
      _tabs.animateTo(1);
    }
  }

  static const _playUrl =
      'https://play.google.com/store/apps/details?id=com.neelam.resumebuilder';

  /// Trigger the Play in-app review flow; fall back to opening the store page.
  Future<void> _rateApp() async {
    _analytics.log('rate_app');
    final review = InAppReview.instance;
    try {
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await review.openStoreListing();
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the rating dialog.')),
      );
    }
  }

  /// Share the app's Play Store link via the system share sheet.
  Future<void> _shareApp() async {
    _analytics.log('share_app');
    await Share.share(
      'Build and AI-enhance your resume with AI Resume Builder — '
      'download it as PDF or Word:\n$_playUrl',
      subject: 'AI Resume Builder',
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
      _analytics.log('reset');
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
              Text('AI Resume Builder',
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
          _exporting
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.ink),
                  ),
                )
              : PopupMenuButton<String>(
                  tooltip: 'Download',
                  icon: const Icon(Icons.ios_share, color: AppColors.ink),
                  onSelected: (v) => _download(word: v == 'word'),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'pdf',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.picture_as_pdf),
                        title: Text('Download PDF'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'word',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.description),
                        title: Text('Download Word (.docx)'),
                      ),
                    ),
                  ],
                ),
          PopupMenuButton<String>(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert, color: AppColors.inkMuted),
            onSelected: (v) {
              switch (v) {
                case 'rate':
                  _rateApp();
                  break;
                case 'share':
                  _shareApp();
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'rate',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.star_rate_rounded),
                  title: Text('Rate app'),
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.share),
                  title: Text('Share app'),
                ),
              ),
            ],
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
              onDownloadPdf: _exporting ? null : () => _download(word: false),
              onDownloadWord: _exporting ? null : () => _download(word: true),
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
  final VoidCallback? onDownloadPdf;
  final VoidCallback? onDownloadWord;

  const _DownloadBar({
    required this.busy,
    required this.aiEnhanced,
    required this.paid,
    required this.price,
    required this.onDownloadPdf,
    required this.onDownloadWord,
  });

  @override
  Widget build(BuildContext context) {
    // Debug builds bypass the paywall (see _download), so don't show a pay hint.
    final mustPay = !kDebugMode && aiEnhanced && !paid;
    final payHint = mustPay ? ' (Pay $price)' : '';

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
                      mustPay
                          ? 'AI-enhanced version. Pay $price to download the polished resume.'
                          : 'AI-enhanced version unlocked. Re-download anytime.',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.inkMuted),
                    ),
                  ),
                ]),
              ),
            if (busy)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.brand),
                  ),
                ),
              )
            else
              Row(children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(mustPay ? Icons.lock_open : Icons.picture_as_pdf,
                        size: 18),
                    label: Text('PDF$payHint'),
                    onPressed: onDownloadPdf,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(mustPay ? Icons.lock_open : Icons.description,
                        size: 18),
                    label: const Text('Word'),
                    onPressed: onDownloadWord,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ]),
          ],
        ),
      ),
    );
  }
}
