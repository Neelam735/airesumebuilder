import 'dart:typed_data';

import 'package:printing/printing.dart';

import '../models/resume.dart';
import '../pdf/templates.dart';

class PdfExport {
  static Future<Uint8List> render(ResumeData resume) async {
    try {
      final doc = buildResumePdf(resume);
      return await doc.save();
    } catch (_) {
      // A styled template failed to lay out (e.g. unusually long/complex
      // content) — fall back to a plain, always-safe document so the preview
      // and download never hard-fail.
      final doc = buildFallbackPdf(resume);
      return await doc.save();
    }
  }

  /// Show the system "Share / Save / Print" sheet for the rendered PDF.
  static Future<bool> shareOrSave(ResumeData resume, {String? filename}) async {
    final bytes = await render(resume);
    final safeName = (resume.name.isEmpty ? 'resume' : resume.name)
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return Printing.sharePdf(
      bytes: bytes,
      filename: filename ?? '$safeName.pdf',
    );
  }

  /// Open a print preview that mirrors the configured template.
  static Future<void> preview(ResumeData resume) async {
    await Printing.layoutPdf(
      onLayout: (_) => render(resume),
      name: resume.name.isEmpty ? 'Resume' : resume.name,
    );
  }
}
