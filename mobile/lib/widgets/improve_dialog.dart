import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/resume.dart';
import '../services/api.dart';
import '../services/billing.dart';
import '../services/pdf_extract.dart';
import '../state/resume_provider.dart';
import '../theme.dart';

enum _Stage {
  idle,
  paying,
  paid,
  extracting,
  improving,
  filling,
  done,
  error,
}

class ImproveDialog extends StatefulWidget {
  final ResumeApi api;
  final BillingService billing;

  const ImproveDialog({super.key, required this.api, required this.billing});

  @override
  State<ImproveDialog> createState() => _ImproveDialogState();
}

class _ImproveDialogState extends State<ImproveDialog> {
  _Stage _stage = _Stage.idle;
  String _status = '';
  String? _paymentToken;
  String? _error;

  Future<void> _startPurchase() async {
    setState(() {
      _stage = _Stage.paying;
      _error = null;
      _status = 'Opening Google Play…';
    });
    try {
      final token = await widget.billing.purchaseAndVerify(
        onStatus: (s) => setState(() => _status = s),
      );
      setState(() {
        _paymentToken = token;
        _stage = _Stage.paid;
        _status = 'Payment verified. Upload your PDF resume.';
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _stage = _Stage.error;
      });
    }
  }

  Future<void> _pickAndProcess() async {
    if (_paymentToken == null) return;
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;

    setState(() {
      _stage = _Stage.extracting;
      _error = null;
    });
    try {
      final text = await PdfExtract.fromFile(File(path));
      setState(() => _stage = _Stage.improving);

      final response = await widget.api.parseResume(
        paymentToken: _paymentToken!,
        resumeText: text,
      );
      final improved = (response['resume'] as Map<String, dynamic>?) ?? {};

      setState(() => _stage = _Stage.filling);
      if (!mounted) return;
      final next = _mergeAi(context.read<ResumeProvider>().data, improved);
      context.read<ResumeProvider>().replaceAll(next);

      setState(() => _stage = _Stage.done);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _stage = _Stage.error;
      });
    }
  }

  ResumeData _mergeAi(ResumeData current, Map<String, dynamic> ai) {
    String s(String key, [String fallback = '']) {
      final v = ai[key];
      return v is String && v.trim().isNotEmpty ? v.trim() : fallback;
    }

    List<String> list(String key) =>
        (ai[key] is List)
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
                    child: Text('Import & Improve Resume',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.inkMuted),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Upload your existing PDF and let AI rewrite it using strong, professional language.',
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
      case _Stage.paying:
        return _payCta();
      case _Stage.paid:
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
              'Your resume has been improved and the form is filled.',
              AppColors.success,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('View improved resume'),
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
              onPressed: () => setState(() {
                _error = null;
                _stage = _paymentToken != null ? _Stage.paid : _Stage.idle;
              }),
              child: const Text('Try again'),
            ),
          ],
        );
    }
  }

  Widget _payCta() {
    final price = widget.billing.product?.price ?? '₹29';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.brand.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.brand.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Unlock AI improvement',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    Text('One-time fee per use, billed by Google Play',
                        style: TextStyle(color: AppColors.inkMuted, fontSize: 11)),
                  ],
                ),
              ),
              Text(price,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brand)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ElevatedButton(
          onPressed: _stage == _Stage.paying ? null : _startPurchase,
          child: Text(_stage == _Stage.paying
              ? (_status.isNotEmpty ? _status : 'Processing…')
              : 'Pay with Google Play'),
        ),
        const SizedBox(height: 8),
        const Text(
          'Secure billing via Google Play. You\'ll be able to upload your PDF after the payment is verified.',
          style: TextStyle(color: AppColors.inkMuted, fontSize: 11),
        ),
      ],
    );
  }

  Widget _uploadCta() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _banner('Payment verified. Upload your resume PDF below.', AppColors.success),
        const SizedBox(height: 12),
        InkWell(
          onTap: _pickAndProcess,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.border,
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Icon(Icons.upload_file, size: 32, color: AppColors.brand),
                SizedBox(height: 6),
                Text('Tap to choose a PDF',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                SizedBox(height: 2),
                Text('Standard resumes work best',
                    style: TextStyle(color: AppColors.inkMuted, fontSize: 11)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _processing() {
    final steps = [
      ('Extracting resume', _Stage.extracting),
      ('Improving with AI', _Stage.improving),
      ('Auto-filling form', _Stage.filling),
    ];
    final activeIdx = steps.indexWhere((e) => e.$2 == _stage);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
