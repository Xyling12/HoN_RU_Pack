import re
import zipfile

# Read translations
ru_dict = {}
with open(r'd:\Projects\HoN_RU_Pack\bundle\entities_en.str', 'rb') as f:
    text = f.read().decode('utf-8')
    for line in text.split('\r\n'):
        if '\t' in line:
            parts = line.split('\t')
            ru_dict[parts[0]] = parts[-1]

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

broken = []
for k, en_v in en_dict.items():
    if k in ru_dict:
        ru_v = ru_dict[k]
        # find all {...} in en_v
        en_vars = re.findall(r'\{[^\}]+\}', en_v)
        ru_vars = re.findall(r'\{[^\}]+\}', ru_v)
        
        # We only care if english HAS something that Russian doesn't.
        # But maybe order differs or there are multiple. Just do a set comparison for simplicity.
        en_set = set(en_vars)
        ru_set = set(ru_vars)
        
        missing = en_set - ru_set
        
        # Ignored missing: {} (empty), {value} sometimes changed to numbers?
        # Let's just output if there are any {number,number...} that are missing.
        important_missing = [x for x in missing if any(c.isdigit() for c in x)]
        if important_missing:
            # check if it's actually hardcoded in ru_v
            # e.g. en_v has {10,20,30}, ru_v has "10/20/30"
            broken.append(f"{k}: Missing {important_missing}")

print(f"Found {len(broken)} strings where the translation breaks Scenario 1 by removing variables!")
if len(broken) > 0:
    with open('broken_scenario1.txt', 'w', encoding='utf-8') as f:
        f.write('\n'.join(broken))
