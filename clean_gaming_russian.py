import re

ru_lines = []
with open(r'd:\Projects\HoN_RU_Pack\bundle\entities_en.str', 'rb') as f:
    data = f.read()
    bom = b''
    if data.startswith(b'\xef\xbb\xbf'):
        bom = b'\xef\xbb\xbf'
        data = data[3:]
    text = data.decode('utf-8')
    ru_lines = text.split('\r\n')

fixes = 0
for i, line in enumerate(ru_lines):
    if '\t' in line:
        k, v = line.split('\t', 1)
        new_v = v
        # Custom fix for enemy units
        new_v = re.sub(r'(?i)\bвражеские\s+единицы\b', 'враги', new_v)
        new_v = re.sub(r'(?i)\bвражеских\s+единиц\b', 'врагов', new_v)
        new_v = re.sub(r'(?i)\bвражеским\s+единицам\b', 'врагам', new_v)
        new_v = re.sub(r'(?i)\bвражескими\s+единицами\b', 'врагами', new_v)

        new_v = re.sub(r'(?i)\bсоюзные\s+единицы\b', 'союзники', new_v)
        new_v = re.sub(r'(?i)\bсоюзных\s+единиц\b', 'союзников', new_v)
        new_v = re.sub(r'(?i)\bсоюзным\s+единицам\b', 'союзникам', new_v)
        
        # Spells
        new_v = re.sub(r'(?i)\bзаклинание\b', 'способность', new_v)
        new_v = re.sub(r'(?i)\bзаклинания\b', 'способности', new_v)
        new_v = re.sub(r'(?i)\bзаклинаний\b', 'способностей', new_v)
        new_v = re.sub(r'(?i)\bзаклинаниям\b', 'способностям', new_v)
        new_v = re.sub(r'(?i)\bзаклинаниями\b', 'способностями', new_v)
        new_v = re.sub(r'(?i)\bзаклинании\b', 'способности', new_v)

        # Time
        new_v = re.sub(r'(?i)\bвремя\s+восстановления\b', 'перезарядка', new_v)
        new_v = re.sub(r'(?i)\bв\s+течение\s+(\{?[^\}]+\}?)\s+секунд[a-я]*\b', r'на \1 сек.', new_v)

        if new_v != v:
            ru_lines[i] = k + line[len(k):line.find(v)] + new_v
            fixes += 1

print(f"Cleaned {fixes} lines from cliches.")

with open(r'd:\Projects\HoN_RU_Pack\bundle\entities_en.str', 'wb') as f:
    f.write(bom + '\r\n'.join(ru_lines).encode('utf-8'))
