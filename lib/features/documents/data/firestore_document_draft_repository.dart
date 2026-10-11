import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../domain/document_draft.dart';
import 'document_draft_firestore_mappers.dart';

class FirestoreDocumentDraftRepository {
  FirestoreDocumentDraftRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection {
    return _firestore.collection(FirestorePaths.documentDraftsCollection);
  }

  Stream<List<DocumentDraft>> watchDrafts() {
    return _collection
        .where('status', isEqualTo: 'draft')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => documentDraftFromFirestoreMap(doc.id, doc.data()))
              .toList(growable: false),
        );
  }

  Future<DocumentDraft?> fetchById(String draftId) async {
    final snapshot = await _collection.doc(draftId).get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    return documentDraftFromFirestoreMap(snapshot.id, data);
  }

  Future<void> saveDraft(DocumentDraft draft) {
    return _collection.doc(draft.id).set(documentDraftToFirestoreMap(draft));
  }

  Future<void> deleteDraft(String draftId) {
    return _collection.doc(draftId).delete();
  }
}
