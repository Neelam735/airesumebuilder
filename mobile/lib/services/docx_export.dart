import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/resume.dart';

/// Generates a Word (.docx) version of the resume.
///
/// A .docx is just a ZIP of OpenXML parts. We assemble the minimum set Word
/// needs — `[Content_Types].xml`, `_rels/.rels`, and `word/document.xml` — and
/// render a clean, single‑column, ATS‑friendly layout.
class DocxExport {
  /// Build the .docx file as bytes.
  static Uint8List build(ResumeData r) {
    final accentHex = _hex(r.accent);
    final body = StringBuffer();

    // Header: name + title + contact line.
    body.write(_para(r.name.isNotEmpty ? r.name : 'Your Name',
        size: 40, bold: true, color: '111111', after: 20));
    if (r.title.trim().isNotEmpty) {
      body.write(_para(r.title, size: 24, color: '444444', after: 40));
    }
    final contact = [r.email, r.phone, r.location, r.linkedin]
        .where((e) => e.trim().isNotEmpty)
        .join('   |   ');
    if (contact.isNotEmpty) {
      body.write(_para(contact, size: 18, color: '555555', after: 120));
    }

    void section(String title, void Function() content) {
      body.write(_heading(title, accentHex));
      content();
    }

    if (r.summary.trim().isNotEmpty) {
      section('Summary', () => body.write(_para(r.summary, after: 120)));
    }

    if (r.experience.isNotEmpty) {
      section('Experience', () {
        for (final e in r.experience) {
          body.write(_entryHeading(e.role, e.company, e.duration));
          if (e.description.trim().isNotEmpty) {
            body.write(_para(e.description, after: 140));
          } else {
            body.write(_spacer());
          }
        }
      });
    }

    if (r.skills.isNotEmpty) {
      section('Skills',
          () => body.write(_para(r.skills.join('  •  '), after: 120)));
    }

    if (r.education.isNotEmpty) {
      section('Education', () {
        for (final e in r.education) {
          body.write(_entryHeading(e.degree, e.institution, e.duration));
          if (e.description.trim().isNotEmpty) {
            body.write(_para(e.description, after: 140));
          } else {
            body.write(_spacer());
          }
        }
      });
    }

    if (r.projects.isNotEmpty) {
      section('Projects', () {
        for (final p in r.projects) {
          body.write(_entryHeading(p.name, p.link, ''));
          if (p.description.trim().isNotEmpty) {
            body.write(_para(p.description, after: 140));
          } else {
            body.write(_spacer());
          }
        }
      });
    }

    if (r.languages.isNotEmpty) {
      section('Languages',
          () => body.write(_para(r.languages.join(',  '), after: 120)));
    }

    final documentXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
        '<w:body>'
        '$body'
        '<w:sectPr>'
        '<w:pgSz w:w="11906" w:h="16838"/>'
        '<w:pgMar w:top="1080" w:right="1080" w:bottom="1080" w:left="1080" '
        'w:header="720" w:footer="720" w:gutter="0"/>'
        '</w:sectPr>'
        '</w:body>'
        '</w:document>';

    final archive = Archive();
    void add(String name, String content) {
      final bytes = utf8.encode(content);
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }

    add('[Content_Types].xml', _contentTypesXml);
    add('_rels/.rels', _relsXml);
    add('word/document.xml', documentXml);

    final zipped = ZipEncoder().encode(archive)!;
    return Uint8List.fromList(zipped);
  }

  /// Write the .docx to a temp file and open the system share/save sheet.
  static Future<void> shareOrSave(ResumeData r) async {
    final bytes = build(r);
    final safeName = (r.name.isEmpty ? 'resume' : r.name)
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${safeName.isEmpty ? 'resume' : safeName}.docx');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles(
      [
        XFile(
          file.path,
          mimeType:
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        )
      ],
      subject: '${r.name.isEmpty ? 'Resume' : r.name} — Resume',
    );
  }

  // ---- XML building helpers ------------------------------------------------

  static String _heading(String text, String accentHex) =>
      '<w:p><w:pPr><w:spacing w:before="200" w:after="60"/>'
      '<w:pBdr><w:bottom w:val="single" w:sz="6" w:space="1" w:color="$accentHex"/></w:pBdr>'
      '</w:pPr>'
      '<w:r><w:rPr><w:b/><w:caps/><w:color w:val="$accentHex"/>'
      '<w:sz w:val="24"/><w:szCs w:val="24"/></w:rPr>'
      '<w:t xml:space="preserve">${_esc(text)}</w:t></w:r></w:p>';

  static String _entryHeading(String left, String right, String duration) {
    final title = [left, right].where((s) => s.trim().isNotEmpty).join('  —  ');
    final runs = StringBuffer()
      ..write('<w:r><w:rPr><w:b/><w:sz w:val="22"/><w:szCs w:val="22"/></w:rPr>'
          '<w:t xml:space="preserve">${_esc(title)}</w:t></w:r>');
    if (duration.trim().isNotEmpty) {
      runs.write('<w:r><w:rPr><w:color w:val="666666"/>'
          '<w:sz w:val="18"/><w:szCs w:val="18"/></w:rPr>'
          '<w:t xml:space="preserve">   (${_esc(duration)})</w:t></w:r>');
    }
    return '<w:p><w:pPr><w:spacing w:before="80" w:after="20"/>'
        '<w:keepNext/></w:pPr>$runs</w:p>';
  }

  static String _para(String text,
      {int size = 22, bool bold = false, String color = '222222', int after = 80}) {
    final runs = text.split('\n').map((line) {
      return '<w:r><w:rPr>${bold ? '<w:b/>' : ''}'
          '<w:color w:val="$color"/><w:sz w:val="$size"/><w:szCs w:val="$size"/></w:rPr>'
          '<w:t xml:space="preserve">${_esc(line)}</w:t></w:r>';
    }).join('<w:r><w:br/></w:r>');
    return '<w:p><w:pPr><w:spacing w:after="$after" w:line="276" w:lineRule="auto"/>'
        '</w:pPr>$runs</w:p>';
  }

  static String _spacer() => '<w:p><w:pPr><w:spacing w:after="80"/></w:pPr></w:p>';

  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  /// ARGB int -> "RRGGBB" hex (drops alpha).
  static String _hex(int argb) {
    final rgb = argb & 0x00FFFFFF;
    return rgb.toRadixString(16).padLeft(6, '0').toUpperCase();
  }

  static const String _contentTypesXml =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/word/document.xml" '
      'ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
      '</Types>';

  static const String _relsXml =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" '
      'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" '
      'Target="word/document.xml"/>'
      '</Relationships>';
}
