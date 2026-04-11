# comprehensive_sotm_fix.py
# 1. For all description2:ult_boost keys with value '\r' — copy from base description2
# 2. Fix Pearl name "Жемчуг" -> "Перл"  
# 3. Add missing Thunderbringer4 SotM description
# 4. Fix Revenant4 description overflow
# 5. Fix typo "Ssence Shroud" -> "Essence Shroud"

import sys, re
sys.stdout.reconfigure(encoding='utf-8')

path = r'd:\HoN_RU_Pack\bundle\entities_en.str'
with open(path, 'rb') as f: data = f.read()
bom = b'\xef\xbb\xbf'
assert data.startswith(bom)

text = data[3:].decode('utf-8')
lines = text.split('\r\n')

# Build a dict of key -> (line_index, value)
key_to_idx = {}
for i, line in enumerate(lines):
    if '\t' not in line:
        continue
    key = line.split('\t')[0].strip()
    key_to_idx[key] = i

def get_val(key):
    if key not in key_to_idx:
        return None
    line = lines[key_to_idx[key]]
    parts = line.split('\t', 1)
    return parts[1] if len(parts) > 1 else ''

def set_val(key, new_val):
    if key not in key_to_idx:
        return False
    i = key_to_idx[key]
    tab_prefix = lines[i].split('\t', 1)[0]  # preserve original key column
    lines[i] = tab_prefix + '\t' + new_val.lstrip('\t')
    return True

fixes = 0

# ─── 1. Copy base description2 to empty :ult_boost variants ───────────────────
EMPTY_VALS = {'\\r', '\\\\r', '\r', ''}
for key, idx in list(key_to_idx.items()):
    if not (':ult_boost' in key or ':Yogi_BoobooAlive_Sotm' in key or ':shellshock_ability2_ShootDelay_Sotm' in key):
        continue
    if 'description2' not in key:
        continue
    val = (get_val(key) or '').strip()
    if val not in EMPTY_VALS:
        continue
    # Find base key (without variant suffix)
    base_key = key.split(':')[0]
    base_val = get_val(base_key)
    if base_val is None:
        continue
    base_stripped = base_val.strip()
    if not base_stripped or base_stripped in EMPTY_VALS:
        continue
    # Copy base value to variant
    set_val(key, base_val)
    fixes += 1
    # print(f"  Copied: {key} <- {base_key}")

print(f"SotM ult_boost fixes: {fixes}")

# ─── 2. Fix "Жемчуг" -> "Перл" ────────────────────────────────────────────────
pearl_fixes = 0
for i, line in enumerate(lines):
    if '\t' not in line:
        continue
    key = line.split('\t')[0].strip()
    if not key.startswith('Ability_Pearl') and not key.startswith('State_Pearl'):
        continue
    val = line.split('\t', 1)[1]
    newval = val.replace('Жемчугу', 'Перлу').replace('Жемчуг', 'Перл').replace('жемчуга', 'Перла').replace('жемчуг', 'Перл')
    if newval != val:
        tab_prefix = line.split('\t', 1)[0]
        lines[i] = tab_prefix + '\t' + newval.lstrip('\t')
        pearl_fixes += 1

print(f"Жемчуг->Перл fixes: {pearl_fixes}")

# ─── 3. Add missing Thunderbringer4 SotM description ─────────────────────────
TB4_KEY = 'Ability_Thunderbringer4_description2'
if TB4_KEY not in key_to_idx:
    # Insert after Thunderbringer4_description_simple
    for j, line in enumerate(lines):
        if 'Ability_Thunderbringer4_description_simple' in line and '\t' in line:
            insert_after = j
            break
    else:
        insert_after = None
    if insert_after is not None:
        tb4_sotm = (
            '^gПосох Мастера:^* Грозовое облако выпускает дополнительные '
            'молниеносные удары. Дальность цепной молнии и радиус действия '
            'Громоотвода увеличены. Замедление скор. движ. от Громоотвода '
            'увеличивается до ^o40%^*.'
        )
        new_line = 'Ability_Thunderbringer4_description2\t\t\t\t\t' + tb4_sotm
        lines.insert(insert_after + 1, new_line)
        key_to_idx[TB4_KEY] = insert_after + 1
        fixes += 1
        print(f"Added Thunderbringer4 SotM")
    else:
        print("Thunderbringer4 base key not found for insertion!")
else:
    print(f"Thunderbringer4_description2 already exists")

# ─── 4. Shorten Revenant4 description_simple ──────────────────────────────────
REV_KEY = 'Ability_Revenant4_description_simple'
rev_old = (
    'Увеличивает ^oСкор. движ. на 10%^* для целей, на которые действует ^oEssence Shroud^*. '
    'Теперь вы можете использовать все свои способности, находясь под действием ^oSsence Shroud^*, '
    'и получить ^o{6,12,18} Интеллекта^*.\\n\\n'
    '^oРеплицирует ваши способности на^* {0,1,2} доп. цели в радиусе действия.\\n\\n'
    'Этот навык можно ^oулучшить на уровнях 4, 8 и 12^*.\\n\\n'
    '^gПосох Мастера:^* увеличьте прирост интеллекта до {12,18,24} и уровень этой способности на единицу, вплоть до уровня 4.\\n'
    'На уровне 4 Манифестации ваши способности реплицируются на 4 дополнительных целей в радиусе действия.'
)
rev_new = (
    'Даёт ^o+10% Скор. движ.^* целям под ^oEssence Shroud^*. '
    'Позволяет использовать все способности под ^oEssence Shroud^* и даёт ^o+{6,12,18} Интеллекта^*.\\n\\n'
    '^oСпособности реплицируются^* на {0,1,2} доп. цели в радиусе.\\n'
    'Улучшается на уровнях 4, 8 и 12.\\n\\n'
    '^gПосох Мастера:^* +интеллект до {12,18,24}, +1 уровень способности (макс. 4). '
    'На ур.4: репликация на 4 цели.'
)
if set_val(REV_KEY, rev_new):
    print(f"Revenant4 shortened")

# Fix typo "Ssence Shroud" -> "Essence Shroud" in ult_boost variant
ult_key = 'Ability_Revenant4_description_simple:ult_boost'
if ult_key in key_to_idx:
    val = get_val(ult_key) or ''
    if val and 'Ssence' in val:
        set_val(ult_key, val.replace('Ssence Shroud', 'Essence Shroud'))
        print("Fixed Ssence Shroud typo in ult_boost")

# Global Ssence typo fix
typo_fixes = 0
for i, line in enumerate(lines):
    if 'Ssence Shroud' in line:
        lines[i] = line.replace('Ssence Shroud', 'Essence Shroud')
        typo_fixes += 1
print(f"Ssence->Essence fixes: {typo_fixes}")

# ─── Write ────────────────────────────────────────────────────────────────────
new_text = '\r\n'.join(lines)
with open(path, 'wb') as f:
    f.write(bom + new_text.encode('utf-8'))

with open(path, 'rb') as f: h = f.read(3)
print(f"BOM: {'OK' if h == bom else 'WRONG!'}")
print(f"Total fixes: {fixes}")
