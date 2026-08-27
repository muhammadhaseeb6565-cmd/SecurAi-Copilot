import os
import re

# 1. chat_screen.dart
chat_path = r"F:\The Arzens Intership Tasks\SecurAI Copilot\frontend\lib\screens\chat_screen.dart"
with open(chat_path, "r", encoding="utf-8") as f:
    c = f.read()
c = re.sub(r"\s*static const String _storageKey = 'chat_history';\n", "\n", c)
with open(chat_path, "w", encoding="utf-8") as f:
    f.write(c)

# 2. settings_screen.dart
settings_path = r"F:\The Arzens Intership Tasks\SecurAI Copilot\frontend\lib\screens\settings_screen.dart"
with open(settings_path, "r", encoding="utf-8") as f:
    c = f.read()
c = re.sub(r"\s*void _saveApiUrl\(String value\) \{.*?\n\s*\}\n", "\n", c, flags=re.DOTALL)
with open(settings_path, "w", encoding="utf-8") as f:
    f.write(c)

# 3. api_service.dart
api_path = r"F:\The Arzens Intership Tasks\SecurAI Copilot\frontend\lib\services\api_service.dart"
with open(api_path, "r", encoding="utf-8") as f:
    c = f.read()
c = re.sub(r"import 'package:http/http\.dart' as http;\nimport 'package:http/http\.dart' as http;\n", "import 'package:http/http.dart' as http;\n", c)
c = re.sub(r"import 'package:flutter_secure_storage/flutter_secure_storage\.dart';\nimport 'package:http/http\.dart' as http;\n", "import 'package:flutter_secure_storage/flutter_secure_storage.dart';\n", c)
c = re.sub(r"\s*final String _fallbackAdminToken = 'securai_admin_fallback_9988';\n", "\n", c)
with open(api_path, "w", encoding="utf-8") as f:
    f.write(c)

print("Robust patched")
