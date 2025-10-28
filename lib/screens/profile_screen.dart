import 'package:dress_up/screens/addresses_screen.dart';
import 'package:dress_up/screens/auth/auth_provider.dart';
import 'package:dress_up/screens/auth/welcome_screen.dart';
import 'package:dress_up/screens/favorites_screen.dart';
import 'package:dress_up/screens/help_screen.dart';
import 'package:dress_up/screens/orders_screen.dart';
import 'package:dress_up/screens/payment_methods_screen.dart';
import 'package:dress_up/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatelessWidget {
  final UserModel user;

  const ProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text('Профиль'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context, firestore),
            tooltip: 'Выйти',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Аватар и основная информация
            _buildUserInfo(),
            SizedBox(height: 32),

            // Меню профиля
            _buildProfileMenu(context),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.blueAccent,
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
            style: TextStyle(
              fontSize: 32,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 16),
        Text(
          user.name,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(user.email, style: TextStyle(fontSize: 16, color: Colors.grey)),
        SizedBox(height: 8),
        Text(
          'Зарегистрирован: ${_formatDate(user.createdAt)}',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildProfileMenu(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          _buildProfileItem(
            context,
            Icons.shopping_bag,
            'Мои заказы',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrdersScreen(userId: user.uid),
                ),
              );
            },
          ),
          Divider(height: 1),
          _buildProfileItem(
            context,
            Icons.favorite,
            'Избранное',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FavoritesScreen(user: user),
                ), // Передаем user вместо userId
              );
            },
          ),
          Divider(height: 1),
          _buildProfileItem(
            context,
            Icons.location_on,
            'Адреса доставки',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddressesScreen(userId: user.uid),
                ),
              );
            },
          ),
          Divider(height: 1),
          _buildProfileItem(
            context,
            Icons.payment,
            'Способы оплаты',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentMethodsScreen(userId: user.uid),
                ),
              );
            },
          ),
          Divider(height: 1),
          _buildProfileItem(
            context,
            Icons.settings,
            'Настройки',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(user: user),
                ),
              );
            },
          ),
          Divider(height: 1),
          _buildProfileItem(
            context,
            Icons.help,
            'Помощь',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HelpScreen()),
              );
            },
          ),
          Divider(height: 1),
          _buildProfileItem(
            context,
            Icons.logout,
            'Выйти',
            onTap: () => _showLogoutDialog(context, FirebaseFirestore.instance),
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(
    BuildContext context,
    IconData icon,
    String text, {
    VoidCallback? onTap,
    Color color = Colors.black87,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(text, style: TextStyle(color: color)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: color),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context, FirebaseFirestore firestore) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Выход'),
          content: Text('Вы уверены, что хотите выйти?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                await authProvider.logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WelcomeScreen(firestore: firestore),
                  ),
                  (route) => false,
                );
              },
              child: Text('Выйти', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
