import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/document_draft.dart';
import '../domain/document_line.dart';

DocumentDraft documentDraftFromFirestoreMap(
  String id,
  Map<String, dynamic> data,
) {
  final rawLines = data['lines'] as List<dynamic>? ?? const <dynamic>[];

  return DocumentDraft(
    id: id,
    companyId: data['companyId'] as String? ?? '',
    customerId: data['customerId'] as String? ?? '',
    documentType: data['documentType'] as String? ?? 'proforma',
    status: data['status'] as String? ?? 'draft',
    documentNumber: data['documentNumber'] as String?,
    marginBasisPoints: data['marginBasisPoints'] as int? ?? 0,
    revisionNotes: data['revisionNotes'] as String? ?? '',
    sourcePdfFileName: data['sourcePdfFileName'] as String?,
    sourcePdfSizeInBytes: data['sourcePdfSizeInBytes'] as int?,
    sourcePdfText: data['sourcePdfText'] as String?,
    lines: rawLines
        .whereType<Map<String, dynamic>>()
        .map(documentLineFromFirestoreMap)
        .toList(growable: false),
    createdAt: _dateTimeFromFirestore(data['createdAt']),
    updatedAt: _dateTimeFromFirestore(data['updatedAt']),
  );
}

Map<String, dynamic> documentDraftToFirestoreMap(DocumentDraft draft) {
  return <String, dynamic>{
    'companyId': draft.companyId,
    'customerId': draft.customerId,
    'documentType': draft.documentType,
    'status': draft.status,
    'documentNumber': draft.documentNumber,
    'marginBasisPoints': draft.marginBasisPoints,
    'revisionNotes': draft.revisionNotes,
    'sourcePdfFileName': draft.sourcePdfFileName,
    'sourcePdfSizeInBytes': draft.sourcePdfSizeInBytes,
    'sourcePdfText': draft.sourcePdfText,
    'lines': draft.lines.map(documentLineToFirestoreMap).toList(),
    'createdAt': Timestamp.fromDate(draft.createdAt),
    'updatedAt': Timestamp.fromDate(draft.updatedAt),
  };
}

DocumentLine documentLineFromFirestoreMap(Map<String, dynamic> data) {
  return DocumentLine(
    id: data['id'] as String? ?? '',
    description: data['description'] as String? ?? '',
    quantityMilliunits: data['quantityMilliunits'] as int? ?? 1000,
    unitPriceCents: data['unitPriceCents'] as int? ?? 0,
    taxRateBasisPoints: data['taxRateBasisPoints'] as int? ?? 2100,
    sourceUnitPriceCents: data['sourceUnitPriceCents'] as int?,
    marginBasisPoints: data['marginBasisPoints'] as int?,
  );
}

Map<String, dynamic> documentLineToFirestoreMap(DocumentLine line) {
  return <String, dynamic>{
    'id': line.id,
    'description': line.description,
    'quantityMilliunits': line.quantityMilliunits,
    'unitPriceCents': line.unitPriceCents,
    'taxRateBasisPoints': line.taxRateBasisPoints,
    'sourceUnitPriceCents': line.sourceUnitPriceCents,
    'marginBasisPoints': line.marginBasisPoints,
  };
}

DateTime _dateTimeFromFirestore(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is DateTime) {
    return value;
  }

  return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}
