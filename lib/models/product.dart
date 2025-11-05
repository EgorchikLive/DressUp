class Product {
  final String id;
  final String name;
  final double price;
  final String category;
  final String description;
  List<String> imageUrls;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.description,
    required this.imageUrls,
    // Временный параметр для обратной совместимости
    String? imageUrl,
  }) {
    // Если передали imageUrl, но imageUrls пустой, добавляем его
    if (imageUrls.isEmpty && imageUrl != null) {
      imageUrls = [imageUrl];
    }
  }

  // Конвертация в Map для Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'category': category,
      'description': description,
      'imageUrls': imageUrls, // Изменено на imageUrls
    };
  }

  // Геттер для получения первого изображения (для обратной совместимости)
  String get imageUrl => imageUrls.isNotEmpty ? imageUrls[0] : '';

  @override
  String toString() {
    return 'Product{id: $id, name: $name, price: $price, category: $category}';
  }
}