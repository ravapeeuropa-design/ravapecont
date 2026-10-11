import 'document_line.dart';

class DocumentDraft {
  const DocumentDraft({
    required this.id,
    required this.companyId,
    required this.customerId,
    required this.documentType,
    required this.status,
    required this.marginBasisPoints,
    required this.lines,
    required this.createdAt,
    required this.updatedAt,
    this.documentNumber,
    this.revisionNotes = '',
    this.sourcePdfFileName,
    this.sourcePdfSizeInBytes,
    this.sourcePdfText,
  });

  final String id;
  final String companyId;
  final String customerId;

  /// 'proforma' o 'invoice'.
  final String documentType;

  /// Para este bloque siempre será 'draft'.
  final String status;
  final String? documentNumber;

  /// Ejemplo: 1500 = 15,00 %.
  final int marginBasisPoints;

  final List<DocumentLine> lines;

  final String revisionNotes;
  final String? sourcePdfFileName;
  final int? sourcePdfSizeInBytes;
  final String? sourcePdfText;

  final DateTime createdAt;
  final DateTime updatedAt;

  DocumentDraft copyWith({
    String? id,
    String? companyId,
    String? customerId,
    String? documentType,
    String? status,
    String? documentNumber,
    int? marginBasisPoints,
    List<DocumentLine>? lines,
    String? revisionNotes,
    String? sourcePdfFileName,
    int? sourcePdfSizeInBytes,
    String? sourcePdfText,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DocumentDraft(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      customerId: customerId ?? this.customerId,
      documentType: documentType ?? this.documentType,
      status: status ?? this.status,
      documentNumber: documentNumber ?? this.documentNumber,
      marginBasisPoints: marginBasisPoints ?? this.marginBasisPoints,
      lines: lines ?? this.lines,
      revisionNotes: revisionNotes ?? this.revisionNotes,
      sourcePdfFileName: sourcePdfFileName ?? this.sourcePdfFileName,
      sourcePdfSizeInBytes: sourcePdfSizeInBytes ?? this.sourcePdfSizeInBytes,
      sourcePdfText: sourcePdfText ?? this.sourcePdfText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
