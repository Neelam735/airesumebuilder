import 'dart:io';
import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfExtract {
  /// Extracts plain text from a PDF file, suitable for sending to the AI
  /// improve endpoint. Returns the text; throws if the file is empty or
  /// unreadable.
  static Future<String> fromFile(File file) async {
    final bytes = await file.readAsBytes();
    return fromBytes(bytes);
  }

  static Future<String> fromBytes(Uint8List bytes) async {
    final document = PdfDocument(inputBytes: bytes);
    try {
      final extractor = PdfTextExtractor(document);
      final text = extractor.extractText();
      final cleaned = text.replaceAll(RegExp(r'[ \t]+'), ' ').trim();
      if (cleaned.isEmpty) {
        throw Exception('Could not extract any text from this PDF');
      }
      return cleaned;
    } finally {
      document.dispose();
    }
  }
}
