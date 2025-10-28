import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dress_up/models/product';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Добавить товар в избранное (в подколлекцию favorites)
  Future<void> addToFavorites(String userId, Product product) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(product.id)
          .set({
        'productId': product.id,
        'name': product.name,
        'description': product.description,
        'price': product.price,
        'imageUrl': product.imageUrl,
        'category': product.category,
        'addedAt': Timestamp.now(),
      });
      print('✅ Товар ${product.name} добавлен в избранное пользователя $userId');
    } catch (e) {
      print('❌ Ошибка добавления в избранное: $e');
      throw e;
    }
  }

  // Удалить товар из избранного
  Future<void> removeFromFavorites(String userId, String productId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(productId)
          .delete();
      print('✅ Товар $productId удален из избранного пользователя $userId');
    } catch (e) {
      print('❌ Ошибка удаления из избранного: $e');
      throw e;
    }
  }

  // Получить список избранных товаров
  Future<List<Product>> getFavorites(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .get();

      final favorites = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Product(
          id: doc.id,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          price: (data['price'] ?? 0.0).toDouble(),
          imageUrl: data['imageUrl'] ?? '',
          category: data['category'] ?? '',
        );
      }).toList();

      print('📥 Загружено ${favorites.length} избранных товаров');
      return favorites;
    } catch (e) {
      print('❌ Ошибка получения избранного: $e');
      return [];
    }
  }

  // Stream для отслеживания изменений в избранном
  Stream<List<Product>> getFavoritesStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Product(
          id: doc.id,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          price: (data['price'] ?? 0.0).toDouble(),
          imageUrl: data['imageUrl'] ?? '',
          category: data['category'] ?? '',
        );
      }).toList();
    });
  }

  // Проверить, находится ли товар в избранном
  Future<bool> isProductInFavorites(String userId, String productId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(productId)
          .get();
      return doc.exists;
    } catch (e) {
      print('❌ Ошибка проверки избранного: $e');
      return false;
    }
  }

  // Stream для проверки статуса избранного для конкретного товара
  Stream<bool> isProductInFavoritesStream(String userId, String productId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(productId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }
}