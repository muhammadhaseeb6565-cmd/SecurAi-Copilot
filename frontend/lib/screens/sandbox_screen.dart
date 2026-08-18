import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../services/api_service.dart';

class SandboxScreen extends StatefulWidget {
  const SandboxScreen({super.key});

  @override
  State<SandboxScreen> createState() => _SandboxScreenState();
}

class _SandboxScreenState extends State<SandboxScreen> {
  final _inputController = TextEditingController();
  bool _isLoading = false;
  String? _result;

  Future<void> _analyze() async {
    if (_inputController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final response = await ApiService().sendMessage(
        _inputController.text.trim(),
        "sandbox",
        "phishing-analyze",
      );
      setState(() {
        _result = response['response'];
      });
    } catch (e) {
      setState(() {
        _result = "Error analyzing threat: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Phishing Sandbox', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _inputController,
              maxLines: 6,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Paste suspicious email, SMS, or URL here to safely detonate and analyze it...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _analyze,
                icon: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 2))
                    : const Icon(Icons.security),
                label: Text(_isLoading ? 'Detonating...' : 'Analyze Threat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withOpacity(0.2),
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_result != null)
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                  ),
                  child: Markdown(
                    data: _result!,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(color: Colors.white70, fontSize: 16),
                      strong: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
