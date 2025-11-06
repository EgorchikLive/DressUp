import 'package:dress_up/models/product.dart';
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
  final PageController _imagePageController = PageController();
  int _currentImageIndex = 0;
  bool _isLoading = false;
  bool _isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    if (widget.userId != null) {
      _isFavoriteStream = widget.favoritesService.isProductInFavoritesStream(
        widget.userId!,
        widget.product.id,
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
        widget.product.id,
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
          widget.product.id,
        );
      } else {
        await widget.favoritesService.addToFavorites(
          widget.userId!,
          widget.product,
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
      await cartService.addToCart(
        authProvider.currentUser!.uid,
        widget.product,
      );

      // Получаем актуальное количество после добавления
      final currentQuantity = await cartService.getProductQuantity(
        authProvider.currentUser!.uid,
        widget.product.id,
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
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: _navigateToProductScreen,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Основной контент
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Контейнер для изображения и слайдера
                Stack(
                  children: [
                    // Изображение товара
                    Container(
                      width: double.infinity,
                      height: 140, // Фиксированная высота для изображения
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: widget.product.imageUrls.length > 1
                            ? PageView.builder(
                                controller: _imagePageController,
                                itemCount: widget.product.imageUrls.length,
                                itemBuilder: (context, index) {
                                  return Image.network(
                                    widget.product.imageUrls[index],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: Icon(
                                          Icons.image,
                                          color: Colors.grey[400],
                                        ),
                                      );
                                    },
                                  );
                                },
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentImageIndex = index;
                                  });
                                },
                              )
                            : Image.network(
                                widget.product.imageUrls.isNotEmpty
                                    ? widget.product.imageUrls[0]
                                    : '',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Icon(
                                      Icons.image,
                                      color: Colors.grey[400],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),

                    // Кнопка избранного
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0),
                          shape: BoxShape.circle,
                          // boxShadow: [
                          //   BoxShadow(
                          //     color: Colors.black12,
                          //     blurRadius: 4,
                          //     offset: Offset(0, 2),
                          //   ),
                          // ],
                        ),
                        child: IconButton(
                          icon: _isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.red,
                                    ),
                                  ),
                                )
                              : StreamBuilder<bool>(
                                  stream: _isFavoriteStream,
                                  builder: (context, snapshot) {
                                    final isFavorite = snapshot.data ?? false;
                                    return Icon(
                                      isFavorite
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isFavorite
                                          ? Colors.red
                                          : Colors.grey[600],
                                      size: 20,
                                    );
                                  },
                                ),
                          onPressed: _toggleFavorite,
                          padding: EdgeInsets.all(4),
                          constraints: BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
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
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
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

                // Слайдер под картинкой (только если больше 1 изображения)
                // Или отступ если слайдера нет
                Container(
                  height: 12, // Такая же высота как у слайдера
                  child: widget.product.imageUrls.length > 1
                      ? Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              widget.product.imageUrls.length,
                              (index) => Container(
                                margin: EdgeInsets.symmetric(horizontal: 2),
                                width: _currentImageIndex == index ? 12 : 6,
                                height: 3,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(1.5),
                                  color: _currentImageIndex == index
                                      ? Colors.blue // Активная точка - синяя
                                      : Colors.grey[400], // Неактивные - серые
                                ),
                              ),
                            ),
                          ),
                        )
                      : SizedBox.shrink(), // Пустой контейнер для отступа
                ),

                // Информация о товаре
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 12.0, right: 12.0, bottom: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Название товара - переносится на вторую строку
                        Text(
                          widget.product.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            height: 1.2,
                          ),
                          maxLines: 2, // Две строки для названия
                          overflow: TextOverflow
                              .visible, // Показываем полностью, переносим
                        ),

                        SizedBox(height: 4),

                        // Описание товара - обрезается троеточием
                        Text(
                          widget.product.description,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            height: 1.3,
                          ),
                          maxLines: 2, // Две строки
                          overflow: TextOverflow
                              .ellipsis, // Троеточие если не помещается
                        ),

                        // Гибкий спейсер, который занимает все доступное пространство
                        Expanded(child: SizedBox.shrink()),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Кнопка корзины - всегда внизу карточки
            Positioned(
              left: 12,
              right: 12,
              bottom: 12, // Фиксированное расстояние от низа
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
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Center(
                            child: _isAddingToCart
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
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
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.3,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
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
      ),
    );
  }
}