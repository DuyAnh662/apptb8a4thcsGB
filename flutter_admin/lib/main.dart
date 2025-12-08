import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/admin_provider.dart';
import 'theme/admin_theme.dart';
import 'screens/login_screen.dart';
import 'screens/admin_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminProvider()..initialize(),
      child: Consumer<AdminProvider>(
        builder: (context, provider, _) {
          return MaterialApp(
            title: 'Admin - TB8A4',
            debugShowCheckedModeBanner: false,
            theme: AdminTheme.lightTheme(),
            darkTheme: AdminTheme.darkTheme(),
            themeMode: provider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: provider.isLoggedIn ? const AdminHomeScreen() : const LoginScreen(),
          );
        },
      ),
    );
  }
}
