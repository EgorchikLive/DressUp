import 'package:dress_up/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isInitialized => _isInitialized;

  // Инициализация при запуске приложения
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      await _loadUserFromStorage();
      print('🔄 AuthProvider инициализирован. isLoggedIn: $isLoggedIn');
    } catch (e) {
      print('❌ Ошибка инициализации AuthProvider: $e');
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Загрузка пользователя из локального хранилища
  Future<void> _loadUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_user');
      
      if (userJson != null && userJson.isNotEmpty) {
        print('📁 Загружаем пользователя из хранилища');
        
        // Парсим простой JSON (можно использовать json.decode для сложных структур)
        final userData = _parseUserData(userJson);
        if (userData != null) {
          _currentUser = UserModel(
            uid: userData['uid'] ?? 'unknown',
            name: userData['name'] ?? 'Пользователь',
            email: userData['email'] ?? 'unknown@email.com',
            phoneNumber: userData['phoneNumber'],
            photoURL: userData['photoURL'],
            createdAt: DateTime.parse(userData['createdAt'] ?? DateTime.now().toIso8601String()),
            lastLogin: DateTime.parse(userData['lastLogin'] ?? DateTime.now().toIso8601String()),
          );
          print('✅ Пользователь загружен из хранилища: ${_currentUser!.email}');
        }
      } else {
        print('📁 В хранилище нет данных пользователя');
      }
    } catch (e) {
      print('❌ Ошибка загрузки пользователя из хранилища: $e');
    }
  }

  // Сохранение пользователя в локальное хранилище
  Future<void> _saveUserToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_currentUser != null) {
        final userData = {
          'uid': _currentUser!.uid,
          'name': _currentUser!.name,
          'email': _currentUser!.email,
          'phoneNumber': _currentUser!.phoneNumber ?? '',
          'photoURL': _currentUser!.photoURL ?? '',
          'createdAt': _currentUser!.createdAt.toIso8601String(),
          'lastLogin': _currentUser!.lastLogin.toIso8601String(),
        };
        
        // Сохраняем как строку (можно использовать json.encode для сложных структур)
        final userJson = _encodeUserData(userData);
        await prefs.setString('current_user', userJson);
        print('💾 Пользователь сохранен в хранилище: ${_currentUser!.email}');
      } else {
        await prefs.remove('current_user');
        print('🗑️ Пользователь удален из хранилища');
      }
    } catch (e) {
      print('❌ Ошибка сохранения пользователя в хранилище: $e');
    }
  }

  // Простой парсинг данных пользователя
  Map<String, dynamic>? _parseUserData(String userJson) {
    try {
      // Простая реализация - в реальном приложении используйте json.decode
      final parts = userJson.split('|');
      if (parts.length >= 6) {
        return {
          'uid': parts[0],
          'name': parts[1],
          'email': parts[2],
          'phoneNumber': parts[3].isEmpty ? null : parts[3],
          'photoURL': parts[4].isEmpty ? null : parts[4],
          'createdAt': parts[5],
          'lastLogin': parts.length > 6 ? parts[6] : parts[5],
        };
      }
    } catch (e) {
      print('❌ Ошибка парсинга данных пользователя: $e');
    }
    return null;
  }

  // Простое кодирование данных пользователя
  String _encodeUserData(Map<String, dynamic> userData) {
    return '${userData['uid']}|${userData['name']}|${userData['email']}|${userData['phoneNumber'] ?? ''}|${userData['photoURL'] ?? ''}|${userData['createdAt']}|${userData['lastLogin']}';
  }

  // Вход пользователя
  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('🔐 Попытка входа: $email');

      final firestore = FirebaseFirestore.instance;
      
      // Ищем пользователя
      final query = await firestore
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        print('❌ Пользователь не найден');
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final doc = query.docs.first;
      final data = doc.data();
      
      // Проверяем пароль
      final storedPassword = data['password']?.toString() ?? '';
      if (storedPassword != password.trim()) {
        print('❌ Неверный пароль');
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Создаем пользователя
      _currentUser = UserModel(
        uid: data['uid']?.toString() ?? doc.id,
        name: data['name']?.toString() ?? 'Пользователь',
        email: data['email']?.toString() ?? email,
        phoneNumber: data['phoneNumber']?.toString(),
        photoURL: data['photoURL']?.toString(),
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        lastLogin: DateTime.now(),
      );

      // Сохраняем в хранилище
      await _saveUserToStorage();
      
      _isLoading = false;
      notifyListeners();
      
      print('✅ Вход выполнен: ${_currentUser!.email}');
      return true;
      
    } catch (e) {
      print('❌ Ошибка входа: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Выход пользователя
  Future<void> logout() async {
    _currentUser = null;
    await _saveUserToStorage(); // Очищаем хранилище
    notifyListeners();
    print('🚪 Пользователь вышел из системы');
  }

  // Установить пользователя (для регистрации)
  Future<void> setUser(UserModel user) async {
    _currentUser = user;
    await _saveUserToStorage(); // Сохраняем в хранилище
    notifyListeners();
  }
}