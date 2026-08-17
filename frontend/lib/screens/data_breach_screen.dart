import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DataBreachScreen extends StatefulWidget {
  const DataBreachScreen({super.key});

  @override
  State<DataBreachScreen> createState() => _DataBreachScreenState();
}

class _DataBreachScreenState extends State<DataBreachScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _emailController = TextEditingController();
  
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  bool _hasSearched = false;

  void _runScan() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _result = null;
    });

    final res = await _apiService.breachScan(email);
    
    setState(() {
      _result = res;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Breach Scanner', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.travel_explore, size: 80, color: Colors.purpleAccent),
            const SizedBox(height: 16),
            const Text(
              "Dark Web & Breach Monitor",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Check if your corporate email has been exposed in known data breaches.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: 'Enter email address...',
                prefixIcon: const Icon(Icons.email, color: Colors.purpleAccent),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onSubmitted: (_) => _runScan(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _runScan,
                icon: const Icon(Icons.search),
                label: const Text("Scan Databases"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent.withValues(alpha: 0.2),
                  foregroundColor: Colors.purpleAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
    }
    if (!_hasSearched) {
      return Container();
    }
    
    if (_result == null) {
      return const Center(child: Text("Error fetching results."));
    }

    final bool found = _result!['found'] ?? false;
    final List breaches = _result!['breaches'] ?? [];

    if (!found) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user, size: 60, color: Colors.greenAccent),
            const SizedBox(height: 16),
            const Text("Good News!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
            const SizedBox(height: 8),
            Text("No breaches found for ${_emailController.text}", style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: breaches.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      "Oh no! This email was found in ${breaches.length} data breach(es).",
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        final breach = breaches[index - 1];
        return Card(
          color: Theme.of(context).colorScheme.surface,
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(breach['name'] ?? 'Unknown', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(breach['date'] ?? '', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(breach['description'] ?? '', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (breach['dataclasses'] as List? ?? []).map<Widget>((cls) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(cls.toString(), style: const TextStyle(color: Colors.orangeAccent, fontSize: 10)),
                    );
                  }).toList(),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
