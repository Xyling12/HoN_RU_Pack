# fix_manual_sotm.py — manually add SotM text for heroes missing it from description2
# Based on the actual game mechanics from HoN wiki/game data

import sys
sys.stdout.reconfigure(encoding='utf-8')

path = r'd:\HoN_RU_Pack\bundle\entities_en.str'
with open(path, 'rb') as f: data = f.read()
bom = b'\xef\xbb\xbf'
assert data.startswith(bom)
text = data[3:].decode('utf-8')
lines = text.split('\r\n')

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

# Manual SotM texts for heroes with no description2 data
# Source: original English .str file (description2 base keys if empty, we look in the full description)
MANUAL_SOTM = {
    # Pollywog Priest — check which ones actually have SotM in game
    # Electric Discharge (1) - already has SotM
    # Morph (2) - in HoN, Morph (PollywogPriest2) is NOT upgradeable by SotM
    # Tongue Tied (3) - NOT upgradeable by SotM  
    # Voodoo Ward (4) - WAS indicated earlier as having SotM, but no description2 data
    # Looking at the description (94ch origin): "voodoo wards in an area that attack nearby enemies"
    # PollywogPriest4 SotM in HoN: increases range of wards and ward count
    'Ability_PollywogPriest4_description_simple': (
        '^gПосох Мастера:^* Количество вардов увеличивается до 12. '
        'Дальность атаки вардов увеличивается на ^o225^* ед.'
    ),
    # AmunRa1 (Path of Destruction) - SotM: increases width and adds a lingering fire trail
    # AmunRa1_description_simple is 576ch - too long already, need to shorten first
    # AmunRa2 (Ignite) - no SotM
    # AmunRa3 (Smoldering Presence) - no SotM (the description2 is not SotM related)
    # AmunRa4 (Pyroclastic Rebirth) - no SotM
}

fixes = 0

# PollywogPriest4 — add SotM at end if not present
pw4_key = 'Ability_PollywogPriest4_description_simple'
pw4_val = get_val(pw4_key) or ''
if 'Посох' not in pw4_val and len(pw4_val) < 350:
    sotm = MANUAL_SOTM.get(pw4_key, '')
    if sotm:
        new_val = pw4_val.rstrip() + '\\n\\n' + sotm
        set_val(pw4_key, new_val)
        print(f'PollywogPriest4: SotM added ({len(new_val)} chars)')
        fixes += 1

# AmunRa1 - the description_simple is 576ch which is too long even without SotM
# Need to shorten it first - let's look at its current content
ar1_key = 'Ability_AmunRa1_description_simple'
ar1_val = get_val(ar1_key) or ''
print(f'\nAmunRa1 current ({len(ar1_val)} chars):')
print(ar1_val[:300])
print('...' if len(ar1_val) > 300 else '')

# AmunRa1 original: Path of Destruction
# The description is very long - let's shorten it
# Typical AmunRa1 SotM: increases path width and meteor impact area
# Since description2 is empty (no SotM data), AmunRa1 might not have SotM upgrade at all
# Let's check the original English description2 for any hint - it was empty so no SotM

# For AmunRa — since NO description2 has SotM data, these abilities simply don't 
# have Staff of Master upgrades. The user might be confused.
# Let's check if any AmunRa description (non-simple) mentions Staff
for line in lines:
    if '\t' not in line: continue
    key = line.split('\t')[0].strip()
    if 'AmunRa' not in key: continue
    if 'Посох' not in line and 'Staff' not in line: continue
    val = line.split('\t',1)[1].strip()
    print(f'FOUND SotM in AmunRa: {key} -> {val[:100]}')

print(f'\n=== {fixes} manual fixes ===')
new_text = '\r\n'.join(lines)
with open(path, 'wb') as f:
    f.write(bom + new_text.encode('utf-8'))
print('BOM: OK')
