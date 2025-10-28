// services/seed_products.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductSeeder {
  static final CollectionReference productsCollection = 
      FirebaseFirestore.instance.collection('products');

  // Метод для добавления тестовых товаров
  static Future<void> seedProducts() async {
    try {
      print('Начинаем добавление тестовых товаров...');

      // Список тестовых товаров
      final List<Map<String, dynamic>> testProducts = [
        {
          'id': '1',
          'name': 'Футболка Basic',
          'price': 29.99,
          'category': 'Футболки',
          'description': 'Хлопковая футболка премиального качества',
          'imageUrl': 'https://img.freepik.com/premium-vector/cartoon-blue-tshirt-white-background-isolated-vector_506530-1002.jpg',
        },
        {
          'id': '2', 
          'name': 'Джинсы Slim Fit',
          'price': 79.99,
          'category': 'Джинсы',
          'description': 'Современные джинсы slim fit',
          'imageUrl': 'https://img.freepik.com/premium-vector/vector-illustration-blue-jeans-isolated-white-background_1009561-52.jpg',
        },
        {
          'id': '3',
          'name': 'Черное платье',
          'price': 59.99,
          'category': 'Платья',
          'description': 'Элегантное черное платье',
          'imageUrl': 'https://img.freepik.com/premium-vector/little-black-dress-white-background_1302-8236.jpg',
        },
        {
          'id': '4',
          'name': 'Кожаная куртка',
          'price': 199.99,
          'category': 'Куртки',
          'description': 'Стильная кожаная куртка',
          'imageUrl': 'https://img.freepik.com/premium-vector/black-leather-jacket-isolated-white-background_1302-15645.jpg',
        },
        {
          'id': '5',
          'name': 'Белая футболка',
          'price': 24.99,
          'category': 'Футболки',
          'description': 'Базовая белая футболка',
          'imageUrl': 'https://img.freepik.com/premium-vector/blank-white-t-shirt-template-front-side-views_208581-132.jpg',
        },
        {
          'id': '6',
          'name': 'Классические джинсы',
          'price': 69.99,
          'category': 'Джинсы',
          'description': 'Классические прямые джинсы',
          'imageUrl': 'https://img.freepik.com/premium-vector/blue-jeans-pants-isolated-white-background_1302-12460.jpg',
        },
      ];

      // Добавляем каждый товар в Firestore
      for (final product in testProducts) {
        await productsCollection.doc(product['id']).set(product);
        print('Добавлен товар: ${product['name']}');
      }

      print('Все тестовые товары успешно добавлены!');
      
    } catch (e) {
      print('Ошибка при добавлении товаров: $e');
    }
  }

  // Метод для очистки всех товаров (опционально)
  static Future<void> clearProducts() async {
    try {
      final snapshot = await productsCollection.get();
      final batch = FirebaseFirestore.instance.batch();
      
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      print('Все товары удалены');
    } catch (e) {
      print('Ошибка при удалении товаров: $e');
    }
  }

  // Метод для проверки существования товаров
  static Future<bool> checkIfProductsExist() async {
    try {
      final snapshot = await productsCollection.limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Ошибка при проверке товаров: $e');
      return false;
    }
  }
}