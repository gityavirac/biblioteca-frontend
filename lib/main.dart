import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/optimized_theme.dart';
import 'core/providers/theme_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/reset_password_screen.dart';
import 'presentation/screens/user/user_home.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'data/services/database_seeder.dart';
import 'data/services/supabase_auth_service.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Mostrar app inmediatamente
    runApp(const AppState());
    
    // Inicializar Supabase en background
    _initializeSupabaseInBackground();
    
  } catch (e) {
    print('Error initializing app: $e');
    runApp(const AppState());
  }
}

void _initializeSupabaseInBackground() async {
  try {
    await Supabase.initialize(
      url: 'https://pnefkrshzhlelycbxhqg.supabase.co',
      anonKey: 'sb_publishable_6zUbPKbRdpcFyXmq8QuCKA_r27hgz1m',
    );
    _seedDataInBackground();
  } catch (e) {
    print('Error initializing Supabase: $e');
  }
}

void _seedDataInBackground() {
  // Ejecutar en background para no bloquear la UI
  Future.delayed(const Duration(seconds: 5), () async {
    try {
      await DatabaseSeeder.seedBooks();
      await DatabaseSeeder.seedVideos();
    } catch (e) {
      print('Error seeding data: $e');
    }
  });
}

class AppState extends StatelessWidget {
  const AppState({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const BibliotecaDigitalApp(),
    );
  }
}

class BibliotecaDigitalApp extends StatefulWidget {
  const BibliotecaDigitalApp({super.key});

  @override
  State<BibliotecaDigitalApp> createState() => _BibliotecaDigitalAppState();
}

class _BibliotecaDigitalAppState extends State<BibliotecaDigitalApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  bool _isCheckingSession = true;
  bool _showSplash = !kIsWeb; // Solo mostrar splash en móvil
  Widget _initialScreen = const LoginScreen();

  @override
  void initState() {
    super.initState();
    _checkSession();
    _setupAuthListener();
  }

  Future<void> _checkSession() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          setState(() {
            _initialScreen = UserHome(authService: SupabaseAuthService());
            _isCheckingSession = false;
          });
          return;
        }
      }
    } catch (e) {
      print('Error checking session: $e');
      // Continuar con login screen si hay error
    }
    
    setState(() {
      _isCheckingSession = false;
    });
  }

  void _setupAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;
      
      if (event == AuthChangeEvent.passwordRecovery && session != null) {
        _navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(builder: (context) => const ResetPasswordScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: OptimizedTheme.lightTheme,
      darkTheme: OptimizedTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => _showSplash
            ? SplashScreen(
                onComplete: () {
                  setState(() {
                    _showSplash = false;
                  });
                },
              )
            : _isCheckingSession
                ? Scaffold(
                    backgroundColor: themeProvider.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    body: Center(
                      child: CircularProgressIndicator(
                        color: themeProvider.isDarkMode ? Colors.white : OptimizedTheme.primaryColor,
                      ),
                    ),
                  )
                : _initialScreen,
        '/login': (context) => const LoginScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
      },
      onGenerateRoute: (settings) {
        // Manejar rutas con parámetros
        if (settings.name?.startsWith('/reset-password') == true) {
          return MaterialPageRoute(
            builder: (context) => const ResetPasswordScreen(),
          );
        }
        return null;
      },
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
    );
  }
}
