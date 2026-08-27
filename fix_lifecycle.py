import os
import re

main_dart = r"F:\The Arzens Intership Tasks\SecurAI Copilot\frontend\lib\main.dart"
with open(main_dart, "r", encoding="utf-8") as f:
    content = f.read()

# Remove WidgetsBindingObserver mixin
content = content.replace("with WidgetsBindingObserver", "")

# Remove addObserver and removeObserver
content = re.sub(r"\s*WidgetsBinding\.instance\.addObserver\(this\);\n", "\n", content)
content = re.sub(r"\s*WidgetsBinding\.instance\.removeObserver\(this\);\n", "\n", content)

# Remove didChangeAppLifecycleState completely
lifecycle_regex = r"\s*@override\n\s*void didChangeAppLifecycleState\(AppLifecycleState state\) \{.*?\n\s*\}\n"
content = re.sub(lifecycle_regex, "\n", content, flags=re.DOTALL)

# Let's also remove the _isLocked / _requireBiometrics from _SecurAIAppState entirely.
# The user doesn't want the full-app overlay popping up on resume.
# They only want BiometricGuard at startup (which wraps MainShell) and the settings toggle.

# Remove _isLocked and auth from _SecurAIAppState
content = re.sub(r"\s*bool _isLocked = false;\n\s*final LocalAuthentication auth = LocalAuthentication\(\);\n", "\n", content)

# Remove _requireBiometrics method
require_bio_regex = r"\s*Future<void> _requireBiometrics\(\) async \{.*?\n\s*\}\n"
content = re.sub(require_bio_regex, "\n", content, flags=re.DOTALL)

# Remove the locked screen overlay in build
lock_screen_regex = r"\s*if \(_isLocked\) \{\n\s*return Scaffold\(.*?\n\s*\);\n\s*\}\n"
content = re.sub(lock_screen_regex, "\n", content, flags=re.DOTALL)

# Clean up any _isLocked = true in initState
content = re.sub(r"\s*if \(widget\.prefs\.getBool\('requireBiometrics'\) == true\) \{\n\s*_isLocked = true;\n\s*\}\n", "\n", content)

with open(main_dart, "w", encoding="utf-8") as f:
    f.write(content)

print("Removed aggressive lifecycle biometrics from main.dart")
