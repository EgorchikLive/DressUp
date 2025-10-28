import 'package:cloud_firestore/cloud_firestore.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getProductsStream() {
    return _firestore.collection('dress').snapshots();
  }

  Future<List<QueryDocumentSnapshot>> getProducts() async {
    final snapshot = await _firestore.collection('dress').get();
    return snapshot.docs;
  }
}