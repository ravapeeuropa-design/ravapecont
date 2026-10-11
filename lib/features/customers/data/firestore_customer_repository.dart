import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../../customers/domain/customer_form_data.dart';
import 'customer_firestore_mappers.dart';

class FirestoreCustomerRepository {
  FirestoreCustomerRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<CustomerFormData>> watchCustomers() {
    return _firestore
        .collection(FirestorePaths.customersCollection)
        .orderBy('legalName')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => customerFromFirestoreMap(doc.id, doc.data()))
              .toList(growable: false),
        );
  }

  Future<List<CustomerFormData>> fetchCustomers() {
    return watchCustomers().first;
  }

  Future<CustomerFormData?> fetchCustomerById(String customerId) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.customersCollection)
        .doc(customerId)
        .get();
    final data = snapshot.data();
    return data == null ? null : customerFromFirestoreMap(snapshot.id, data);
  }

  Future<String> createCustomer(CustomerFormData customer) async {
    final data = customerToFirestoreMap(customer)
      ..['createdAt'] = FieldValue.serverTimestamp()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    final document = await _firestore
        .collection(FirestorePaths.customersCollection)
        .add(data);
    return document.id;
  }

  Future<void> updateCustomer(CustomerFormData customer) {
    final data = customerToFirestoreMap(customer)
      ..remove('createdAt')
      ..['updatedAt'] = FieldValue.serverTimestamp();
    return _firestore
        .collection(FirestorePaths.customersCollection)
        .doc(customer.id)
        .set(data, SetOptions(merge: true));
  }

  Future<void> deleteCustomer(String customerId) {
    return _firestore
        .collection(FirestorePaths.customersCollection)
        .doc(customerId)
        .delete();
  }
}
