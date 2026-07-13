import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import 'pdf_extract.dart';

/// Unified résumé text extraction for the "Enhance with AI" flow.
///
/// Supports:
///   • PDF  (.pdf)  — via [PdfExtract] (Syncfusion)
///   • Word (.docx) — by unzipping the OpenXML package and reading the text
///                    runs (`<w:t>`) out of `word/document.xml`.
///
/// Legacy binary Word (.doc, pre-2007) is NOT an OpenXML/ZIP file and cannot
/// be parsed reliably on-device, so it is rejected with a clear message.
class DocumentExtract {
  /// Extensions we advertise to the file picker.
  static const List<String> allowedExtensions = ['pdf', 'docx', 'doc'];

  /// Reads [file], picks an extractor by extension, and returns clean text.
  /// Throws with a user-friendly message on unsupported/empty input.
  static Future<String> fromFile(File file) async {
    final ext = _extensionOf(file.path);
    final bytes = await file.readAsBytes();
    return fromBytes(bytes, extension: ext);
  }

  /// Extracts text from raw [bytes]. [extension] should be the lowercase file
  /// extension without a dot (e.g. `pdf`, `docx`). When null/unknown we sniff
  /// the magic bytes so a mis-labelled file still works.
  static Future<String> fromBytes(Uint8List bytes, {String? extension}) async {
    final ext = extension ?? _sniff(bytes);
    switch (ext) {
      case 'pdf':
        return PdfExtract.fromBytes(bytes);
      case 'docx':
        return _fromDocx(bytes);
      case 'doc':
        throw Exception(
          'Old .doc files aren\'t supported. Open it in Word or Google Docs '
          'and save as .docx or PDF, then upload again.',
        );
      default:
        // Unknown extension — sniff the content before giving up.
        final sniffed = _sniff(bytes);
        if (sniffed == 'pdf') return PdfExtract.fromBytes(bytes);
        if (sniffed == 'docx') return _fromDocx(bytes);
        throw Exception('Unsupported file type. Upload a PDF or Word (.docx) file.');
    }
  }

  // ---- .docx -------------------------------------------------------------

  static Future<String> _fromDocx(Uint8List bytes) async {
    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw Exception('This Word file looks corrupted or is not a valid .docx.');
    }

    final entry = _findEntry(archive, 'word/document.xml');
    if (entry == null) {
      throw Exception('Could not read the Word document body (missing document.xml).');
    }

    final xmlString = utf8.decode(entry.content as List<int>, allowMalformed: true);
    final document = XmlDocument.parse(xmlString);

    final buffer = StringBuffer();
    // Walk the body in document order so paragraphs and line breaks are kept.
    for (final node in document.descendants.whereType<XmlElement>()) {
      switch (node.name.local) {
        case 't': // <w:t> — a run of visible text
          buffer.write(node.innerText);
          break;
        case 'tab': // <w:tab> — a tab stop
          buffer.write('\t');
          break;
        case 'br': // <w:br> — an explicit line break
        case 'cr':
          buffer.write('\n');
          break;
        case 'p': // <w:p> — end of a paragraph
          buffer.write('\n');
          break;
      }
    }

    final cleaned = buffer
        .toString()
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    if (cleaned.isEmpty) {
      throw Exception('Could not extract any text from this Word document.');
    }
    return cleaned;
  }

  // ---- helpers -----------------------------------------------------------

  static String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return '';
    return path.substring(dot + 1).toLowerCase();
  }

  static ArchiveFile? _findEntry(Archive archive, String name) {
    for (final f in archive.files) {
      if (f.isFile && f.name == name) return f;
    }
    return null;
  }

  /// Sniffs container magic bytes: PDFs start with `%PDF`, ZIP-based formats
  /// (including .docx) start with `PK\x03\x04`.
  static String _sniff(Uint8List b) {
    if (b.length >= 4 && b[0] == 0x25 && b[1] == 0x50 && b[2] == 0x44 && b[3] == 0x46) {
      return 'pdf'; // %PDF
    }
    if (b.length >= 4 && b[0] == 0x50 && b[1] == 0x4B && b[2] == 0x03 && b[3] == 0x04) {
      return 'docx'; // PK.. (zip) — assume OpenXML Word
    }
    return '';
  }
}
