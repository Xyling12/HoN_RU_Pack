import os

bundle_dir = r"d:\HoN_RU_Pack\bundle"
files_to_process = ["entities_en.str", "interface_en.str"]

replacements = [
    # Item: Teleportation Stone
    ("После окончания перезарядки использование стоит золота. Стоимость золота снижается со временем.", "При использовании после перезарядки расходует золото. Стоимость уменьшается со временем."),
    
    # Item: Armor of the Mad Mage
    ("Пассивно применяет aura^* к ближайшим врагам.", "Аура: применяет aura^* к ближайшим врагам."),
    
    # Item: Bloodborne Maul
    ("При повреждении получает 1 заряд за каждые 10 потерянных здоровья", "При получении урона набирает 1 заряд за каждые 10 потерянного здоровья"),
    ("вашим атакам противрагов, не являющихся структурами", "вашим атакам против существ"),
    ("Теряет 15 зарядов сек. после 4 сек. отсутствия урона от врагов", "Теряет по 15 зарядов в сек., если не получает урон 4 сек"),
    
    # Item: Bound Eye
    ("Показывает скрытые юниты^* рядом со своим владельцем.", "Раскрывает невидимых существ^* вокруг владельца."),
    ("Можно активировать, чтобы открыть варды и воронов.", "При активации обнаруживает варды и воронов."),
    ("Невозможно продать. После того, как его уронили или передали, летающий курьер больше не сможет его снова подобрать.", "Нельзя продать. Если выбросить или передать, курьер больше не сможет его подобрать."),
    
    # Item: Cheese
    ("Эти волшебные бананы мгновенно восстанавливают огромное количество здоровья и маны.", "Эти волшебные бананы мгновенно восстанавливают огромное количество здоровья и маны."),
    ("Подходит для слота для расходных материалов ^296^*.", "Занимает слот для расходников ^296^*."),
    ("Получается при убийстве Кон гора (или нескольких других боссов).^*", "Выпадает после убийства Конгора (или некоторых других боссов).^*"),
    
    # Lore overrides (Accursed)
    ("Многие гадали, какой великий проклятый воин ныне живет в муках внутри пылающих доспехов, что маршируют в рядах Адского Легиона.", "Кое-кто до сих пор гадает, какой великий проклятый воин скрывается в пылающих доспехах Адского Легиона."),
]

total_changes = 0
for filename in files_to_process:
    filepath = os.path.join(bundle_dir, filename)
    if not os.path.exists(filepath): continue
    
    with open(filepath, 'rb') as f:
        data = f.read()
    
    has_bom = data.startswith(b'\xef\xbb\xbf')
    if has_bom:
        text = data[3:].decode('utf-8', errors='replace')
    else:
        text = data.decode('utf-8', errors='replace')
    
    lines = text.split('\r\n')
    changed_lines = 0
    
    for i in range(len(lines)):
        if '\t' not in lines[i]:
            continue
        parts = lines[i].split('\t')
        key = parts[0]
        val = parts[-1]
        
        orig_val = val
        for old, new in replacements:
            val = val.replace(old, new)
        
        if orig_val != val:
            parts[-1] = val
            lines[i] = '\t'.join(parts)
            changed_lines += 1
            print(f"Changed in {filename}: {key}")
            
    if changed_lines > 0:
        new_text = '\r\n'.join(lines)
        new_data = new_text.encode('utf-8')
        if has_bom:
            new_data = b'\xef\xbb\xbf' + new_data
        with open(filepath, 'wb') as f:
            f.write(new_data)
        total_changes += changed_lines

print(f"Done. Fixed {total_changes} item/lore/settings lines across all files.")
