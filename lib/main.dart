import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/routes/app_router.dart';
import 'package:beer_store_app/core/theme/app_theme.dart';
import 'package:beer_store_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:beer_store_app/features/products/presentation/providers/product_provider.dart';
import 'package:beer_store_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:beer_store_app/core/theme/theme_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, themeProvider, __) => MaterialApp(
          title:                     'My App',
          debugShowCheckedModeBanner: false,
          theme:                     AppTheme.light,
          darkTheme:                 AppTheme.dark,
          themeMode:                 themeProvider.mode,
          initialRoute:              AppRouter.splash,
          routes:                    AppRouter.routes,
        ),
      ),
    );
  }
}