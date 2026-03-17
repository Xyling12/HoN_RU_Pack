path = r'd:\HoN_RU_Pack\sanitize_bundle.py'
with open(path,'r',encoding='utf-8') as f:
    t = f.read()
t = t.replace("TARGET_VERSION = b'1.9.9k'", "TARGET_VERSION = b'1.9.9l'")
with open(path,'w',encoding='utf-8') as f:
    f.write(t)
with open(r'd:\HoN_RU_Pack\version.txt','w') as f:
    f.write('1.9.9l')
print('Version bumped to 1.9.9l')
