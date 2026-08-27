lock_file = r"F:\The Arzens Intership Tasks\SecurAI Copilot\frontend\pubspec.lock"
with open(lock_file, "r", encoding="utf-8") as f:
    lines = f.readlines()

new_lines = []
skip = False
for line in lines:
    if line.startswith("  flutter_windowmanager:"):
        skip = True
        continue
    if skip:
        if line.startswith("    dependency:") or line.startswith("    description:") or line.startswith("      name:") or line.startswith("      sha256:") or line.startswith("      url:") or line.startswith("    source:") or line.startswith("    version:"):
            continue
        else:
            skip = False
    
    if not skip:
        new_lines.append(line)

with open(lock_file, "w", encoding="utf-8") as f:
    f.writelines(new_lines)
print("Manually patched pubspec.lock")
