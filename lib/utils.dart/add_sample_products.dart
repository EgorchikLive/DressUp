// utils/add_sample_products.dart
import 'package:dress_up/productsCollection.dart';

class SampleProductsAdder {
  static Future<void> addSampleProducts() async {
    print('Проверяем наличие товаров...');
    final productsExist = await ProductSeeder.checkIfProductsExist();
    
    if (productsExist) {
      print('Товары уже существуют в базе данных');
      return;
    }
    
    print('Добавляем тестовые товары...');
    await ProductSeeder.seedProducts();
  }
}