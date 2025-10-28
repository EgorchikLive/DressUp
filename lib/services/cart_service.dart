import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dress_up/models/product';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Добавить товар в корзину
  Future<void> addToCart(String userId, Product product, {int quantity = 1}) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(product.id)
          .set({
        'productId': product.id,
        'name': product.name,
        'description': product.description,
        'price': product.price,
        'imageUrl': product.imageUrl,
        'category': product.category,
        'quantity': quantity,
        'addedAt': Timestamp.now(),
      });
      print('✅ Товар ${product.name} добавлен в корзину пользователя $userId');
    } catch (e) {
      print('❌ Ошибка добавления в корзину: $e');
      throw e;
    }
  }

  // Удалить товар из корзины
  Future<void> removeFromCart(String userId, String productId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(productId)
          .delete();
      print('✅ Товар $productId удален из корзины пользователя $userId');
    } catch (e) {
      print('❌ Ошибка удаления из корзины: $e');
      throw e;
    }
  }

  // Обновить количество товара
  Future<void> updateQuantity(String userId, String productId, int quantity) async {
    try {
      if (quantity <= 0) {
        await removeFromCart(userId, productId);
      } else {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('cart')
            .doc(productId)
            .update({
          'quantity': quantity,
          'updatedAt': Timestamp.now(),
        });
      }
      print('✅ Количество товара $productId обновлено: $quantity');
    } catch (e) {
      print('❌ Ошибка обновления количества: $e');
      throw e;
    }
  }

  // Получить все товары из корзины
  Future<List<CartItem>> getCartItems(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .orderBy('addedAt', descending: true)
          .get();

      final cartItems = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return CartItem(
          product: Product(
            id: doc.id,
            name: data['name'] ?? '',
            description: data['description'] ?? '',
            price: (data['price'] ?? 0.0).toDouble(),
            imageUrl: data['imageUrl'] ?? '',
            category: data['category'] ?? '',
          ),
          quantity: data['quantity'] ?? 1,
          addedAt: data['addedAt']?.toDate() ?? DateTime.now(),
        );
      }).toList();

      print('📥 Загружено ${cartItems.length} товаров из корзины');
      return cartItems;
    } catch (e) {
      print('❌ Ошибка получения корзины: $e');
      return [];
    }
  }

  // Stream для отслеживания изменений в корзине
  Stream<List<CartItem>> getCartItemsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return CartItem(
          product: Product(
            id: doc.id,
            name: data['name'] ?? '',
            description: data['description'] ?? '',
            price: (data['price'] ?? 0.0).toDouble(),
            imageUrl: data['imageUrl'] ?? '',
            category: data['category'] ?? '',
          ),
          quantity: data['quantity'] ?? 1,
          addedAt: data['addedAt']?.toDate() ?? DateTime.now(),
        );
      }).toList();
    });
  }

  // Очистить всю корзину
  Future<void> clearCart(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      print('✅ Корзина пользователя $userId очищена');
    } catch (e) {
      print('❌ Ошибка очистки корзины: $e');
      throw e;
    }
  }

  // Получить общую стоимость корзины
  Future<double> getTotalPrice(String userId) async {
    final cartItems = await getCartItems(userId);
    return cartItems.fold<double>(0, (total, item) => total + (item.product.price * item.quantity));
  }
}

// Модель для элемента корзины
class CartItem {
  final Product product;
  final int quantity;
  final DateTime addedAt;

  CartItem({
    required this.product,
    required this.quantity,
    required this.addedAt,
  });

  double get totalPrice => product.price * quantity;
}