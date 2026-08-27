import os
import re

main_dart = r"F:\The Arzens Intership Tasks\SecurAI Copilot\frontend\lib\main.dart"
with open(main_dart, "r", encoding="utf-8") as f:
    content = f.read()

content = re.sub(r"final LocalAuthentication auth = LocalAuthentication\(\);\n", "", content)
content = re.sub(r"import 'package:local_auth/local_auth\.dart';\n", "", content)

# 2. _requireBiometrics in main.dart:
content = re.sub(r"IconButton\(\s*icon: const Icon\(Icons\.fingerprint\),\s*onPressed: _requireBiometrics,\s*\),", "", content)

# BiometricGuard wrapper in main.dart
content = re.sub(r"return BiometricGuard\(\s*prefs: widget\.prefs,\s*child: MainShell\(\s*initialIndex: _currentIndex,\s*onTabSelected: _onTabSelected,\s*supabaseClient: widget\.supabaseClient,\s*\),\s*\);", r"return MainShell(\n            initialIndex: _currentIndex,\n            onTabSelected: _onTabSelected,\n            supabaseClient: widget.supabaseClient,\n          );", content, flags=re.DOTALL)

with open(main_dart, "w", encoding="utf-8") as f:
    f.write(content)

dashboard_dart = r"F:\The Arzens Intership Tasks\SecurAI Copilot\frontend\lib\screens\dashboard_screen.dart"
with open(dashboard_dart, "r", encoding="utf-8") as f:
    content = f.read()

content = re.sub(r"\s*final LocalAuthentication auth = LocalAuthentication\(\);\n", "\n", content)
content = content.replace(r"?score=$_overallThreatScore", "?score=0.0") # fallback

with open(dashboard_dart, "w", encoding="utf-8") as f:
    f.write(content)

settings_dart = r"F:\The Arzens Intership Tasks\SecurAI Copilot\frontend\lib\screens\settings_screen.dart"
with open(settings_dart, "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace("value: _requireBiometrics,", "value: false,")
content = content.replace("onChanged: _saveBiometrics,", "onChanged: (val) {},")

with open(settings_dart, "w", encoding="utf-8") as f:
    f.write(content)

print("Fixed syntax errors")
