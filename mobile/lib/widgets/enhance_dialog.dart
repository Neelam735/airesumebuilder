import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/resume.dart';
import '../services/analytics.dart';
import '../services/api.dart';
import '../services/document_extract.dart';
import '../state/resume_provider.dart';
import '../theme.dart';

enum _Stage { idle, extracting, improving, filling, done, error }

/// Free flow: pick a PDF or Word (.docx) file, extract text, send to
/// /resume/parse, merge the AI-enhanced JSON back into the form, and flip the
/// aiEnhanced flag so the next download is paid.
class EnhanceDialog extends StatefulWidget {
  final ResumeApi api;
  final Analytics analytics;

  const EnhanceDialog({super.key, required this.api, required this.analytics});

  @override
  State<EnhanceDialog> createState() => _EnhanceDialogState();
}

class _EnhanceDialogState extends State<EnhanceDialog> {
  _Stage _stage = _Stage.idle;
  String? _error;
  double _progress = 0; // 0..1 shown as a percentage while enhancing
  Timer? _ticker;
  Timer? _autoClose;

  @override
  void dispose() {
    _ticker?.cancel();
    _autoClose?.cancel();
    super.dispose();
  }

  /// Close the dialog, signalling the caller whether enhancement succeeded
  /// (true → caller switches to the Preview tab).
  void _close(bool enhanced) {
    _ticker?.cancel();
    _autoClose?.cancel();
    if (mounted) Navigator.of(context).pop(enhanced);
  }

  /// Ceiling the bar eases toward for the current stage. The AI step has no
  /// real byte-progress, so we creep toward 0.9 to signal ongoing work.
  double get _stageTarget {
    switch (_stage) {
      case _Stage.extracting:
        return 0.25;
      case _Stage.improving:
        return 0.90;
      case _Stage.filling:
        return 0.97;
      case _Stage.done:
        return 1.0;
      default:
        return 0.0;
    }
  }

  /// Smoothly animate [_progress] toward the current stage's target so the
  /// percentage always appears to be moving, even during the long AI call.
  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_stage == _Stage.done) {
          _progress = 1.0;
          t.cancel();
        } else if (_stage == _Stage.error) {
          t.cancel();
        } else {
          _progress += (_stageTarget - _progress) * 0.08;
          if (_progress > 0.985) _progress = 0.985;
        }
      });
    });
  }

  Future<void> _pickAndProcess() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: DocumentExtract.allowedExtensions,
      allowMultiple: false,
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;

    final ext = path.contains('.') ? path.split('.').last.toLowerCase() : '';
    widget.analytics.log('enhance_started', ext);

    setState(() {
      _stage = _Stage.extracting;
      _error = null;
      _progress = 0.02;
    });
    _startTicker();
    try {
      final text = await DocumentExtract.fromFile(File(path));
      setState(() => _stage = _Stage.improving);

      final response = await widget.api.parseResume(
        paymentToken: '',
        resumeText: text,
      );
      final improved = (response['resume'] as Map<String, dynamic>?) ?? {};

      setState(() => _stage = _Stage.filling);
      if (!mounted) return;
      final provider = context.read<ResumeProvider>();
      final next = _mergeAi(provider.data, improved);
      provider.replaceAll(next);
      provider.markAiEnhanced();

      setState(() {
        _stage = _Stage.done;
        _progress = 1.0;
      });
      _ticker?.cancel();
      widget.analytics.log('enhance_success');
      // Briefly show 100% / success, then auto-advance to the Preview tab.
      _autoClose = Timer(const Duration(milliseconds: 1100), () => _close(true));
    } catch (e) {
      _ticker?.cancel();
      final msg = e.toString().replaceFirst('Exception: ', '');
      widget.analytics.log('enhance_failed', msg);
      setState(() {
        _error = msg;
        _stage = _Stage.error;
      });
    }
  }

  ResumeData _mergeAi(ResumeData current, Map<String, dynamic> ai) {
    String s(String key, [String fallback = '']) {
      final v = ai[key];
      return v is String && v.trim().isNotEmpty ? v.trim() : fallback;
    }

    List<String> list(String key) => (ai[key] is List)
        ? (ai[key] as List)
            .map((e) => e?.toString() ?? '')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList()
        : <String>[];

    final exp = (ai['experience'] is List)
        ? (ai['experience'] as List)
            .map((e) => Experience.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList()
        : current.experience;
    final edu = (ai['education'] is List)
        ? (ai['education'] as List)
            .map((e) => Education.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList()
        : current.education;
    final proj = (ai['projects'] is List)
        ? (ai['projects'] as List)
            .map((e) => Project.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList()
        : current.projects;

    return ResumeData(
      name: s('name', current.name),
      title: s('title', current.title),
      email: s('email', current.email),
      phone: s('phone', current.phone),
      location: s('location', current.location),
      linkedin: s('linkedin', current.linkedin),
      summary: s('summary', current.summary),
      skills: list('skills').isEmpty ? current.skills : list('skills'),
      experience: exp.isEmpty ? current.experience : exp,
      education: edu.isEmpty ? current.education : edu,
      projects: proj.isEmpty ? current.projects : proj,
      languages: list('languages').isEmpty ? current.languages : list('languages'),
      template: current.template,
      accent: current.accent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: AppColors.brand, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Enhance Resume using AI',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  IconButton(
                    onPressed: () => _close(_stage == _Stage.done),
                    icon: const Icon(Icons.close, color: AppColors.inkMuted),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Upload your existing PDF or Word (.docx) resume and let AI rewrite it '
                'using strong, professional language. '
                'Enhancement is free — payment is only required when you download.',
                style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              _body(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    switch (_stage) {
      case _Stage.idle:
        return _uploadCta();
      case _Stage.extracting:
      case _Stage.improving:
      case _Stage.filling:
        return _processing();
      case _Stage.done:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _banner(
              'Your resume has been enhanced. Opening the Preview tab so you '
              'can download it; payment is only needed when you tap Download.',
              AppColors.success,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _close(true),
              child: const Text('View & download'),
            ),
          ],
        );
      case _Stage.error:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _banner(_error ?? 'Something went wrong.', AppColors.danger),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                _ticker?.cancel();
                setState(() {
                  _error = null;
                  _stage = _Stage.idle;
                  _progress = 0;
                });
              },
              child: const Text('Try again'),
            ),
          ],
        );
    }
  }

  Widget _uploadCta() {
    return InkWell(
      onTap: _pickAndProcess,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          children: [
            Icon(Icons.upload_file, size: 32, color: AppColors.brand),
            SizedBox(height: 6),
            Text('Tap to choose a PDF or Word file',
                style: TextStyle(fontWeight: FontWeight.w500)),
            SizedBox(height: 2),
            Text('PDF or .docx — standard resumes work best',
                style: TextStyle(color: AppColors.inkMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _processing() {
    final steps = [
      ('Extracting resume', _Stage.extracting),
      ('Enhancing with AI', _Stage.improving),
      ('Auto-filling form', _Stage.filling),
    ];
    final activeIdx = steps.indexWhere((e) => e.$2 == _stage);
    final current = activeIdx >= 0 ? steps[activeIdx].$1 : 'Working';
    final double pct = _progress.clamp(0.0, 1.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Determinate progress bar with a live percentage. Real byte-progress
        // isn't available for the AI call, so the value eases toward each
        // stage's target (see _startTicker) to always look like it's moving.
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: AppColors.brand.withOpacity(0.15),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brand),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text('$current…',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink)),
            ),
            Text('${(pct * 100).round()}%',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brand)),
          ],
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < steps.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: i == activeIdx
                    ? AppColors.brand.withOpacity(0.6)
                    : i < activeIdx
                        ? AppColors.success.withOpacity(0.3)
                        : AppColors.border,
              ),
              color: i == activeIdx
                  ? AppColors.brand.withOpacity(0.08)
                  : i < activeIdx
                      ? AppColors.success.withOpacity(0.06)
                      : Colors.transparent,
            ),
            child: Row(children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < activeIdx
                      ? AppColors.success
                      : i == activeIdx
                          ? AppColors.brand
                          : AppColors.border,
                ),
              ),
              const SizedBox(width: 10),
              Text(steps[i].$1,
                  style: TextStyle(
                    color: i == activeIdx
                        ? AppColors.ink
                        : i < activeIdx
                            ? AppColors.success
                            : AppColors.inkMuted,
                  )),
            ]),
          ),
      ],
    );
  }

  Widget _banner(String text, Color tone) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tone.withOpacity(0.1),
        border: Border.all(color: tone.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(color: tone, fontSize: 13)),
    );
  }
}
