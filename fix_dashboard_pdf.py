import os
import re

dashboard_dart = r"F:\The Arzens Intership Tasks\SecurAI Copilot\frontend\lib\screens\dashboard_screen.dart"
with open(dashboard_dart, "r", encoding="utf-8") as f:
    content = f.read()

# Add printing and pdf imports if missing
imports_to_add = "import 'package:http/http.dart' as http;\nimport 'package:printing/printing.dart';\n"
if "package:printing/printing.dart" not in content:
    content = content.replace("import 'package:flutter/material.dart';", imports_to_add + "import 'package:flutter/material.dart';")

# Rewrite _downloadIRReport
old_method = """  Future<void> _downloadIRReport() async {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading Incident Report PDF...')));
    // In a real app we would use url_launcher to open the PDF link, 
    // or download it via flutter_downloader.
    final Uri url = Uri.parse('https://securai-copilot.onrender.com/api/generate-ir-report?score=');
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Report generated. Go to: ')));
  }"""

new_method = """  Future<void> _downloadIRReport() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading Incident Report PDF...')));
    }
    
    try {
      final baseUrl = await ApiService.getBaseUrl();
      final Uri url = Uri.parse('$baseUrl/api/generate-ir-report?score=$_overallThreatScore');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF Generated! Opening preview...')));
        }
        await Printing.sharePdf(bytes: response.bodyBytes, filename: 'Incident_Report.pdf');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to download: ${response.statusCode}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error downloading PDF: $e')));
      }
    }
  }"""

content = content.replace(old_method, new_method)

with open(dashboard_dart, "w", encoding="utf-8") as f:
    f.write(content)

print("Updated dashboard_screen.dart to use printing package for PDF")
