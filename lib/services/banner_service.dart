import 'package:cloud_firestore/cloud_firestore.dart';

class BannerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getBanners() async {
    try {
      print('🔄 ЗАПУСК getBanners...');
      
      final snapshot = await _firestore
          .collection('stock_tape')
          .get();

      print('📊 Получено документов из Firebase: ${snapshot.docs.length}');
      
      if (snapshot.docs.isEmpty) {
        print('❌ Коллекция stock_tape пуста!');
        return [];
      }

      // Детальная информация о каждом документе
      print('📋 ДЕТАЛИ ДОКУМЕНТОВ:');
      for (var i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data();
        print('   ${i + 1}. Документ ID: "${doc.id}"');
        print('      - title: "${data['title']}"');
        print('      - isActive: ${data['isActive']}');
        print('      - order: "${data['order']}"');
        print('      - image: ${data['image'] != null ? "ЕСТЬ" : "НЕТ"}');
        print('      - Все поля: ${data.keys.toList()}');
      }

      // Преобразуем в список
      var banners = <Map<String, dynamic>>[];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        // Проверяем наличие обязательных полей
        final hasTitle = data['title'] != null && data['title'].toString().isNotEmpty;
        final hasImage = data['image'] != null && data['image'].toString().isNotEmpty;
        
        if (!hasTitle) {
          print('⚠️ Документ ${doc.id}: Пропускаем - нет title');
          continue;
        }
        
        if (!hasImage) {
          print('⚠️ Документ ${doc.id}: Пропускаем - нет image');
          continue;
        }

        final banner = {
          'id': doc.id,
          'image': data['image']?.toString() ?? '',
          'title': data['title']?.toString() ?? 'Без названия',
          'subtitle': data['subtitle']?.toString() ?? '',
          'route': data['route']?.toString() ?? '',
          'description': data['description']?.toString() ?? '',
          'isActive': data['isActive'] ?? false,
          'order': data['order']?.toString() ?? '0',
          'targetCategory': data['targetCategory']?.toString() ?? '',
          'buttonText': data['buttonText']?.toString() ?? 'Смотреть предложения',
        };
        
        banners.add(banner);
        print('✅ Добавлен баннер: "${banner['title']}"');
      }

      // Сортируем по order
      banners.sort((a, b) {
        try {
          final orderA = int.tryParse(a['order']?.toString() ?? '0') ?? 0;
          final orderB = int.tryParse(b['order']?.toString() ?? '0') ?? 0;
          return orderA.compareTo(orderB);
        } catch (e) {
          return 0;
        }
      });

      print('🎯 ИТОГО загружено баннеров: ${banners.length}');
      print('📝 Список баннеров после сортировки:');
      for (var i = 0; i < banners.length; i++) {
        print('   ${i + 1}. ${banners[i]['title']} (order: ${banners[i]['order']})');
      }

      return banners;

    } catch (e) {
      print('❌ КРИТИЧЕСКАЯ ОШИБКА в getBanners: $e');
      print('🔧 Stack trace: ${e.toString()}');
      return [];
    }
  }

  // Метод для проверки конкретного документа
  Future<void> debugDocument(String docId) async {
    try {
      print('🔍 ПРОВЕРКА ДОКУМЕНТА $docId...');
      
      final doc = await _firestore.collection('stock_tape').doc(docId).get();
      
      if (!doc.exists) {
        print('❌ Документ $docId не существует!');
        return;
      }
      
      final data = doc.data()!;
      print('✅ Документ $docId существует');
      print('📊 Данные: $data');
      print('🔑 Поля: ${data.keys.toList()}');
      
    } catch (e) {
      print('❌ Ошибка проверки документа $docId: $e');
    }
  }
  
}