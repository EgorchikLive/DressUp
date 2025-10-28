import 'package:dress_up/models/product';
import 'package:dress_up/services/FavoritesService.dart';
import 'package:dress_up/widgets/banner_slider.dart';
import 'package:dress_up/widgets/category_filter.dart';
import 'package:dress_up/widgets/home_state_manager.dart';
import 'package:dress_up/widgets/product_card.dart';
import 'package:dress_up/widgets/product_grid.dart';
import 'package:dress_up/widgets/search_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/auth/auth_provider.dart';
import '../services/product_service.dart';

class HomeScreen extends StatefulWidget {
  final ScrollController scrollController;

  const HomeScreen({
    Key? key, 
    required this.scrollController,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  final HomeStateManager _stateManager = HomeStateManager();
  final ProductService _productService = ProductService();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _stateManager.init(onChanged: _onStateChanged);
  }

  void _onStateChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _stateManager.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() {});
    await Future.delayed(Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final authProvider = Provider.of<AuthProvider>(context);
    final String? userId = authProvider.isLoggedIn ? authProvider.currentUser?.uid : null;

    return Scaffold(
      appBar: AppBar(
        title: _stateManager.isSearching 
            ? Text('Поиск: ${_stateManager.searchQuery}')
            : Text('DressUp'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (!_stateManager.isSearching) ...[
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _stateManager.setSearching(true);
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _stateManager.searchFocusNode.requestFocus();
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.sort),
              onPressed: () => _stateManager.showSortOptions(context),
            ),
          ] else ...[
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                _stateManager.clearSearch();
              },
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          controller: widget.scrollController,
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [
            // Поисковая строка
            SliverToBoxAdapter(
              child: SearchBarWidget(stateManager: _stateManager),
            ),

            // Выбор категорий
            SliverToBoxAdapter(
              child: CategoryFilterWidget(
                stateManager: _stateManager,
                onCategoryChanged: _onStateChanged,
              ),
            ),

            if (_stateManager.isSearching) ...[
              // Режим поиска
              _buildSearchResults(userId),
            ] else ...[
              // Обычный режим - используем StreamBuilder внутри
              _buildNormalView(userId),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(String? userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _productService.getProductsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingSliver();
        }

        if (snapshot.hasError) {
          return _buildErrorSliver('Ошибка загрузки товаров');
        }

        final products = snapshot.data?.docs ?? [];
        final filteredProducts = _stateManager.filterAndSortProducts(products);

        if (filteredProducts.isEmpty) {
          return _buildEmptySearchSliver();
        }

        return ProductGrid(
          products: filteredProducts,
          userId: userId,
        );
      },
    );
  }

  Widget _buildNormalView(String? userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _productService.getProductsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingSliver();
        }

        if (snapshot.hasError) {
          return _buildErrorSliver('Ошибка загрузки товаров');
        }

        final products = snapshot.data?.docs ?? [];
        final filteredProducts = _stateManager.filterAndSortProducts(products);

        return SliverList(
          delegate: SliverChildListDelegate([
            // Заголовок
            _buildHeader(userId),
            
            // Первые 2 товара
            if (filteredProducts.isNotEmpty) 
              _buildProductsAsWidgets(filteredProducts.take(2).toList(), userId),
            
            // Слайдер
            BannerSlider(),
            
            // Остальные товары
            if (filteredProducts.length > 2)
              _buildProductsAsWidgets(filteredProducts.sublist(2), userId),
          ]),
        );
      },
    );
  }

  Widget _buildProductsAsWidgets(List<QueryDocumentSnapshot> products, String? userId) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.7,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final productDoc = products[index];
          try {
            final product = _parseProductFromDoc(productDoc);
            final favoritesService = FavoritesService();
            
            return ProductCard(
              product: product,
              userId: userId,
              favoritesService: favoritesService,
            );
          } catch (e) {
            return Container(
              padding: EdgeInsets.all(8),
              child: Column(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  Text('Ошибка загрузки'),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Product _parseProductFromDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    return Product(
      id: data['id']?.toString() ?? doc.id,
      name: data['name']?.toString() ?? 'Без названия',
      price: _parsePrice(data['price']),
      category: data['category']?.toString() ?? 'Без категории',
      description: data['description']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
    );
  }

  double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) return double.tryParse(price) ?? 0.0;
    return 0.0;
  }

  Widget _buildHeader(String? userId) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _stateManager.isCategoryFilterActive 
                    ? '${_stateManager.selectedCategories.length} категории' 
                    : 'Все товары',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_stateManager.selectedSort != 'По умолчанию')
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sort, size: 16, color: Colors.blue),
                      SizedBox(width: 4),
                      Text(
                        _stateManager.selectedSort,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 8),
          if (userId == null)
            Text(
              'Войдите в аккаунт, чтобы добавлять товары в избранное',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingSliver() {
    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildErrorSliver(String message) {
    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySearchSliver() {
    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
              SizedBox(height: 16),
              Text(
                'Ничего не найдено',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Попробуйте изменить запрос',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// import 'package:dress_up/models/product';
// import 'package:dress_up/screens/auth/auth_provider.dart';
// import 'package:dress_up/services/FavoritesService.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../widgets/product_card.dart';

// class HomeScreen extends StatefulWidget {
//   final ScrollController scrollController;

//   HomeScreen({
//     Key? key, 
//     required this.scrollController,
//   }) : super(key: key);

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
//   Set<String> _selectedCategories = {'Все'};
//   String _selectedSort = 'По умолчанию';
//   final List<String> _categories = [
//     'Все',
//     'Платья',
//     'Футболки',
//     'Джинсы',
//     'Куртки',
//     'Свитшоты',
//     'Брюки',
//     'Обувь',
//     'Рубашки',
//     'Юбки',
//     'Пальто',
//     'Блузки',
//     'Шорты',
//     'Пиджаки',
//     'Аксессуары',
//   ];

//   final Map<String, String> _sortOptions = {
//     'По умолчанию': 'default',
//     'По цене (сначала дешевые)': 'price_asc',
//     'По цене (сначала дорогие)': 'price_desc',
//     'По названию (А-Я)': 'name_asc',
//     'По названию (Я-А)': 'name_desc',
//     'По популярности': 'popularity',
//   };

//   // Переменные для поиска
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//   bool _isSearching = false;
//   FocusNode _searchFocusNode = FocusNode();

//   @override
//   bool get wantKeepAlive => true;

//   @override
//   void initState() {
//     super.initState();
//     _searchFocusNode.addListener(_onSearchFocusChange);
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _searchFocusNode.dispose();
//     super.dispose();
//   }

//   void _onSearchFocusChange() {
//     if (!_searchFocusNode.hasFocus && _searchQuery.isEmpty) {
//       setState(() {
//         _isSearching = false;
//       });
//     }
//   }

//   // Методы для работы с выбором категорий
//   void _toggleCategorySelection(String category) {
//     setState(() {
//       if (category == 'Все') {
//         _selectedCategories = {'Все'};
//       } else {
//         _selectedCategories.remove('Все');
        
//         if (_selectedCategories.contains(category)) {
//           _selectedCategories.remove(category);
//           if (_selectedCategories.isEmpty) {
//             _selectedCategories.add('Все');
//           }
//         } else {
//           _selectedCategories.add(category);
//         }
//       }
//     });
//   }

//   void _clearSelection() {
//     setState(() {
//       _selectedCategories = {'Все'};
//     });
//   }

//   // Получить отображаемый текст для выбранных категорий
//   String get _displayCategoriesText {
//     if (_selectedCategories.contains('Все') || _selectedCategories.isEmpty) {
//       return 'Все категории';
//     }
    
//     if (_selectedCategories.length == 1) {
//       return _selectedCategories.first;
//     }
    
//     return '${_selectedCategories.length} категории';
//   }

//   // Проверить, активна ли фильтрация по категориям
//   bool get _isCategoryFilterActive {
//     return !_selectedCategories.contains('Все') && _selectedCategories.isNotEmpty;
//   }

//   void _showSortOptions(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       builder: (BuildContext context) {
//         return Container(
//           padding: EdgeInsets.all(16),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Сортировка товаров',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               SizedBox(height: 16),
//               ..._sortOptions.keys.map((sortTitle) {
//                 return _buildSortOption(
//                   context,
//                   sortTitle,
//                   _getSortIcon(sortTitle),
//                   () {
//                     setState(() {
//                       _selectedSort = sortTitle;
//                     });
//                     Navigator.pop(context);
//                   },
//                   isSelected: _selectedSort == sortTitle,
//                 );
//               }).toList(),
//               SizedBox(height: 8),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // Показать диалог выбора категорий
//   void _showCategoryDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return StatefulBuilder(
//           builder: (context, setDialogState) {
//             return AlertDialog(
//               title: Row(
//                 children: [
//                   Icon(Icons.category, color: Colors.blue),
//                   SizedBox(width: 8),
//                   Text('Выбор категорий'),
//                   Spacer(),
//                   if (_isCategoryFilterActive)
//                     TextButton(
//                       onPressed: () {
//                         _clearSelection();
//                         setDialogState(() {});
//                       },
//                       child: Text(
//                         'Очистить',
//                         style: TextStyle(color: Colors.blue),
//                       ),
//                     ),
//                 ],
//               ),
//               content: Container(
//                 width: double.maxFinite,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     // Список категорий
//                     Container(
//                       constraints: BoxConstraints(maxHeight: 400),
//                       child: ListView.builder(
//                         shrinkWrap: true,
//                         itemCount: _categories.length,
//                         itemBuilder: (context, index) {
//                           final category = _categories[index];
//                           final isSelected = _selectedCategories.contains(category);
                          
//                           return Card(
//                             margin: EdgeInsets.symmetric(vertical: 4),
//                             elevation: 1,
//                             child: ListTile(
//                               leading: Container(
//                                 width: 24,
//                                 height: 24,
//                                 decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(4),
//                                   border: Border.all(
//                                     color: isSelected ? Colors.blue : Colors.grey[400]!,
//                                     width: 2,
//                                   ),
//                                   color: isSelected ? Colors.blue : Colors.transparent,
//                                 ),
//                                 child: isSelected
//                                     ? Icon(
//                                         Icons.check,
//                                         size: 16,
//                                         color: Colors.white,
//                                       )
//                                     : null,
//                               ),
//                               title: Text(
//                                 category,
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   color: isSelected ? Colors.blue : Colors.black87,
//                                   fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//                                 ),
//                               ),
//                               onTap: () {
//                                 _toggleCategorySelection(category);
//                                 setDialogState(() {});
//                               },
//                               tileColor: isSelected ? Colors.blue.withOpacity(0.05) : null,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                                 side: BorderSide(
//                                   color: isSelected ? Colors.blue.withOpacity(0.3) : Colors.transparent,
//                                   width: 1,
//                                 ),
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                     SizedBox(height: 16),
//                     // Информация о выборе
//                     Container(
//                       padding: EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.grey[50],
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: Colors.grey[300]!),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(Icons.info_outline, size: 16, color: Colors.blue),
//                           SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                               'Выбрано: ${_selectedCategories.length}',
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 color: Colors.grey[700],
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ),
//                           if (_isCategoryFilterActive)
//                             Wrap(
//                               spacing: 4,
//                               children: _selectedCategories.take(2).map((category) {
//                                 return Chip(
//                                   label: Text(
//                                     category.length > 8 ? '${category.substring(0, 8)}...' : category,
//                                     style: TextStyle(fontSize: 11),
//                                   ),
//                                   backgroundColor: Colors.blue.withOpacity(0.1),
//                                   labelStyle: TextStyle(color: Colors.blue),
//                                   materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                                 );
//                               }).toList(),
//                             ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: Text('Отмена', style: TextStyle(color: Colors.grey[600])),
//                 ),
//                 ElevatedButton(
//                   onPressed: () => Navigator.pop(context),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue,
//                     foregroundColor: Colors.white,
//                   ),
//                   child: Text('Применить'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }

//   // Виджет кнопки выбора категорий
//   Widget _buildCategoryDropdown() {
//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: _isCategoryFilterActive ? Colors.blue : Colors.grey[300]!,
//           width: _isCategoryFilterActive ? 2 : 1,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black12,
//             blurRadius: 4,
//             offset: Offset(0, 2),
//           ),
//         ],
//       ),
//       child: InkWell(
//         onTap: () => _showCategoryDialog(context),
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//           child: Row(
//             children: [
//               Icon(
//                 Icons.category,
//                 color: _isCategoryFilterActive ? Colors.blue : Colors.grey[600],
//                 size: 20,
//               ),
//               SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Категории',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                     SizedBox(height: 2),
//                     Text(
//                       _displayCategoriesText,
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                         color: _isCategoryFilterActive ? Colors.blue : Colors.black87,
//                       ),
//                     ),
//                     if (_isCategoryFilterActive && _selectedCategories.length > 1)
//                       SizedBox(height: 4),
//                     if (_isCategoryFilterActive && _selectedCategories.length > 1)
//                       Wrap(
//                         spacing: 4,
//                         runSpacing: 2,
//                         children: _selectedCategories.take(3).map((category) {
//                           return Container(
//                             padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                             decoration: BoxDecoration(
//                               color: Colors.blue.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Text(
//                               category.length > 10 ? '${category.substring(0, 10)}...' : category,
//                               style: TextStyle(
//                                 fontSize: 10,
//                                 color: Colors.blue,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           );
//                         }).toList(),
//                       ),
//                   ],
//                 ),
//               ),
//               SizedBox(width: 8),
//               // Бейдж с количеством выбранных категорий
//               if (_isCategoryFilterActive)
//                 Container(
//                   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: Colors.blue,
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Text(
//                     '${_selectedCategories.length}',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               SizedBox(width: 8),
//               Icon(
//                 Icons.arrow_drop_down,
//                 color: _isCategoryFilterActive ? Colors.blue : Colors.grey[600],
//                 size: 24,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // Метод для поиска товаров
//   List<QueryDocumentSnapshot> _searchProducts(List<QueryDocumentSnapshot> products) {
//     if (_searchQuery.isEmpty) return products;

//     final query = _searchQuery.toLowerCase();
//     return products.where((doc) {
//       final data = doc.data() as Map<String, dynamic>;
//       final name = (data['name'] ?? '').toString().toLowerCase();
//       final description = (data['description'] ?? '').toString().toLowerCase();
//       final category = (data['category'] ?? '').toString().toLowerCase();

//       return name.contains(query) || 
//              description.contains(query) || 
//              category.contains(query);
//     }).toList();
//   }

//   // Виджет поисковой строки
//   Widget _buildSearchBar() {
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: TextField(
//         controller: _searchController,
//         focusNode: _searchFocusNode,
//         decoration: InputDecoration(
//           hintText: 'Поиск товаров...',
//           prefixIcon: Icon(Icons.search),
//           suffixIcon: _searchQuery.isNotEmpty
//               ? IconButton(
//                   icon: Icon(Icons.clear),
//                   onPressed: () {
//                     _searchController.clear();
//                     setState(() {
//                       _searchQuery = '';
//                       _isSearching = false;
//                     });
//                   },
//                 )
//               : null,
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide.none,
//           ),
//           filled: true,
//           fillColor: Colors.grey[100],
//           contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
//         ),
//         onChanged: (value) {
//           setState(() {
//             _searchQuery = value.trim();
//             _isSearching = value.isNotEmpty;
//           });
//         },
//         onSubmitted: (value) {
//           setState(() {
//             _searchQuery = value.trim();
//             _isSearching = value.isNotEmpty;
//           });
//         },
//       ),
//     );
//   }

//   // Виджет результатов поиска
//   Widget _buildSearchResults(List<QueryDocumentSnapshot> allProducts) {
//     final searchResults = _searchProducts(allProducts);
//     final filteredResults = _filterProductsByCategory(searchResults);
//     final sortedResults = _sortProducts(filteredResults);

//     if (searchResults.isEmpty) {
//       return SliverToBoxAdapter(
//         child: Center(
//           child: Padding(
//             padding: const EdgeInsets.all(40.0),
//             child: Column(
//               children: [
//                 Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
//                 SizedBox(height: 16),
//                 Text(
//                   'Ничего не найдено',
//                   style: TextStyle(fontSize: 18, color: Colors.grey),
//                 ),
//                 SizedBox(height: 8),
//                 Text(
//                   'Попробуйте изменить запрос',
//                   style: TextStyle(fontSize: 14, color: Colors.grey[500]),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     }

//     return SliverPadding(
//       padding: const EdgeInsets.all(8.0),
//       sliver: SliverGrid(
//         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2,
//           crossAxisSpacing: 8,
//           mainAxisSpacing: 8,
//           childAspectRatio: 0.7,
//         ),
//         delegate: SliverChildBuilderDelegate(
//           (context, index) {
//             final productDoc = sortedResults[index];
//             try {
//               final product = _parseProductFromDoc(productDoc);
//               final authProvider = Provider.of<AuthProvider>(context, listen: false);
//               final String? userId = authProvider.isLoggedIn ? authProvider.currentUser?.uid : null;
//               final FavoritesService favoritesService = FavoritesService();
              
//               return ProductCard(
//                 product: product,
//                 userId: userId,
//                 favoritesService: favoritesService,
//               );
//             } catch (e) {
//               return Container(
//                 padding: EdgeInsets.all(8),
//                 child: Column(
//                   children: [
//                     Icon(Icons.error, color: Colors.red),
//                     Text('Ошибка загрузки'),
//                   ],
//                 ),
//               );
//             }
//           },
//           childCount: sortedResults.length,
//         ),
//       ),
//     );
//   }

//   // Фильтрация товаров по выбранным категориям
//   List<QueryDocumentSnapshot> _filterProductsByCategory(List<QueryDocumentSnapshot> products) {
//     if (_selectedCategories.contains('Все') || _selectedCategories.isEmpty) {
//       return products;
//     }

//     return products.where((doc) {
//       final data = doc.data() as Map<String, dynamic>;
//       final category = (data['category'] ?? '').toString();
//       return _selectedCategories.contains(category);
//     }).toList();
//   }

//   IconData _getSortIcon(String sortTitle) {
//     switch (sortTitle) {
//       case 'По цене (сначала дешевые)':
//         return Icons.arrow_upward;
//       case 'По цене (сначала дорогие)':
//         return Icons.arrow_downward;
//       case 'По названию (А-Я)':
//         return Icons.sort_by_alpha;
//       case 'По названию (Я-А)':
//         return Icons.sort_by_alpha;
//       case 'По популярности':
//         return Icons.trending_up;
//       default:
//         return Icons.sort;
//     }
//   }

//   Widget _buildSortOption(
//     BuildContext context,
//     String title,
//     IconData icon,
//     VoidCallback onTap, {
//     bool isSelected = false,
//   }) {
//     return ListTile(
//       leading: Icon(
//         icon, 
//         color: isSelected ? Colors.blue : Colors.grey[600],
//       ),
//       title: Text(
//         title,
//         style: TextStyle(
//           color: isSelected ? Colors.blue : Colors.black,
//           fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//         ),
//       ),
//       onTap: onTap,
//       contentPadding: EdgeInsets.zero,
//       trailing: isSelected ? Icon(Icons.check, color: Colors.blue) : null,
//     );
//   }

//   // Метод для сортировки списка товаров
//   List<QueryDocumentSnapshot> _sortProducts(List<QueryDocumentSnapshot> products) {
//     List<QueryDocumentSnapshot> sortedProducts = List.from(products);
    
//     switch (_selectedSort) {
//       case 'По цене (сначала дешевые)':
//         sortedProducts.sort((a, b) {
//           final priceA = _parsePrice((a.data() as Map<String, dynamic>)['price']);
//           final priceB = _parsePrice((b.data() as Map<String, dynamic>)['price']);
//           return priceA.compareTo(priceB);
//         });
//         break;
        
//       case 'По цене (сначала дорогие)':
//         sortedProducts.sort((a, b) {
//           final priceA = _parsePrice((a.data() as Map<String, dynamic>)['price']);
//           final priceB = _parsePrice((b.data() as Map<String, dynamic>)['price']);
//           return priceB.compareTo(priceA);
//         });
//         break;
        
//       case 'По названию (А-Я)':
//         sortedProducts.sort((a, b) {
//           final nameA = ((a.data() as Map<String, dynamic>)['name'] ?? '').toString().toLowerCase();
//           final nameB = ((b.data() as Map<String, dynamic>)['name'] ?? '').toString().toLowerCase();
//           return nameA.compareTo(nameB);
//         });
//         break;
        
//       case 'По названию (Я-А)':
//         sortedProducts.sort((a, b) {
//           final nameA = ((a.data() as Map<String, dynamic>)['name'] ?? '').toString().toLowerCase();
//           final nameB = ((b.data() as Map<String, dynamic>)['name'] ?? '').toString().toLowerCase();
//           return nameB.compareTo(nameA);
//         });
//         break;
        
//       case 'По популярности':
//         sortedProducts.sort((a, b) {
//           final ratingA = ((a.data() as Map<String, dynamic>)['rating'] ?? 0).toDouble();
//           final ratingB = ((b.data() as Map<String, dynamic>)['rating'] ?? 0).toDouble();
//           return ratingB.compareTo(ratingA);
//         });
//         break;
        
//       case 'По умолчанию':
//       default:
//         break;
//     }
    
//     return sortedProducts;
//   }

//   // Метод для создания Product из документа
//   Product _parseProductFromDoc(QueryDocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>? ?? {};
    
//     return Product(
//       id: data['id']?.toString() ?? doc.id,
//       name: data['name']?.toString() ?? 'Без названия',
//       price: _parsePrice(data['price']),
//       category: data['category']?.toString() ?? 'Без категории',
//       description: data['description']?.toString() ?? '',
//       imageUrl: data['imageUrl']?.toString() ?? '',
//     );
//   }

//   double _parsePrice(dynamic price) {
//     if (price == null) return 0.0;
//     if (price is double) return price;
//     if (price is int) return price.toDouble();
//     if (price is String) return double.tryParse(price) ?? 0.0;
//     return 0.0;
//   }

//   // Функция обновления данных
//   Future<void> _refreshData() async {
//     setState(() {});
//     await Future.delayed(Duration(seconds: 1));
//   }

//   @override
//   Widget build(BuildContext context) {
//     super.build(context);
    
//     final authProvider = Provider.of<AuthProvider>(context);
//     final String? userId = authProvider.isLoggedIn ? authProvider.currentUser?.uid : null;
//     final FavoritesService favoritesService = FavoritesService();

//     return Scaffold(
//       appBar: AppBar(
//         title: _isSearching 
//             ? Text('Поиск: $_searchQuery')
//             : Text('DressUp'),
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         elevation: 0,
//         actions: [
//           if (!_isSearching) ...[
//             IconButton(
//               icon: Icon(Icons.search),
//               onPressed: () {
//                 setState(() {
//                   _isSearching = true;
//                 });
//                 WidgetsBinding.instance.addPostFrameCallback((_) {
//                   _searchFocusNode.requestFocus();
//                 });
//               },
//             ),
//             IconButton(
//               icon: Icon(Icons.sort),
//               onPressed: () => _showSortOptions(context),
//             ),
//           ] else ...[
//             IconButton(
//               icon: Icon(Icons.clear),
//               onPressed: () {
//                 _searchController.clear();
//                 setState(() {
//                   _searchQuery = '';
//                   _isSearching = false;
//                 });
//               },
//             ),
//           ],
//         ],
//       ),
//       body: RefreshIndicator(
//         onRefresh: _refreshData,
//         child: CustomScrollView(
//           controller: widget.scrollController,
//           physics: AlwaysScrollableScrollPhysics(),
//           slivers: [
//             // Поисковая строка (показывается всегда)
//             SliverToBoxAdapter(
//               child: _buildSearchBar(),
//             ),

//             // Выпадающий список категорий
//             SliverToBoxAdapter(
//               child: _buildCategoryDropdown(),
//             ),

//             if (_isSearching) ...[
//               // Режим поиска - показываем только результаты поиска
//               StreamBuilder<QuerySnapshot>(
//                 stream: FirebaseFirestore.instance
//                     .collection('dress')
//                     .snapshots(),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return SliverToBoxAdapter(
//                       child: Center(
//                         child: Padding(
//                           padding: const EdgeInsets.all(20.0),
//                           child: CircularProgressIndicator(),
//                         ),
//                       ),
//                     );
//                   }

//                   if (snapshot.hasError) {
//                     return SliverToBoxAdapter(
//                       child: Center(
//                         child: Padding(
//                           padding: const EdgeInsets.all(20.0),
//                           child: Column(
//                             children: [
//                               Icon(Icons.error_outline, size: 64, color: Colors.red),
//                               SizedBox(height: 16),
//                               Text(
//                                 'Ошибка загрузки товаров',
//                                 style: TextStyle(fontSize: 16, color: Colors.grey),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     );
//                   }

//                   final products = snapshot.data?.docs ?? [];
//                   return _buildSearchResults(products);
//                 },
//               ),
//             ] else ...[
//               // Обычный режим - стандартная структура
//               // 1. Заголовок
//               SliverToBoxAdapter(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             _isCategoryFilterActive 
//                                 ? '${_selectedCategories.length} категории' 
//                                 : 'Все товары',
//                             style: TextStyle(
//                               fontSize: 24,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           if (_selectedSort != 'По умолчанию')
//                             Container(
//                               padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                               decoration: BoxDecoration(
//                                 color: Colors.blue.withOpacity(0.1),
//                                 borderRadius: BorderRadius.circular(16),
//                               ),
//                               child: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   Icon(Icons.sort, size: 16, color: Colors.blue),
//                                   SizedBox(width: 4),
//                                   Text(
//                                     _selectedSort,
//                                     style: TextStyle(
//                                       fontSize: 12,
//                                       color: Colors.blue,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                         ],
//                       ),
//                       SizedBox(height: 8),
//                       if (userId == null)
//                         Text(
//                           'Войдите в аккаунт, чтобы добавлять товары в избранное',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.grey,
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               ),

//               // 2. Первые 2 товара
//               StreamBuilder<QuerySnapshot>(
//                 stream: FirebaseFirestore.instance
//                     .collection('dress')
//                     .snapshots(),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return SliverToBoxAdapter(
//                       child: Center(
//                         child: Padding(
//                           padding: const EdgeInsets.all(20.0),
//                           child: CircularProgressIndicator(),
//                         ),
//                       ),
//                     );
//                   }

//                   if (snapshot.hasError) {
//                     return SliverToBoxAdapter(
//                       child: Center(
//                         child: Padding(
//                           padding: const EdgeInsets.all(20.0),
//                           child: Column(
//                             children: [
//                               Icon(Icons.error_outline, size: 64, color: Colors.red),
//                               SizedBox(height: 16),
//                               Text(
//                                 'Ошибка загрузки товаров',
//                                 style: TextStyle(fontSize: 16, color: Colors.grey),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     );
//                   }

//                   final products = snapshot.data?.docs ?? [];
//                   final filteredProducts = _filterProductsByCategory(products);
//                   final sortedProducts = _sortProducts(filteredProducts);
//                   final firstTwoProducts = sortedProducts.take(2).toList();

//                   if (firstTwoProducts.isEmpty) {
//                     return SliverToBoxAdapter(
//                       child: SizedBox.shrink(),
//                     );
//                   }

//                   return SliverPadding(
//                     padding: const EdgeInsets.all(8.0),
//                     sliver: SliverGrid(
//                       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                         crossAxisCount: 2,
//                         crossAxisSpacing: 8,
//                         mainAxisSpacing: 8,
//                         childAspectRatio: 0.7,
//                       ),
//                       delegate: SliverChildBuilderDelegate(
//                         (context, index) {
//                           final productDoc = firstTwoProducts[index];
//                           try {
//                             final product = _parseProductFromDoc(productDoc);
//                             return ProductCard(
//                               product: product,
//                               userId: userId,
//                               favoritesService: favoritesService,
//                             );
//                           } catch (e) {
//                             return Container(
//                               padding: EdgeInsets.all(8),
//                               child: Column(
//                                 children: [
//                                   Icon(Icons.error, color: Colors.red),
//                                   Text('Ошибка загрузки'),
//                                 ],
//                               ),
//                             );
//                           }
//                         },
//                         childCount: firstTwoProducts.length,
//                       ),
//                     ),
//                   );
//                 },
//               ),

//               // 3. Слайдер
//               SliverToBoxAdapter(
//                 child: BannerSlider(),
//               ),

//               // 4. Остальные товары (начиная с 3-го)
//               StreamBuilder<QuerySnapshot>(
//                 stream: FirebaseFirestore.instance
//                     .collection('dress')
//                     .snapshots(),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return SliverToBoxAdapter(
//                       child: SizedBox.shrink(),
//                     );
//                   }

//                   if (snapshot.hasError) {
//                     return SliverToBoxAdapter(
//                       child: SizedBox.shrink(),
//                     );
//                   }

//                   final products = snapshot.data?.docs ?? [];
//                   final filteredProducts = _filterProductsByCategory(products);
//                   final sortedProducts = _sortProducts(filteredProducts);
//                   final remainingProducts = sortedProducts.length > 2 
//                       ? sortedProducts.sublist(2) 
//                       : <QueryDocumentSnapshot>[];

//                   if (remainingProducts.isEmpty) {
//                     return SliverToBoxAdapter(
//                       child: SizedBox.shrink(),
//                     );
//                   }

//                   return SliverPadding(
//                     padding: const EdgeInsets.all(8.0),
//                     sliver: SliverGrid(
//                       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                         crossAxisCount: 2,
//                         crossAxisSpacing: 8,
//                         mainAxisSpacing: 8,
//                         childAspectRatio: 0.7,
//                       ),
//                       delegate: SliverChildBuilderDelegate(
//                         (context, index) {
//                           final productDoc = remainingProducts[index];
//                           try {
//                             final product = _parseProductFromDoc(productDoc);
//                             return ProductCard(
//                               product: product,
//                               userId: userId,
//                               favoritesService: favoritesService,
//                             );
//                           } catch (e) {
//                             return Container(
//                               padding: EdgeInsets.all(8),
//                               child: Column(
//                                 children: [
//                                   Icon(Icons.error, color: Colors.red),
//                                   Text('Ошибка загрузки'),
//                                 ],
//                               ),
//                             );
//                           }
//                         },
//                         childCount: remainingProducts.length,
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }

// // Циклический слайдер (остается без изменений)
// class BannerSlider extends StatefulWidget {
//   const BannerSlider({Key? key}) : super(key: key);

//   @override
//   State<BannerSlider> createState() => _BannerSliderState();
// }

// class _BannerSliderState extends State<BannerSlider> {
//   final PageController _bannerController = PageController(viewportFraction: 0.9);
//   int _currentBanner = 0;
//   final List<Map<String, dynamic>> _banners = [
//     {
//       'image': 'https://i.pinimg.com/originals/66/18/3c/66183c6d3569b5ee453ddada768152f4.jpg',
//       'title': 'Новая коллекция',
//       'subtitle': 'Скидки до 50%'
//     },
//     {
//       'image': 'https://i.pinimg.com/originals/da/fe/42/dafe421c17ecc9db4e263bbfa74c7d0f.png',
//       'title': 'Сезон распродаж',
//       'subtitle': 'Лучшие предложения'
//     },
//     {
//       'image': 'https://avatars.mds.yandex.net/i?id=c2f566aa9bda261c25304e36e9f75af5_l-4334445-images-thumbs&n=13',
//       'title': 'Бесплатная доставка',
//       'subtitle': 'При заказе от \$50'
//     },
//   ];

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_banners.length > 1) {
//         final initialPage = _banners.length * 1000;
//         _bannerController.jumpToPage(initialPage);
//         _updateCurrentBanner(0);
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _bannerController.dispose();
//     super.dispose();
//   }

//   void _updateCurrentBanner(int page) {
//     final actualPage = page % _banners.length;
//     if (_currentBanner != actualPage) {
//       setState(() {
//         _currentBanner = actualPage;
//       });
//     }
//   }

//   Widget _buildBannerSlide(Map<String, dynamic> banner, int index) {
//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: 8),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black12,
//             blurRadius: 8,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(16),
//         child: Stack(
//           children: [
//             Image.network(
//               banner['image'],
//               fit: BoxFit.cover,
//               width: double.infinity,
//               loadingBuilder: (context, child, loadingProgress) {
//                 if (loadingProgress == null) return child;
//                 return Container(
//                   color: Colors.grey[300],
//                   child: Center(
//                     child: CircularProgressIndicator(
//                       value: loadingProgress.expectedTotalBytes != null
//                           ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
//                           : null,
//                     ),
//                   ),
//                 );
//               },
//               errorBuilder: (context, error, stackTrace) {
//                 return Container(
//                   color: Colors.grey[300],
//                   child: Icon(Icons.image, color: Colors.grey[500], size: 50),
//                 );
//               },
//             ),
//             Container(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.bottomCenter,
//                   end: Alignment.topCenter,
//                   colors: [
//                     Colors.black.withOpacity(0.7),
//                     Colors.transparent,
//                   ],
//                 ),
//               ),
//             ),
//             Positioned(
//               left: 16,
//               bottom: 16,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     banner['title'],
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   SizedBox(height: 4),
//                   Text(
//                     banner['subtitle'],
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 14,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildBannerIndicators() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: _banners.asMap().entries.map((entry) {
//         return AnimatedContainer(
//           duration: Duration(milliseconds: 300),
//           width: _currentBanner == entry.key ? 20 : 8,
//           height: 8,
//           margin: EdgeInsets.symmetric(horizontal: 4),
//           decoration: BoxDecoration(
//             shape: _currentBanner == entry.key ? BoxShape.rectangle : BoxShape.circle,
//             borderRadius: _currentBanner == entry.key ? BorderRadius.circular(4) : null,
//             color: _currentBanner == entry.key ? Colors.blue : Colors.grey[300],
//           ),
//         );
//       }).toList(),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         SizedBox(height: 16),
//         Container(
//           height: 160,
//           child: PageView.builder(
//             controller: _bannerController,
//             itemCount: _banners.length > 1 ? null : _banners.length,
//             onPageChanged: _updateCurrentBanner,
//             itemBuilder: (context, index) {
//               final actualIndex = index % _banners.length;
//               return _buildBannerSlide(_banners[actualIndex], actualIndex);
//             },
//           ),
//         ),
//         SizedBox(height: 8),
//         _buildBannerIndicators(),
//         SizedBox(height: 16),
//       ],
//     );
//   }
// }