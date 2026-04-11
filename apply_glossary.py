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

word_replacements = [
    # Typos
    (r'(?i)\bоглушениеу\b', 'оглушению'),
    
    # Mechanics capitalizations
    (r'(?i)\bоглушение\b', 'Оглушение'),
    (r'(?i)\bоглушения\b', 'Оглушения'),
    (r'(?i)\bоглушает\b', 'Оглушает'),
    (r'(?i)\bоглушены\b', 'Оглушены'),
    (r'(?i)\bоглушению\b', 'Оглушению'),
    (r'(?i)\bоглушена\b', 'Оглушена'),
    (r'(?i)\bоглушенным\b', 'Оглушенным'),
    (r'(?i)\bоглушении\b', 'Оглушении'),
    (r'(?i)\bоглушит\b', 'Оглушит'),
    (r'(?i)\bоглушением\b', 'Оглушением'),
    (r'(?i)\bоглушенной\b', 'Оглушенной'),
    (r'(?i)\bоглушений\b', 'Оглушений'),
    
    (r'(?i)\bбезмолвия\b', 'Безмолвия'),
    (r'(?i)\bбезмолвие\b', 'Безмолвие'),
    
    (r'(?i)\bобезоруживание\b', 'Обезоруживание'),
    (r'(?i)\bобезоруживает\b', 'Обезоруживает'),
    (r'(?i)\bобезоруживания\b', 'Обезоруживания'),
    
    (r'(?i)\bнедоумение\b', 'Недоумение'),
    (r'(?i)\bнедоумения\b', 'Недоумения'),
    
    (r'(?i)\bкорни\b', 'Оцепенение'),
    (r'(?i)\bкорнями\b', 'Оцепенением'),
    (r'(?i)\bоцепенение\b', 'Оцепенение'),
    (r'(?i)\bоцепенения\b', 'Оцепенения'),
    (r'(?i)\bоцепенением\b', 'Оцепенением'),
]

fixes = 0
changed_keys = []
for i, line in enumerate(ru_lines):
    if '\t' in line:
        k, v = line.split('\t', 1)
        # Skip names entirely to prevent weird bugs, only affect descriptions
        if k.endswith('_name'): continue
            
        new_v = v
        for pattern, replacement in word_replacements:
            # We must be careful not to keep modifying text unnecessarily if it's already Correct
            # But re.sub replaces everything that matches ignoring case.
            # So "Оглушение" will be replaced by "Оглушение" - effectively no logical change.
            new_v = re.sub(pattern, replacement, new_v)
            
        if new_v != v:
            ru_lines[i] = k + line[len(k):line.find(v)] + new_v
            fixes += 1
            changed_keys.append(k)

print(f"Glossary synced! Cleared {fixes} lines.")

with open(r'd:\Projects\HoN_RU_Pack\bundle\entities_en.str', 'wb') as f:
    f.write(bom + '\r\n'.join(ru_lines).encode('utf-8'))
