import 'package:dress_up/models/product';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dress_up/services/FavoritesService.dart';
import 'package:dress_up/widgets/product_card.dart';

class ProductGrid extends StatelessWidget {
  final List<QueryDocumentSnapshot> products;
  final String? userId;
  final EdgeInsetsGeometry? padding;

  const ProductGrid({
    Key? key,
    required this.products,
    required this.userId,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: padding ?? EdgeInsets.zero,
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.7,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final productDoc = products[index];
            try {
              final product = _parseProductFromDoc(productDoc);
              final favoritesService = FavoritesService();
              
              return ProductCard(
                product: product,
                userId: userId,
                favoritesService: favoritesService,
              );
            } catch (e) {
              return Container(
                padding: EdgeInsets.all(8),
                child: Column(
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    Text('Ошибка загрузки'),
                  ],
                ),
              );
            }
          },
          childCount: products.length,
        ),
      ),
    );
  }

  Product _parseProductFromDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    return Product(
      id: data['id']?.toString() ?? doc.id,
      name: data['name']?.toString() ?? 'Без названия',
      price: _parsePrice(data['price']),
      category: data['category']?.toString() ?? 'Без категории',
      description: data['description']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
    );
  }

  double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) return double.tryParse(price) ?? 0.0;
    return 0.0;
  }
}