import os
import re

dashboard_dart = r"F:\The Arzens Intership Tasks\SecurAI Copilot\frontend\lib\screens\dashboard_screen.dart"
with open(dashboard_dart, "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace(r"?score=$_overallThreatScore", "?score=0.0")

with open(dashboard_dart, "w", encoding="utf-8") as f:
    f.write(content)

print("Fixed _overallThreatScore")
