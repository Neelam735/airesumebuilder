import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../services/pdf_export.dart';
import '../state/resume_provider.dart';
import '../theme.dart';

/// Live resume preview rendered by rasterising the same PDF used for export,
/// so what you see is exactly what gets shared.
class ResumePreview extends StatelessWidget {
  const ResumePreview({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResumeProvider>();
    final resume = provider.data;

    return Container(
      color: AppColors.bg,
      child: PdfPreview(
        key: ValueKey(_previewKey(provider)),
        build: (_) => PdfExport.render(resume),
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        allowPrinting: false,
        allowSharing: false,
        useActions: false,
        loadingWidget: const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(color: AppColors.brand),
          ),
        ),
        scrollViewDecoration: const BoxDecoration(color: AppColors.bg),
      ),
    );
  }

  /// A cheap hash used to invalidate the cached PDF when any input changes.
  int _previewKey(ResumeProvider p) {
    final r = p.data;
    return Object.hashAll([
      r.name,
      r.title,
      r.email,
      r.phone,
      r.location,
      r.linkedin,
      r.summary,
      r.skills.join('|'),
      r.experience.map((e) => '${e.role}|${e.company}|${e.duration}|${e.description}').join('||'),
      r.education.map((e) => '${e.degree}|${e.institution}|${e.duration}|${e.description}').join('||'),
      r.projects.map((e) => '${e.name}|${e.link}|${e.description}').join('||'),
      r.languages.join('|'),
      r.template,
      r.accent,
    ]);
  }
}
