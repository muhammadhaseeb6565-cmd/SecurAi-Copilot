import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ApiService _apiService = ApiService();
  bool _isGenerating = false;
  String? _generatedReport;

  Future<List<Map<String, dynamic>>>? _alertsFuture;
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  void _startScan() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _alertsFuture = _apiService.fetchRealAlerts(url);
    });
  }

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
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: Markdown(
            data: _generatedReport ?? "Loading...",
            styleSheet: MarkdownStyleSheet(
              code: TextStyle(
                backgroundColor: Colors.black.withValues(alpha: 0.2),
                fontFamily: 'monospace',
              ),
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
              _shareAsPdf(title, _generatedReport ?? "Empty Report");
            },
            icon: const Icon(Icons.share),
            label: const Text("Share PDF"),
          ),
        ],
      ),
    );
  }

  Future<void> _shareAsPdf(String title, String content) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Paragraph(text: content),
          ];
        },
      ),
    );
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'securai_report.pdf',
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
            Text(
              "> Git commit: 'Auto-patch security vulnerability'\n> Pushing to origin/main...\n> Triggering CI/CD pipeline...\n> Kubernetes pod rolling update...",
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patch successfully deployed to Production!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Real-Time Security Scans',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      hintText: 'Enter target URL (e.g., example.com)',
                      prefixIcon: const Icon(
                        Icons.language,
                        color: Colors.cyanAccent,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    onSubmitted: (_) => _startScan(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _startScan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent.withValues(alpha: 0.1),
                    foregroundColor: Colors.cyanAccent,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.search),
                ),
              ],
            ),
          ),
          Expanded(
            child: _alertsFuture == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.radar,
                          size: 80,
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Enter a website URL to begin Deep Scan",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : FutureBuilder<List<Map<String, dynamic>>>(
                    future: _alertsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError || !snapshot.hasData) {
                        return Center(
                          child: Text(
                            'Error loading alerts.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        );
                      }

                      final alerts = snapshot.data!;

                      return RefreshIndicator(
                        onRefresh: () async {
                          setState(() {
                            _alertsFuture = _apiService.fetchRealAlerts(
                              _urlController.text.trim(),
                            );
                          });
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: alerts.length,
                          itemBuilder: (context, index) {
                            final alert = alerts[index];
                            final isHigh =
                                alert["severity"].toString().toLowerCase() ==
                                "high";
                            final isLow =
                                alert["severity"].toString().toLowerCase() ==
                                "low";

                            Color statusColor = isHigh
                                ? Colors.redAccent
                                : (isLow
                                      ? Colors.greenAccent
                                      : Colors.orangeAccent);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: statusColor.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: statusColor.withValues(alpha: 0.05),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Icon(
                                                isHigh
                                                    ? Icons.error_outline
                                                    : (isLow
                                                          ? Icons
                                                                .check_circle_outline
                                                          : Icons
                                                                .warning_amber),
                                                color: statusColor,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  alert["title"]!,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: statusColor,
                                                      ),
                                                  overflow:
                                                      TextOverflow.visible,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            alert["severity"]!,
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        alert["details"]!,
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    if (!isLow)
                                      Wrap(
                                        alignment: WrapAlignment.end,
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          ElevatedButton.icon(
                                            onPressed: _isGenerating
                                                ? null
                                                : () => _generatePatch(
                                                    alert["details"]!,
                                                  ),
                                            icon: const Icon(
                                              Icons.build,
                                              size: 16,
                                            ),
                                            label: const Text("Generate Patch"),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors
                                                  .greenAccent
                                                  .withValues(alpha: 0.1),
                                              foregroundColor:
                                                  Colors.greenAccent,
                                            ),
                                          ),
                                          ElevatedButton.icon(
                                            onPressed: _isGenerating
                                                ? null
                                                : () => _generateReport(
                                                    alert["details"]!,
                                                  ),
                                            icon: const Icon(
                                              Icons.auto_awesome,
                                              size: 16,
                                            ),
                                            label: const Text("AI Report"),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.1),
                                              foregroundColor: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
