import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
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
          return BiometricGuard(prefs: prefs, child: MainShell(prefs: prefs));
        }
        // If not logged in, go to LoginScreen
        return LoginScreen(prefs: prefs);
      },
    );
  }
}

class BiometricGuard extends StatefulWidget {
  final SharedPreferences prefs;
  final Widget child;

  const BiometricGuard({super.key, required this.prefs, required this.child});

  @override
  State<BiometricGuard> createState() => _BiometricGuardState();
}

class _BiometricGuardState extends State<BiometricGuard> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticated = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final requireBiometrics = widget.prefs.getBool('requireBiometrics') ?? false;
    if (!requireBiometrics) {
      if (mounted) setState(() { _isAuthenticated = true; _isChecking = false; });
      return;
    }

    try {
      final canCheck = await auth.canCheckBiometrics || await auth.isDeviceSupported();
      if (!canCheck) {
        if (mounted) setState(() { _isAuthenticated = true; _isChecking = false; });
        return;
      }

      final authenticated = await auth.authenticate(
        localizedReason: 'Please authenticate to access SecurAI Copilot',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (mounted) {
        setState(() {
          _isAuthenticated = authenticated;
          _isChecking = false;
        });
      }
    } on PlatformException catch (_) {
      if (mounted) setState(() { _isAuthenticated = false; _isChecking = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)));
    }

    if (!_isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 80, color: Colors.redAccent),
              const SizedBox(height: 24),
              const Text("App Locked", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Biometric authentication required.", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _checkBiometrics,
                icon: const Icon(Icons.fingerprint),
                label: const Text("Unlock"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent.withValues(alpha: 0.2),
                  foregroundColor: Colors.cyanAccent,
                ),
              )
            ],
          ),
        ),
      );
    }

    return widget.child;
  }
}
