# batch_fix_round3.py — fixes all known description issues

import sys, re
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

# ── 1. Scout4 — remove duplicate SotM, keep only clean Russian version ───────
# The description_simple has: main_text + \n\n^gStaff Мастера^*... + \n\n^gЭта способность...
scout4_key = 'Ability_Scout4_description_simple'
scout4_val = get_val(scout4_key) or ''
if 'Staff' in scout4_val or 'Стафф' in scout4_val:
    # Remove everything from \n\n^gStaff onwards — we'll replace with clean SotM
    cut_idx = scout4_val.find('\\n\\n^gStaff')
    if cut_idx == -1:
        cut_idx = scout4_val.find('\\n\\n^gЭта способность может быть усилена')
    if cut_idx != -1:
        main_text = scout4_val[:cut_idx]
        sotm_clean = (
            '\\n\\n^gПосох Мастера:^* Позволяет использовать способность, '
            'не нарушая скрытности. Дальность атаки увеличивается до ^o3800^* ед. '
            'После попадания позволяет ^oпрыгнуть к цели^* на 3 сек.'
        )
        if set_val(scout4_key, main_text + sotm_clean):
            print(f"Scout4: fixed duplicate SotM, now {len(main_text + sotm_clean)} chars")
            fixes += 1

# ── 2. Fayde4 — shorten main body + SotM so total ≤ 420 chars ────────────────
fayde4_key = 'Ability_Fayde4_description_simple'
# New compact version
fayde4_new = (
    'Станьте тенью: ^oНевидимость {22,40,55} сек.^*, '
    '^oпрохождение сквозь деревья и существ^*, '
    '^o+15% Скор. движ.^*, ^o{800,1000,1200} Обзор^*.\\n\\n'
    '1-я атака: ^oМаг. урон {150,200,250} + {10,15,20}% от тек. ХП^* за 2 сек. '
    '+ ^oснижение лечения на {20,40,60}%^* на 4 сек.\\n\\n'
    '^gПосох Мастера:^* 1-я атака сохраняется 5 сек. после истечения Отражения. '
    'Отражение → ^g"Танец теней"^* (3 заряда): телепорт + Шаг в тень 1 сек. '
    'Доп. ^o0,6x^* DoT цели.'
)
if set_val(fayde4_key, fayde4_new):
    print(f"Fayde4: rewritten to {len(fayde4_new)} chars")
    fixes += 1

# ── 3. Revenant4 — much shorter version ──────────────────────────────────────
rev4_key = 'Ability_Revenant4_description_simple'
rev4_new = (
    '^o+10% Скор. движ.^* целям под ^oEssence Shroud^*. '
    'Позволяет применять способности под ^oEssence Shroud^*. '
    '^o+{6,12,18} Интеллекта^*.\\n\\n'
    '^oРепликация^* способностей на {0,1,2} доп. цели.\\n'
    'Улучшается на уровнях 4, 8 и 12.\\n\\n'
    '^gПосох Мастера:^* +{12,18,24} Интеллекта, +1 ур. способности (макс. 4). '
    'На ур.4: репликация на 4 цели.'
)
if set_val(rev4_key, rev4_new):
    print(f"Revenant4: rewritten to {len(rev4_new)} chars")
    fixes += 1

# ── 4. SirBenzington2 — shorten main + keep SotM visible ─────────────────────
sirb2_key = 'Ability_SirBenzington2_description_simple'
sirb2_val = get_val(sirb2_key) or ''
if 'Посох Мастера' in sirb2_val or 'Эффект посоха' in sirb2_val:
    # The SotM text is there but description is too long; just shorten the whole thing
    sirb2_new = (
        'Бафф на 4 сек.: ^oсбрасывает перезарядку атаки^*, '
        '^o+150 дальности атаки^*, каждая атака добавляет ^o{30,60,90,120} + {15,30,45,60} маг. урона^* '
        'следующей атаке.\\n\\n'
        'Каждая успешная атака добавляет ^o1^* заряд.\\n'
        'При 3 зарядах: ПКМ → авто-применение.\\n\\n'
        '^gПосох Мастера:^* Пассивно +250 дальности атаки и перезарядка сокращается до 5 сек.'
    )
    if set_val(sirb2_key, sirb2_new):
        print(f"SirBenzington2: rewrote to {len(sirb2_new)} chars")
        fixes += 1
else:
    # SotM text not there at all — append it
    desc2 = get_val('Ability_SirBenzington2_description2') or ''
    if desc2 and 'Посох' in desc2:
        sirb2_new = (
            'Бафф на 4 сек.: ^oсбрасывает перезарядку атаки^*, '
            '^o+150 дальности атаки^*, каждая атака добавляет ^o{30,60,90,120} + {15,30,45,60} маг. урона^* '
            'следующей атаке.\\n\\n'
            'Каждая успешная атака добавляет ^o1^* заряд.\\n'
            'При 3 зарядах: ПКМ → авто-применение.\\n\\n'
            '^gПосох Мастера:^* Пассивно +250 дальности атаки и перезарядка сокращается до 5 сек.'
        )
        if set_val(sirb2_key, sirb2_new):
            print(f"SirBenzington2: added SotM ({len(sirb2_new)} chars)")
            fixes += 1

# ── 5. Pharaoh4 — check and fix SotM ─────────────────────────────────────────
pharaoh4_key = 'Ability_Pharaoh4_description_simple'
pharaoh4_val = get_val(pharaoh4_key) or ''
if 'Посох' not in pharaoh4_val and 'Staff' not in pharaoh4_val:
    pharaoh4_desc2 = get_val('Ability_Pharaoh4_description2') or ''
    if pharaoh4_desc2 and 'Посох' in pharaoh4_desc2:
        # Extract just the effect text
        effect = pharaoh4_desc2.strip()
        if len(pharaoh4_val) + len(effect) + 4 < 500:
            new_val = pharaoh4_val.rstrip() + '\\n\\n' + effect
        else:
            # Shorten effect
            effect_short = re.sub(r'\^g[^\\^]*\^\\*\\n\\n\^g[Ээ]ффект посоха:\^\\*\s*', '', effect)
            new_val = pharaoh4_val.rstrip() + '\\n\\n^gПосох Мастера:^* ' + effect_short[:150]
        set_val(pharaoh4_key, new_val)
        print(f"Pharaoh4: SotM added ({len(new_val)} chars)")
        fixes += 1
    else:
        print(f"Pharaoh4: no description2 SotM found")
else:
    print(f"Pharaoh4: SotM already present")

# ── 6. Pollywog — check abilities ────────────────────────────────────────────
for abil_n in ['1', '2', '3', '4']:
    pw_key = f'Ability_Pollywog{abil_n}_description_simple'
    pw_val = get_val(pw_key) or ''
    if not pw_val: continue
    if 'Посох' in pw_val or 'Staff' in pw_val: 
        print(f"Pollywog{abil_n}: SotM already present")
        continue
    pw_desc2 = get_val(f'Ability_Pollywog{abil_n}_description2') or ''
    if pw_desc2 and 'Посох' in pw_desc2:
        effect = pw_desc2.strip()
        new_val = pw_val.rstrip() + '\\n\\n' + effect
        if len(new_val) < 500:
            set_val(pw_key, new_val)
            print(f"Pollywog{abil_n}: SotM added ({len(new_val)} chars)")
            fixes += 1

# ── 7. Amun Ra (he's mapped to Pharaoh entity with different key?) ────────────
# Amun Ra in HoN is actually 'AmunRa' hero - check that key
for abil_n in ['1', '2', '3', '4']:
    ar_key = f'Ability_AmunRa{abil_n}_description_simple'
    ar_val = get_val(ar_key) or ''
    if not ar_val: continue
    if 'Посох' in ar_val or 'Staff' in ar_val:
        print(f"AmunRa{abil_n}: SotM present")
        continue
    ar_desc2 = get_val(f'Ability_AmunRa{abil_n}_description2') or ''
    if ar_desc2 and 'Посох' in ar_desc2:
        effect = ar_desc2.strip()
        new_val = ar_val.rstrip() + '\\n\\n' + effect
        if len(new_val) < 500:
            set_val(ar_key, new_val)
            print(f"AmunRa{abil_n}: SotM added ({len(new_val)} chars)")
            fixes += 1

# ── 8. Run global pass for ANY remaining heroes where description_simple < 360 chars
#        and has no SotM but description2 does ───────────────────────────────────
for key in list(key_to_idx.keys()):
    if 'description2' not in key or ':' in key: continue
    if not (key.startswith('Ability_') or key.startswith('Item_')): continue
    desc2_val = (get_val(key) or '').strip()
    if 'Посох' not in desc2_val: continue

    base = key.replace('_description2', '')
    simple_key = base + '_description_simple'
    simple_val = get_val(simple_key)
    if simple_val is None: continue
    simple_stripped = simple_val.strip()
    if 'Посох' in simple_stripped or 'Staff' in simple_stripped: continue
    if not simple_stripped: continue

    # Only append if result would be short enough
    combined = simple_stripped.rstrip() + '\\n\\n' + desc2_val
    if len(combined) <= 420:
        set_val(simple_key, combined)
        hero = base.split('_')[1] if '_' in base else base
        print(f"  +SotM: {hero}")
        fixes += 1

print(f"\n=== Total: {fixes} fixes ===")

new_text = '\r\n'.join(lines)
with open(path, 'wb') as f:
    f.write(bom + new_text.encode('utf-8'))
with open(path, 'rb') as f: h = f.read(3)
print(f"BOM: {'OK' if h == bom else 'WRONG!'}")
