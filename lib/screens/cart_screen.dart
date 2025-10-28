import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/cart_service.dart';

class CartScreen extends StatefulWidget {
  final UserModel user;

  const CartScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  late Stream<List<CartItem>> _cartStream;

  @override
  void initState() {
    super.initState();
    _cartStream = _cartService.getCartItemsStream(widget.user.uid);
  }

  void _removeItem(String productId) {
    _cartService.removeFromCart(widget.user.uid, productId);
  }

  void _updateQuantity(String productId, int newQuantity) {
    _cartService.updateQuantity(widget.user.uid, productId, newQuantity);
  }

  void _clearCart() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Очистить корзину?'),
        content: Text('Вы уверены, что хотите удалить все товары из корзины?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              _cartService.clearCart(widget.user.uid);
              Navigator.pop(context);
            },
            child: Text('Очистить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _checkout() {
    // Здесь можно добавить логику оформления заказа
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Функция оформления заказа в разработке'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Корзина'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          StreamBuilder<List<CartItem>>(
            stream: _cartStream,
            builder: (context, snapshot) {
              final hasItems = snapshot.hasData && snapshot.data!.isNotEmpty;
              if (hasItems) {
                return IconButton(
                  icon: Icon(Icons.delete_outline),
                  onPressed: _clearCart,
                  tooltip: 'Очистить корзину',
                );
              }
              return SizedBox();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<CartItem>>(
        stream: _cartStream,
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
                    'Ошибка загрузки корзины',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final cartItems = snapshot.data ?? [];

          if (cartItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
                  SizedBox(height: 20),
                  Text(
                    'Корзина пуста',
                    style: TextStyle(
                      fontSize: 18, 
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Добавляйте товары в корзину,\nнажимая на кнопку "В корзину"',
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

          final totalPrice = cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);

          return Column(
            children: [
              // Список товаров
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return _buildCartItem(item);
                  },
                ),
              ),

              // Итоговая панель
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
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
                        Text(
                          'Итого:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${totalPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _checkout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Оформить заказ',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            // Изображение товара
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(item.product.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 12),

            // Информация о товаре
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '\$${item.product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),

                  // Счетчик количества
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove, size: 20),
                        onPressed: item.quantity > 1
                            ? () => _updateQuantity(item.product.id, item.quantity - 1)
                            : null,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          padding: EdgeInsets.all(4),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '${item.quantity}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.add, size: 20),
                        onPressed: () => _updateQuantity(item.product.id, item.quantity + 1),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          padding: EdgeInsets.all(4),
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _removeItem(item.product.id),
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