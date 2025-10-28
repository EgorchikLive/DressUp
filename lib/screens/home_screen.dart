import 'package:dress_up/models/product';
import 'package:dress_up/screens/auth/auth_provider.dart';
import 'package:dress_up/services/FavoritesService.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  final ScrollController scrollController;

  HomeScreen({
    Key? key, 
    required this.scrollController,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  String _selectedCategory = 'Все';
  String _selectedSort = 'По умолчанию';
  final List<String> _categories = [
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

  final Map<String, String> _sortOptions = {
    'По умолчанию': 'default',
    'По цене (сначала дешевые)': 'price_asc',
    'По цене (сначала дорогие)': 'price_desc',
    'По названию (А-Я)': 'name_asc',
    'По названию (Я-А)': 'name_desc',
    'По популярности': 'popularity',
  };

  // Переменные для поиска
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  FocusNode _searchFocusNode = FocusNode();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onSearchFocusChange);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchFocusChange() {
    if (!_searchFocusNode.hasFocus && _searchQuery.isEmpty) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _showSortOptions(BuildContext context) {
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
              ..._sortOptions.keys.map((sortTitle) {
                return _buildSortOption(
                  context,
                  sortTitle,
                  _getSortIcon(sortTitle),
                  () {
                    setState(() {
                      _selectedSort = sortTitle;
                    });
                    Navigator.pop(context);
                  },
                  isSelected: _selectedSort == sortTitle,
                );
              }).toList(),
              SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // Метод для поиска товаров
  List<QueryDocumentSnapshot> _searchProducts(List<QueryDocumentSnapshot> products) {
    if (_searchQuery.isEmpty) return products;

    final query = _searchQuery.toLowerCase();
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

  // Виджет поисковой строки
  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Поиск товаров...',
          prefixIcon: Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _isSearching = false;
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim();
            _isSearching = value.isNotEmpty;
          });
        },
        onSubmitted: (value) {
          setState(() {
            _searchQuery = value.trim();
            _isSearching = value.isNotEmpty;
          });
        },
      ),
    );
  }

  // Виджет результатов поиска
  Widget _buildSearchResults(List<QueryDocumentSnapshot> allProducts) {
    final searchResults = _searchProducts(allProducts);
    final sortedResults = _sortProducts(searchResults);

    if (searchResults.isEmpty) {
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

    return SliverPadding(
      padding: const EdgeInsets.all(8.0),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.7,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final productDoc = sortedResults[index];
            try {
              final product = _parseProductFromDoc(productDoc);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final String? userId = authProvider.isLoggedIn ? authProvider.currentUser?.uid : null;
              final FavoritesService favoritesService = FavoritesService();
              
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
          childCount: sortedResults.length,
        ),
      ),
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

  // Метод для сортировки списка товаров
  List<QueryDocumentSnapshot> _sortProducts(List<QueryDocumentSnapshot> products) {
    List<QueryDocumentSnapshot> sortedProducts = List.from(products);
    
    switch (_selectedSort) {
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

  // Метод для создания Product из документа
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

  // Функция обновления данных
  Future<void> _refreshData() async {
    setState(() {});
    await Future.delayed(Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final authProvider = Provider.of<AuthProvider>(context);
    final String? userId = authProvider.isLoggedIn ? authProvider.currentUser?.uid : null;
    final FavoritesService favoritesService = FavoritesService();

    return Scaffold(
      appBar: AppBar(
        title: _isSearching 
            ? Text('Поиск: $_searchQuery')
            : Text('DressUp'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (!_isSearching) ...[
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _searchFocusNode.requestFocus();
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.sort),
              onPressed: () => _showSortOptions(context),
            ),
          ] else ...[
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _isSearching = false;
                });
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
            // Поисковая строка (показывается всегда)
            SliverToBoxAdapter(
              child: _buildSearchBar(),
            ),

            if (_isSearching) ...[
              // Режим поиска - показываем только результаты поиска
              StreamBuilder<QuerySnapshot>(
                stream: _selectedCategory == 'Все' 
                    ? FirebaseFirestore.instance
                        .collection('dress')
                        .snapshots()
                    : FirebaseFirestore.instance
                        .collection('dress')
                        .where('category', isEqualTo: _selectedCategory)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Icon(Icons.error_outline, size: 64, color: Colors.red),
                              SizedBox(height: 16),
                              Text(
                                'Ошибка загрузки товаров',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final products = snapshot.data?.docs ?? [];
                  return _buildSearchResults(products);
                },
              ),
            ] else ...[
              // Обычный режим - стандартная структура
              // 1. Категории
              SliverToBoxAdapter(
                child: Container(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          selectedColor: Colors.blue,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 2. Заголовок
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedCategory == 'Все' ? 'Все товары' : _selectedCategory,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_selectedSort != 'По умолчанию')
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
                                    _selectedSort,
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
                ),
              ),

              // 3. Первые 2 товара
              StreamBuilder<QuerySnapshot>(
                stream: _selectedCategory == 'Все' 
                    ? FirebaseFirestore.instance
                        .collection('dress')
                        .snapshots()
                    : FirebaseFirestore.instance
                        .collection('dress')
                        .where('category', isEqualTo: _selectedCategory)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Icon(Icons.error_outline, size: 64, color: Colors.red),
                              SizedBox(height: 16),
                              Text(
                                'Ошибка загрузки товаров',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final products = snapshot.data?.docs ?? [];
                  final sortedProducts = _sortProducts(products);
                  final firstTwoProducts = sortedProducts.take(2).toList();

                  if (firstTwoProducts.isEmpty) {
                    return SliverToBoxAdapter(
                      child: SizedBox.shrink(),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.all(8.0),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.7,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final productDoc = firstTwoProducts[index];
                          try {
                            final product = _parseProductFromDoc(productDoc);
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
                        childCount: firstTwoProducts.length,
                      ),
                    ),
                  );
                },
              ),

              // 4. Слайдер
              SliverToBoxAdapter(
                child: BannerSlider(),
              ),

              // 5. Остальные товары (начиная с 3-го)
              StreamBuilder<QuerySnapshot>(
                stream: _selectedCategory == 'Все' 
                    ? FirebaseFirestore.instance
                        .collection('dress')
                        .snapshots()
                    : FirebaseFirestore.instance
                        .collection('dress')
                        .where('category', isEqualTo: _selectedCategory)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SliverToBoxAdapter(
                      child: SizedBox.shrink(),
                    );
                  }

                  if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: SizedBox.shrink(),
                    );
                  }

                  final products = snapshot.data?.docs ?? [];
                  final sortedProducts = _sortProducts(products);
                  final remainingProducts = sortedProducts.length > 2 
                      ? sortedProducts.sublist(2) 
                      : <QueryDocumentSnapshot>[];

                  if (remainingProducts.isEmpty) {
                    return SliverToBoxAdapter(
                      child: SizedBox.shrink(),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.all(8.0),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.7,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final productDoc = remainingProducts[index];
                          try {
                            final product = _parseProductFromDoc(productDoc);
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
                        childCount: remainingProducts.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Циклический слайдер (остается без изменений)
class BannerSlider extends StatefulWidget {
  const BannerSlider({Key? key}) : super(key: key);

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  final PageController _bannerController = PageController(viewportFraction: 0.9);
  int _currentBanner = 0;
  final List<Map<String, dynamic>> _banners = [
    {
      'image': 'https://i.pinimg.com/originals/66/18/3c/66183c6d3569b5ee453ddada768152f4.jpg',
      'title': 'Новая коллекция',
      'subtitle': 'Скидки до 50%'
    },
    {
      'image': 'https://i.pinimg.com/originals/da/fe/42/dafe421c17ecc9db4e263bbfa74c7d0f.png',
      'title': 'Сезон распродаж',
      'subtitle': 'Лучшие предложения'
    },
    {
      'image': 'https://avatars.mds.yandex.net/i?id=c2f566aa9bda261c25304e36e9f75af5_l-4334445-images-thumbs&n=13',
      'title': 'Бесплатная доставка',
      'subtitle': 'При заказе от \$50'
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_banners.length > 1) {
        final initialPage = _banners.length * 1000;
        _bannerController.jumpToPage(initialPage);
        _updateCurrentBanner(0);
      }
    });
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  void _updateCurrentBanner(int page) {
    final actualPage = page % _banners.length;
    if (_currentBanner != actualPage) {
      setState(() {
        _currentBanner = actualPage;
      });
    }
  }

  Widget _buildBannerSlide(Map<String, dynamic> banner, int index) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Image.network(
              banner['image'],
              fit: BoxFit.cover,
              width: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[300],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: Icon(Icons.image, color: Colors.grey[500], size: 50),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    banner['title'],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    banner['subtitle'],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _banners.asMap().entries.map((entry) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          width: _currentBanner == entry.key ? 20 : 8,
          height: 8,
          margin: EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: _currentBanner == entry.key ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: _currentBanner == entry.key ? BorderRadius.circular(4) : null,
            color: _currentBanner == entry.key ? Colors.blue : Colors.grey[300],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 16),
        Container(
          height: 160,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: _banners.length > 1 ? null : _banners.length,
            onPageChanged: _updateCurrentBanner,
            itemBuilder: (context, index) {
              final actualIndex = index % _banners.length;
              return _buildBannerSlide(_banners[actualIndex], actualIndex);
            },
          ),
        ),
        SizedBox(height: 8),
        _buildBannerIndicators(),
        SizedBox(height: 16),
      ],
    );
  }
}