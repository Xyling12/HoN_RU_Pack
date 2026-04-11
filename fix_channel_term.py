# fix_channel_term.py — replace wrong "удержание" (holding) with "концентрация" (channeling)
import sys
sys.stdout.reconfigure(encoding='utf-8')

path = r'd:\HoN_RU_Pack\bundle\entities_en.str'
with open(path,'rb') as f: data=f.read()
bom = b'\xef\xbb\xbf'
text = data[3:].decode('utf-8')

# Channel in HoN = click → stand still, moving breaks it
# Best Russian equivalent: "концентрация" (noun), "концентрируется" (verb)
replacements = [
    # Imperatives (descriptions address player)
    ('Удерживай активацию, чтобы', 'Концентрируйся:'),
    ('Удерживай активацию:', 'Концентрируйся:'),
    ('Удерживай, нагревая', 'Концентрируется — нагревает'),
    ('Удерживай, осыпая', 'Концентрируется — осыпает'),
    ('Удерживай активацию', 'Концентрируйся'),
    ('Удерживай до', 'Концентрируется до'),
    ('Удерживай', 'Концентрируется'),
    # Verbs (third person)
    ('Удерживает', 'Концентрируется'),
    ('удерживает', 'концентрируется'),
    ('Удерживая', 'Концентрируясь'),
    ('удерживая', 'концентрируясь'),
    # Nouns
    ('Удержание Камня', 'Чтение Камня'),
    ('Удержание Post', 'Чтение Post'),
    ('Удержание Home', 'Чтение Home'),
    ('Удержание занимает', 'Чтение занимает'),
    ('Удержание до', 'Концентрация до'),
    ('Удержание', 'Концентрация'),
    ('удержания', 'концентрации'),
    ('удержание', 'концентрацию'),
    # Cleanup leftover awkward combos
    ('после разрыва концентрации', 'после прерывания'),
    ('после концентрации', 'после применения'),
    ('разрыв концентрации', 'прерывание'),
    ('разрыва концентрации', 'прерывания'),
    ('Сек. концентрации', 'Сек. чтения'),
    ('сек. концентрации', 'сек. чтения'),
]

fixes = 0
for old, new in replacements:
    if old in text:
        cnt = text.count(old)
        text = text.replace(old, new)
        fixes += cnt
        print(f'  {cnt}x  {old!r} → {new!r}')

print(f'\nTotal: {fixes} replacements')
with open(path,'wb') as f:
    f.write(bom + text.encode('utf-8'))

h = open(path,'rb').read(3)
print('BOM OK' if h == bom else 'BOM WRONG')
