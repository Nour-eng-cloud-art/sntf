import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:sntf/core/theme/app_theme.dart';
import 'package:sntf/core/theme/theme_provider.dart';
import 'package:sntf/providers/auth_provider.dart';
import 'package:sntf/providers/transport_provider.dart';
import 'package:sntf/providers/commercial_provider.dart';
import 'package:sntf/providers/incident_provider.dart';
import 'package:sntf/providers/map_provider.dart';
import 'package:sntf/providers/routing_provider.dart';
import 'package:sntf/ui/screen/auth/login.dart';
import 'package:sntf/ui/screen/auth/signin.dart';
import 'package:sntf/ui/screen/home/aide.dart';
import 'package:sntf/ui/screen/home/contact.dart';
import 'package:sntf/ui/screen/home/home_page.dart';
import 'package:sntf/ui/screen/home/policy.dart';
import 'package:sntf/ui/screen/home/user_condition.dart';
import 'package:sntf/ui/screen/routing/route_planning_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>();

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
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
    return MultiProvider(
      providers: [
        // Auth Provider - must be first as others depend on it
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
        // Transport Provider - lignes, stations, horaires
        ChangeNotifierProvider<TransportProvider>(
          create: (_) => TransportProvider(),
        ),
        // Commercial Provider - tickets, abonnements, amendes
        ChangeNotifierProxyProvider<AuthProvider, CommercialProvider>(
          create: (_) => CommercialProvider(),
          update: (_, authProvider, commercialProvider) {
            if (authProvider.isAuthenticated && authProvider.userId != null) {
              commercialProvider?.initialize(authProvider.userId!);
            } else {
              commercialProvider?.clear();
            }
            return commercialProvider ?? CommercialProvider();
          },
        ),
        // Incident Provider - pannes
        ChangeNotifierProvider<IncidentProvider>(
          create: (_) => IncidentProvider(),
        ),
        // Map Provider - location services
        ChangeNotifierProvider<MapProvider>(
          create: (_) => MapProvider(),
        ),
        // Routing Provider - itinerary planning
        ChangeNotifierProvider<RoutingProvider>(
          create: (_) => RoutingProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'SNTF',
        debugShowCheckedModeBanner: false,
         
        // Apply light theme
        theme: AppTheme.lightTheme,
        
        // Apply dark theme
        darkTheme: AppTheme.darkTheme,
        
        // Theme mode (system, light, or dark)
        themeMode: _themeProvider.themeMode,
        
        // Use a builder to check auth state and redirect
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            // Show loading while checking auth state
            if (authProvider.status == AuthStatus.initial || 
                authProvider.status == AuthStatus.loading) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            // Redirect based on auth state
            if (authProvider.isAuthenticated) {
              return const HomePage();
            }
            return const Login();
          },
        ),
        
        routes: {
          '/login': (context) => const Login(),
          '/signin': (context) => const Signin(),
          '/home': (context) => const HomePage(),
          '/route-planning': (context) => const RoutePlanningScreen(),
          'FaQ': (context) => const FAQPage(),
          'Contact': (context) => const ContactPage(),
          'Conditions': (context) => const PolicyPage(),
          'Legal': (context) => const LegalTextPage(title: "Mentions Légales"),
          
        },
      ),
    );
  }
}

