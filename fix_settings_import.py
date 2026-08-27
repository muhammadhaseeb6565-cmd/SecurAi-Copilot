import os
import re

settings = r"F:\The Arzens Intership Tasks\SecurAI Copilot\frontend\lib\screens\settings_screen.dart"
with open(settings, "r", encoding="utf-8") as f:
    c = f.read()

# I removed material.dart by accident. Let's add it back at the top.
c = "import 'package:flutter/material.dart';\n" + c

with open(settings, "w", encoding="utf-8") as f:
    f.write(c)

print("Restored material.dart to settings_screen.dart")
