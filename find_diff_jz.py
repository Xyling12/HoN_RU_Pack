import zipfile
import sys

old_keys = {}
with open(r'd:\Projects\HoN_RU_Pack\bundle\entities_en.str', 'rb') as f:
    text = f.read()[3:].decode('utf-8')
    for line in text.split('\r\n'):
        if '\t' in line:
            k = line.split('\t')[0]
            old_keys[k] = line

z = zipfile.ZipFile(r'C:\Users\Maxim\AppData\Local\Juvio\heroes of newerth\resources0.jz')
content = z.read('stringtables/entities_en.str')
if content.startswith(b'\xef\xbb\xbf'):
    content = content[3:]
new_text = content.decode('utf-8')

new_keys = []
for line in new_text.split('\r\n'):
    if '\t' in line:
        k = line.split('\t')[0]
        if k not in old_keys:
            new_keys.append(line)

with open('latest_changes.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(new_keys))

print(f"Found {len(new_keys)} completely new keys!")
