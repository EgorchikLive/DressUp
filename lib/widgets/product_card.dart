import 'package:dress_up/models/product';
import 'package:dress_up/services/FavoritesService.dart';
import 'package:dress_up/services/cart_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/auth/auth_provider.dart';
import '../screens/product_screen.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final String? userId;
  final FavoritesService favoritesService;

  const ProductCard({
    Key? key,
    required this.product,
    required this.userId,
    required this.favoritesService,
  }) : super(key: key);

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late Stream<bool> _isFavoriteStream;
  late Stream<int> _cartQuantityStream;
  bool _isLoading = false;
  bool _isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    if (widget.userId != null) {
      _isFavoriteStream = widget.favoritesService.isProductInFavoritesStream(
        widget.userId!, 
        widget.product.id
      );
    } else {
      _isFavoriteStream = Stream.value(false);
    }
    
    _setupCartStream();
  }

  void _setupCartStream() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isLoggedIn && authProvider.currentUser != null) {
      final cartService = CartService();
      _cartQuantityStream = cartService.getProductQuantityStream(
        authProvider.currentUser!.uid, 
        widget.product.id
      );
    } else {
      _cartQuantityStream = Stream.value(0);
    }
  }

  Future<void> _toggleFavorite() async {
    if (widget.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Войдите в аккаунт, чтобы добавлять в избранное'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final isCurrentlyFavorite = await widget.favoritesService
          .isProductInFavorites(widget.userId!, widget.product.id);

      if (isCurrentlyFavorite) {
        await widget.favoritesService.removeFromFavorites(
          widget.userId!, 
          widget.product.id
        );
      } else {
        await widget.favoritesService.addToFavorites(
          widget.userId!, 
          widget.product
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !isCurrentlyFavorite 
              ? '❤️ Товар добавлен в избранное' 
              : '💔 Товар удален из избранного',
          ),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('❌ Ошибка переключения избранного: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addToCart() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isLoggedIn || authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Войдите в аккаунт, чтобы добавлять в корзину'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isAddingToCart = true;
    });

    try {
      final cartService = CartService();
      await cartService.addToCart(authProvider.currentUser!.uid, widget.product);
      
      // Получаем актуальное количество после добавления
      final currentQuantity = await cartService.getProductQuantity(
        authProvider.currentUser!.uid, 
        widget.product.id
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🛒 Товар добавлен в корзину ($currentQuantity шт.)'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Перейти',
            textColor: Colors.white,
            onPressed: () {
              // Навигация в корзину
            },
          ),
        ),
      );
    } catch (e) {
      print('❌ Ошибка добавления в корзину: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при добавлении в корзину: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isAddingToCart = false;
      });
    }
  }

  void _navigateToProductScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductScreen(product: widget.product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: _navigateToProductScreen,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Изображение товара
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        widget.product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Icon(Icons.image, color: Colors.grey[400]),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  // Кнопка избранного
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                ),
                              )
                            : StreamBuilder<bool>(
                                stream: _isFavoriteStream,
                                builder: (context, snapshot) {
                                  final isFavorite = snapshot.data ?? false;
                                  return Icon(
                                    isFavorite ? Icons.favorite : Icons.favorite_border,
                                    color: isFavorite ? Colors.red : Colors.grey[600],
                                    size: 20,
                                  );
                                },
                              ),
                        onPressed: _toggleFavorite,
                        padding: EdgeInsets.all(4),
                        constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                    ),
                  ),

                  // Счетчик количества в корзине (если больше 0)
                  StreamBuilder<int>(
                    stream: _cartQuantityStream,
                    builder: (context, snapshot) {
                      final quantity = snapshot.data ?? 0;
                      if (quantity > 0) {
                        return Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$quantity',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }
                      return SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
            
            // Информация о товаре
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Название товара
                  Text(
                    widget.product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  SizedBox(height: 4),
                  
                  // Описание товара
                  Text(
                    widget.product.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  SizedBox(height: 8),
                  
                  // Цена и кнопка корзины
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: StreamBuilder<int>(
                          stream: _cartQuantityStream,
                          builder: (context, snapshot) {
                            final quantity = snapshot.data ?? 0;
                            return Container(
                              decoration: BoxDecoration(
                                color: quantity > 0 ? Colors.green : Colors.blue,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _addToCart,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Center(
                                      child: _isAddingToCart
                                          ? SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.shopping_cart,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  '\$${widget.product.price.toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                if (quantity > 0) ...[
                                                  SizedBox(width: 4),
                                                  Container(
                                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withOpacity(0.3),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      '$quantity',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}