import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> syncClassification({
    required String breedName,
    required String detectedBreed,
    required double confidence,
    required DateTime timestamp,
    required bool isCorrect,
  }) async {
    try {
      await _firestore
          .collection('classifications')
          .add({
            'breedName': breedName,
            'detectedBreed': detectedBreed,
            'confidence': confidence,
            'isCorrect': isCorrect,
            'timestamp': timestamp,
            'uploadedAt': FieldValue.serverTimestamp(),
          })
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Sync timeout - check internet connection'),
          );
    } catch (e) {
      throw Exception('Failed to sync classification: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getClassifications({
    String? breedFilter,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore.collection('classifications');

      if (breedFilter != null) {
        query = query.where('breedName', isEqualTo: breedFilter);
      }

      query = query.orderBy('timestamp', descending: true).limit(limit);

      final QuerySnapshot snapshot = await query.get();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch classifications: $e');
    }
  }

  Future<void> deleteClassification(String documentId) async {
    try {
      await _firestore.collection('classifications').doc(documentId).delete();
    } catch (e) {
      throw Exception('Failed to delete classification: $e');
    }
  }
}
