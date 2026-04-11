# fix_sotm_in_description_simple.py
# In HoN, description2 keys DON'T render in the tooltip.
# SotM text must be embedded at the END of _description_simple.
# This script scans all description2 keys with real SotM text,
# and if the corresponding _description_simple does NOT have SotM text,
# appends it to the end of _description_simple.

import sys
sys.stdout.reconfigure(encoding='utf-8')

path = r'd:\HoN_RU_Pack\bundle\entities_en.str'
with open(path, 'rb') as f: data = f.read()
bom = b'\xef\xbb\xbf'
assert data.startswith(bom)
text = data[3:].decode('utf-8')
lines = text.split('\r\n')

# Build key→line index map
key_to_idx = {}
for i, line in enumerate(lines):
    if '\t' not in line: continue
    key = line.split('\t')[0].strip()
    if key not in key_to_idx:
        key_to_idx[key] = i

def get_val(key):
    idx = key_to_idx.get(key)
    if idx is None: return None
    parts = lines[idx].split('\t', 1)
    return parts[1].strip() if len(parts) > 1 else ''

def set_val(key, new_val):
    idx = key_to_idx.get(key)
    if idx is None: return False
    tab_prefix = lines[idx].split('\t', 1)[0]
    lines[idx] = tab_prefix + '\t' + new_val
    return True

EMPTY_VALS = {'\\r', '\\\\r', '\r', '', '\\r\\n'}
SOTM_MARKERS = ['Посох Мастера', 'Эффект посоха', 'может быть усилена']

def is_sotm_text(val):
    return any(m in val for m in SOTM_MARKERS) and not val.strip() in EMPTY_VALS

fixes = 0
skipped = 0

# Find all description2 base keys (without :variant suffix) that have SotM content
for key in list(key_to_idx.keys()):
    if 'description2' not in key: continue
    if ':' in key: continue  # skip variant keys
    if not (key.startswith('Ability_') or key.startswith('Item_')): continue

    desc2_val = get_val(key) or ''
    if not is_sotm_text(desc2_val): continue

    # Find the corresponding _description_simple key
    base = key.replace('_description2', '')  # e.g. Ability_Fayde4
    simple_key = base + '_description_simple'
    simple_val = get_val(simple_key)
    if simple_val is None: continue

    # Check if description_simple already has SotM text
    if is_sotm_text(simple_val):
        skipped += 1
        continue

    # Append SotM text from description2 to description_simple
    # Strip the standard "Эта способность может быть усилена..." prefix if present
    sotm_text = desc2_val.strip()
    # If it starts with the standard header, keep it as is for readability
    # but ensure it starts with \n\n separator
    if not sotm_text.startswith('^gПосох') and not sotm_text.startswith('^gЭта'):
        continue  # skip if can't determine proper SotM text

    # Build new description_simple = old + \n\n + SotM
    new_simple = simple_val.rstrip() + '\\n\\n' + sotm_text
    if set_val(simple_key, new_simple):
        fixes += 1
        hero = base.split('_')[1] if '_' in base else base
        print(f"  [{hero}] {simple_key} <- SotM appended")

print(f"\nTotal: {fixes} heroes/items got SotM text in description_simple ({skipped} already had it)")

new_text = '\r\n'.join(lines)
with open(path, 'wb') as f:
    f.write(bom + new_text.encode('utf-8'))
with open(path, 'rb') as f: h = f.read(3)
print(f"BOM: {'OK' if h == bom else 'WRONG!'}")
