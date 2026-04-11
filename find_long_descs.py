import sys
sys.stdout.reconfigure(encoding='utf-8')

path = r'd:\HoN_RU_Pack\bundle\entities_en.str'
with open(path, 'rb') as f:
    data = f.read()

bom = b'\xef\xbb\xbf'
text = data[3:].decode('utf-8', errors='replace') if data.startswith(bom) else data.decode('utf-8', errors='replace')

# Search for description keys for specific abilities
search_names = [
    'True Strike',       # Shadowblade Mirage Strike
    'Mirage Strike',     
    'Fire и Ice',
    'Огонь и лед',
    'Сохранение',
    'пузыр',             # Pearl Preservation bubble
    'Отражение',
    'Разделитесь',       # Gemini split
    'иллюзию на',        # Mirage Strike
]

lines = text.split('\r\n')
for i, line in enumerate(lines):
    if '\t' not in line:
        continue
    key, val = line.split('\t', 1)
    key = key.strip()
    for term in search_names:
        if term in val:
            print(f"KEY: {key}")
            print(f"VAL: {val[:200]}")
            print()
            break
