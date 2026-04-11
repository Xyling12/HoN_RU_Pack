# fix_pollywog_amunra_sotm.py
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

fixes = 0

# Pollywog description2 for abilities
for n in ['1','2','3','4']:
    simple_key = f'Ability_PollywogPriest{n}_description_simple'
    desc2_key  = f'Ability_PollywogPriest{n}_description2'
    simple_val = get_val(simple_key) or ''
    desc2_val  = get_val(desc2_key) or ''

    if 'Посох' in simple_val:
        print(f'PollywogPriest{n}: already has SotM ({len(simple_val)} chars)')
        continue
    if 'Посох' not in desc2_val:
        print(f'PollywogPriest{n}: no description2 SotM (desc2={len(desc2_val)})')
        continue

    combined = simple_val.rstrip() + '\\n\\n' + desc2_val.strip()
    if len(combined) <= 430:
        set_val(simple_key, combined)
        print(f'PollywogPriest{n}: SotM added ({len(combined)} chars)')
        fixes += 1
    else:
        # Too long — just append short version
        # Extract just the effect part (after ^gЭффект посоха:^* )
        effect = desc2_val.strip()
        idx2 = effect.find('^gЭффект посоха:^*')
        if idx2 != -1:
            effect_text = effect[idx2:]
        else:
            effect_text = '^gПосох Мастера:^* ' + effect.replace('^gЭта способность может быть усилена Посохом Мастера.^*\\n\\n', '')
        short_combined = simple_val.rstrip() + '\\n\\n^gЭта способность усиливается Посохом Мастера.^*\\n' + effect_text[:200]
        set_val(simple_key, short_combined)
        print(f'PollywogPriest{n}: SotM added (short, {len(short_combined)} chars)')
        fixes += 1

# AmunRa — check which ability has SotM in description2
for n in ['1','2','3','4']:
    simple_key = f'Ability_AmunRa{n}_description_simple'
    desc2_key  = f'Ability_AmunRa{n}_description2'
    simple_val = get_val(simple_key) or ''
    desc2_val  = get_val(desc2_key) or ''

    print(f'AmunRa{n}: simple={len(simple_val)}ch sotm_simple={"Посох" in simple_val}, desc2={len(desc2_val)}ch sotm_desc2={"Посох" in desc2_val}')

    if 'Посох' in simple_val: continue
    if 'Посох' not in desc2_val: continue

    combined = simple_val.rstrip() + '\\n\\n' + desc2_val.strip()
    if len(combined) <= 430:
        set_val(simple_key, combined)
        print(f'  AmunRa{n}: SotM added ({len(combined)} chars)')
        fixes += 1
    else:
        print(f'  AmunRa{n}: too long ({len(combined)} chars), skipping')

print(f'\n=== {fixes} total fixes ===')
new_text = '\r\n'.join(lines)
with open(path, 'wb') as f:
    f.write(bom + new_text.encode('utf-8'))
print(f'BOM: OK')
