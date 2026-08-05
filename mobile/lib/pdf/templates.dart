import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/resume.dart';

// Sidebar width for the Modern template (34% of an A4 page).
final double _sidebarW = PdfPageFormat.a4.width * 0.34;

pw.Document buildResumePdf(ResumeData raw) {
  // Sanitise every string so glyphs the built-in font can't encode (smart
  // quotes, em-dashes, Rs., non-Latin scripts, ...) never crash the renderer.
  final resume = _sanitizeResume(raw);
  final accent = PdfColor.fromInt(resume.accent);
  final doc = pw.Document();

  switch (resume.template) {
    case TemplateId.modern:
      _addModern(doc, resume, accent);
      break;
    case TemplateId.classic:
      doc.addPage(pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(48, 44, 48, 44),
        ),
        build: (ctx) => _classicChildren(resume, accent),
      ));
      break;
    case TemplateId.minimal:
      doc.addPage(pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(48, 50, 48, 50),
        ),
        build: (ctx) => _minimalChildren(resume, accent),
      ));
      break;
  }
  return doc;
}

/// A dead-simple, single-column document that cannot overflow - used as a
/// last-resort fallback if a styled template ever throws during layout.
pw.Document buildFallbackPdf(ResumeData raw) {
  final r = _sanitizeResume(raw);
  final doc = pw.Document();
  final out = <pw.Widget>[];

  void line(String s, {double size = 11, bool bold = false}) {
    if (s.trim().isEmpty) return;
    out.add(pw.Text(s,
        style: pw.TextStyle(
            fontSize: size,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)));
  }

  void heading(String s) {
    out.add(pw.SizedBox(height: 10));
    line(s.toUpperCase(), size: 12, bold: true);
    out.add(pw.SizedBox(height: 4));
  }

  line(r.name.isNotEmpty ? r.name : 'Your Name', size: 20, bold: true);
  line(r.title, size: 12);
  line([r.email, r.phone, r.location, r.linkedin]
      .where((e) => e.trim().isNotEmpty)
      .join('  |  '), size: 9);

  if (r.summary.isNotEmpty) {
    heading('Summary');
    line(r.summary);
  }
  if (r.experience.isNotEmpty) {
    heading('Experience');
    for (final e in r.experience) {
      line([e.role, e.company, e.duration].where((x) => x.trim().isNotEmpty).join(' - '),
          bold: true);
      line(e.description);
      out.add(pw.SizedBox(height: 6));
    }
  }
  if (r.skills.isNotEmpty) {
    heading('Skills');
    line(r.skills.join(', '));
  }
  if (r.education.isNotEmpty) {
    heading('Education');
    for (final e in r.education) {
      line([e.degree, e.institution, e.duration].where((x) => x.trim().isNotEmpty).join(' - '),
          bold: true);
      line(e.description);
      out.add(pw.SizedBox(height: 6));
    }
  }
  if (r.projects.isNotEmpty) {
    heading('Projects');
    for (final p in r.projects) {
      line([p.name, p.link].where((x) => x.trim().isNotEmpty).join(' - '), bold: true);
      line(p.description);
      out.add(pw.SizedBox(height: 6));
    }
  }
  if (r.languages.isNotEmpty) {
    heading('Languages');
    line(r.languages.join(', '));
  }
  if (out.isEmpty) out.add(pw.Text('Your Name'));

  doc.addPage(pw.MultiPage(
    pageTheme: pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(48, 48, 48, 48),
    ),
    build: (ctx) => out,
  ));
  return doc;
}

// ---- Text safety -----------------------------------------------------------

/// Maps common Unicode punctuation to ASCII and drops anything the standard
/// PDF (WinAnsi) fonts can't render, so text never throws during layout.
String _safe(String s) {
  if (s.isEmpty) return s;
  // Keyed by Unicode code point to avoid look-alike duplicate keys.
  const swaps = <int, String>{
    0x2018: "'", 0x2019: "'", 0x201A: "'", 0x201B: "'", // curly single quotes
    0x201C: '"', 0x201D: '"', 0x201E: '"', // curly double quotes
    0x2013: '-', 0x2014: '-', 0x2015: '-', 0x2212: '-', // en/em dash, minus
    0x2026: '...', // ellipsis
    0x2022: '-', 0x25CF: '-', 0x25AA: '-', 0x00B7: '-', // bullets / middle dot
    0x20B9: 'Rs.', // rupee
    0x2122: '(TM)', 0x00AE: '(R)', 0x00A9: '(C)',
    0xFB01: 'fi', 0xFB02: 'fl', // ligatures
  };
  final buf = StringBuffer();
  for (final rune in s.runes) {
    final swap = swaps[rune];
    if (swap != null) {
      buf.write(swap);
    } else if (rune == 0x0A || rune == 0x0D || rune == 0x09) {
      buf.write(String.fromCharCode(rune)); // keep newlines / tabs
    } else if (rune >= 0x20 && rune <= 0x7E) {
      buf.write(String.fromCharCode(rune)); // printable ASCII
    } else if (rune >= 0xA1 && rune <= 0xFF) {
      buf.write(String.fromCharCode(rune)); // Latin-1 (accents etc.)
    } else if (rune == 0xA0 || (rune >= 0x2000 && rune <= 0x200A) || rune == 0x202F) {
      buf.write(' '); // various Unicode spaces -> normal space
    }
    // else: unsupported glyph - drop it rather than crash.
  }
  return buf.toString();
}

List<String> _safeList(List<String> xs) =>
    xs.map(_safe).where((e) => e.trim().isNotEmpty).toList();

ResumeData _sanitizeResume(ResumeData r) => ResumeData(
      name: _safe(r.name),
      title: _safe(r.title),
      email: _safe(r.email),
      phone: _safe(r.phone),
      location: _safe(r.location),
      linkedin: _safe(r.linkedin),
      summary: _safe(r.summary),
      skills: _safeList(r.skills),
      experience: r.experience
          .map((e) => e.copyWith(
                role: _safe(e.role),
                company: _safe(e.company),
                duration: _safe(e.duration),
                description: _safe(e.description),
              ))
          .toList(),
      education: r.education
          .map((e) => e.copyWith(
                degree: _safe(e.degree),
                institution: _safe(e.institution),
                duration: _safe(e.duration),
                description: _safe(e.description),
              ))
          .toList(),
      projects: r.projects
          .map((p) => p.copyWith(
                name: _safe(p.name),
                description: _safe(p.description),
                link: _safe(p.link),
              ))
          .toList(),
      languages: _safeList(r.languages),
      template: r.template,
      accent: r.accent,
    );

// ---- Shared helpers --------------------------------------------------------

pw.Widget _h(String s, {double size = 11, PdfColor? color, bool bold = false}) =>
    pw.Text(
      s,
      style: pw.TextStyle(
        fontSize: size,
        color: color ?? PdfColors.grey800,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    );

pw.Widget _row(List<String> items) => pw.Wrap(
      spacing: 10,
      runSpacing: 2,
      children: items
          .where((e) => e.trim().isNotEmpty)
          .map((s) => pw.Text(s,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)))
          .toList(),
    );

/// Keeps a section [header] glued to its first item so a heading is never left
/// stranded at the bottom of a page while its content flows to the next one.
/// The header + first item become one non-splitting block (Padding is not a
/// spanning widget, so MultiPage moves it whole); remaining items paginate.
List<pw.Widget> _glue(List<pw.Widget> header, List<pw.Widget> items) {
  if (items.isEmpty) return header;
  return [
    pw.Padding(
      padding: pw.EdgeInsets.zero,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [...header, items.first],
      ),
    ),
    ...items.skip(1),
  ];
}

// ---- Classic ---------------------------------------------------------------

List<pw.Widget> _classicChildren(ResumeData r, PdfColor accent) {
  final out = <pw.Widget>[];

  out.add(pw.Center(
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          r.name.isNotEmpty ? r.name : 'Your Name',
          style: pw.TextStyle(
              fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
        ),
        if (r.title.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(r.title.toUpperCase(),
                style: const pw.TextStyle(
                    fontSize: 10, letterSpacing: 2, color: PdfColors.grey700)),
          ),
        pw.SizedBox(height: 6),
        _row([r.email, r.phone, r.location, r.linkedin]),
      ],
    ),
  ));
  out.add(pw.SizedBox(height: 6));
  out.add(pw.Container(height: 2, color: accent));
  out.add(pw.SizedBox(height: 14));

  void section(String title, List<pw.Widget> children) {
    out.addAll(_glue([_classicHeader(title, accent)], children));
    out.add(pw.SizedBox(height: 12));
  }

  if (r.summary.isNotEmpty) section('Summary', [_h(r.summary)]);
  if (r.experience.isNotEmpty) {
    section(
      'Experience',
      r.experience
          .map((e) => _experienceRow(e.role, e.company, e.duration, e.description))
          .toList(),
    );
  }
  if (r.skills.isNotEmpty) {
    section('Skills', [_h(r.skills.where((s) => s.trim().isNotEmpty).join('  -  '))]);
  }
  if (r.education.isNotEmpty) {
    section(
      'Education',
      r.education
          .map((e) => _experienceRow(e.degree, e.institution, e.duration, e.description))
          .toList(),
    );
  }
  if (r.projects.isNotEmpty) {
    section(
      'Projects',
      r.projects.map((p) => _experienceRow(p.name, p.link, '', p.description)).toList(),
    );
  }
  if (r.languages.isNotEmpty) {
    section('Languages', [_h(r.languages.where((l) => l.trim().isNotEmpty).join('  -  '))]);
  }
  return out;
}

pw.Widget _classicHeader(String title, PdfColor accent) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(title.toUpperCase(),
              style: pw.TextStyle(
                  fontSize: 10,
                  letterSpacing: 2,
                  color: accent,
                  fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Container(height: 0.5, color: PdfColor.fromInt(accent.toInt() | 0x33000000)),
          pw.SizedBox(height: 6),
        ],
      ),
    );

pw.Widget _experienceRow(String left, String right, String duration, String description) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.RichText(
                text: pw.TextSpan(children: [
                  pw.TextSpan(
                    text: left,
                    style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey900),
                  ),
                  if (right.isNotEmpty)
                    pw.TextSpan(
                      text: '  -  $right',
                      style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                    ),
                ]),
              ),
            ),
            if (duration.isNotEmpty) ...[
              pw.SizedBox(width: 8),
              pw.Text(duration,
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            ],
          ],
        ),
        if (description.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: _h(description),
          ),
      ],
    ),
  );
}

// ---- Modern (sidebar) ------------------------------------------------------
// The sidebar is painted as a full-height page band via buildBackground, with
// its text content drawn on page 1 only. The main column flows through
// MultiPage as a flat list of widgets, so it paginates without ever throwing.

void _addModern(pw.Document doc, ResumeData r, PdfColor accent) {
  final tint = PdfColor(accent.red, accent.green, accent.blue, 0.08);
  doc.addPage(pw.MultiPage(
    pageTheme: pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.only(left: _sidebarW + 24, right: 32, top: 34, bottom: 34),
      buildBackground: (ctx) => pw.FullPage(
        ignoreMargins: true,
        child: pw.Stack(
          children: [
            // Full-height sidebar band on every page.
            pw.Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: pw.Container(
                width: _sidebarW,
                decoration: pw.BoxDecoration(color: tint),
              ),
            ),
            // Sidebar text only on the first page.
            if (ctx.pageNumber == 1)
              pw.Positioned(
                left: 0,
                top: 0,
                child: pw.Container(
                  width: _sidebarW,
                  padding: const pw.EdgeInsets.all(24),
                  child: _modernSidebar(r, accent),
                ),
              ),
          ],
        ),
      ),
    ),
    build: (ctx) => _modernMain(r, accent),
  ));
}

pw.Widget _modernSidebar(ResumeData r, PdfColor accent) {
  final contacts = [r.email, r.phone, r.location, r.linkedin]
      .where((e) => e.trim().isNotEmpty)
      .toList();
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Container(width: 48, height: 4, color: accent),
      pw.SizedBox(height: 10),
      pw.Text(
        r.name.isNotEmpty ? r.name : 'Your Name',
        style: pw.TextStyle(
            fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
      ),
      if (r.title.isNotEmpty)
        pw.Text(r.title,
            style: pw.TextStyle(
                fontSize: 11, color: accent, fontWeight: pw.FontWeight.bold)),
      if (contacts.isNotEmpty) ...[
        pw.SizedBox(height: 14),
        _modernHeading('Contact', accent),
        ...contacts.map((s) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text(s,
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
            )),
      ],
      if (r.skills.isNotEmpty) ...[
        pw.SizedBox(height: 12),
        _modernHeading('Skills', accent),
        ...r.skills.where((s) => s.trim().isNotEmpty).map((s) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text('- $s',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
            )),
      ],
      if (r.education.isNotEmpty) ...[
        pw.SizedBox(height: 12),
        _modernHeading('Education', accent),
        ...r.education.map((e) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(e.degree,
                      style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey900)),
                  if (e.institution.isNotEmpty)
                    pw.Text(e.institution,
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  if (e.duration.isNotEmpty)
                    pw.Text(e.duration,
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
            )),
      ],
      if (r.languages.isNotEmpty) ...[
        pw.SizedBox(height: 12),
        _modernHeading('Languages', accent),
        pw.Text(r.languages.join(', '),
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
      ],
    ],
  );
}

List<pw.Widget> _modernMain(ResumeData r, PdfColor accent) {
  final out = <pw.Widget>[];
  if (r.summary.isNotEmpty) {
    out.addAll(_glue([_modernSection('Profile', accent)], [_h(r.summary)]));
    out.add(pw.SizedBox(height: 12));
  }
  if (r.experience.isNotEmpty) {
    final items = r.experience
        .map<pw.Widget>((e) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(e.role,
                            style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey900)),
                      ),
                      if (e.duration.isNotEmpty) ...[
                        pw.SizedBox(width: 8),
                        pw.Text(e.duration,
                            style: const pw.TextStyle(
                                fontSize: 9, color: PdfColors.grey600)),
                      ],
                    ],
                  ),
                  if (e.company.isNotEmpty)
                    pw.Text(e.company,
                        style: pw.TextStyle(
                            fontSize: 10,
                            fontStyle: pw.FontStyle.italic,
                            color: PdfColors.grey700)),
                  if (e.description.isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 2),
                      child: _h(e.description),
                    ),
                ],
              ),
            ))
        .toList();
    out.addAll(_glue([_modernSection('Experience', accent)], items));
    out.add(pw.SizedBox(height: 4));
  }
  if (r.projects.isNotEmpty) {
    final items = r.projects
        .map<pw.Widget>((p) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(p.name,
                            style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey900)),
                      ),
                      if (p.link.isNotEmpty) ...[
                        pw.SizedBox(width: 8),
                        pw.Text(p.link,
                            style: const pw.TextStyle(
                                fontSize: 9, color: PdfColors.grey600)),
                      ],
                    ],
                  ),
                  if (p.description.isNotEmpty) _h(p.description),
                ],
              ),
            ))
        .toList();
    out.addAll(_glue([_modernSection('Projects', accent)], items));
  }

  // If there is no main-column content at all, MultiPage needs at least one
  // widget - keep it non-empty so it never fails to build.
  if (out.isEmpty) out.add(pw.SizedBox());
  return out;
}

pw.Widget _modernHeading(String text, PdfColor accent) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(text.toUpperCase(),
          style: pw.TextStyle(
              fontSize: 9,
              letterSpacing: 1.5,
              color: accent,
              fontWeight: pw.FontWeight.bold)),
    );

pw.Widget _modernSection(String text, PdfColor accent) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(text.toUpperCase(),
              style: pw.TextStyle(
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: pw.FontWeight.bold,
                  color: accent)),
          pw.Container(height: 1.5, color: accent),
          pw.SizedBox(height: 6),
        ],
      ),
    );

// ---- Minimal (timeline) ----------------------------------------------------

List<pw.Widget> _minimalChildren(ResumeData r, PdfColor accent) {
  final out = <pw.Widget>[];

  out.add(pw.Text(
    r.name.isNotEmpty ? r.name : 'Your Name',
    style: pw.TextStyle(
        fontSize: 26, fontWeight: pw.FontWeight.normal, color: PdfColors.grey900),
  ));
  if (r.title.isNotEmpty) {
    out.add(pw.Padding(
      padding: const pw.EdgeInsets.only(top: 2),
      child: pw.Text(r.title,
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
    ));
  }
  out.add(pw.SizedBox(height: 8));
  out.add(_row([r.email, r.phone, r.location, r.linkedin]));
  out.add(pw.SizedBox(height: 16));

  void section(String title, List<pw.Widget> children) {
    out.addAll(_glue(
        [_minimalHeader(title, accent), pw.SizedBox(height: 8)], children));
    out.add(pw.SizedBox(height: 16));
  }

  if (r.summary.isNotEmpty) section('About', [_h(r.summary)]);
  if (r.experience.isNotEmpty) {
    section(
      'Experience',
      r.experience
          .map((e) => _minimalTimeline(e.duration, e.role, e.company, e.description))
          .toList(),
    );
  }
  if (r.education.isNotEmpty) {
    section(
      'Education',
      r.education
          .map((e) => _minimalTimeline(e.duration, e.degree, e.institution, e.description))
          .toList(),
    );
  }
  if (r.skills.isNotEmpty) section('Skills', [_h(r.skills.join(' / '))]);
  if (r.projects.isNotEmpty) {
    section(
      'Projects',
      r.projects.map((p) => _minimalTimeline('', p.name, p.link, p.description)).toList(),
    );
  }
  if (r.languages.isNotEmpty) section('Languages', [_h(r.languages.join(' / '))]);
  return out;
}

pw.Widget _minimalHeader(String title, PdfColor accent) => pw.Text(
      title.toUpperCase(),
      style: pw.TextStyle(
          fontSize: 9,
          letterSpacing: 3,
          color: accent,
          fontWeight: pw.FontWeight.bold),
    );

pw.Widget _minimalTimeline(String left, String title, String sub, String body) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 90,
          child: pw.Text(left,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(title,
                  style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey900)),
              if (sub.isNotEmpty)
                pw.Text(sub,
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              if (body.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: _h(body),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
