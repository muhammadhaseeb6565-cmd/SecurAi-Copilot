import os
import re

main_dart = r"F:\The Arzens Intership Tasks\SecurAI Copilot\frontend\lib\main.dart"
with open(main_dart, "r", encoding="utf-8") as f:
    content = f.read()

# Remove the Iron Vault logic inside didChangeAppLifecycleState
old_lifecycle = """  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      Clipboard.setData(const ClipboardData(text: ""));
      // Iron Vault: Lock the app instantly when it goes to the background
      setState(() {
        _isSecureLocked = true;
      });
    } else if (state == AppLifecycleState.resumed && _isSecureLocked) {
      // Require biometrics to unlock
      _requireBiometrics();
    }
  }"""

new_lifecycle = """  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      Clipboard.setData(const ClipboardData(text: ""));
      // Removed aggressive Iron Vault locking based on user request.
    }
  }"""

content = content.replace(old_lifecycle, new_lifecycle)

with open(main_dart, "w", encoding="utf-8") as f:
    f.write(content)

print("Removed aggressive lifecycle biometrics from main.dart")
