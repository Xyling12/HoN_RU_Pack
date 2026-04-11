import os

v15_path = r'd:\HoN_RU_Pack\entities_v15.str'
bundle_path = r'd:\HoN_RU_Pack\bundle\entities_en.str'

name_map = {}

# 1. Read original English hero names
with open(v15_path, 'rb') as f:
    text_v15 = f.read().decode('utf-16le', errors='ignore')

for line in text_v15.split('\r\n'):
    if '\t' in line:
        key, val = line.split('\t', 1)
        key = key.strip()
        if key.startswith('Hero_') and key.endswith('_name'):
            name_map[key] = val.strip()

print(f"Loaded {len(name_map)} English Hero/Avatar names from v1.5 archive.")

# 2. Patch bundle entities_en.str
with open(bundle_path, 'rb') as f:
    text_bundle = f.read().decode('utf-8-sig', errors='ignore')

lines = text_bundle.split('\r\n')
changed = 0

for i, line in enumerate(lines):
    if '\t' in line:
        parts = line.split('\t', 1)
        key = parts[0].strip()
        if key in name_map:
            english_name = name_map[key]
            # Replace if it's currently translated (not exactly english_name)
            if parts[1].strip() != english_name:
                lines[i] = parts[0] + '\t' + english_name
                changed += 1

if changed > 0:
    new_text = b'\xef\xbb\xbf' + '\r\n'.join(lines).encode('utf-8')
    with open(bundle_path, 'wb') as f:
        f.write(new_text)
    print(f"Restored {changed} Hero/Avatar names to English!")
else:
    print("No hero names needed restoring.")
