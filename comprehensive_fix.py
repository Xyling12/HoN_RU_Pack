# comprehensive_fix.py
# 1. Fixes English artifacts in ability/item descriptions
# 2. Applies smart abbreviations to shorten all long descriptions
# Targets entities_en.str — BOM MUST be preserved.

import sys, re
sys.stdout.reconfigure(encoding='utf-8')

path = r'd:\HoN_RU_Pack\bundle\entities_en.str'
with open(path, 'rb') as f: data = f.read()
bom = b'\xef\xbb\xbf'
assert data.startswith(bom), "BOM missing!"

text = data[3:].decode('utf-8', errors='replace')
lines = text.split('\r\n')

DESC_SUFFIXES = ('_description_simple', '_description', '_IMPACT_effect', '_FRAME_effect', '_info')

# ── 1. Terminology fixes (English artifacts + bad machine translation) ──────────

TERM_FIXES = [
    # CC mechanics (apply only in value context)
    (' Silence ',        ' Безмолвие '),
    ('^oSilence^*',      '^oБезмолвие^*'),
    (' Silenced ',       ' в Безмолвии '),
    ('Mini-Stun',        'Мини-оглушение'),
    ('Mini Stun',        'Мини-оглушение'),
    ('^oMini-Stun^*',    '^oМини-оглушение^*'),
    ('Unitwalking',      'прохождение сквозь существ'),
    ('Treewalking',      'прохождение сквозь деревья'),
    ('Clearvision',      'ясное зрение'),
    ('Truestrike',       'точный удар'),
    ('True Strike',      'Точный удар'),
    (' Bash ',           ' Оглушение '),
    ('^yBash^*',         '^yОглушение^*'),

    # Item/stat terms
    ('Lifesteal',        'вампиризм'),
    ('Magic Damage',     'маг. урон'),
    ('Magic Armor',      'маг. броня'),
    ('Attack Speed',     'скор. атаки'),
    ('Movement Speed',   'скор. движ.'),
    ('Damage Shield',    'щит урона'),
    ('^oDamage Shield',  '^oщит урона'),
    (' Armor ',          ' броня '),

    # HP/Health in plain English
    ('} Health^*',       '} ХП^*'),
    ('} Health ',        '} ХП '),
    (' Health^*',        ' ХП^*'),
    (' Health ',         ' ХП '),

    # Abbreviations for wordy stat names already not caught by compress_descriptions
    ('Скорость сотворения',  'скор. каста'),
    ('Регенерация здоровья', 'реген. ХП'),
    ('Регенерацию здоровья', 'реген. ХП'),
    ('регенерация здоровья', 'реген. ХП'),
    ('регенерацию здоровья', 'реген. ХП'),
    ('Регенерация маны',     'реген. маны'),
    ('регенерация маны',     'реген. маны'),
    ('базового урона',       'баз. урона'),
    ('базовый урон',         'баз. урон'),
    ('базового атаки',       'баз. атаки'),
    ('процента здоровья',    '% ХП'),
    ('процент здоровья',     '% ХП'),

    # Verbose directions/particles
    ('в течение ',           'на '),   # "на X сек." is more natural than "в течение X сек."
    ('в течение^o',          'на^o'),
    # CAREFUL: don't replace "в течение" inside numeric values with caret
]

changed_lines = 0
changed_terms = 0

for i, line in enumerate(lines):
    if '\t' not in line:
        continue
    key = line.split('\t')[0].strip()
    if not any(key.endswith(s) for s in DESC_SUFFIXES):
        continue
    
    val = line.split('\t', 1)[1]
    orig_val = val
    
    for old, new in TERM_FIXES:
        val = val.replace(old, new)
    
    if val != orig_val:
        lines[i] = key + '\t' + val.lstrip('\t')
        # Restore the original tab structure
        tab_part = line.split('\t', 1)[0]
        rest = line[len(tab_part):]  # keep all tabs from original key-col
        val_only = rest.lstrip('\t')
        new_val = val.lstrip('\t')
        lines[i] = tab_part + rest[:len(rest)-len(val_only)] + new_val
        changed_terms += val.count('') - orig_val.count('')  # rough count
        changed_lines += 1

total_changed = changed_lines
print(f"Term/abbreviation fixes: {changed_lines} lines")

# ── 2. Write back ──────────────────────────────────────────────────────────────
new_text = '\r\n'.join(lines)
new_data = bom + new_text.encode('utf-8')
with open(path, 'wb') as f:
    f.write(new_data)

with open(path, 'rb') as f: h = f.read(3)
print(f"BOM: {'OK' if h == bom else 'WRONG!'}")
print(f"Total: {total_changed} description lines improved")
