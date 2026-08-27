import os
import re

main_shell = r"F:\The Arzens Intership Tasks\SecurAI Copilot\frontend\lib\screens\main_shell.dart"
with open(main_shell, "r", encoding="utf-8") as f:
    content = f.read()

# Add import if missing
if "training_screen.dart" not in content:
    content = content.replace("import 'dashboard_screen.dart';", "import 'dashboard_screen.dart';\nimport 'training_screen.dart';")

# Add the ListTile back to Drawer if missing
if "DevSecOps Training" not in content:
    list_tile = """
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('DevSecOps Training'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TrainingScreen()),
              );
            },
          ),"""
    
    # Insert it before the Settings ListTile
    content = content.replace("          ListTile(\n            leading: const Icon(Icons.settings),", list_tile + "\n          ListTile(\n            leading: const Icon(Icons.settings),")

with open(main_shell, "w", encoding="utf-8") as f:
    f.write(content)

print("Restored DevSecOps Training in drawer")
