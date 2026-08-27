import os
import re

def patch_file(path, replacements):
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()
    for old, new in replacements:
        content = content.replace(old, new)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)

# 1. chat_screen.dart
patch_file(r"F:\The Arzens Intership Tasks\SecurAI Copilot\frontend\lib\screens\chat_screen.dart", [
    ("  static const String _storageKey = 'chat_history';\n", "")
])

# 2. dashboard_screen.dart
patch_file(r"F:\The Arzens Intership Tasks\SecurAI Copilot\frontend\lib\screens\dashboard_screen.dart", [
    ("import 'package:http/http.dart' as http;\nimport 'package:fl_chart/fl_chart.dart';", "import 'package:fl_chart/fl_chart.dart';"),
    ("    } catch (e) {\n    }", "    } catch (e) {\n      debugPrint('Error: $e');\n    }"),
    ("import 'package:flutter/material.dart';\nimport 'package:printing/printing.dart';\nimport 'package:flutter/material.dart';", "import 'package:printing/printing.dart';\nimport 'package:flutter/material.dart';")
])

# 3. settings_screen.dart
patch_file(r"F:\The Arzens Intership Tasks\SecurAI Copilot\frontend\lib\screens\settings_screen.dart", [
    ("  void _saveApiUrl(String value) {\n    setState(() {\n      _apiUrl = value;\n      widget.prefs.setString('apiUrl', value);\n    });\n  }\n", ""),
    ("import 'package:flutter/material.dart';\nimport 'package:printing/printing.dart';", "import 'package:printing/printing.dart';")
])

# 4. api_service.dart
patch_file(r"F:\The Arzens Intership Tasks\SecurAI Copilot\frontend\lib\services\api_service.dart", [
    ("import 'package:http/http.dart' as http;\nimport 'package:flutter_secure_storage/flutter_secure_storage.dart';\nimport 'package:http/http.dart' as http;", "import 'package:http/http.dart' as http;\nimport 'package:flutter_secure_storage/flutter_secure_storage.dart';"),
    ("  final String _fallbackAdminToken = 'securai_admin_fallback_9988';\n", ""),
    ("print(", "debugPrint(")
])

# 5. Fix empty catch in dashboard_screen
dash_path = r"F:\The Arzens Intership Tasks\SecurAI Copilot\frontend\lib\screens\dashboard_screen.dart"
with open(dash_path, "r", encoding="utf-8") as f:
    c = f.read()
c = re.sub(r"\} catch \(e\) \{\s*\}", "} catch (e) {\n      debugPrint('Exception caught: $e');\n    }", c)
with open(dash_path, "w", encoding="utf-8") as f:
    f.write(c)

print("Patched warnings")
