import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/resume.dart';

pw.Document buildResumePdf(ResumeData resume) {
  final accent = PdfColor.fromInt(resume.accent);
  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(0),
      maxPages: 100,
      build: (ctx) => _dispatchWidgets(resume, accent),
    ),
  );
  return doc;
}

List<pw.Widget> _dispatchWidgets(ResumeData r, PdfColor accent) {
  switch (r.template) {
    case TemplateId.classic:
      return [_classic(r, accent)];
    case TemplateId.modern:
      return _modernBlocks(r, accent);
    case TemplateId.minimal:
      return [_minimal(r, accent)];
  }
}

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

pw.Widget _muted(String s, {double size = 9}) => pw.Text(
      s,
      style: pw.TextStyle(fontSize: size, color: PdfColors.grey600),
    );

pw.Widget _row(List<String> items, {String sep = ' · '}) =>
    pw.Wrap(
      spacing: 10,
      runSpacing: 2,
      children: items
          .where((e) => e.trim().isNotEmpty)
          .map((s) => pw.Text(s, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)))
          .toList(),
    );

// ---- Classic ---------------------------------------------------------------

pw.Widget _classic(ResumeData r, PdfColor accent) {
  return pw.Padding(
    padding: const pw.EdgeInsets.fromLTRB(48, 44, 48, 44),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Center(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                r.name.isNotEmpty ? r.name : 'Your Name',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900,
                ),
              ),
              if (r.title.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text(
                    r.title.toUpperCase(),
                    style: const pw.TextStyle(
                      fontSize: 10,
                      letterSpacing: 2,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
              pw.SizedBox(height: 6),
              _row([r.email, r.phone, r.location, r.linkedin]),
            ],
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Container(height: 2, color: accent),
        pw.SizedBox(height: 14),
        if (r.summary.isNotEmpty) _classicSection('Summary', accent, [_h(r.summary)]),
        if (r.experience.isNotEmpty)
          _classicSection(
            'Experience',
            accent,
            r.experience
                .map((e) => _experienceRow(e.role, e.company, e.duration, e.description))
                .toList(),
          ),
        if (r.skills.isNotEmpty)
          _classicSection(
            'Skills',
            accent,
            [_h(r.skills.where((s) => s.trim().isNotEmpty).join(' · '))],
          ),
        if (r.education.isNotEmpty)
          _classicSection(
            'Education',
            accent,
            r.education
                .map((e) => _experienceRow(e.degree, e.institution, e.duration, e.description))
                .toList(),
          ),
        if (r.projects.isNotEmpty)
          _classicSection(
            'Projects',
            accent,
            r.projects
                .map((p) => _experienceRow(p.name, p.link, '', p.description))
                .toList(),
          ),
        if (r.languages.isNotEmpty)
          _classicSection(
            'Languages',
            accent,
            [_h(r.languages.where((l) => l.trim().isNotEmpty).join(' · '))],
          ),
      ],
    ),
  );
}

pw.Widget _classicSection(String title, PdfColor accent, List<pw.Widget> children) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 14),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 10,
            letterSpacing: 2,
            color: accent,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Container(height: 0.5, color: PdfColor.fromInt(accent.toInt() | 0x33000000)),
        pw.SizedBox(height: 6),
        ...children,
      ],
    ),
  );
}

pw.Widget _experienceRow(String left, String right, String duration, String description) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
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
                      color: PdfColors.grey900,
                    ),
                  ),
                  if (right.isNotEmpty)
                    pw.TextSpan(
                      text: '  ·  $right',
                      style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                    ),
                ]),
              ),
            ),
            if (duration.isNotEmpty)
              pw.Text(duration, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
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

pw.Widget _modern(ResumeData r, PdfColor accent) {
  final tint = PdfColor(accent.red, accent.green, accent.blue, 0.08);
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Container(
        color: tint,
        padding: const pw.EdgeInsets.fromLTRB(28, 24, 28, 18),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(width: 48, height: 4, color: accent),
            pw.SizedBox(height: 10),
            pw.Text(
              r.name.isNotEmpty ? r.name : 'Your Name',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
            ),
            if (r.title.isNotEmpty)
              pw.Text(r.title, style: pw.TextStyle(fontSize: 11, color: accent, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 14),
            _modernHeading('Contact', accent),
            ...[r.email, r.phone, r.location, r.linkedin].where((e) => e.trim().isNotEmpty).map(
                  (s) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: pw.Text(s, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                  ),
                ),
            if (r.skills.isNotEmpty) ...[
              pw.SizedBox(height: 6),
              _muted('${r.skills.where((s) => s.trim().isNotEmpty).length} skills listed', size: 8),
            ],
          ],
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(28, 18, 28, 28),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            if (r.education.isNotEmpty) ...[
              if (r.skills.isNotEmpty) ...[
                _modernSection('Skills', accent),
                pw.Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: r.skills
                      .where((s) => s.trim().isNotEmpty)
                      .map(
                        (s) => pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: pw.BoxDecoration(
                            color: PdfColor(accent.red, accent.green, accent.blue, 0.14),
                            borderRadius: pw.BorderRadius.circular(3),
                          ),
                          child: pw.Text(s, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey900)),
                        ),
                      )
                      .toList(),
                ),
                pw.SizedBox(height: 8),
              ],
              _modernSection('Education', accent),
              ...r.education.map(
                (e) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(e.degree, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
                      if (e.institution.isNotEmpty) pw.Text(e.institution, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      if (e.duration.isNotEmpty) pw.Text(e.duration, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    ],
                  ),
                ),
              ),
            ],
            if (r.languages.isNotEmpty) ...[
              _modernSection('Languages', accent),
              pw.Text(r.languages.join(', '), style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
              pw.SizedBox(height: 8),
            ],
            if (r.summary.isNotEmpty) ...[
              _modernSection('Profile', accent),
              _h(r.summary),
              pw.SizedBox(height: 12),
            ],
            if (r.experience.isNotEmpty) ...[
              _modernSection('Experience', accent),
              ...r.experience.map((e) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Expanded(
                              child: pw.Text(e.role,
                                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
                            ),
                            if (e.duration.isNotEmpty) pw.Text(e.duration, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                          ],
                        ),
                        if (e.company.isNotEmpty)
                          pw.Text(e.company, style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
                        if (e.description.isNotEmpty)
                          pw.Padding(padding: const pw.EdgeInsets.only(top: 2), child: _h(e.description)),
                      ],
                    ),
                  )),
            ],
            if (r.projects.isNotEmpty) ...[
              _modernSection('Projects', accent),
              ...r.projects.map((p) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Expanded(
                              child: pw.Text(p.name,
                                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
                            ),
                            if (p.link.isNotEmpty) pw.Text(p.link, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                          ],
                        ),
                        if (p.description.isNotEmpty) _h(p.description),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    ],
  );
}

List<pw.Widget> _modernBlocks(ResumeData r, PdfColor accent) {
  final tint = PdfColor(accent.red, accent.green, accent.blue, 0.08);
  final sections = <pw.Widget>[
    pw.Container(
      color: tint,
      padding: const pw.EdgeInsets.fromLTRB(28, 24, 28, 18),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(width: 48, height: 4, color: accent),
          pw.SizedBox(height: 10),
          pw.Text(
            r.name.isNotEmpty ? r.name : 'Your Name',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
          ),
          if (r.title.isNotEmpty)
            pw.Text(r.title, style: pw.TextStyle(fontSize: 11, color: accent, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 14),
          _modernHeading('Contact', accent),
          ...[r.email, r.phone, r.location, r.linkedin].where((e) => e.trim().isNotEmpty).map(
                (s) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Text(s, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                ),
              ),
        ],
      ),
    ),
  ];

  void addSection(String title, List<pw.Widget> children, {double bottom = 8}) {
    if (children.isEmpty) return;
    sections.add(
      pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(28, 18, 28, 0),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
          _modernSection(title, accent),
          ...children,
          pw.SizedBox(height: bottom),
        ]),
      ),
    );
  }

  addSection('Skills', r.skills.where((s) => s.trim().isNotEmpty).map((s) => pw.Container(
    margin: const pw.EdgeInsets.only(right: 4, bottom: 4),
    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: pw.BoxDecoration(
      color: PdfColor(accent.red, accent.green, accent.blue, 0.14),
      borderRadius: pw.BorderRadius.circular(3),
    ),
    child: pw.Text(s, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey900)),
  )).toList(), bottom: 4);

  addSection('Education', r.education.map((e) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(e.degree, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
      if (e.institution.isNotEmpty) pw.Text(e.institution, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
      if (e.duration.isNotEmpty) pw.Text(e.duration, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
    ]),
  )).toList());

  if (r.languages.isNotEmpty) {
    addSection('Languages', [
      pw.Text(r.languages.join(', '), style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
    ]);
  }
  if (r.summary.isNotEmpty) addSection('Profile', [_h(r.summary)], bottom: 12);
  addSection('Experience', r.experience.map((e) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Expanded(child: pw.Text(e.role, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900))),
        if (e.duration.isNotEmpty) pw.Text(e.duration, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
      ]),
      if (e.company.isNotEmpty) pw.Text(e.company, style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
      if (e.description.isNotEmpty) pw.Padding(padding: const pw.EdgeInsets.only(top: 2), child: _h(e.description)),
    ]),
  )).toList());
  addSection('Projects', r.projects.map((p) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Expanded(child: pw.Text(p.name, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900))),
        if (p.link.isNotEmpty) pw.Text(p.link, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
      ]),
      if (p.description.isNotEmpty) _h(p.description),
    ]),
  )).toList());

  return sections;
}

pw.Widget _modernHeading(String text, PdfColor accent) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        text.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 9,
          letterSpacing: 1.5,
          color: accent,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );

pw.Widget _modernSection(String text, PdfColor accent) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            text.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: pw.FontWeight.bold,
              color: accent,
            ),
          ),
          pw.Container(height: 1.5, color: accent),
          pw.SizedBox(height: 6),
        ],
      ),
    );

// ---- Minimal (timeline) ----------------------------------------------------

pw.Widget _minimal(ResumeData r, PdfColor accent) {
  return pw.Padding(
    padding: const pw.EdgeInsets.fromLTRB(48, 50, 48, 50),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(
          r.name.isNotEmpty ? r.name : 'Your Name',
          style: pw.TextStyle(
            fontSize: 26,
            fontWeight: pw.FontWeight.normal,
            color: PdfColors.grey900,
          ),
        ),
        if (r.title.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(r.title,
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
          ),
        pw.SizedBox(height: 8),
        _row([r.email, r.phone, r.location, r.linkedin]),
        pw.SizedBox(height: 16),
        if (r.summary.isNotEmpty) _minimalSection('About', accent, _h(r.summary)),
        if (r.experience.isNotEmpty)
          _minimalSection(
            'Experience',
            accent,
            pw.Column(
              children: r.experience
                  .map((e) => _minimalTimeline(e.duration, e.role, e.company, e.description))
                  .toList(),
            ),
          ),
        if (r.education.isNotEmpty)
          _minimalSection(
            'Education',
            accent,
            pw.Column(
              children: r.education
                  .map((e) => _minimalTimeline(e.duration, e.degree, e.institution, e.description))
                  .toList(),
            ),
          ),
        if (r.skills.isNotEmpty)
          _minimalSection('Skills', accent, _h(r.skills.join(' / '))),
        if (r.projects.isNotEmpty)
          _minimalSection(
            'Projects',
            accent,
            pw.Column(
              children: r.projects
                  .map((p) => _minimalTimeline('', p.name, p.link, p.description))
                  .toList(),
            ),
          ),
        if (r.languages.isNotEmpty)
          _minimalSection('Languages', accent, _h(r.languages.join(' / '))),
      ],
    ),
  );
}

pw.Widget _minimalSection(String title, PdfColor accent, pw.Widget child) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 16),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 9,
            letterSpacing: 3,
            color: accent,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        child,
      ],
    ),
  );
}

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
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey700)),
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
