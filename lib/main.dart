import 'package:flutter/material.dart';
import 'package:kohlberg/screens/login_screen.dart';
import 'package:kohlberg/screens/main_navigation_screen.dart';
import 'package:kohlberg/services/auth_service.dart';
import 'package:kohlberg/services/cart_service.dart';
import 'package:kohlberg/services/favorite_service.dart';
import 'package:provider/provider.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final isAuthenticated = await AuthService.isAuthenticated();
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartService()),
          ChangeNotifierProvider(create: (_) => FavoriteService()),
        ],
        child: MyApp(initialRoute: isAuthenticated ? '/main' : '/login'),
      ),
    );
  } catch (e) {
    print('Error inicializando la app: $e');
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartService()),
          ChangeNotifierProvider(create: (_) => FavoriteService()),
        ],
        child: const MyApp(initialRoute: '/login'),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({Key? key, required this.initialRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vinos Kohlberg',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/main': (context) => const MainNavigationScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}