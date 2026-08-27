import os
import re

pubspec = r"F:\The Arzens Intership Tasks\SecurAI Copilot\frontend\pubspec.yaml"
with open(pubspec, "r", encoding="utf-8") as f:
    content = f.read()

content = re.sub(r"\s*local_auth: \^2\.3\.0\n", "\n", content)

with open(pubspec, "w", encoding="utf-8") as f:
    f.write(content)

print("Removed local_auth from pubspec.yaml")
