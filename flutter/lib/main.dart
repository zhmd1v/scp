import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/auth/presentation/pages/welcome_page.dart';
import 'providers/auth_provider.dart';

void main() {
  runApp(const SCPApp());
}

class SCPApp extends StatelessWidget {
  const SCPApp({super.key});

  static const _seedColor = Color(0xFF0E3E45);
  static const _accentColor = Color(0xFFC6F62C);
  static const _backgroundColor = Color(0xFFE9EEF0);

  ThemeData _buildTheme() {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      primary: _seedColor,
      secondary: _accentColor,
      background: _backgroundColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: baseScheme,
      scaffoldBackgroundColor: _backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: _seedColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _seedColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Supplier Consumer Platform',
        theme: _buildTheme(),
        home: const WelcomePage(),
      ),
    );
  }
}
