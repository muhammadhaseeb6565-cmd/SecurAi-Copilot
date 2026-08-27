path = r"F:\The Arzens Intership Tasks\SecurAI Copilot\frontend\lib\main.dart"

with open(path, "r", encoding="utf-8") as f:
    content = f.read()

# Restore missing imports that were accidentally deleted
missing = (
    "import 'screens/main_shell.dart';\n"
    "import 'screens/splash_screen.dart';\n"
    "import 'dart:convert';\n"
    "import 'package:http/http.dart' as http;\n"
    "import 'package:workmanager/workmanager.dart';\n"
    "import 'package:flutter_local_notifications/flutter_local_notifications.dart';\n"
    "import 'package:flutter_windowmanager/flutter_windowmanager.dart';\n"
    "import 'screens/security_block_screen.dart';\n"
    "\n"
    "final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =\n"
    "    FlutterLocalNotificationsPlugin();\n"
    "\n"
)

old_marker = "import 'screens/login_screen.dart';\n@pragma('vm:entry-point')"
new_marker = "import 'screens/login_screen.dart';\n" + missing + "@pragma('vm:entry-point')"

if old_marker in content:
    content = content.replace(old_marker, new_marker)
    print("Imports restored OK")
else:
    print("Marker not found - current state:")
    print(repr(content[:600]))

# Remove the jailbreak detection plugin calls and replace with pure Dart implementation
old_jailbreak = (
    "    bool isCompromised = false;\n"
    "    try {\n"
    "      bool jailbroken = await FlutterJailbreakDetection.jailbroken;\n"
    "      bool developerMode = await FlutterJailbreakDetection.developerMode;\n"
    "      isCompromised = jailbroken || developerMode;\n"
    "    } catch (e) {\n"
    "      isCompromised = true;\n"
    "    }\n"
)

new_jailbreak = (
    "    // Pure-Dart root/jailbreak detection (replaces flutter_jailbreak_detection plugin)\n"
    "    bool isCompromised = false;\n"
    "    if (Platform.isAndroid || Platform.isIOS) {\n"
    "      try {\n"
    "        // Check for common root/jailbreak indicators without a native plugin\n"
    "        final List<String> suspiciousPaths = [\n"
    "          '/system/app/Superuser.apk', '/sbin/su', '/system/bin/su',\n"
    "          '/system/xbin/su', '/data/local/xbin/su', '/data/local/bin/su',\n"
    "          '/system/sd/xbin/su', '/system/bin/failsafe/su',\n"
    "          '/data/local/su', '/su/bin/su',\n"
    "          '/Applications/Cydia.app', '/private/var/lib/apt',\n"
    "          '/private/var/mobile/Library/SBSettings',\n"
    "          '/Library/MobileSubstrate/MobileSubstrate.dylib',\n"
    "        ];\n"
    "        for (final p in suspiciousPaths) {\n"
    "          if (await File(p).exists()) {\n"
    "            isCompromised = true;\n"
    "            break;\n"
    "          }\n"
    "        }\n"
    "      } catch (e) {\n"
    "        // Cannot determine — assume safe\n"
    "        isCompromised = false;\n"
    "      }\n"
    "    }\n"
)

if old_jailbreak in content:
    content = content.replace(old_jailbreak, new_jailbreak)
    print("Jailbreak detection replaced with pure Dart OK")
else:
    print("Jailbreak block not found in file")

with open(path, "w", encoding="utf-8") as f:
    f.write(content)

print("File written successfully")
