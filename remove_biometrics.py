import os
import re

main_dart = r"F:\The Arzens Intership Tasks\SecurAI Copilot\frontend\lib\main.dart"
with open(main_dart, "r", encoding="utf-8") as f:
    content = f.read()

# 1. Remove BiometricGuard entirely
biometric_guard_regex = r"class BiometricGuard extends StatefulWidget.*?class _BiometricGuardState extends State<BiometricGuard>.*?}\n}\n"
content = re.sub(biometric_guard_regex, "", content, flags=re.DOTALL)

# 2. In _SecurAIAppState, remove _requireBiometrics from resume
content = re.sub(r"// Require biometrics to unlock\s*_requireBiometrics\(\);\s*", "", content)

# 3. Remove _requireBiometrics method
require_biometrics_regex = r"Future<void> _requireBiometrics\(\) async \{.*?\}\n  \}\n"
content = re.sub(require_biometrics_regex, "", content, flags=re.DOTALL)

# 4. Remove BiometricGuard wrapping around return MainShell
content = re.sub(r"return BiometricGuard\(\s*prefs:\s*widget\.prefs,\s*child:\s*(MainShell\(.*?\)),\s*\);", r"return \1;", content, flags=re.DOTALL)

# 5. Remove local_auth import
content = re.sub(r"import 'package:local_auth/local_auth\.dart';\n", "", content)

# 6. Check if there are any remaining `isLocked` logic from `_requireBiometrics` that needs cleaning
content = re.sub(r"bool _isLocked = false;\n", "", content)
content = re.sub(r"if \(_isLocked\) \{.*?(return Scaffold.*?)\}\n\s*return\s", r"return ", content, flags=re.DOTALL)

with open(main_dart, "w", encoding="utf-8") as f:
    f.write(content)

print("Cleaned main.dart")

# Now Dashboard screen
dashboard_dart = r"F:\The Arzens Intership Tasks\SecurAI Copilot\frontend\lib\screens\dashboard_screen.dart"
with open(dashboard_dart, "r", encoding="utf-8") as f:
    content = f.read()

content = re.sub(r"import 'package:local_auth/local_auth\.dart';\n", "", content)

auth_regex = r"Future<bool> _authenticate\(\) async \{.*?\}\n"
content = re.sub(auth_regex, "Future<bool> _authenticate() async { return true; }\n", content, flags=re.DOTALL)

with open(dashboard_dart, "w", encoding="utf-8") as f:
    f.write(content)

print("Cleaned dashboard_screen.dart")

# Now Settings screen
settings_dart = r"F:\The Arzens Intership Tasks\SecurAI Copilot\frontend\lib\screens\settings_screen.dart"
with open(settings_dart, "r", encoding="utf-8") as f:
    content = f.read()

content = re.sub(r"\s*bool _requireBiometrics = false;\n", "\n", content)
content = re.sub(r"\s*_requireBiometrics = widget\.prefs\.getBool\('requireBiometrics'\) \?\? false;\n", "\n", content)
save_bio_regex = r"\s*void _saveBiometrics\(bool value\) \{.*?\n  \}\n"
content = re.sub(save_bio_regex, "\n", content, flags=re.DOTALL)

# SwitchListTile for Biometrics
switch_regex = r"\s*SwitchListTile\(\s*title: const Text\('Require Biometrics'\).*?onChanged: _saveBiometrics,\s*\),\s*const Divider\(\),"
content = re.sub(switch_regex, "", content, flags=re.DOTALL)

with open(settings_dart, "w", encoding="utf-8") as f:
    f.write(content)

print("Cleaned settings_screen.dart")

