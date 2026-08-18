import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CveFeedScreen extends StatefulWidget {
  const CveFeedScreen({super.key});

  @override
  _CveFeedScreenState createState() => _CveFeedScreenState();
}

class _CveFeedScreenState extends State<CveFeedScreen> {
  List<dynamic> _cves = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCves();
  }

  Future<void> _fetchCves() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(Uri.parse('https://cve.circl.lu/api/last')).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        setState(() {
          _cves = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load CVEs: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error fetching threat feed: $e';
        _isLoading = false;
      });
    }
  }

  Color _getSeverityColor(double cvss) {
    if (cvss >= 9.0) return Colors.redAccent;
    if (cvss >= 7.0) return Colors.orangeAccent;
    if (cvss >= 4.0) return Colors.yellowAccent;
    return Colors.greenAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Live Zero-Day Feed', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchCves,
            tooltip: 'Refresh Feed',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchCves,
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: Colors.cyanAccent,
                  backgroundColor: Colors.black,
                  onRefresh: _fetchCves,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _cves.length,
                    itemBuilder: (context, index) {
                      final cve = _cves[index];
                      final cvss = (cve['cvss'] ?? 0.0).toDouble();
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                        ),
                        child: ExpansionTile(
                          iconColor: Colors.cyanAccent,
                          collapsedIconColor: Colors.grey,
                          title: Text(
                            cve['id'] ?? 'Unknown CVE',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent, fontSize: 18),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                Icon(Icons.warning, color: _getSeverityColor(cvss), size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'CVSS: ${cvss.toStringAsFixed(1)}',
                                  style: TextStyle(color: _getSeverityColor(cvss), fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 16),
                                const Icon(Icons.date_range, color: Colors.grey, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  (cve['Published'] ?? '').split('T').first,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                cve['summary'] ?? 'No summary available.',
                                style: const TextStyle(color: Colors.white70, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
