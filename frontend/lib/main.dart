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
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final response = await http.get(Uri.parse('https://cve.circl.lu/api/last')).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final cves = jsonDecode(response.body) as List<dynamic>;
        if (cves.isNotEmpty) {
          final topCve = cves.first;
          final cvss = (topCve['cvss'] ?? 0.0).toDouble();
          
          if (cvss >= 7.0) {
            const AndroidNotificationDetails androidPlatformChannelSpecifics =
                AndroidNotificationDetails(
              'securai_cve_channel',
              'Critical CVE Alerts',
              channelDescription: 'Alerts for high severity vulnerabilities',
              importance: Importance.max,
              priority: Priority.high,
            );
            const NotificationDetails platformChannelSpecifics =
                NotificationDetails(android: androidPlatformChannelSpecifics);
            
            await flutterLocalNotificationsPlugin.show(
              0,
              'CRITICAL THREAT: ',
              'CVSS : '.substring(0, 100) + '...',
              platformChannelSpecifics,
            );
          }
        }
      }
    } catch (e) {
      print('Background task error: ');
    }
    return Future.value(true);
  });
}

final supabase = Supabase.instance.client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );
  Workmanager().registerPeriodicTask(
    "1",
    "cveCheckTask",
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );
  
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
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FFFF), // Cyan Accent
          secondary: Color(0xFFFF00FF), // Neon Magenta
          surface: Color(0xFF0D0D12),
        ),
        scaffoldBackgroundColor: const Color(0xFF050505), // AMOLED Black
        textTheme: GoogleFonts.shareTechMonoTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white,
          displayColor: const Color(0xFF00FFFF),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.orbitron(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF00FFFF)),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF0D0D12),
          elevation: 10,
          shadowColor: const Color(0xFF00FFFF).withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: const Color(0xFF00FFFF).withValues(alpha: 0.5), width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00FFFF).withValues(alpha: 0.1),
            foregroundColor: const Color(0xFF00FFFF),
            side: const BorderSide(color: Color(0xFF00FFFF), width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            elevation: 8,
            shadowColor: const Color(0xFF00FFFF).withValues(alpha: 0.5),
          )
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0D0D12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFF00FFFF), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: const Color(0xFF00FFFF).withValues(alpha: 0.3), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFF00FFFF), width: 2),
          ),
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
