import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/job.dart';
import '../services/api.dart';
import '../state/resume_provider.dart';
import '../theme.dart';
import 'apply_dialog.dart';

class JobsPanel extends StatefulWidget {
  final ResumeApi api;
  const JobsPanel({super.key, required this.api});

  @override
  State<JobsPanel> createState() => _JobsPanelState();
}

class _JobsPanelState extends State<JobsPanel> {
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  List<JobMatch> _matches = const [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final resume = context.read<ResumeProvider>().data;
    setState(() {
      _loading = true;
      _error = null;
      _matches = const [];
    });
    try {
      final results = await widget.api.matchJobs(
        skills: resume.skills,
        title: _titleCtrl.text.isEmpty ? resume.title : _titleCtrl.text,
        location: _locationCtrl.text.isEmpty ? null : _locationCtrl.text,
        limit: 12,
      );
      setState(() {
        _matches = results;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final resume = context.watch<ResumeProvider>().data;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: AppColors.accent, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                const Text('Auto-apply by skills',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'We scan thousands of remote jobs and rank them against your resume\'s skills. '
              'Tap Apply to draft a tailored cover letter and open the listing.',
              style: TextStyle(color: AppColors.inkMuted, fontSize: 11),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _titleCtrl,
                  decoration: InputDecoration(
                    hintText: resume.title.isEmpty ? 'Role' : resume.title,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _locationCtrl,
                  decoration: const InputDecoration(hintText: 'Location'),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.travel_explore, size: 18),
              label: Text(_loading ? 'Scanning…' : 'Find matching jobs'),
              onPressed: (_loading || resume.skills.isEmpty) ? null : _search,
            ),
            if (resume.skills.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Add at least one skill to enable job matching.',
                    style: TextStyle(color: AppColors.inkMuted, fontSize: 11)),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!,
                    style: const TextStyle(color: AppColors.danger, fontSize: 12)),
              ),
            if (_matches.isNotEmpty) ...[
              const SizedBox(height: 12),
              ..._matches.map((j) => _JobCard(
                    job: j,
                    onApply: () => showDialog(
                      context: context,
                      builder: (_) => ApplyDialog(api: widget.api, job: j),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobMatch job;
  final VoidCallback onApply;
  const _JobCard({required this.job, required this.onApply});

  @override
  Widget build(BuildContext context) {
    final score = job.score.round();
    final (bg, fg) = score >= 70
        ? (AppColors.success.withOpacity(0.15), AppColors.success)
        : score >= 40
            ? (AppColors.warn.withOpacity(0.15), AppColors.warn)
            : (AppColors.soft, AppColors.inkMuted);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(
                    [job.company, job.location, job.jobType]
                        .where((e) => e.isNotEmpty)
                        .join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.inkMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: fg.withOpacity(0.3)),
              ),
              child: Text('$score% match',
                  style: TextStyle(
                      fontSize: 10, color: fg, fontWeight: FontWeight.w600)),
            ),
          ]),
          if (job.matchedSkills.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: job.matchedSkills.take(6).map((s) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.brand.withOpacity(0.2)),
                  ),
                  child: Text(s,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.accent)),
                );
              }).toList(),
            ),
          ],
          if (job.salary.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('💰 ${job.salary}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.inkMuted)),
            ),
          if (job.snippet.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                job.snippet,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.inkMuted, height: 1.3),
              ),
            ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('Apply with AI', style: TextStyle(fontSize: 12)),
                onPressed: onApply,
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
