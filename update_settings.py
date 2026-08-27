import os
import re

settings_dart = r"F:\The Arzens Intership Tasks\SecurAI Copilot\frontend\lib\screens\settings_screen.dart"
with open(settings_dart, "r", encoding="utf-8") as f:
    content = f.read()

# Add imports if they don't exist
if "import 'package:printing/printing.dart';" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:printing/printing.dart';\nimport 'package:pdf/pdf.dart';\nimport 'package:pdf/widgets.dart' as pw;")

# Update _exportData to be explicitly for clipboard
export_data_method = """  void _exportData() {
    final allKeys = widget.prefs.getKeys();
    final Map<String, dynamic> data = {};
    for (var key in allKeys) {
      data[key] = widget.prefs.get(key);
    }

    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

    Clipboard.setData(ClipboardData(text: jsonStr));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Data copied to clipboard!')));
  }"""

new_export_methods = """  void _exportData() {
    final allKeys = widget.prefs.getKeys();
    final Map<String, dynamic> data = {};
    for (var key in allKeys) {
      data[key] = widget.prefs.get(key);
    }

    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

    Clipboard.setData(ClipboardData(text: jsonStr));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('JSON copied to clipboard!')));
  }

  Future<void> _exportDataToPdf() async {
    final allKeys = widget.prefs.getKeys();
    final Map<String, dynamic> data = {};
    for (var key in allKeys) {
      data[key] = widget.prefs.get(key);
    }

    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

    final pdf = pw.Document();
    
    // Add page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('SecurAI Copilot - Exported Configuration', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text(jsonStr, style: const pw.TextStyle(fontSize: 12)),
            ]
          );
        },
      ),
    );

    // Prompt user to save/share the PDF
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'SecurAI_Settings.pdf');
  }"""

content = content.replace(export_data_method, new_export_methods)

# Update the UI
old_tile = """          ListTile(
            title: const Text('Export My Data'),
            subtitle: const Text(
              'Download a JSON copy of your personal settings and app data',
            ),
            trailing: const Icon(Icons.download, color: Colors.cyanAccent),
            onTap: _exportData,
          ),"""

new_tiles = """          ListTile(
            title: const Text('Copy JSON Configuration'),
            subtitle: const Text(
              'Copy your personal settings and app data as JSON to clipboard',
            ),
            trailing: const Icon(Icons.copy, color: Colors.cyanAccent),
            onTap: _exportData,
          ),
          ListTile(
            title: const Text('Export JSON as PDF'),
            subtitle: const Text(
              'Generate a PDF document of your JSON configuration',
            ),
            trailing: const Icon(Icons.picture_as_pdf, color: Colors.cyanAccent),
            onTap: _exportDataToPdf,
          ),"""

content = content.replace(old_tile, new_tiles)

with open(settings_dart, "w", encoding="utf-8") as f:
    f.write(content)

print("Updated settings screen with copy JSON and PDF export options")
