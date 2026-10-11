import '../../../app/app_local_state.dart';
import '../../../core/utils/id_generator.dart';
import 'document_draft.dart';
import 'document_line.dart';

class DocumentDraftMapper {
  const DocumentDraftMapper._();

  static DocumentDraft fromLocalState(
    DocumentDraftState localDraft, {
    required String draftId,
    DateTime? createdAt,
  }) {
    final now = DateTime.now().toUtc();

    final companyId = localDraft.companyId;
    final customerId = localDraft.customerId;

    if (companyId == null || companyId.isEmpty) {
      throw StateError('Debes seleccionar una compañía.');
    }

    if (customerId == null || customerId.isEmpty) {
      throw StateError('Debes seleccionar un cliente.');
    }

    return DocumentDraft(
      id: draftId,
      companyId: companyId,
      customerId: customerId,
      documentType: localDraft.documentType,
      status: 'draft',
      documentNumber: localDraft.documentNumber,
      marginBasisPoints: localDraft.marginPercent * 100,
      revisionNotes: localDraft.revisionNotes,
      sourcePdfFileName: localDraft.sourcePdf?.fileName,
      sourcePdfSizeInBytes: localDraft.sourcePdf?.sizeInBytes,
      sourcePdfText: localDraft.sourcePdf?.extractedText,
      lines: localDraft.lines
          .map(
            (line) => DocumentLine(
              id: line.id.isEmpty ? IdGenerator.next() : line.id,
              description: line.article.trim(),
              quantityMilliunits: (line.quantity * 1000).round(),
              unitPriceCents:
                  (line.unitPriceWithMargin(localDraft.marginPercent) * 100)
                      .round(),
              taxRateBasisPoints: line.taxRate * 100,
              sourceUnitPriceCents: (line.sourceUnitPrice * 100).round(),
              marginBasisPoints: localDraft.marginPercent * 100,
            ),
          )
          .toList(growable: false),
      createdAt: createdAt ?? now,
      updatedAt: now,
    );
  }
}
