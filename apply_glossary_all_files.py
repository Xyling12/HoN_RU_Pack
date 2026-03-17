# apply_glossary_all_files.py
# Uses official translate-str.md workflow glossary and rules.
# ENCODING RULES (from project-context.md):
#   - entities_en.str: MUST have BOM (EF BB BF)
#   - All others: MUST NOT have BOM
#   - Only byte replacement. No text-mode re-encoding.

import os

BUNDLE = r'd:\HoN_RU_Pack\bundle'

def apply(filepath, replacements, needs_bom):
    with open(filepath, 'rb') as f:
        data = f.read()

    bom = b'\xef\xbb\xbf'
    if needs_bom and not data.startswith(bom):
        data = bom + data
    elif not needs_bom and data.startswith(bom):
        data = data[3:]

    total = 0
    log = []
    for old_str, new_str in replacements:
        old = old_str.encode('utf-8')
        new = new_str.encode('utf-8')
        count = data.count(old)
        if count:
            data = data.replace(old, new)
            total += count
            log.append(f"  [{count:4}x] {old_str!r}")
    
    with open(filepath, 'wb') as f:
        f.write(data)
    return total, log


# ================================================
# OFFICIAL GLOSSARY (from translate-str.md)
# ================================================
CORE_GLOSSARY = [
    # Stats (from glossary table)
    ('Attack Speed',         'Скорость атаки'),
    ('Movement Speed',       'Скорость движения'),
    ('Magic Armor',          'Магическая броня'),
    # NOTE: "Health", "Mana", "Damage", "Armor", "Stun", etc. are already translated upstream

    # Abbreviated stats (from UI-Fit section) — apply consistently
    ('магического урона',    'маг. урона'),
    ('физического урона',    'физ. урона'),
    ('чистого урона',        'чист. урона'),
    ('истинного урона',      'чист. урона'),
    ('скорость передвижения','скор. движ.'),
    ('скорость движения',    'скор. движ.'),
    ('скорости передвижения','скор. движ.'),
    ('скорости движения',    'скор. движ.'),
    ('Скорость передвижения','Скор. движ.'),
    ('Скорость движения',    'Скор. движ.'),
    ('скорость атаки',       'скор. атаки'),
    ('скорости атаки',       'скор. атаки'),
    ('Скорость атаки',       'Скор. атаки'),
    ('максимального здоровья','макс. здоровья'),
    ('текущего здоровья',    'тек. здоровья'),
    ('МаксПоинтов',          'макс.'),           # edge case
    ('регенерация здоровья', 'реген. ХП'),
    ('регенерацию здоровья', 'реген. ХП'),
    ('регенерацию маны',     'реген. маны'),
    ('регенерация маны',     'реген. маны'),

    # Mechanics (from "Перевод внутренних механик" section)
    # NOTE: official glossary says "существ" NOT "юнитов"!
    ('^oTree/Unitwalking^*',    '^oпрохождение сквозь деревья и существ^*'),
    ('^oTreewalking^*',         '^oпрохождение сквозь деревья^*'),
    ('^oUnitwalking^*',         '^oпрохождение сквозь существ^*'),
    ('^oUnitWalking^*',         '^oпрохождение сквозь существ^*'),
    ('^oClearvision^*',         '^oбеспрепятственный обзор^*'),
    ('^oClearVision^*',         '^oбеспрепятственный обзор^*'),
    ('^oTruestrike^*',          '^oТочный удар^*'),
    ('^oTrueStrike^*',          '^oТочный удар^*'),
    ('^oMana Steal^*',          '^oПохищение маны^*'),
    ('^oShadow Walk^*',         '^oШаг в тень^*'),
    # Without tags
    ('Tree/Unitwalking',        'прохождение сквозь деревья и существ'),
    ('Treewalking',             'прохождение сквозь деревья'),
    ('TreeWalking',             'прохождение сквозь деревья'),
    ('Unitwalking',             'прохождение сквозь существ'),
    ('UnitWalking',             'прохождение сквозь существ'),
    ('Clearvision',             'беспрепятственный обзор'),
    ('ClearVision',             'беспрепятственный обзор'),
    ('Truestrike',              'Точный удар'),
    ('TrueStrike',              'Точный удар'),
    ('Mana Steal',              'Похищение маны'),

    # English artifacts in descriptions (NOT in Popup_* keys)
    ('^oally^*',                '^oсоюзник^*'),
    ('^oallies^*',              '^oсоюзники^*'),
    ('^oDebuffs^*',             '^oотрицательные эффекты^*'),
    ('^oDebuff^*',              '^oотрицательный эффект^*'),
    ('^oBuffs^*',               '^oположительные эффекты^*'),
    ('^oBuff^*',                '^oположительный эффект^*'),
]

# Glossary for game_messages and client_messages — keep short, no CC term changes
MESSAGES_GLOSSARY = [
    ('Courier',    'Курьер'),
    ('courier',    'курьер'),
    ('Ward',       'Вард'),
    ('ward',       'вард'),
    ('Deny',       'Отказ'),
    ('deny',       'отказ'),
]

# ================================================
# FILE-SPECIFIC CONFIGS
# ================================================
files = [
    {
        'name': 'entities_en.str',
        'bom': True,
        'glossary': CORE_GLOSSARY,
    },
    {
        'name': 'interface_en.str',
        'bom': False,
        'glossary': [
            # UI-specific fixes only (no description mechanics here)
            ('^oally^*',       '^oсоюзник^*'),
        ],
    },
    {
        'name': 'game_messages_en.str',
        'bom': False,
        'glossary': MESSAGES_GLOSSARY,
    },
    {
        'name': 'client_messages_en.str',
        'bom': False,
        'glossary': MESSAGES_GLOSSARY,
    },
    {
        'name': 'bot_messages_en.str',
        'bom': False,
        'glossary': MESSAGES_GLOSSARY,
    },
]

grand_total = 0
report_lines = []

for cfg in files:
    path = os.path.join(BUNDLE, cfg['name'])
    total, log = apply(path, cfg['glossary'], cfg['bom'])
    grand_total += total
    report_lines.append(f"\n### {cfg['name']}: {total} замен")
    report_lines.extend(log if log else ['  (ничего не изменилось)'])
    print(f"[{cfg['name']}]: {total} replacements")
    for l in log:
        print(l)

# BOM verification pass
print("\n=== BOM Verification ===")
report_lines.append("\n### BOM проверка")
for cfg in files:
    path = os.path.join(BUNDLE, cfg['name'])
    with open(path, 'rb') as f:
        header = f.read(3)
    has_bom = (header == b'\xef\xbb\xbf')
    ok = (has_bom == cfg['bom'])
    status = "OK" if ok else "WRONG!!!"
    msg = f"  {cfg['name']}: BOM={has_bom}, expected={cfg['bom']} -> {status}"
    print(msg)
    report_lines.append(msg)

# Save report
report_path = r'd:\HoN_RU_Pack\glossary_report.txt'
with open(report_path, 'w', encoding='utf-8') as f:
    f.write(f"# Glossary Application Report\n")
    f.write(f"Total replacements: {grand_total}\n")
    f.write('\n'.join(report_lines))
print(f"\nReport saved to {report_path}")
print(f"Grand total: {grand_total} replacements")
