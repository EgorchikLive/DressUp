import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/banner_service.dart';

class BannerSlider extends StatefulWidget {
  const BannerSlider({Key? key}) : super(key: key);

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  final PageController _bannerController = PageController(viewportFraction: 0.9);
  final BannerService _bannerService = BannerService();
  int _currentBanner = 0;
  List<Map<String, dynamic>> _banners = [];
  bool _isLoading = true;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  Future<void> _loadBanners() async {
    try {
      print('🎯 НАЧАЛО ЗАГРУЗКИ БАННЕРОВ...');
      
      final banners = await _bannerService.getBanners();
      
      if (mounted) {
        setState(() {
          _banners = banners;
          _isLoading = false;
        });
        
        print('✅ ЗАВЕРШЕНИЕ ЗАГРУЗКИ: ${_banners.length} баннеров');
        
        // Запускаем автоматическую прокрутку если баннеров больше 1
        if (_banners.length > 1) {
          _startAutoScroll();
          // Устанавливаем начальную позицию для бесконечной прокрутки
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final initialPage = _banners.length * 1000;
            _bannerController.jumpToPage(initialPage);
          });
        }
      }
    } catch (e) {
      print('❌ Ошибка в _loadBanners: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_banners.length > 1 && _bannerController.hasClients) {
        final nextPage = _bannerController.page!.round() + 1;
        _bannerController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
  }

  void _updateCurrentBanner(int page) {
    if (_banners.isEmpty) return;
    
    final actualPage = page % _banners.length;
    if (_currentBanner != actualPage) {
      setState(() {
        _currentBanner = actualPage;
      });
    }
  }

  Widget _buildBannerSlide(Map<String, dynamic> banner, int index) {
    final imageUrl = banner['image'] ?? '';
    final title = banner['title'] ?? 'Без названия';
    final subtitle = banner['subtitle'] ?? '';
    final isActive = banner['isActive'] ?? false;

    return GestureDetector(
      onTap: () => _navigateToBannerPage(context, banner),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Изображение баннера
              _buildBannerImage(imageUrl, title),
              
              // Затемнение для неактивных баннеров
              if (!isActive)
                Container(
                  color: Colors.black54,
                ),
              
              // Градиент для текста
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
              
              // Текст баннера
              Positioned(
                left: 16,
                bottom: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.black87,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          shadows: const [
                            Shadow(
                              blurRadius: 4,
                              color: Colors.black87,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Индикатор активности и порядковый номер для отладки
              Positioned(
                top: 8,
                left: 8,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#${banner['order']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!isActive) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'НЕАКТИВЕН',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerImage(String imageUrl, String title) {
    if (imageUrl.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image, color: Colors.grey, size: 50),
            const SizedBox(height: 8),
            Text(
              'Нет изображения',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
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
        print('❌ Ошибка загрузки изображения: $error');
        return Container(
          color: Colors.grey[300],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.grey, size: 40),
              const SizedBox(height: 8),
              Text(
                'Ошибка загрузки',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBannerIndicator(int index) {
    return GestureDetector(
      onTap: () {
        _stopAutoScroll();
        final targetPage = _currentBanner - (_currentBanner % _banners.length) + index;
        _bannerController.animateToPage(
          targetPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _startAutoScroll();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: _currentBanner == index ? 20 : 8,
        height: 8,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          shape: _currentBanner == index ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: _currentBanner == index ? BorderRadius.circular(4) : null,
          color: _currentBanner == index 
              ? Colors.blue.shade600 
              : Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildBannerIndicators() {
    if (_banners.isEmpty || _banners.length == 1) return const SizedBox();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _banners.asMap().entries.map((entry) {
        return _buildBannerIndicator(entry.key);
      }).toList(),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Загрузка баннеров...'),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.campaign, size: 40, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Баннеры не найдены',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadBanners,
              child: const Text('Обновить'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        
        // Заголовок секции
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Icon(Icons.campaign, color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Специальные предложения',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${_banners.length})',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Слайдер баннеров
        Container(
          height: 160,
          child: _isLoading
              ? _buildLoadingState()
              : _banners.isEmpty
                  ? _buildEmptyState()
                  : PageView.builder(
                      controller: _bannerController,
                      itemCount: _banners.length > 1 ? null : _banners.length, // Бесконечная прокрутка
                      onPageChanged: _updateCurrentBanner,
                      itemBuilder: (context, index) {
                        if (_banners.isEmpty) return _buildEmptyState();
                        final actualIndex = index % _banners.length;
                        return _buildBannerSlide(_banners[actualIndex], actualIndex);
                      },
                    ),
        ),
        
        // Индикаторы
        if (!_isLoading && _banners.length > 1) ...[
          const SizedBox(height: 12),
          _buildBannerIndicators(),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  void _navigateToBannerPage(BuildContext context, Map<String, dynamic> banner) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BannerDetailPage(banner: banner),
      ),
    );
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }
}

// BannerDetailPage остается без изменений
class BannerDetailPage extends StatelessWidget {
  final Map<String, dynamic> banner;

  const BannerDetailPage({Key? key, required this.banner}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(banner['title'] ?? 'Акция'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.network(
              banner['image'] ?? '',
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    banner['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    banner['subtitle'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(banner['description'] ?? ''),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}