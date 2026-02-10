import 'package:flutter/material.dart';
import 'package:sntf/core/theme/app_theme.dart';
import 'package:sntf/core/theme/theme_provider.dart';
import 'package:sntf/ui/screen/auth/login.dart';
import 'package:sntf/ui/screen/auth/signin.dart';
import 'package:sntf/ui/screen/home/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeProvider _themeProvider = ThemeProvider();

  ThemeProvider get themeProvider => _themeProvider;

  @override
  void initState() {
    super.initState();
    _themeProvider.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeProvider.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  /// Toggle theme from anywhere in the app
  void toggleTheme() {
    _themeProvider.toggleTheme();
  }

  /// Set specific theme mode
  void setThemeMode(ThemeMode mode) {
    _themeProvider.setThemeMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SNTF',
      debugShowCheckedModeBanner: false,
      
      // Apply light theme
      theme: AppTheme.lightTheme,
      
      // Apply dark theme
      darkTheme: AppTheme.darkTheme,
      
      // Theme mode (system, light, or dark)
      themeMode: _themeProvider.themeMode,
      
      initialRoute: '/login',
      routes: {
        '/login': (context) => const Login(),
        '/signin': (context) => const Signin(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}

