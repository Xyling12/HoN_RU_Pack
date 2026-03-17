# fix_channel_cleanup.py — fix leftovers after channel term replacement
import sys
sys.stdout.reconfigure(encoding='utf-8')

path = r'd:\HoN_RU_Pack\bundle\entities_en.str'
with open(path,'rb') as f: data=f.read()
bom = b'\xef\xbb\xbf'
text = data[3:].decode('utf-8')

# Also remaining "поддержание" that was missed
replacements = [
    # Awkward combos from chained replacements
    ('Концентрируется вражеский отряд языком', 'Удерживает виагу языком'),  # Pollywog = tongue grab
    ('Концентрируется вражеский отряд языком', 'Держит врага на языке'),
    ('Концентрация до срок до', 'Концентрация до'),
    ('Концентрация до Концентрации до', 'Концентрация до'),
    ('удерживать концентрацию', 'концентрироваться'),
    ('не нарушая .* концентрацию', 'не прерывая концентрацию'),
    # Pollywog specific fix
    ('Концентрируется вражеский отряд', 'Удерживает врага'),
    # Rhapsody
    ('Концентрация до срок', 'Концентрация до'),
    # Remaining "поддержание" / "Поддержание"
    ('Поддержание на срок до', 'Концентрация до'),
    ('поддержание на срок до', 'концентрация до'),
    ('не нарушая ^* поддержание', 'не прерывая концентрацию'),
    ('не нарушая^* поддержание', 'не прерывая концентрацию'),
    ('не нарушая поддержание', 'не прерывая концентрацию'),
    ('канализации', 'концентрации'),  # catch any remaining
    ('Канализации', 'концентрации'),
]

fixes = 0
for old, new in replacements:
    if old in text:
        cnt = text.count(old)
        text = text.replace(old, new)
        fixes += cnt
        print(f'  {cnt}x  {old!r} → {new!r}')

# Now specifically fix Pollywog Priest 3
old_pp = 'Концентрируется вражеский отряд языком на'
new_pp = 'Удерживает врага языком на'
if old_pp in text:
    text = text.replace(old_pp, new_pp)
    fixes += 1
    print(f'  Pollywog fix: OK')

print(f'\nTotal cleanup: {fixes}')
with open(path,'wb') as f:
    f.write(bom + text.encode('utf-8'))
print('BOM:', 'OK' if open(path,'rb').read(3)==bom else 'WRONG')
