import 'package:cloud_firestore/cloud_firestore.dart';

import '../../documents/data/document_draft_firestore_mappers.dart';
import '../../documents/domain/document_line.dart';
import '../../documents/domain/document_totals.dart';
import 'invoice_status.dart';

InvoiceStatus invoiceStatusFromFirestore(Object? value) {
  switch (value) {
    case 'issued':
      return InvoiceStatus.issued;
    case 'pdfPending':
      return InvoiceStatus.pdfPending;
    case 'sent':
      return InvoiceStatus.sent;
    case 'partiallyPaid':
      return InvoiceStatus.partiallyPaid;
    case 'paid':
      return InvoiceStatus.paid;
    case 'overdue':
      return InvoiceStatus.overdue;
    case 'rectified':
      return InvoiceStatus.rectified;
    case 'cancelled':
      return InvoiceStatus.cancelled;
    case 'draft':
    default:
      return InvoiceStatus.draft;
  }
}

String invoiceStatusToFirestore(InvoiceStatus status) {
  switch (status) {
    case InvoiceStatus.draft:
      return 'draft';
    case InvoiceStatus.issued:
      return 'issued';
    case InvoiceStatus.pdfPending:
      return 'pdfPending';
    case InvoiceStatus.sent:
      return 'sent';
    case InvoiceStatus.partiallyPaid:
      return 'partiallyPaid';
    case InvoiceStatus.paid:
      return 'paid';
    case InvoiceStatus.overdue:
      return 'overdue';
    case InvoiceStatus.rectified:
      return 'rectified';
    case InvoiceStatus.cancelled:
      return 'cancelled';
  }
}

class Invoice {
  const Invoice({
    required this.id,
    required this.status,
    required this.series,
    required this.companyId,
    required this.customerId,
    required this.lines,
    required this.totals,
    required this.createdAt,
    required this.updatedAt,
    this.documentDate,
    this.invoiceNumber,
    this.invoiceCode,
    this.invoiceYear,
    this.issuedAt,
    this.sourceProformaId,
    this.sourceProformaNumber,
    this.companyName,
    this.customerName,
  });

  final String id;
  final InvoiceStatus status;
  final String series;
  final int? invoiceNumber;
  final String? invoiceCode;
  final int? invoiceYear;
  final DateTime? issuedAt;
  final DateTime? documentDate;
  final String? sourceProformaId;
  final String? sourceProformaNumber;
  final String? companyName;
  final String? customerName;
  final String companyId;
  final String customerId;
  final List<DocumentLine> lines;
  final DocumentTotals totals;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isDraft => status == InvoiceStatus.draft;
  bool get isIssued => status == InvoiceStatus.issued;

  factory Invoice.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    final rawLines = data['lines'] as List<dynamic>? ?? const <dynamic>[];
    final rawTotals =
        data['totals'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final companySnapshot =
        data['companySnapshot'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final customerSnapshot =
        data['customerSnapshot'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final netCents = rawTotals['netCents'] as int? ?? 0;
    final taxCents = rawTotals['taxCents'] as int? ?? 0;

    return Invoice(
      id: snapshot.id,
      status: invoiceStatusFromFirestore(data['status']),
      series: data['invoiceSeries'] as String? ?? 'F',
      invoiceNumber: data['invoiceNumber'] as int?,
      invoiceCode: data['invoiceCode'] as String?,
      invoiceYear: data['invoiceYear'] as int?,
      issuedAt: (data['issuedAt'] as Timestamp?)?.toDate(),
      documentDate: (data['documentDate'] as Timestamp?)?.toDate(),
      sourceProformaId: data['sourceProformaId'] as String?,
      sourceProformaNumber: data['sourceProformaNumber'] as String?,
      companyName: companySnapshot['name'] as String?,
      customerName: customerSnapshot['name'] as String?,
      companyId: data['companyId'] as String? ?? '',
      customerId: data['customerId'] as String? ?? '',
      lines: rawLines
          .whereType<Map<String, dynamic>>()
          .map(documentLineFromFirestoreMap)
          .toList(growable: false),
      totals: DocumentTotals(
        netCents: netCents,
        taxCents: taxCents,
        totalCents: netCents + taxCents,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
