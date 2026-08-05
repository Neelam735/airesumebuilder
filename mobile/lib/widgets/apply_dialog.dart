import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/job.dart';
import '../services/api.dart';
import '../services/pdf_export.dart';
import '../state/resume_provider.dart';
import '../theme.dart';

class ApplyDialog extends StatefulWidget {
  final ResumeApi api;
  final JobMatch job;
  const ApplyDialog({super.key, required this.api, required this.job});

  @override
  State<ApplyDialog> createState() => _ApplyDialogState();
}

class _ApplyDialogState extends State<ApplyDialog> {
  String _letter = '';
  bool _drafting = true;
  bool _applying = false;
  bool _done = false;
  String? _error;
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
    _draft();
  }

  Future<void> _draft() async {
    final resume = context.read<ResumeProvider>().data;
    try {
      final letter = await widget.api.draftCoverLetter(
        name: resume.name,
        title: resume.title,
        summary: resume.summary,
        skills: resume.skills,
        jobTitle: widget.job.title,
        company: widget.job.company,
        jobDescription: widget.job.snippet,
      );
      setState(() {
        _letter = letter;
        _ctrl.text = letter;
        _drafting = false;
      });
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.message : e.toString();
        _drafting = false;
      });
    }
  }

  Future<void> _apply() async {
    setState(() => _applying = true);
    try {
      final resume = context.read<ResumeProvider>().data;
      final companySlug = widget.job.company
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-');
      final nameSlug = (resume.name.isEmpty ? 'resume' : resume.name)
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-');
      await PdfExport.shareOrSave(resume, filename: '$nameSlug-$companySlug.pdf');

      if (widget.job.url.isNotEmpty) {
        final uri = Uri.parse(widget.job.url);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      setState(() {
        _applying = false;
        _done = true;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _applying = false;
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                const Expanded(
                  child: Text('APPLY WITH AI',
                      style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.5,
                          color: AppColors.inkMuted)),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppColors.inkMuted),
                ),
              ]),
              Text(widget.job.title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              if (widget.job.company.isNotEmpty)
                Text(
                  [widget.job.company, widget.job.location]
                      .where((e) => e.isNotEmpty)
                      .join(' · '),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.inkMuted),
                ),
              const SizedBox(height: 16),
              if (_drafting)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.soft,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.brand),
                      ),
                      SizedBox(width: 10),
                      Text('Drafting tailored cover letter…',
                          style: TextStyle(color: AppColors.ink, fontSize: 13)),
                    ],
                  ),
                ),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                ),
              if (!_drafting && _error == null) ...[
                const Text('Cover letter (editable)',
                    style: TextStyle(color: AppColors.inkMuted, fontSize: 11)),
                const SizedBox(height: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: TextField(
                    controller: _ctrl,
                    minLines: 8,
                    maxLines: 14,
                    onChanged: (v) => _letter = v,
                    style: const TextStyle(
                        fontFamily: 'serif', fontSize: 13, height: 1.5),
                    decoration: const InputDecoration(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy letter'),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _letter));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cover letter copied'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(_done ? Icons.check : Icons.download_rounded,
                          size: 16),
                      label: Text(_applying
                          ? 'Preparing…'
                          : _done
                              ? 'Opened — apply now'
                              : 'Save PDF & open job'),
                      onPressed: (_applying || _done) ? null : _apply,
                    ),
                  ),
                ]),
                if (_done)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Your tailored resume PDF was shared and the job page opened in your browser. '
                      'Paste the letter into the application form.',
                      style: TextStyle(
                          color: AppColors.inkMuted, fontSize: 11, height: 1.4),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
