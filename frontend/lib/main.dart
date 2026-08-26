import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/splash_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'screens/security_block_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Background isolates must initialize their own plugins
      const AndroidInitializationSettings initSettingsAndroid =
          AndroidInitializationSettings('@mipmap/launcher_icon');
      const InitializationSettings initSettings = InitializationSettings(
        android: initSettingsAndroid,
      );
      await flutterLocalNotificationsPlugin.initialize(initSettings);

      final response = await http
          .get(Uri.parse('https://cve.circl.lu/api/last'))
          .timeout(const Duration(seconds: 15));
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
                  channelDescription:
                      'Alerts for high severity vulnerabilities',
                  importance: Importance.max,
                  priority: Priority.high,
                );
            const NotificationDetails platformChannelSpecifics =
                NotificationDetails(android: androidPlatformChannelSpecifics);

            await flutterLocalNotificationsPlugin.show(
              0,
              'CRITICAL THREAT: ',
              '${'CVSS : '.substring(0, 100)}...',
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
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

    Workmanager().registerPeriodicTask(
      "1",
      "cveCheckTask",
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
    );

    await Supabase.initialize(
      url: 'https://rnjffzwflbbyznzhcqpg.supabase.co',
      anonKey: 'sb_publishable_AGB2Fv2K6FXtyVeVLa_tWA_LE4foSrP',
    );

    final prefs = await SharedPreferences.getInstance();

    // Pure-Dart root/jailbreak detection (replaces flutter_jailbreak_detection plugin)
    bool isCompromised = false;
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        // Check for common root/jailbreak indicators without a native plugin
        final List<String> suspiciousPaths = [
          '/system/app/Superuser.apk', '/sbin/su', '/system/bin/su',
          '/system/xbin/su', '/data/local/xbin/su', '/data/local/bin/su',
          '/system/sd/xbin/su', '/system/bin/failsafe/su',
          '/data/local/su', '/su/bin/su',
          '/Applications/Cydia.app', '/private/var/lib/apt',
          '/private/var/mobile/Library/SBSettings',
          '/Library/MobileSubstrate/MobileSubstrate.dylib',
        ];
        for (final p in suspiciousPaths) {
          if (await File(p).exists()) {
            isCompromised = true;
            break;
          }
        }
      } catch (e) {
        // Cannot determine — assume safe
        isCompromised = false;
      }
    }

    if (isCompromised) {
      runApp(const SecurityBlockApp());
      return;
    }

    runApp(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(prefs),
        child: SecurAIApp(prefs: prefs),
      ),
    );
  } catch (e, stackTrace) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Fatal Startup Error:\n$e\n\n$stackTrace',
                style: const TextStyle(color: Colors.red, fontSize: 14),
                textDirection: TextDirection.ltr,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ThemeProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  late ThemeMode _themeMode;

  ThemeProvider(this._prefs) {
    _themeMode = (_prefs.getBool('isDarkMode') ?? true)
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  ThemeMode get themeMode => _themeMode;

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _prefs.setBool('isDarkMode', isDark);
    notifyListeners();
  }
}

class SecurAIApp extends StatefulWidget {
  final SharedPreferences prefs;
  const SecurAIApp({super.key, required this.prefs});

  @override
  State<SecurAIApp> createState() => _SecurAIAppState();
}

class _SecurAIAppState extends State<SecurAIApp> with WidgetsBindingObserver {
  bool _isSecureLocked = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      Clipboard.setData(const ClipboardData(text: ""));
      // Iron Vault: Lock the app instantly when it goes to the background
      setState(() {
        _isSecureLocked = true;
      });
    } else if (state == AppLifecycleState.resumed && _isSecureLocked) {
      }
  }

  
  @override
  Widget build(BuildContext context) {
    if (_isSecureLocked) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, color: Colors.redAccent, size: 100),
                const SizedBox(height: 20),
                const Text('IRON VAULT LOCKED', style: TextStyle(color: Colors.redAccent, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                  child: const Text('UNLOCK SESSION'),
                )
              ],
            ),
          ),
        ),
      );
    }

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
        textTheme: GoogleFonts.shareTechMonoTextTheme(
          Theme.of(context).textTheme,
        ).apply(bodyColor: Colors.white, displayColor: const Color(0xFF00FFFF)),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.orbitron(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00FFFF),
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF0D0D12),
          elevation: 10,
          shadowColor: const Color(0xFF00FFFF).withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(
              color: const Color(0xFF00FFFF).withValues(alpha: 0.5),
              width: 1,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00FFFF).withValues(alpha: 0.1),
            foregroundColor: const Color(0xFF00FFFF),
            side: const BorderSide(color: Color(0xFF00FFFF), width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            elevation: 8,
            shadowColor: const Color(0xFF00FFFF).withValues(alpha: 0.5),
          ),
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
            borderSide: BorderSide(
              color: const Color(0xFF00FFFF).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFF00FFFF), width: 2),
          ),
        ),
        useMaterial3: true,
      ),
      home: SplashScreen(prefs: widget.prefs),
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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final session = snapshot.data?.session ?? supabase.auth.currentSession;
        if (session != null) {
          return BiometricGuard(
            prefs: prefs,
            child: MainShell(prefs: prefs),
          );
        }
        // If not logged in, go to LoginScreen
        return LoginScreen(prefs: prefs);
      },
    );
  }
}

