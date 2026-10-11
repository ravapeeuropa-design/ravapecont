import 'package:flutter/foundation.dart';

import '../features/documents/domain/document_draft.dart';
import '../features/documents/domain/document_line_draft.dart';
import '../features/documents/domain/imported_pdf_source.dart';
import '../features/invoices/domain/invoice.dart';
import 'app_routes.dart';

class DocumentDraftState {
  const DocumentDraftState({
    this.persistedDraftId,
    this.persistedCreatedAt,
    this.documentNumber,
    this.companyId,
    this.customerId,
    this.documentType = 'proforma',
    this.marginPercent = 0,
    this.revisionNotes = '',
    this.sourcePdf,
    this.lines = const <DocumentLineDraft>[],
  });

  final String? companyId;
  final String? persistedDraftId;
  final DateTime? persistedCreatedAt;
  final String? documentNumber;
  final String? customerId;
  final String documentType;
  final int marginPercent;
  final String revisionNotes;
  final ImportedPdfSource? sourcePdf;
  final List<DocumentLineDraft> lines;

  DocumentDraftState copyWith({
    String? companyId,
    String? persistedDraftId,
    DateTime? persistedCreatedAt,
    String? documentNumber,
    String? customerId,
    String? documentType,
    int? marginPercent,
    String? revisionNotes,
    ImportedPdfSource? sourcePdf,
    List<DocumentLineDraft>? lines,
  }) {
    return DocumentDraftState(
      companyId: companyId ?? this.companyId,
      persistedDraftId: persistedDraftId ?? this.persistedDraftId,
      persistedCreatedAt: persistedCreatedAt ?? this.persistedCreatedAt,
      documentNumber: documentNumber ?? this.documentNumber,
      customerId: customerId ?? this.customerId,
      documentType: documentType ?? this.documentType,
      marginPercent: marginPercent ?? this.marginPercent,
      revisionNotes: revisionNotes ?? this.revisionNotes,
      sourcePdf: sourcePdf ?? this.sourcePdf,
      lines: lines ?? this.lines,
    );
  }
}

class AppLocalState extends ChangeNotifier {
  AppLocalState()
    : currentRoute = '/dashboard',
      selectedCompanyId = null,
      selectedCustomerId = null,
      documentDraft = const DocumentDraftState();

  String currentRoute;
  String? selectedCompanyId;
  String? selectedCustomerId;
  DocumentDraftState documentDraft;
  String? _editingInvoiceId;
  Invoice? _initialInvoice;
  String? _sourceProformaId;
  String? _sourceProformaNumber;
  DocumentDraft? _sourceProformaDraft;

  String? get editingInvoiceId => _editingInvoiceId;
  Invoice? get initialInvoice => _initialInvoice;
  String? get sourceProformaId => _sourceProformaId;
  String? get sourceProformaNumber => _sourceProformaNumber;
  DocumentDraft? get sourceProformaDraft => _sourceProformaDraft;

  void navigateTo(String route) {
    currentRoute = route;

    if (route == '/companies') {
      selectedCompanyId = null;
    } else if (route == '/customers') {
      selectedCustomerId = null;
    }

    notifyListeners();
  }

  void selectCompany(String companyId) {
    selectedCompanyId = companyId;
    currentRoute = '/companies/$companyId';
    notifyListeners();
  }

  void selectCustomer(String customerId) {
    selectedCustomerId = customerId;
    currentRoute = AppRoutes.customerDetail(customerId);
    notifyListeners();
  }

  void setDocumentDraft(DocumentDraftState draft) {
    documentDraft = draft;
    notifyListeners();
  }

  void updateDocumentDraft({
    String? companyId,
    String? customerId,
    String? documentType,
    int? marginPercent,
    String? revisionNotes,
  }) {
    documentDraft = documentDraft.copyWith(
      companyId: companyId,
      customerId: customerId,
      documentType: documentType,
      marginPercent: marginPercent,
      revisionNotes: revisionNotes,
    );

    notifyListeners();
  }

  void setPersistedDraft({
    required String draftId,
    required DateTime createdAt,
  }) {
    documentDraft = documentDraft.copyWith(
      persistedDraftId: draftId,
      persistedCreatedAt: createdAt,
    );

    notifyListeners();
  }

  void createDraft() {
    documentDraft = const DocumentDraftState();
    currentRoute = '/documents/new';
    notifyListeners();
  }

  void editDraft(DocumentDraft draft) {
    documentDraft = DocumentDraftState(
      persistedDraftId: draft.id,
      persistedCreatedAt: draft.createdAt,
      documentNumber: draft.documentNumber,
      companyId: draft.companyId,
      customerId: draft.customerId,
      documentType: draft.documentType,
      marginPercent: draft.marginBasisPoints ~/ 100,
      revisionNotes: draft.revisionNotes,
      lines: List<DocumentLineDraft>.unmodifiable(
        draft.lines.map(
          (line) => DocumentLineDraft(
            id: line.id,
            reference: '',
            article: line.description,
            quantity: line.quantityMilliunits / 1000,
            sourceUnitPrice:
                (line.sourceUnitPriceCents ?? line.unitPriceCents) / 100,
            taxRate: line.taxRateBasisPoints ~/ 100,
            usesManualPrice: line.sourceUnitPriceCents == null,
          ),
        ),
      ),
    );
    currentRoute = '/documents/new';
    notifyListeners();
  }

  void openInvoicesList() {
    _clearInvoiceNavigation();
    currentRoute = AppRoutes.invoicesList;
    notifyListeners();
  }

  void openNewInvoice() {
    _clearInvoiceNavigation();
    currentRoute = AppRoutes.invoiceEditor;
    notifyListeners();
  }

  void openProformaSelectorForInvoice() {
    _clearInvoiceNavigation();
    currentRoute = AppRoutes.selectProformaForInvoice;
    notifyListeners();
  }

  void openInvoiceFromProforma(DocumentDraft proforma) {
    _editingInvoiceId = null;
    _initialInvoice = null;
    _sourceProformaId = proforma.id;
    _sourceProformaNumber = proforma.documentNumber;
    _sourceProformaDraft = proforma;
    currentRoute = AppRoutes.invoiceEditor;
    notifyListeners();
  }

  void openInvoiceForEdit(Invoice invoice) {
    _editingInvoiceId = invoice.id;
    _initialInvoice = invoice;
    _sourceProformaId = invoice.sourceProformaId;
    _sourceProformaNumber = invoice.sourceProformaNumber;
    _sourceProformaDraft = null;
    currentRoute = AppRoutes.invoiceEditor;
    notifyListeners();
  }

  void setEditingInvoiceId(String invoiceId) {
    _editingInvoiceId = invoiceId;
    notifyListeners();
  }

  void _clearInvoiceNavigation() {
    _editingInvoiceId = null;
    _initialInvoice = null;
    _sourceProformaId = null;
    _sourceProformaNumber = null;
    _sourceProformaDraft = null;
  }

  void clearDocumentDraft() {
    documentDraft = const DocumentDraftState();
    notifyListeners();
  }

  void setSourcePdf(ImportedPdfSource? sourcePdf) {
    documentDraft = documentDraft.copyWith(sourcePdf: sourcePdf);

    notifyListeners();
  }

  void setDocumentLines(List<DocumentLineDraft> lines) {
    documentDraft = documentDraft.copyWith(
      lines: List<DocumentLineDraft>.unmodifiable(lines),
    );

    notifyListeners();
  }

  void addDocumentLine(DocumentLineDraft line) {
    setDocumentLines([...documentDraft.lines, line]);
  }

  void updateDocumentLine(DocumentLineDraft line) {
    setDocumentLines([
      for (final item in documentDraft.lines)
        if (item.id == line.id) line else item,
    ]);
  }

  void removeDocumentLine(String lineId) {
    setDocumentLines([
      for (final item in documentDraft.lines)
        if (item.id != lineId) item,
    ]);
  }

  String? companyIdFromRoute(String route) {
    final segments = route.trim().split('/');
    if (segments.length < 3 ||
        segments[0].isNotEmpty ||
        segments[1] != 'companies' ||
        segments[2].isEmpty) {
      return null;
    }

    if (segments.length == 3) {
      return segments[2];
    }

    if (segments.length == 4 &&
        (segments[3] == 'invoices' || segments[3] == 'quotes')) {
      return segments[2];
    }

    return null;
  }
}
