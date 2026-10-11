import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../domain/imported_pdf_source.dart';

class LocalPdfImportService {
  const LocalPdfImportService();

  static const int maxFileSizeInBytes = 20 * 1024 * 1024;

  Future<ImportedPdfSource?> pickAndExtract() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );

    if (file == null) {
      return null;
    }

    final bytes = await file.readAsBytes();

    if (bytes.isEmpty) {
      throw const PdfImportException(
        'No se pudieron leer los datos del PDF seleccionado.',
      );
    }

    if (bytes.lengthInBytes > maxFileSizeInBytes) {
      throw const PdfImportException(
        'El PDF supera el tamaño máximo permitido de 20 MB.',
      );
    }

    return _extract(
      fileName: file.name,
      bytes: bytes,
    );
  }

  ImportedPdfSource _extract({
    required String fileName,
    required Uint8List bytes,
  }) {
    PdfDocument? document;

    try {
      document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);

      final pageTexts = <String>[];

      for (var pageIndex = 0;
          pageIndex < document.pages.count;
          pageIndex++) {
        final pageText = extractor
            .extractText(
              startPageIndex: pageIndex,
              endPageIndex: pageIndex,
            )
            .trim();

        if (pageText.isNotEmpty) {
          pageTexts.add(
            '--- PÁGINA ${pageIndex + 1} ---\n$pageText',
          );
        }
      }

      final extractedText = pageTexts.join('\n\n').trim();

      return ImportedPdfSource(
        fileName: fileName,
        bytes: bytes,
        extractedText: extractedText,
        importedAt: DateTime.now().toUtc(),
        hasExtractableText: extractedText.isNotEmpty,
      );
    } catch (error) {
      return ImportedPdfSource(
        fileName: fileName,
        bytes: bytes,
        extractedText: '',
        importedAt: DateTime.now().toUtc(),
        hasExtractableText: false,
        extractionError: error.toString(),
      );
    } finally {
      document?.dispose();
    }
  }
}

class PdfImportException implements Exception {
  const PdfImportException(this.message);

  final String message;

  @override
  String toString() => message;
}
