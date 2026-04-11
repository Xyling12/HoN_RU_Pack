import re

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
        starts = len(re.findall(r'\^[a-wy-zA-Z0-9]', v))
        ends = len(re.findall(r'\^\*', v))
        if starts > ends:
            diff = starts - ends
            new_v = v + ('^*' * diff)
            ru_lines[i] = k + line[len(k):line.find(v)] + new_v
            fixes += 1

with open(r'd:\Projects\HoN_RU_Pack\bundle\entities_en.str', 'wb') as f:
    f.write(bom + '\r\n'.join(ru_lines).encode('utf-8'))

print(f"Fixed {fixes} color leak bugs.")
