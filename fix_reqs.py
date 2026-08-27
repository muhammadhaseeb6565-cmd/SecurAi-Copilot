import codecs

with open('backend/requirements.txt', 'rb') as f:
    content = f.read()

# Replace UTF-16 null bytes if they exist in the text, or just clean the file
lines = []
for line in content.split(b'\n'):
    line = line.replace(b'\x00', b'')
    line = line.strip()
    if line:
        lines.append(line.decode('utf-8', errors='ignore'))

with codecs.open('backend/requirements.txt', 'w', 'utf-8') as f:
    for line in lines:
        f.write(line + '\n')
