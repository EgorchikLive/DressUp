import 'package:dress_up/models/product.dart';
import 'package:dress_up/services/FavoritesService.dart';
import 'package:dress_up/services/cart_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/auth/auth_provider.dart';

class ProductScreen extends StatefulWidget {
  final Product product;

  const ProductScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final PageController _pageController = PageController();
  final PageController _imagePageController = PageController(); // Добавляем отдельный контроллер для изображений
  int _currentPage = 0;
  int _currentImageIndex = 0; // Добавляем переменную для индекса изображения
  final FavoritesService _favoritesService = FavoritesService();
  final CartService _cartService = CartService();
  bool _isFavorite = false;
  bool _isLoading = false;
  bool _isAddingToCart = false;
  late Stream<int> _cartQuantityStream;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
    _setupCartStream();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.round();
      });
    });
  }

  void _setupCartStream() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isLoggedIn && authProvider.currentUser != null) {
      _cartQuantityStream = _cartService.getProductQuantityStream(
        authProvider.currentUser!.uid,
        widget.product.id,
      );
    } else {
      _cartQuantityStream = Stream.value(0);
    }
  }

  Future<void> _checkIfFavorite() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isLoggedIn && authProvider.currentUser != null) {
      try {
        final isFavorite = await _favoritesService.isProductInFavorites(
          authProvider.currentUser!.uid,
          widget.product.id,
        );
        setState(() {
          _isFavorite = isFavorite;
        });
      } catch (e) {
        print('❌ Ошибка проверки избранного: $e');
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isLoggedIn || authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Войдите в аккаунт, чтобы добавлять в избранное'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isFavorite) {
        await _favoritesService.removeFromFavorites(
          authProvider.currentUser!.uid,
          widget.product.id,
        );
      } else {
        await _favoritesService.addToFavorites(
          authProvider.currentUser!.uid,
          widget.product,
        );
      }

      setState(() {
        _isFavorite = !_isFavorite;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorite
                ? '❤️ Товар добавлен в избранное'
                : '💔 Товар удален из избранного',
          ),
          duration: Duration(seconds: 2),
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
        ),
      );
      return;
    }

    setState(() {
      _isAddingToCart = true;
    });

    try {
      await _cartService.addToCart(
        authProvider.currentUser!.uid,
        widget.product,
      );

      // Получаем актуальное количество после добавления
      final currentQuantity = await _cartService.getProductQuantity(
        authProvider.currentUser!.uid,
        widget.product.id,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🛒 Товар добавлен в корзину ($currentQuantity шт.)'),
          duration: Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Перейти',
            textColor: Colors.white,
            onPressed: () {
              // Навигация в корзину
              // Navigator.push(context, MaterialPageRoute(builder: (context) => CartScreen()));
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

  @override
  void dispose() {
    _pageController.dispose();
    _imagePageController.dispose(); // Не забываем освободить контроллер
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // AppBar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Детали товара',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _isFavorite ? Colors.red : Colors.black,
                          ),
                    onPressed: _toggleFavorite,
                  ),
                ],
              ),
            ),

            // Swipeable content
            Expanded(
              child: PageView(
                controller: _pageController,
                children: [_buildImagePage(), _buildDescriptionPage()],
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPageIndicator(0, 'Изображение'),
                  SizedBox(width: 20),
                  _buildPageIndicator(1, 'Описание'),
                ],
              ),
            ),

            // Product info and actions
            _buildProductInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Заменяем одиночное изображение на PageView для нескольких изображений
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: widget.product.imageUrls.length > 1
                        ? PageView.builder(
                            controller: _imagePageController, // Используем отдельный контроллер
                            itemCount: widget.product.imageUrls.length,
                            itemBuilder: (context, index) {
                              return Image.network(
                                widget.product.imageUrls[index],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Icon(
                                      Icons.image,
                                      size: 80,
                                      color: Colors.grey[400],
                                    ),
                                  );
                                },
                              );
                            },
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index; // Теперь переменная объявлена
                              });
                            },
                          )
                        : Image.network(
                            widget.product.imageUrls.isNotEmpty
                                ? widget.product.imageUrls[0]
                                : '',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.image,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                              );
                            },
                          ),
                  ),
                ),

                // Индикатор для нескольких изображений
                if (widget.product.imageUrls.length > 1)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.product.imageUrls.length,
                        (index) => Container(
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentImageIndex == index
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Счетчик добавлений в корзину
                StreamBuilder<int>(
                  stream: _cartQuantityStream,
                  builder: (context, snapshot) {
                    final quantity = snapshot.data ?? 0;
                    if (quantity > 0) {
                      return Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
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
                            '$quantity в корзине',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
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
          SizedBox(height: 16),
          Text(
            widget.product.imageUrls.length > 1
                ? 'Свайпните для просмотра других изображений →'
                : 'Свайпните влево для описания →',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Описание товара',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 20),
            Text(
              widget.product.description,
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Категория: ${widget.product.category}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 30),
            Text(
              '← Свайпните вправо для изображения',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int pageIndex, String label) {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == pageIndex ? Colors.blue : Colors.grey[300],
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: _currentPage == pageIndex ? Colors.blue : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildProductInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    widget.product.category,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              Text(
                '\$${widget.product.price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StreamBuilder<int>(
                  stream: _cartQuantityStream,
                  builder: (context, snapshot) {
                    final quantity = snapshot.data ?? 0;
                    return ElevatedButton(
                      onPressed: _isAddingToCart ? null : _addToCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: quantity > 0
                            ? Colors.green
                            : Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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
                                Icon(Icons.shopping_cart, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  quantity > 0
                                      ? 'Добавить еще'
                                      : 'Добавить в корзину',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (quantity > 0) ...[
                                  SizedBox(width: 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$quantity',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                    );
                  },
                ),
              ),
              SizedBox(width: 12),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.share),
                  onPressed: () {
                    // Поделиться товаром
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}