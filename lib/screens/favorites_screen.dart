import 'package:dress_up/models/product';
import 'package:dress_up/services/FavoritesService.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../widgets/product_card.dart';

class FavoritesScreen extends StatefulWidget {
  final UserModel user; // Ожидаем UserModel

  const FavoritesScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  late Stream<List<Product>> _favoritesStream;

  @override
  void initState() {
    super.initState();
    _favoritesStream = _favoritesService.getFavoritesStream(widget.user.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Избранное'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<List<Product>>(
        stream: _favoritesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Ошибка загрузки',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final favorites = snapshot.data ?? [];

          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey[300]),
                  SizedBox(height: 20),
                  Text(
                    'Нет избранных товаров',
                    style: TextStyle(
                      fontSize: 18, 
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Добавляйте товары в избранное,\nнажимая на сердечко',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14, 
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final product = favorites[index];
              
              return ProductCard(
                product: product,
                userId: widget.user.uid, // Используем uid из UserModel
                favoritesService: _favoritesService,
              );
            },
          );
        },
      ),
    );
  }
}