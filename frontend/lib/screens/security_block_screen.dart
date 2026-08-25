import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class SecurityBlockScreen extends StatelessWidget {
  const SecurityBlockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.gpp_bad, color: Colors.redAccent, size: 100),
              const SizedBox(height: 24),
              const Text(
                'SECURITY VIOLATION',
                style: TextStyle(color: Colors.redAccent, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'This device appears to be compromised (rooted, jailbroken, or running in an unauthorized emulator). For your security, SecurAI Copilot cannot run in this environment.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () => SystemNavigator.pop(),
                icon: const Icon(Icons.exit_to_app),
                label: const Text('EXIT APP'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
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
