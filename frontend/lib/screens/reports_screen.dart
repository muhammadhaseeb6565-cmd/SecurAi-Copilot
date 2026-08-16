import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ApiService _apiService = ApiService();
  bool _isGenerating = false;
  String? _generatedReport;

  final List<Map<String, String>> _mockAlerts = [
    {
      "title": "BOLA Vulnerability Detected",
      "severity": "High",
      "time": "10 mins ago",
      "details": "User ID 401 attempted to access /api/v1/users/402/profile. Request was blocked but indicates Broken Object Level Authorization testing."
    },
    {
      "title": "Rate Limit Exceeded",
      "severity": "Medium",
      "time": "1 hour ago",
      "details": "IP 192.168.1.55 exceeded 100 requests/minute on /api/login endpoint. Possible credential stuffing attack."
    }
  ];

  void _generateReport(String details) async {
    setState(() {
      _isGenerating = true;
      _generatedReport = null;
    });

    final report = await _apiService.generateReport(details);

    setState(() {
      _generatedReport = report;
      _isGenerating = false;
    });
    
    _showReportDialog("AI Incident Report");
  }

  void _generatePatch(String details) async {
    setState(() {
      _isGenerating = true;
      _generatedReport = null;
    });

    final patch = await _apiService.generateCodePatch(details);

    setState(() {
      _generatedReport = patch;
      _isGenerating = false;
    });
    
    _showReportDialog("Self-Healing Code Patch");
  }

  void _showReportDialog(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: Markdown(
            data: _generatedReport ?? "Loading...",
            styleSheet: MarkdownStyleSheet(
              code: TextStyle(backgroundColor: Theme.of(context).colorScheme.surface, fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
          if (title == "Self-Healing Code Patch")
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _deployFix();
              },
              icon: const Icon(Icons.rocket_launch),
              label: const Text("Deploy Patch"),
            ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Incident Report shared as PDF!')),
              );
            },
            icon: const Icon(Icons.share),
            label: const Text("Share PDF"),
          )
        ],
      ),
    );
  }

  void _deployFix() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text("Deploying Patch to Production..."),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(),
            SizedBox(height: 16),
            Text("> Git commit: 'Auto-patch security vulnerability'\n> Pushing to origin/main...\n> Triggering CI/CD pipeline...\n> Kubernetes pod rolling update...", style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 4));
    
    if (mounted) {
      Navigator.pop(context); // close dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patch successfully deployed to Production!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Alerts', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _mockAlerts.length,
        itemBuilder: (context, index) {
          final alert = _mockAlerts[index];
          final isHigh = alert["severity"] == "High";
          return Card(
            color: Theme.of(context).colorScheme.surface,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isHigh ? Icons.error_outline : Icons.warning_amber,
                            color: isHigh ? Colors.red : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            alert["title"]!,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(alert["time"]!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(alert["details"]!, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isGenerating ? null : () => _generatePatch(alert["details"]!),
                        icon: const Icon(Icons.build, size: 18),
                        label: const Text("Generate Code Patch"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.withValues(alpha: 0.2),
                          foregroundColor: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _isGenerating ? null : () => _generateReport(alert["details"]!),
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: const Text("Generate Report"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                          foregroundColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
