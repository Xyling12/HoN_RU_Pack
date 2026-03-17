# compress_descriptions.py
# Compresses ability AND item descriptions in entities_en.str
# RULES: byte-safe (BOM preserved), numbers/colors never touched,
#        only description/flavor/info value fields are modified.

import re

entities_path = r'd:\HoN_RU_Pack\bundle\entities_en.str'

# ── Description key suffixes to process ───────────────────────────────────────
DESCRIPTION_KEYS = (
    '_description',
    '_description_simple',
    '_IMPACT_effect',
    '_FRAME_effect',
    '_tooltip_flavor',
    '_info',        # Item info fields
    '_lore',
    '_passive',
    '_active',
)

# ── Official abbreviations from translate-str.md + common verbose patterns ────
# Order matters: more specific patterns first.
ABBREVS = [
    # Damage types
    ('магического урона',   'маг. урона'),
    ('магический урон',     'маг. урон'),
    ('физического урона',   'физ. урона'),
    ('физический урон',     'физ. урон'),
    ('чистого урона',       'чист. урона'),
    ('истинного урона',     'чист. урона'),
    ('чистый урон',         'чист. урон'),

    # Speed stats
    ('скорость передвижения', 'скор. движ.'),
    ('скорости передвижения', 'скор. движ.'),
    ('скорость движения',   'скор. движ.'),
    ('скорости движения',   'скор. движ.'),
    ('Скорость передвижения','Скор. движ.'),
    ('Скорость движения',   'Скор. движ.'),
    ('скорость атаки',      'скор. атаки'),
    ('скорости атаки',      'скор. атаки'),
    ('Скорость атаки',      'Скор. атаки'),

    # HP/Mana
    ('максимального здоровья',  'макс. здоровья'),
    ('максимальное здоровье',   'макс. здоровье'),
    ('максимальную ману',       'макс. ману'),
    ('максимальной маны',       'макс. маны'),
    ('регенерацию здоровья',    'реген. ХП'),
    ('регенерация здоровья',    'Реген. ХП'),
    ('регенерацию маны',        'реген. маны'),
    ('регенерация маны',        'Реген. маны'),
    ('текущего здоровья',       'тек. здоровья'),

    # Armor / resistance
    ('магическую броню',        'маг. броню'),
    ('магическая броня',        'маг. броня'),
    ('магической брони',        'маг. брони'),
    ('сопротивление магии',     'сопрот. магии'),
    ('сопротивления магии',     'сопрот. магии'),

    # Time words used in context (only at sentence end or inside clauses)
    (' секунды',    ' сек.'),
    (' секунду',    ' сек.'),
    (' секунд ',    ' сек. '),
    (' секунд.',    ' сек.'),
    (' секунд\r',   ' сек.\r'),
    ('секундой',    'сек.'),
    (' минуты',     ' мин.'),
    (' минуту',     ' мин.'),
    (' минут ',     ' мин. '),

    # Verbose extra words
    ('дополнительного',     'доп.'),
    ('дополнительную',      'доп.'),
    ('дополнительные',      'доп.'),
    ('дополнительный',      'доп.'),
    ('ежесекундно',         'в сек.'),
    ('каждую секунду',      'в сек.'),
    ('каждые секун',        'каждые сек.'),   # edge

    # Area descriptions
    ('Дальность применения:', 'Дальность:'),
    ('дальность применения',  'дальность'),
]

# ── Load file ──────────────────────────────────────────────────────────────────
with open(entities_path, 'rb') as f:
    data = f.read()

bom = b'\xef\xbb\xbf'
assert data.startswith(bom), "BOM missing — abort!"

text = data[3:].decode('utf-8', errors='replace')
lines = text.split('\r\n')

changed_count = 0
char_saved = 0
report_lines = []

for i, line in enumerate(lines):
    if '\t' not in line:
        continue
    tab_pos = line.index('\t')
    key = line[:tab_pos].strip()
    
    # Only process description-type keys
    if not any(key.endswith(suffix) for suffix in DESCRIPTION_KEYS):
        continue
    
    value = line[tab_pos:]  # keep all tabs + value
    orig_value = value
    
    for old, new in ABBREVS:
        value = value.replace(old, new)
    
    if value != orig_value:
        saved = len(orig_value.encode('utf-8')) - len(value.encode('utf-8'))
        char_saved += saved
        changed_count += 1
        lines[i] = key + value
        report_lines.append(f"  [{key}] -{saved}b")

# ── Write back ─────────────────────────────────────────────────────────────────
new_text = '\r\n'.join(lines)
new_data = bom + new_text.encode('utf-8')

with open(entities_path, 'wb') as f:
    f.write(new_data)

# ── Report ─────────────────────────────────────────────────────────────────────
report_path = r'd:\HoN_RU_Pack\compression_report.txt'
with open(report_path, 'w', encoding='utf-8') as f:
    f.write(f"# Compression Report — entities_en.str\n")
    f.write(f"Lines changed: {changed_count}\n")
    f.write(f"Bytes saved: {char_saved}\n\n")
    f.write('\n'.join(report_lines))

print(f"Done. {changed_count} lines shortened, ~{char_saved} bytes saved.")
print(f"Report: {report_path}")
# Verify BOM
with open(entities_path,'rb') as f: h=f.read(3)
print(f"BOM check: {'OK' if h==bom else 'WRONG!'}")
