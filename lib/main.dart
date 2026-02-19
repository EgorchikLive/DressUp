import 'package:dress_up/firebase_options.dart';
import 'package:dress_up/screens/auth/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:hidable/hidable.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/profile_screen.dart';
import 'models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      await Firebase.initializeApp(
        name: "[DEFAULT]",
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    print("Ошибка инициализации Firebase: $e");
    // Продолжаем работу даже если Firebase не инициализирован
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
      ],
      child: MaterialApp(
        title: 'DressUp',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.grey[100],
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
        routes: {
          '/login': (context) =>
              LoginScreen(firestore: FirebaseFirestore.instance),
          '/register': (context) =>
              RegisterScreen(firestore: FirebaseFirestore.instance),
          '/home': (context) => const MainScreenWrapper(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        print(
          '🔄 AuthWrapper: isInitialized=${authProvider.isInitialized}, isLoading=${authProvider.isLoading}, isLoggedIn=${authProvider.isLoggedIn}',
        );

        if (!authProvider.isInitialized || authProvider.isLoading) {
          return const SplashScreen();
        }

        if (authProvider.isLoggedIn && authProvider.currentUser != null) {
          print(
            '✅ Автоматический вход для: ${authProvider.currentUser!.email}',
          );
          return MainScreen(user: authProvider.currentUser!);
        }

        print('🔓 Показываем WelcomeScreen');
        return WelcomeScreen(
          firestore: firestore,
          onLoginPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LoginScreen(firestore: firestore),
              ),
            );
          },
          onRegisterPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RegisterScreen(firestore: firestore),
              ),
            );
          },
        );
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'DressUp',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Загрузка...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Colors.blueAccent),
          ],
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final UserModel user;

  const MainScreen({super.key, required this.user});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addObserver(this);

    _tabController.addListener(_handleTabChange);

    print(
      '🏠 MainScreen инициализирован для пользователя: ${widget.user.email}',
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentIndex = _tabController.index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user.uid.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              const Text(
                'Ошибка данных пользователя',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Пожалуйста, войдите снова'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  context.read<AuthProvider>().logout();
                },
                child: const Text('Выйти'),
              ),
            ],
          ),
        ),
      );
    }

    final List<Widget> screens = [
      HomeScreen(scrollController: _scrollController), // Теперь работает!
      FavoritesScreen(user: widget.user),
      CartScreen(user: widget.user),
      ProfileScreen(user: widget.user),
    ];

    return Scaffold(
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: screens,
      ),
      bottomNavigationBar: Hidable(
        controller: _scrollController,
        child: ConvexAppBar(
          style: TabStyle.reactCircle,
          backgroundColor: Colors.white,
          color: Colors.grey[600],
          activeColor: Colors.blueAccent,
          items: const [
            TabItem(icon: Icons.home, title: 'Главная'),
            TabItem(icon: Icons.favorite, title: 'Избранное'),
            TabItem(icon: Icons.shopping_cart, title: 'Корзина'),
            TabItem(icon: Icons.person, title: 'Профиль'),
          ],
          initialActiveIndex: _currentIndex,
          onTap: (int index) {
            setState(() {
              _currentIndex = index;
            });
            _tabController.animateTo(index);
          },
        ),
      ),
    );
  }
}

class MainScreenWrapper extends StatelessWidget {
  const MainScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoggedIn && authProvider.currentUser != null) {
          return MainScreen(user: authProvider.currentUser!);
        } else {
          return LoginScreen(firestore: FirebaseFirestore.instance);
        }
      },
    );
  }
}
