import 'package:flutter/material.dart';
import '../services/api_service.dart';

class GithubPrScreen extends StatefulWidget {
  const GithubPrScreen({super.key});

  @override
  _GithubPrScreenState createState() => _GithubPrScreenState();
}

class _GithubPrScreenState extends State<GithubPrScreen> {
  final _repoController = TextEditingController(text: 'muhammadhaseeb6565-cmd/SecurAi-Copilot');
  final _prController = TextEditingController(text: '1');
  final _patController = TextEditingController();
  
  bool _isLoading = false;
  String? _reviewResult;
  String? _error;

  Future<void> _runReview() async {
    setState(() {
      _isLoading = true;
      _reviewResult = null;
      _error = null;
    });

    final repo = _repoController.text.trim();
    final pr = int.tryParse(_prController.text.trim()) ?? 1;
    final pat = _patController.text.trim();

    final result = await ApiService.githubPrReview(repo, pr, pat);
    
    setState(() {
      _isLoading = false;
      if (result != null) {
        if (result.containsKey('error')) {
          _error = result['error'];
        } else {
          _reviewResult = result['review'];
        }
      } else {
        _error = "Failed to connect to backend.";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('GitHub PR Auditor', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _repoController,
                    decoration: const InputDecoration(
                      labelText: 'Repository (owner/repo)',
                      prefixIcon: Icon(Icons.code, color: Colors.cyanAccent),
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _prController,
                    decoration: const InputDecoration(
                      labelText: 'Pull Request Number',
                      prefixIcon: Icon(Icons.merge_type, color: Colors.cyanAccent),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _patController,
                    decoration: const InputDecoration(
                      labelText: 'Personal Access Token (Optional for public)',
                      prefixIcon: Icon(Icons.vpn_key, color: Colors.cyanAccent),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _runReview,
                    icon: _isLoading 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : const Icon(Icons.security),
                    label: Text(_isLoading ? 'Auditing Code...' : 'Run Security Audit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.1)),
                ),
                child: SingleChildScrollView(
                  child: _error != null
                      ? Text('Error: $_error', style: const TextStyle(color: Colors.redAccent))
                      : _reviewResult != null
                          ? Text(_reviewResult!, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5))
                          : const Center(
                              child: Text('AI Audit Results will appear here.', style: TextStyle(color: Colors.grey)),
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
