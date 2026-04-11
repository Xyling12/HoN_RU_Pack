import re

abbrev_rules = {
    r'(?i)магического урона': 'маг. урона',
    r'(?i)физического урона': 'физ. урона',
    r'(?i)чистого урона': 'чист. урона',
    r'(?i)скорость передвижения': 'скор. движ.',
    r'(?i)скорость атаки': 'скор. атаки',
    r'(?i)максимального здоровья': 'макс. здоровья',
    r'(?i)текущего здоровья': 'тек. здоровья',
    r'(?i)регенераци[яию] здоровья': 'реген. ХП',
}

ru_lines = []
with open(r'd:\Projects\HoN_RU_Pack\bundle\entities_en.str', 'rb') as f:
    data = f.read()
    bom = b''
    if data.startswith(b'\xef\xbb\xbf'):
        bom = b'\xef\xbb\xbf'
        data = data[3:]
    text = data.decode('utf-8')
    ru_lines = text.split('\r\n')

fixes = 0
for i, line in enumerate(ru_lines):
    if '\t' in line:
        k, v = line.split('\t', 1)
        new_v = v
        for bad, good in abbrev_rules.items():
            new_v = re.sub(bad, good, new_v)
        if new_v != v:
            # preserve original tabs!
            ru_lines[i] = k + line[len(k):line.find(v)] + new_v
            fixes += 1

with open(r'd:\Projects\HoN_RU_Pack\bundle\entities_en.str', 'wb') as f:
    f.write(bom + '\r\n'.join(ru_lines).encode('utf-8'))

print(f"Fixed {fixes} terminology violations.")
