import zipfile
import re

ru_lines = []
ru_dict = {}
ru_keys_idx = {}
with open(r'd:\Projects\HoN_RU_Pack\bundle\entities_en.str', 'rb') as f:
    data = f.read()
    bom = b''
    if data.startswith(b'\xef\xbb\xbf'):
        bom = b'\xef\xbb\xbf'
        data = data[3:]
    text = data.decode('utf-8')
    ru_lines = text.split('\r\n')
    for i, line in enumerate(ru_lines):
        if '\t' in line:
            parts = line.split('\t')
            ru_dict[parts[0]] = parts[-1]
            ru_keys_idx[parts[0]] = i

en_dict = {}
z = zipfile.ZipFile(r'C:\Users\Maxim\AppData\Local\Juvio\heroes of newerth\resources0.jz')
new_text = z.read('stringtables/entities_en.str')
if new_text.startswith(b'\xef\xbb\xbf'): new_text = new_text[3:]
new_text = new_text.decode('utf-8')
for line in new_text.split('\r\n'):
    if '\t' in line:
        parts = line.split('\t')
        en_dict[parts[0]] = parts[-1]

target_prefixes = ('Hero_', 'Ability_', 'Item_', 'Familiar_', 'Pet_', 'Building_')

fixes = 0
for k, en_v in en_dict.items():
    if k.endswith('_name') and any(k.startswith(p) for p in target_prefixes):
        if k in ru_dict:
            ru_v = ru_dict[k]
            if ru_v != en_v:
                # We revert to English name
                old_line = ru_lines[ru_keys_idx[k]]
                prefix = old_line[:old_line.rfind('\t')+1]
                ru_lines[ru_keys_idx[k]] = prefix + en_v
                fixes += 1

print(f"Reverted {fixes} names back to exact English!")

with open(r'd:\Projects\HoN_RU_Pack\bundle\entities_en.str', 'wb') as f:
    f.write(bom + '\r\n'.join(ru_lines).encode('utf-8'))
