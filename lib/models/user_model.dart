import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime lastLogin;
  final List<String> favoriteProductIds; // Добавляем поле для избранного

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.photoURL,
    required this.createdAt,
    required this.lastLogin,
    this.favoriteProductIds = const [], // По умолчанию пустой список
  });

  // АЛЬТЕРНАТИВНЫЙ КОНСТРУКТОР - полностью безопасный
  factory UserModel.safeFromFirestore(Map<String, dynamic>? data) {
    print('🛡️  Используем безопасный конструктор');
    
    // Если data null, возвращаем пользователя по умолчанию
    if (data == null) {
      print('⚠️  Данные null, возвращаем пользователя по умолчанию');
      return UserModel.defaultUser();
    }

    try {
      // Безопасное извлечение данных
      final uid = _safeGetString(data, 'uid', 'default_uid');
      final name = _safeGetString(data, 'name', 'Пользователь');
      final email = _safeGetString(data, 'email', 'unknown@email.com');
      final phoneNumber = _safeGetString(data, 'phoneNumber', '');
      final photoURL = _safeGetString(data, 'photoURL', '');
      
      // Безопасное извлечение списка избранного
      final favoriteProductIds = _safeGetStringList(data, 'favoriteProductIds');

      final createdAt = _safeGetDateTime(data, 'createdAt');
      final lastLogin = _safeGetDateTime(data, 'lastLogin');

      final user = UserModel(
        uid: uid,
        name: name,
        email: email,
        phoneNumber: phoneNumber.isEmpty ? null : phoneNumber,
        photoURL: photoURL.isEmpty ? null : photoURL,
        createdAt: createdAt,
        lastLogin: lastLogin,
        favoriteProductIds: favoriteProductIds,
      );

      print('✅ Безопасно создан UserModel: ${user.email}');
      print('⭐ Избранных товаров: ${favoriteProductIds.length}');
      return user;
      
    } catch (e) {
      print('❌ Ошибка в безопасном конструкторе: $e');
      return UserModel.defaultUser();
    }
  }

  // Пользователь по умолчанию
  factory UserModel.defaultUser() {
    return UserModel(
      uid: 'default_uid_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Пользователь',
      email: 'default@email.com',
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
      favoriteProductIds: [],
    );
  }

  // Старые методы для совместимости (можно удалить позже)
  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    print('⚡ Используем старый конструктор');
    return UserModel.safeFromFirestore(data);
  }

  // Вспомогательные методы
  static String _safeGetString(Map<String, dynamic> data, String key, String fallback) {
    try {
      final value = data[key];
      if (value == null) return fallback;
      return value.toString().trim();
    } catch (e) {
      return fallback;
    }
  }

  static List<String> _safeGetStringList(Map<String, dynamic> data, String key) {
    try {
      final value = data[key];
      if (value is List) {
        return value.whereType<String>().toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static DateTime _safeGetDateTime(Map<String, dynamic> data, String key) {
    try {
      final value = data[key];
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
      'favoriteProductIds': favoriteProductIds, // Добавляем в map
    };
  }

  // Метод для копирования с обновленными полями
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phoneNumber,
    String? photoURL,
    DateTime? createdAt,
    DateTime? lastLogin,
    List<String>? favoriteProductIds,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      favoriteProductIds: favoriteProductIds ?? this.favoriteProductIds,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: "$name", email: "$email", favorites: ${favoriteProductIds.length})';
  }
}