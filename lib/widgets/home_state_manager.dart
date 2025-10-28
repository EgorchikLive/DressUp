import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeStateManager {
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  
  Set<String> selectedCategories = {'Все'};
  String selectedSort = 'По умолчанию';
  String searchQuery = '';
  bool isSearching = false;

  // Колбэк для уведомления об изменении состояния
  VoidCallback? onStateChanged;

  final List<String> categories = [
    'Все',
    'Платья',
    'Футболки',
    'Джинсы',
    'Куртки',
    'Свитшоты',
    'Брюки',
    'Обувь',
    'Рубашки',
    'Юбки',
    'Пальто',
    'Блузки',
    'Шорты',
    'Пиджаки',
    'Аксессуары',
  ];

  final Map<String, String> sortOptions = {
    'По умолчанию': 'default',
    'По цене (сначала дешевые)': 'price_asc',
    'По цене (сначала дорогие)': 'price_desc',
    'По названию (А-Я)': 'name_asc',
    'По названию (Я-А)': 'name_desc',
    'По популярности': 'popularity',
  };

  void init({VoidCallback? onChanged}) {
    searchFocusNode.addListener(_onSearchFocusChange);
    onStateChanged = onChanged;
  }

  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
  }

  void _onSearchFocusChange() {
    if (!searchFocusNode.hasFocus && searchQuery.isEmpty) {
      isSearching = false;
      _notifyStateChanged();
    }
  }

  void _notifyStateChanged() {
    onStateChanged?.call();
  }

  void setSearching(bool value) {
    isSearching = value;
    _notifyStateChanged();
  }

  void clearSearch() {
    searchController.clear();
    searchQuery = '';
    isSearching = false;
    _notifyStateChanged();
  }

  void updateSearchQuery(String value) {
    searchQuery = value.trim();
    isSearching = value.isNotEmpty;
    _notifyStateChanged();
  }

  // Методы для работы с категориями
  void toggleCategorySelection(String category) {
    if (category == 'Все') {
      selectedCategories = {'Все'};
    } else {
      selectedCategories.remove('Все');
      
      if (selectedCategories.contains(category)) {
        selectedCategories.remove(category);
        if (selectedCategories.isEmpty) {
          selectedCategories.add('Все');
        }
      } else {
        selectedCategories.add(category);
      }
    }
    _notifyStateChanged();
  }

  void clearCategorySelection() {
    selectedCategories = {'Все'};
    _notifyStateChanged();
  }

  void setSelectedSort(String sort) {
    selectedSort = sort;
    _notifyStateChanged();
  }

  bool get isCategoryFilterActive {
    return !selectedCategories.contains('Все') && selectedCategories.isNotEmpty;
  }

  String get displayCategoriesText {
    if (selectedCategories.contains('Все') || selectedCategories.isEmpty) {
      return 'Все категории';
    }
    
    if (selectedCategories.length == 1) {
      return selectedCategories.first;
    }
    
    return '${selectedCategories.length} категории';
  }

  // Остальные методы без изменений...
  List<QueryDocumentSnapshot> filterAndSortProducts(List<QueryDocumentSnapshot> products) {
    List<QueryDocumentSnapshot> filteredProducts = _filterProductsByCategory(products);
    
    if (searchQuery.isNotEmpty) {
      filteredProducts = _searchProducts(filteredProducts);
    }
    
    return _sortProducts(filteredProducts);
  }

  List<QueryDocumentSnapshot> _searchProducts(List<QueryDocumentSnapshot> products) {
    final query = searchQuery.toLowerCase();
    return products.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['name'] ?? '').toString().toLowerCase();
      final description = (data['description'] ?? '').toString().toLowerCase();
      final category = (data['category'] ?? '').toString().toLowerCase();

      return name.contains(query) || 
             description.contains(query) || 
             category.contains(query);
    }).toList();
  }

  List<QueryDocumentSnapshot> _filterProductsByCategory(List<QueryDocumentSnapshot> products) {
    if (selectedCategories.contains('Все') || selectedCategories.isEmpty) {
      return products;
    }

    return products.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final category = (data['category'] ?? '').toString();
      return selectedCategories.contains(category);
    }).toList();
  }

  List<QueryDocumentSnapshot> _sortProducts(List<QueryDocumentSnapshot> products) {
    List<QueryDocumentSnapshot> sortedProducts = List.from(products);
    
    switch (selectedSort) {
      case 'По цене (сначала дешевые)':
        sortedProducts.sort((a, b) {
          final priceA = _parsePrice((a.data() as Map<String, dynamic>)['price']);
          final priceB = _parsePrice((b.data() as Map<String, dynamic>)['price']);
          return priceA.compareTo(priceB);
        });
        break;
        
      case 'По цене (сначала дорогие)':
        sortedProducts.sort((a, b) {
          final priceA = _parsePrice((a.data() as Map<String, dynamic>)['price']);
          final priceB = _parsePrice((b.data() as Map<String, dynamic>)['price']);
          return priceB.compareTo(priceA);
        });
        break;
        
      case 'По названию (А-Я)':
        sortedProducts.sort((a, b) {
          final nameA = ((a.data() as Map<String, dynamic>)['name'] ?? '').toString().toLowerCase();
          final nameB = ((b.data() as Map<String, dynamic>)['name'] ?? '').toString().toLowerCase();
          return nameA.compareTo(nameB);
        });
        break;
        
      case 'По названию (Я-А)':
        sortedProducts.sort((a, b) {
          final nameA = ((a.data() as Map<String, dynamic>)['name'] ?? '').toString().toLowerCase();
          final nameB = ((b.data() as Map<String, dynamic>)['name'] ?? '').toString().toLowerCase();
          return nameB.compareTo(nameA);
        });
        break;
        
      case 'По популярности':
        sortedProducts.sort((a, b) {
          final ratingA = ((a.data() as Map<String, dynamic>)['rating'] ?? 0).toDouble();
          final ratingB = ((b.data() as Map<String, dynamic>)['rating'] ?? 0).toDouble();
          return ratingB.compareTo(ratingA);
        });
        break;
        
      case 'По умолчанию':
      default:
        break;
    }
    
    return sortedProducts;
  }

  double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) return double.tryParse(price) ?? 0.0;
    return 0.0;
  }

  // Диалоги
  void showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Сортировка товаров',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              ...sortOptions.keys.map((sortTitle) {
                return _buildSortOption(
                  context,
                  sortTitle,
                  _getSortIcon(sortTitle),
                  () {
                    setSelectedSort(sortTitle);
                    Navigator.pop(context);
                  },
                  isSelected: selectedSort == sortTitle,
                );
              }).toList(),
              SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void showCategoryDialog(BuildContext context, VoidCallback onDialogClosed) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.category, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Выбор категорий'),
                  Spacer(),
                  if (isCategoryFilterActive)
                    TextButton(
                      onPressed: () {
                        clearCategorySelection();
                        setDialogState(() {});
                      },
                      child: Text(
                        'Очистить',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Список категорий
                    Container(
                      constraints: BoxConstraints(maxHeight: 400),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isSelected = selectedCategories.contains(category);
                          
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 4),
                            elevation: 1,
                            child: ListTile(
                              leading: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isSelected ? Colors.blue : Colors.grey[400]!,
                                    width: 2,
                                  ),
                                  color: isSelected ? Colors.blue : Colors.transparent,
                                ),
                                child: isSelected
                                    ? Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              title: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isSelected ? Colors.blue : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                              onTap: () {
                                toggleCategorySelection(category);
                                setDialogState(() {});
                              },
                              tileColor: isSelected ? Colors.blue.withOpacity(0.05) : null,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: isSelected ? Colors.blue.withOpacity(0.3) : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 16),
                    // Информация о выборе
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.blue),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Выбрано: ${selectedCategories.length}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (isCategoryFilterActive)
                            Wrap(
                              spacing: 4,
                              children: selectedCategories.take(2).map((category) {
                                return Chip(
                                  label: Text(
                                    category.length > 8 ? '${category.substring(0, 8)}...' : category,
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor: Colors.blue.withOpacity(0.1),
                                  labelStyle: TextStyle(color: Colors.blue),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onDialogClosed();
                  },
                  child: Text('Отмена', style: TextStyle(color: Colors.grey[600])),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onDialogClosed();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Применить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isSelected = false,
  }) {
    return ListTile(
      leading: Icon(
        icon, 
        color: isSelected ? Colors.blue : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blue : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      trailing: isSelected ? Icon(Icons.check, color: Colors.blue) : null,
    );
  }

  IconData _getSortIcon(String sortTitle) {
    switch (sortTitle) {
      case 'По цене (сначала дешевые)':
        return Icons.arrow_upward;
      case 'По цене (сначала дорогие)':
        return Icons.arrow_downward;
      case 'По названию (А-Я)':
        return Icons.sort_by_alpha;
      case 'По названию (Я-А)':
        return Icons.sort_by_alpha;
      case 'По популярности':
        return Icons.trending_up;
      default:
        return Icons.sort;
    }
  }
}