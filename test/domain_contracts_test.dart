import 'package:flutter_test/flutter_test.dart';
import 'package:ravapecont/features/companies/domain/company_email_account.dart';
import 'package:ravapecont/features/documents/domain/document_line.dart';
import 'package:ravapecont/features/documents/domain/document_totals.dart';
import 'package:ravapecont/features/invoices/domain/invoice_status.dart';
import 'package:ravapecont/features/quotes/domain/quote_status.dart';

void main() {
  test('DocumentTotals rejects inconsistent totals', () {
    expect(
      () => DocumentTotals(netCents: 100, taxCents: 21, totalCents: 130),
      throwsArgumentError,
    );
  });

  test('DocumentLine calculates net amount using integers', () {
    final line = DocumentLine(
      id: '1',
      description: 'Test',
      quantityMilliunits: 1500,
      unitPriceCents: 200,
      taxRateBasisPoints: 2100,
    );

    expect(line.lineNetCents, 300);
  });

  test('CompanyEmailAccount contains no secrets by design', () {
    final account = const CompanyEmailAccount(
      id: '1',
      companyId: 'company-1',
      email: 'facturacion@empresa.com',
      displayName: 'Facturación',
      provider: CompanyEmailProvider.smtp,
      status: CompanyEmailAccountStatus.pending,
      isDefault: true,
      replyTo: 'reply@empresa.com',
    );

    expect(account.toString(), isNot(contains('token')));
    expect(account.toString(), isNot(contains('secret')));
    expect(account.toString(), isNot(contains('password')));
  });

  test('QuoteStatus has exactly the requested values', () {
    expect(
      QuoteStatus.values,
      [
        QuoteStatus.draft,
        QuoteStatus.ready,
        QuoteStatus.sent,
        QuoteStatus.viewed,
        QuoteStatus.accepted,
        QuoteStatus.rejected,
        QuoteStatus.expired,
        QuoteStatus.converted,
        QuoteStatus.cancelled,
      ],
    );
  });

  test('InvoiceStatus has exactly the requested values', () {
    expect(
      InvoiceStatus.values,
      [
        InvoiceStatus.draft,
        InvoiceStatus.issued,
        InvoiceStatus.pdfPending,
        InvoiceStatus.sent,
        InvoiceStatus.partiallyPaid,
        InvoiceStatus.paid,
        InvoiceStatus.overdue,
        InvoiceStatus.rectified,
        InvoiceStatus.cancelled,
      ],
    );
  });
}
