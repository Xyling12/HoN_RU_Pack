import os

interface_path = r'd:\HoN_RU_Pack\bundle\interface_en.str'

with open(interface_path, 'rb') as f:
    text = f.read().decode('utf-8-sig', errors='ignore')

replacements = {
    'tooltip_range': 'Дальность:',
    'compendium_range': 'Дальность:',
    'heroinfo_range': '^cДальность:^*',
    'heroinfo_mana_cost': '^cМана:^*',
    'heroinfo_cooldown': '^cПерезарядка:^* {time} сек.'
}

lines = text.split('\r\n')
changed = 0

for i, line in enumerate(lines):
    if '\t' in line:
        key, val = line.split('\t', 1)
        key = key.strip()
        if key in replacements:
            if val.strip() != replacements[key]:
                # Preserve exact spacing by splitting and replacing only the value
                prefix = line.split('\t')[0]
                lines[i] = prefix + '\t' + replacements[key]
                changed += 1

if changed > 0:
    new_text = b'\xef\xbb\xbf' + '\r\n'.join(lines).encode('utf-8')
    with open(interface_path, 'wb') as f:
        f.write(new_text)
    print(f"Fixed {changed} interface tooltips to Russian!")
else:
    print("Interface tooltips already correct.")
