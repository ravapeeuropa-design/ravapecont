import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../../companies/domain/company_form_data.dart';
import 'company_firestore_mappers.dart';

class FirestoreCompanyRepository {
  FirestoreCompanyRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<CompanyFormData>> watchCompanies() {
    return _firestore
        .collection(FirestorePaths.companiesCollection)
        .orderBy('legalName')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => companyFromFirestoreMap(doc.id, doc.data()))
              .toList(growable: false),
        );
  }

  Future<List<CompanyFormData>> fetchCompanies() {
    return watchCompanies().first;
  }

  Future<CompanyFormData?> fetchCompanyById(String companyId) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.companiesCollection)
        .doc(companyId)
        .get();
    final data = snapshot.data();
    return data == null ? null : companyFromFirestoreMap(snapshot.id, data);
  }

  Future<String> createCompany(CompanyFormData company) async {
    final data = companyToFirestoreMap(company)
      ..['createdAt'] = FieldValue.serverTimestamp()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    final document = await _firestore
        .collection(FirestorePaths.companiesCollection)
        .add(data);
    return document.id;
  }

  Future<void> updateCompany(CompanyFormData company) {
    final data = companyToFirestoreMap(company)
      ..remove('createdAt')
      ..['updatedAt'] = FieldValue.serverTimestamp();
    return _firestore
        .collection(FirestorePaths.companiesCollection)
        .doc(company.id)
        .set(data, SetOptions(merge: true));
  }

  Future<void> deleteCompany(String companyId) {
    return _firestore
        .collection(FirestorePaths.companiesCollection)
        .doc(companyId)
        .delete();
  }
}
