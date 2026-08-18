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
        "analyze-phishing",
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Phishing Sandbox', style: TextStyle(fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _inputController,
              maxLines: 6,
              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Paste suspicious email, SMS, or URL here to safely detonate and analyze it...',
                hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
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
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: theme.colorScheme.primary, strokeWidth: 2))
                    : const Icon(Icons.security),
                label: Text(_isLoading ? 'Detonating...' : 'Analyze Threat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
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
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Markdown(
                    data: _result!,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16),
                      strong: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
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
