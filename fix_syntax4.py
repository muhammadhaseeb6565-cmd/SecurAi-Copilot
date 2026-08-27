import os
import re

main_dart = r"F:\The Arzens Intership Tasks\SecurAI Copilot\frontend\lib\main.dart"
with open(main_dart, "r", encoding="utf-8") as f:
    content = f.read()

content = re.sub(r"return BiometricGuard\(\s*prefs: prefs,\s*child: MainShell\(\s*initialIndex: 0,\s*onTabSelected: \(i\) \{\},\s*supabaseClient: _supabase,\s*\),\s*\);", r"return MainShell(\n            initialIndex: 0,\n            onTabSelected: (i) {},\n            supabaseClient: _supabase,\n          );", content, flags=re.DOTALL)

with open(main_dart, "w", encoding="utf-8") as f:
    f.write(content)

print("Fixed final BiometricGuard")
