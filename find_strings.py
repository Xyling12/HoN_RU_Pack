import os

bundle_dir = r'd:\HoN_RU_Pack\bundle'
targets = ['Жемчужина', 'CD:', 'Затраты маны:', 'Диапазон:']

for filename in ['entities_en.str', 'interface_en.str', 'client_messages_en.str']:
    filepath = os.path.join(bundle_dir, filename)
    if not os.path.exists(filepath): continue
    with open(filepath, 'rb') as f:
        data = f.read()
    try:
        text = data.decode('utf-8-sig')
    except:
        text = data.decode('utf-8', errors='ignore')
    
    for i, line in enumerate(text.split('\r\n')):
        for target in targets:
            if target in line:
                key = line.split('\t')[0] if '\t' in line else ''
                print(f"[{filename}] Line {i} [{key}]: {line.strip()[:100]}")
