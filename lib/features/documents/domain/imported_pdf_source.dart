import 'dart:typed_data';

class ImportedPdfSource {
  const ImportedPdfSource({
    required this.fileName,
    required this.bytes,
    required this.extractedText,
    required this.importedAt,
    required this.hasExtractableText,
    this.extractionError,
  });

  final String fileName;
  final Uint8List bytes;
  final String extractedText;
  final DateTime importedAt;
  final bool hasExtractableText;
  final String? extractionError;

  int get sizeInBytes => bytes.lengthInBytes;
}
