import 'package:flutter/material.dart';
import '../services/api_service.dart';

class GithubPrScreen extends StatefulWidget {
  const GithubPrScreen({super.key});

  @override
  _GithubPrScreenState createState() => _GithubPrScreenState();
}

class _GithubPrScreenState extends State<GithubPrScreen> {
  final _repoController = TextEditingController();
  final _prController = TextEditingController();
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

  Future<void> _deployFix() async {
    if (_reviewResult == null) return;
    
    setState(() {
      _isLoading = true;
    });

    final repo = _repoController.text.trim();
    final pr = int.tryParse(_prController.text.trim()) ?? 1;
    final pat = _patController.text.trim();

    if (pat.isEmpty) {
      setState(() {
        _error = "Personal Access Token is required to deploy a fix.";
        _isLoading = false;
      });
      return;
    }

    final result = await ApiService.githubAutoFix(repo, pr, pat, _reviewResult!);
    
    setState(() {
      _isLoading = false;
      if (result != null) {
        if (result.containsKey('error')) {
          _error = result['error'];
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['status'] ?? 'Fix deployed!')));
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
                      labelText: 'Personal Access Token (Required for fix)',
                      prefixIcon: Icon(Icons.vpn_key, color: Colors.cyanAccent),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _runReview,
                          icon: _isLoading 
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                              : const Icon(Icons.security),
                          label: Text(_isLoading ? 'Auditing...' : 'Run Audit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyanAccent,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      if (_reviewResult != null) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _deployFix,
                            icon: _isLoading 
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.healing),
                            label: const Text('Deploy Fix'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.magentaAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ],
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
