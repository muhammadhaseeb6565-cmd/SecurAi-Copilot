import os
import re

main_dart = r"F:\The Arzens Intership Tasks\SecurAI Copilot\frontend\lib\main.dart"
with open(main_dart, "r", encoding="utf-8") as f:
    content = f.read()

# Fix 1
content = re.sub(r"onPressed: _requireBiometrics,", "onPressed: () {},", content)

# Fix 2
content = re.sub(r"return BiometricGuard\(\s*prefs: widget\.prefs,\s*child: MainShell\(", r"return MainShell(", content)
content = re.sub(r"initialIndex: _currentIndex,\n\s*onTabSelected: _onTabSelected,\n\s*supabaseClient: widget\.supabaseClient,\n\s*\),\n\s*\);", r"initialIndex: _currentIndex,\n            onTabSelected: _onTabSelected,\n            supabaseClient: widget.supabaseClient,\n          );", content)


with open(main_dart, "w", encoding="utf-8") as f:
    f.write(content)

print("Fixed main.dart")
