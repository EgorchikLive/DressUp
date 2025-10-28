import 'package:flutter/material.dart';

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