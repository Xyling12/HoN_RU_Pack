# audit_text_quality.py — sample all 3 text categories for quality review
import sys, re
sys.stdout.reconfigure(encoding='utf-8')

path = r'd:\HoN_RU_Pack\bundle\entities_en.str'
with open(path,'rb') as f: data=f.read()
bom = b'\xef\xbb\xbf'
text = data[3:].decode('utf-8')
lines = text.split('\r\n')

ability_descs = {}   # key -> val_clean
hero_lore = {}
item_descs = {}

pat_clean = re.compile(r'\^[a-zA-Z!]')

for line in lines:
    if '\t' not in line: continue
    key = line.split('\t')[0].strip()
    if ':' in key: continue
    val = line.split('\t',1)[1].strip()
    val_c = pat_clean.sub('',val).replace('\\n',' ').strip()

    if '_description_simple' in key:
        ability_descs[key] = val_c
    elif '_flavortext' in key:
        hero_lore[key] = val_c
    elif '_description' in key and '_description_simple' not in key:
        # Could be hero or item desc
        if 'Item_' in key or 'Recipe_' in key or 'Token_' in key or 'Homebrew_' in key:
            item_descs[key] = val_c
        else:
            hero_lore[key] = val_c

out = []

# === SECTION 1: ABILITY DESCRIPTIONS - machine phrases ===
out.append('='*70)
out.append('SECTION 1: ABILITY DESCRIPTIONS — machine-style phrases')
out.append('='*70)
BAD_PHRASES = [
    'Активируйте, чтобы',
    'Предоставляет',
    'Выберите поддержание',
    'Выберите локацию',
    'Нацельтесь на',
    'Переключаемый',
    'Обеспечивает',
    'Дает вам',
    'Дает вашим',
    'Переключите',
    'Выберите врага',
    'Выберите место',
    'Выберите область',
    'Выберите отряд',
    'Направьте',
]
for phrase in BAD_PHRASES:
    matching = [(k,v) for k,v in ability_descs.items() if phrase in v]
    if not matching: continue
    out.append(f'\n--- "{phrase}" ({len(matching)} описаний) ---')
    for k,v in matching[:3]:  # show 3 samples per phrase
        hero = k.replace('Ability_','').replace('_description_simple','')
        out.append(f'  [{hero}] {v[:200]}')

# === SECTION 2: HERO LORE ===
out.append('\n' + '='*70)
out.append('SECTION 2: HERO LORE / FLAVORTEXT')
out.append('='*70)
out.append(f'Total lore entries: {len(hero_lore)}')
for k,v in list(hero_lore.items())[:20]:
    out.append(f'\n[{k}]')
    out.append(f'  {v[:300]}')

# === SECTION 3: ITEM DESCRIPTIONS ===
out.append('\n' + '='*70)
out.append('SECTION 3: ITEM DESCRIPTIONS')
out.append('='*70)
out.append(f'Total item desc entries: {len(item_descs)}')
for k,v in list(item_descs.items())[:20]:
    out.append(f'\n[{k}]')
    out.append(f'  {v[:300]}')

report = '\n'.join(out)
with open(r'd:\HoN_RU_Pack\text_quality_audit.txt','w',encoding='utf-8') as f:
    f.write(report)
print(f'ability_descs: {len(ability_descs)}, hero_lore: {len(hero_lore)}, item_descs: {len(item_descs)}')
print('Written: text_quality_audit.txt')
