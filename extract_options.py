import re

interface_path = r'd:\HoN_RU_Pack\bundle\interface_en.str'
output_path = r'd:\HoN_RU_Pack\settings_audit.txt'

with open(interface_path, 'r', encoding='utf-8-sig', errors='ignore') as f:
    lines = f.readlines()

settings = []
for line in lines:
    if line.startswith('options_') and '\t' in line:
        parts = line.split('\t', 1)
        key = parts[0].strip()
        val = parts[1].strip()
        settings.append(f"{key} : {val}")

with open(output_path, 'w', encoding='utf-8') as f:
    f.write("\n".join(settings))

print(f"Extracted {len(settings)} settings strings.")
