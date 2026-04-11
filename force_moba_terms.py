import os

entities_path = r'd:\HoN_RU_Pack\bundle\entities_en.str'

with open(entities_path, 'rb') as f:
    data = f.read()

text = data.decode('utf-8-sig')

replacements = [
    ('^oally^*', '^oсоюзник^*'),
    ('^oallies^*', '^oсоюзники^*'),
    (' ally ', ' союзник '),
    (' allies ', ' союзники '),
    ('^oDebuffs^*', '^oотрицательные эффекты^*'),
    ('^oDebuff^*', '^oотрицательный эффект^*'),
    (' Debuffs', ' отрицательные эффекты'),
    (' Debuff', ' отрицательный эффект'),
    ('^oBuffs^*', '^oположительные эффекты^*'),
    ('^oBuff^*', '^oположительный эффект^*'),
    (' Buffs', ' положительные эффекты'),
    (' Buff', ' положительный эффект'),
    ('CD:', 'Перезарядка:'),
    ('Диапазон:', 'Дальность:'),
    ('Затраты маны:', 'Мана:'),
]

changed = 0
for old, new in replacements:
    count = text.count(old)
    if count > 0:
        text = text.replace(old, new)
        changed += count
        print(f"Replaced {count} instances of {old}")

if changed > 0:
    new_data = b'\xef\xbb\xbf' + text.encode('utf-8')
    with open(entities_path, 'wb') as f:
        f.write(new_data)
    print(f"Applied {changed} text replacements.")
else:
    print("No matches found.")
