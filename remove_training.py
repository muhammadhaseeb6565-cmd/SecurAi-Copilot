import os
import re

main_shell = r"F:\The Arzens Intership Tasks\SecurAI Copilot\frontend\lib\screens\main_shell.dart"
with open(main_shell, "r", encoding="utf-8") as f:
    content = f.read()

# Remove import
content = re.sub(r"import 'training_screen\.dart';\n", "", content)

# Remove the ListTile from Drawer
list_tile_regex = r"\s*ListTile\(\s*leading: const Icon\(Icons\.school\),\s*title: const Text\('DevSecOps Training'\),\s*onTap: \(\) \{.*?\n\s*\},?\n\s*\),?"
content = re.sub(list_tile_regex, "", content, flags=re.DOTALL)

with open(main_shell, "w", encoding="utf-8") as f:
    f.write(content)

print("Removed DevSecOps Training from drawer")
