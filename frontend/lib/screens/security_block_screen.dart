import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityBlockApp extends StatelessWidget {
  const SecurityBlockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0D12),
      ),
      home: const SecurityBlockScreen(),
    );
  }
}

class SecurityBlockScreen extends StatefulWidget {
  const SecurityBlockScreen({super.key});

  @override
  State<SecurityBlockScreen> createState() => _SecurityBlockScreenState();
}

class _SecurityBlockScreenState extends State<SecurityBlockScreen> {
  int _strikes = 0;

  @override
  void initState() {
    super.initState();
    _checkStrikes();
  }

  Future<void> _checkStrikes() async {
    final prefs = await SharedPreferences.getInstance();
    int currentStrikes = prefs.getInt('security_strikes') ?? 0;
    currentStrikes++;
    await prefs.setInt('security_strikes', currentStrikes);
    
    setState(() {
      _strikes = currentStrikes;
    });

    if (currentStrikes > 1) {
      // Aggressive response: Wipe everything.
      await prefs.clear();
      // Optional: await const FlutterSecureStorage().deleteAll();
      // In a real app we would aggressively wipe all local databases here.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.gpp_bad, color: _strikes > 1 ? Colors.red : Colors.orangeAccent, size: 100),
              const SizedBox(height: 24),
              Text(
                _strikes > 1 ? 'SECURITY BREACH DETECTED' : 'WARNING: HACKING ATTEMPT',
                style: TextStyle(
                  color: _strikes > 1 ? Colors.red : Colors.orangeAccent,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _strikes > 1 
                    ? 'Device permanently banned. All local secure data has been destroyed.'
                    : 'Don\'t try to hack the system, it will cause problems for you. This incident has been logged.',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  if (Platform.isAndroid) {
                    SystemNavigator.pop();
                  } else {
                    exit(0);
                  }
                },
                icon: const Icon(Icons.exit_to_app),
                label: const Text('EXIT SYSTEM'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _strikes > 1 ? Colors.red : Colors.orangeAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
