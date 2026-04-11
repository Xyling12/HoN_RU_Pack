import re
import zipfile

# Read translations
ru_lines = []
ru_dict = {}
ru_keys_idx = {}
with open(r'd:\Projects\HoN_RU_Pack\bundle\entities_en.str', 'rb') as f:
    text = f.read().decode('utf-8')
    ru_lines = text.split('\r\n')
    for i, line in enumerate(ru_lines):
        if '\t' in line:
            parts = line.split('\t')
            ru_dict[parts[0]] = parts[-1]
            ru_keys_idx[parts[0]] = i

# Read english
en_dict = {}
z = zipfile.ZipFile(r'C:\Users\Maxim\AppData\Local\Juvio\heroes of newerth\resources0.jz')
new_text = z.read('stringtables/entities_en.str')
if new_text.startswith(b'\xef\xbb\xbf'): new_text = new_text[3:]
new_text = new_text.decode('utf-8')
for line in new_text.split('\r\n'):
    if '\t' in line:
        parts = line.split('\t')
        en_dict[parts[0]] = parts[-1]

fixes = 0

for k, en_v in en_dict.items():
    if k in ru_dict:
        ru_v = ru_dict[k]
        en_vars = re.findall(r'\{[^\}]+\}', en_v)
        ru_vars = re.findall(r'\{[^\}]+\}', ru_v)
        
        en_set = set(en_vars)
        ru_set = set(ru_vars)
        missing = en_set - ru_set
        
        important_missing = [x for x in missing if any(c.isdigit() for c in x)]
        if important_missing:
            new_ru_v = ru_v
            for var in important_missing:
                inner = var.strip('{}')
                # Create permutations that translators might have used
                slash_vers = inner.replace(',', '/')
                spaced_slash = inner.replace(',', ' / ')
                comma_space = inner.replace(',', ', ')
                spaced_dash = inner.replace(',', ' - ')
                
                new_ru_v = new_ru_v.replace(slash_vers, var)
                new_ru_v = new_ru_v.replace(spaced_slash, var)
                new_ru_v = new_ru_v.replace(comma_space, var)
                new_ru_v = new_ru_v.replace(spaced_dash, var)
                # Simple comma replace! Sometimes they just left commas without brackets.
                new_ru_v = new_ru_v.replace(inner, var)

            if new_ru_v != ru_v:
                fixes += 1
                ru_dict[k] = new_ru_v
                old_line = ru_lines[ru_keys_idx[k]]
                prefix = old_line[:old_line.rfind('\t')+1]
                ru_lines[ru_keys_idx[k]] = prefix + new_ru_v

print(f"Automatically fixed {fixes} strings!")

with open(r'd:\Projects\HoN_RU_Pack\bundle\entities_en.str', 'wb') as f:
    f.write('\r\n'.join(ru_lines).encode('utf-8'))
