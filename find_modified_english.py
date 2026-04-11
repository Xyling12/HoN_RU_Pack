import zipfile

old_dict = {}
with open(r'd:\Projects\HoN_RU_Pack\entities_v15.str', 'rb') as f:
    text_data = f.read()
    try:
        text = text_data.decode('utf-8-sig') # tries utf-8 with bom
    except UnicodeDecodeError:
        text = text_data.decode('utf-16') # tries utf-16
        
    for line in text.split('\r\n'):
        if '\t' in line:
            parts = line.split('\t')
            old_dict[parts[0]] = parts[-1]

z = zipfile.ZipFile(r'C:\Users\Maxim\AppData\Local\Juvio\heroes of newerth\resources0.jz')
new_text = z.read('stringtables/entities_en.str')
if new_text.startswith(b'\xef\xbb\xbf'): new_text = new_text[3:]
new_text = new_text.decode('utf-8')

changed_keys = []
for line in new_text.split('\r\n'):
    if '\t' in line:
        parts = line.split('\t')
        k = parts[0]
        v = parts[-1]
        
        # We find modified keys!
        if k in old_dict and old_dict[k] != v:
            changed_keys.append(f"{k}\t{v}")

with open('modified_keys.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(changed_keys))

print(f"Found {len(changed_keys)} modified keys!")
