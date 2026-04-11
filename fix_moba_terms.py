import os
import re

entities_path = r'd:\HoN_RU_Pack\bundle\entities_en.str'

replacements = [
    # English artifacts
    (r'(?i)\bally\b', 'союзник'),
    (r'(?i)\ballies\b', 'союзники'),
    (r'(?i)\bDebuffs\b', 'отрицательные эффекты'),
    (r'(?i)\bDebuff\b', 'отрицательный эффект'),
    (r'(?i)\bBuffs\b', 'положительные эффекты'),
    (r'(?i)\bBuff\b', 'положительный эффект'),
    
    # UI elements in tooltips
    (r'(?i)CD:', 'Перезарядка:'),
    (r'(?i)Диапазон:', 'Дальность:'),
    (r'(?i)Затраты маны:', 'Мана:'),
    
    # Remaining time artifacts
    (r'(?i)\bсекунды\b', 'сек.'),
    (r'(?i)\bсекунд\b', 'сек.'),
    (r'(?i)\bсекунду\b', 'сек.'),
]

compiled_replacements = [(re.compile(pattern), replace_with) for pattern, replace_with in replacements]

with open(entities_path, 'rb') as f:
    data = f.read()

text = data.decode('utf-8-sig')
lines = text.split('\r\n')
changed_lines = 0

def apply_regexes(line_text):
    for reg, rep in compiled_replacements:
        def match_case(m):
            original = m.group(0)
            if original.isupper() and len(original) > 1:
                return rep.upper()
            elif original[0].isupper():
                return rep.capitalize()
            return rep
        line_text = reg.sub(match_case, line_text)
    return line_text

for i, line in enumerate(lines):
    if '\t' in line:
        parts = line.split('\t', 1)
        key = parts[0].strip()
        # Apply to description and flavor strings
        if 'description' in key or 'IMPACT' in key or 'FRAME' in key or 'flavor' in key or 'tooltip' in key:
            val = parts[1]
            new_val = apply_regexes(val)
            if new_val != val:
                lines[i] = parts[0] + '\t' + new_val
                changed_lines += 1

if changed_lines > 0:
    new_text = '\r\n'.join(lines)
    bom = b'\xef\xbb\xbf'
    new_data = bom + new_text.encode('utf-8')
    
    with open(entities_path, 'wb') as f:
        f.write(new_data)
    
    print(f"Fixed machine translation artifacts in {changed_lines} lines cleanly.")
else:
    print("No lines matched for translation fixing.")
