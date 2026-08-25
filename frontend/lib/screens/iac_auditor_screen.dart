import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../services/api_service.dart';

class IacAuditorScreen extends StatefulWidget {
  const IacAuditorScreen({super.key});

  @override
  State<IacAuditorScreen> createState() => _IacAuditorScreenState();
}

class _IacAuditorScreenState extends State<IacAuditorScreen> {
  final _inputController = TextEditingController();
  bool _isLoading = false;
  String? _result;

  Future<void> _audit() async {
    if (_inputController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final response = await ApiService().sendMessage(
        _inputController.text.trim(),
        "iac",
        "audit-iac",
      );
      setState(() {
        _result = response['response'];
      });
    } catch (e) {
      setState(() {
        _result = "Error auditing IaC: $e";
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
        title: const Text(
          'Cloud / IaC Auditor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _inputController,
              maxLines: 8,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              decoration: InputDecoration(
                hintText:
                    'Paste your Dockerfile, docker-compose.yml, or Kubernetes YAML here to check for privilege escalation or secrets...',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _audit,
                icon: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.cloud_done),
                label: Text(_isLoading ? 'Auditing...' : 'Run Cloud Audit'),
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
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Markdown(
                    data: _result!,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 14,
                      ),
                      code: TextStyle(
                        color: theme.colorScheme.primary,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.3),
                        ),
                      ),
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
