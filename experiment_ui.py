import codecs

ru_lines = []
with open(r'd:\Projects\HoN_RU_Pack\bundle\entities_en.str', 'rb') as f:
    data = f.read()
    bom = b''
    if data.startswith(b'\xef\xbb\xbf'):
        bom = b'\xef\xbb\xbf'
        data = data[3:]
    text = data.decode('utf-8')
    ru_lines = text.split('\r\n')

for i, line in enumerate(ru_lines):
    if line.startswith('Ability_Pyromancer1_description_simple\t'):
        k = line.split('\t')[0]
        # preserve tabs
        tabs = line[len(k):][:line[len(k):].rfind('\t')+1]
        if not tabs: tabs = '\t'
        ru_lines[i] = k + tabs + "Запускает вперед разрушительную волну огня.\\n\\n^cЭффект на линии:^*\\n^yУрон:^* ^o{110,180,250,320} маг. урона^*"
    
    elif line.startswith('Ability_WitchSlayer1_description_simple\t'):
        k = line.split('\t')[0]
        tabs = line[len(k):][:line[len(k):].rfind('\t')+1]
        if not tabs: tabs = '\t'
        ru_lines[i] = k + tabs + "Взламывает землю под ногами врагов.\\n\\n^cЭффект на линии:^*\\n^yУрон:^* ^o{100,150,200,250} маг. урона^*\\n^yКонтроль:^* Подбрасывание и ^oОглушение^* ({1.3,1.7,2.1,2.5} сек.)"

    elif line.startswith('Ability_AmunRa1_description_simple\t'):
        k = line.split('\t')[0]
        tabs = line[len(k):][:line[len(k):].rfind('\t')+1]
        if not tabs: tabs = '\t'
        ru_lines[i] = k + tabs + "^rРасход: 20% от тек. ХП^*\\n\\nМетеор поражает врагов:\\n^yУрон:^* ^o{90,140,190,240} маг. урона^*\\n^yКонтроль:^* ^oОглушение^* (1 сек.)\\n^yИсцеление:^* ^r10%^* от макс. ХП (за героя)\\n\\nПри попадании по себе:\\n^yСкорость:^* ^o{20,40,60,80} скор. движ.^* (на 6 сек.)\\n^yИсцеление:^* ^r5%^* от макс. ХП"

with open(r'd:\Projects\HoN_RU_Pack\bundle\entities_en.str', 'wb') as f:
    f.write(bom + '\r\n'.join(ru_lines).encode('utf-8'))
