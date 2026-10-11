import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../domain/invoice.dart';

class IssuedInvoiceResult {
  const IssuedInvoiceResult({
    required this.number,
    required this.code,
    required this.alreadyIssued,
  });

  final int number;
  final String code;
  final bool alreadyIssued;
}

class FirestoreInvoiceRepository {
  FirestoreInvoiceRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _invoices =>
      _firestore.collection(FirestorePaths.invoicesCollection);

  CollectionReference<Map<String, dynamic>> get _counters =>
      _firestore.collection(FirestorePaths.invoiceCountersCollection);

  Future<List<Invoice>> fetchInvoices() async {
    final snapshot = await _invoices
        .orderBy('updatedAt', descending: true)
        .get();

    return snapshot.docs.map(Invoice.fromFirestore).toList(growable: false);
  }

  Stream<List<Invoice>> watchInvoices() {
    return _invoices
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(Invoice.fromFirestore).toList(growable: false),
        );
  }

  Future<Invoice?> fetchInvoiceById(String invoiceId) async {
    final snapshot = await _invoices.doc(invoiceId).get();

    if (!snapshot.exists) {
      return null;
    }

    return Invoice.fromFirestore(snapshot);
  }

  Future<String> saveDraft({
    required String? invoiceId,
    required Map<String, dynamic> editableData,
    required String series,
    String? sourceProformaId,
    String? sourceProformaNumber,
  }) async {
    final draftData = <String, dynamic>{
      ...editableData,
      'documentType': 'invoice',
      'status': 'draft',
      'invoiceSeries': series,
      'invoiceNumber': null,
      'invoiceCode': null,
      'invoiceYear': null,
      'issuedAt': null,
      'sourceProformaId': sourceProformaId,
      'sourceProformaNumber': sourceProformaNumber,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (invoiceId == null) {
      final document = await _invoices.add(<String, dynamic>{
        ...draftData,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return document.id;
    }

    final existing = await _invoices.doc(invoiceId).get();
    if (!existing.exists) {
      throw StateError('No se ha encontrado el borrador de factura.');
    }
    final status = existing.data()?['status'];

    if (status == 'issued') {
      throw StateError(
        'No se puede guardar una factura emitida como borrador.',
      );
    }

    await _invoices.doc(invoiceId).set(draftData, SetOptions(merge: true));

    return invoiceId;
  }

  Future<IssuedInvoiceResult> issueInvoice({
    required String invoiceId,
    required int year,
    required String series,
  }) {
    final invoiceRef = _invoices.doc(invoiceId);
    final counterRef = _counters.doc('${year}_$series');

    return _firestore.runTransaction<IssuedInvoiceResult>((transaction) async {
      final invoiceSnapshot = await transaction.get(invoiceRef);

      if (!invoiceSnapshot.exists) {
        throw StateError('No se ha encontrado el borrador de factura.');
      }

      final invoiceData = invoiceSnapshot.data();
      if (invoiceData == null) {
        throw StateError('El borrador de factura no contiene datos.');
      }

      if (invoiceData['status'] == 'issued') {
        final number = invoiceData['invoiceNumber'] as int?;
        final code = invoiceData['invoiceCode'] as String?;
        if (number == null || code == null) {
          throw StateError('La factura emitida no tiene numeración válida.');
        }
        return IssuedInvoiceResult(
          number: number,
          code: code,
          alreadyIssued: true,
        );
      }

      if (invoiceData['status'] != 'draft') {
        throw StateError(
          'Solo se pueden emitir facturas que estén en borrador.',
        );
      }

      final companySnapshot =
          invoiceData['companySnapshot'] as Map<String, dynamic>?;
      final bankAccount =
          companySnapshot?['bankAccount'] as Map<String, dynamic>?;
      final iban = (bankAccount?['iban'] as String? ?? '')
          .replaceAll(RegExp(r'\s+'), '')
          .toUpperCase();
      if (bankAccount?['isDefault'] != true ||
          !RegExp(r'^ES[A-Z0-9]{22}$').hasMatch(iban)) {
        throw StateError(
          'La compañía emisora necesita una cuenta bancaria principal válida.',
        );
      }

      final counterSnapshot = await transaction.get(counterRef);
      final counterData = counterSnapshot.data();
      final lastNumber = counterSnapshot.exists
          ? (counterData?['lastNumber'] as int? ?? 0)
          : 0;
      final nextNumber = lastNumber + 1;
      final code = '$series-$year-${nextNumber.toString().padLeft(5, '0')}';

      transaction.set(counterRef, <String, dynamic>{
        'year': year,
        'series': series,
        'lastNumber': nextNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.update(invoiceRef, <String, dynamic>{
        'status': 'issued',
        'invoiceNumber': nextNumber,
        'invoiceYear': year,
        'invoiceSeries': series,
        'invoiceCode': code,
        'issuedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return IssuedInvoiceResult(
        number: nextNumber,
        code: code,
        alreadyIssued: false,
      );
    });
  }

  Future<void> saveIssuedChanges({
    required String invoiceId,
    required Map<String, dynamic> editableData,
  }) async {
    final ref = _invoices.doc(invoiceId);
    final snapshot = await ref.get();

    if (!snapshot.exists) {
      throw StateError('No se ha encontrado la factura.');
    }

    if (snapshot.data()?['status'] != 'issued') {
      throw StateError('Esta operación exige una factura emitida.');
    }

    final changes = Map<String, dynamic>.of(editableData)
      ..remove('documentType')
      ..remove('status')
      ..remove('invoiceNumber')
      ..remove('invoiceCode')
      ..remove('invoiceYear')
      ..remove('invoiceSeries')
      ..remove('issuedAt')
      ..remove('createdAt')
      ..remove('companyId')
      ..remove('customerId')
      ..remove('companySnapshot')
      ..remove('customerSnapshot')
      ..remove('customer');

    await ref.set(<String, dynamic>{
      ...changes,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
