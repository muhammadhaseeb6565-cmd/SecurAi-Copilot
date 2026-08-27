import os

pubspec = r"F:\The Arzens Intership Tasks\SecurAI Copilot\frontend\pubspec.yaml"
with open(pubspec, "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace("  flutter_windowmanager: ^0.2.0\n", "")

with open(pubspec, "w", encoding="utf-8") as f:
    f.write(content)


main_dart = r"F:\The Arzens Intership Tasks\SecurAI Copilot\frontend\lib\main.dart"
with open(main_dart, "r", encoding="utf-8") as f:
    main_content = f.read()

main_content = main_content.replace("import 'package:flutter_windowmanager/flutter_windowmanager.dart';\n", "")

# Remove the windowmanager block
wm_block = """    if (Platform.isAndroid) {
      await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    }

"""
main_content = main_content.replace(wm_block, "")

# Fallback block removal just in case spacing is different
wm_block2 = """    if (Platform.isAndroid) {
      await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    }
"""
main_content = main_content.replace(wm_block2, "")

with open(main_dart, "w", encoding="utf-8") as f:
    f.write(main_content)

print("Removed flutter_windowmanager from pubspec and main.dart")
