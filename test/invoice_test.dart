import 'package:flutter_test/flutter_test.dart';
import 'package:ravapecont/features/invoices/domain/invoice.dart';
import 'package:ravapecont/features/invoices/domain/invoice_status.dart';

void main() {
  test('invoice status uses draft as safe Firestore default', () {
    expect(invoiceStatusFromFirestore(null), InvoiceStatus.draft);
    expect(invoiceStatusFromFirestore('unknown'), InvoiceStatus.draft);
  });

  test('invoice status round-trips every supported value', () {
    for (final status in InvoiceStatus.values) {
      expect(
        invoiceStatusFromFirestore(invoiceStatusToFirestore(status)),
        status,
      );
    }
  });
}
