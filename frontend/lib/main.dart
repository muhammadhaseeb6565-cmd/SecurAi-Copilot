import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/splash_screen.dart';

final supabase = Supabase.instance.client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://rnjffzwflbbyznzhcqpg.supabase.co',
    anonKey: 'sb_publishable_AGB2Fv2K6FXtyVeVLa_tWA_LE4foSrP',
  );

  // Commented out to allow screenshots during development
  // if (Platform.isAndroid && kReleaseMode) {
  //   await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  // }
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(prefs),
      child: SecurAIApp(prefs: prefs),
    ),
  );
}

class ThemeProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  late ThemeMode _themeMode;

  ThemeProvider(this._prefs) {
    _themeMode = (_prefs.getBool('isDarkMode') ?? true) ? ThemeMode.dark : ThemeMode.light;
  }

  ThemeMode get themeMode => _themeMode;

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _prefs.setBool('isDarkMode', isDark);
    notifyListeners();
  }
}

class SecurAIApp extends StatelessWidget {
  final SharedPreferences prefs;

  const SecurAIApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'SecurAI Copilot',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.light,
          surface: Colors.white,
          primary: Colors.blueAccent,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyanAccent,
          brightness: Brightness.dark,
          surface: const Color(0xFF141414),
          primary: Colors.cyanAccent,
        ),
        scaffoldBackgroundColor: const Color(0xFF050505), // AMOLED Black
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: SplashScreen(prefs: prefs),
    );
  }
}

class AuthGuard extends StatelessWidget {
  final SharedPreferences prefs;
  
  const AuthGuard({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final session = snapshot.data?.session ?? supabase.auth.currentSession;
        if (session != null) {
          return MainShell(prefs: prefs);
        }
        // If not logged in, go to LoginScreen
        return LoginScreen(prefs: prefs);
      },
    );
  }
}
