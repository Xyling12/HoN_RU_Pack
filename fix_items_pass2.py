import os, re

bundle_dir = r"d:\HoN_RU_Pack\bundle"
entities_file = os.path.join(bundle_dir, "entities_en.str")

with open(entities_file, 'rb') as f:
    data = f.read()

has_bom = data.startswith(b'\xef\xbb\xbf')
text = data[3:].decode('utf-8', errors='replace') if has_bom else data.decode('utf-8', errors='replace')
lines = text.split('\r\n')

item_replacements = [
    # Stats
    ("Разведка^*", "Интеллект^*"),
    ("Прочность^*", "Сила^*"),
    
    # Types of heroes
    ("героями дальний тип атаки", "героями дальнего боя"),
    ("героями дальнего тип атаки", "героями дальнего боя"),
    ("герой дальний тип атаки", "герой дальнего боя"),
    ("герой ^gдальний тип атаки^*", "герой ^gдальнего боя^*"),
    ("героем ^gдальний тип атаки^*", "героем ^gдальнего боя^*"),
    
    # Wingbow specifically
    ("от ^* до ^g дальний тип атаки^* героев", "^* героям ^gдальнего боя^*"),
    ("от ^* до ^g дальнего типа атаки^* героев", "^* героям ^gдальнего боя^*"),
    ("от ^* до ^gрукопашного боя^* героев", "^* героям ^gближнего боя^*"),
    ("передвижения по единицам", "прохождение сквозь существ"),
    
    # Mechanics
    ("Кон гора", "Конгора"),
    ("Конгор", "Конгор"),
    ("отрицает^* их", "добивает^* их"), # Deny -> добивает
    ("Сгруппируйте 5 нейтральных лагерей", "Сделайте 5 стаков нейтралов"),
    ("Транс фигурировать", "превратить"),
    ("молчание, замешательство", "Безмолвие, Перплекс"),
    ("до ^o заблокировать", "^oзаблокировать"),
    ("до ^oзаблокировать", "^oзаблокировать"),
    ("перезарядка отключено", "способность не на перезарядке"),

    # Item simple descriptions cleanup
    ("Используйте для", "Используйте, чтобы"),
    
    # Ravens
    ("Вызовите ^oRaven^*", "Призовите ^oВорона^*"),
    ("вражеских воронов^*", "вражеских воронов^*"),
    ("^oRavens^*", "^oВоронов^*"),
    ("Raven", "Ворон"), # Just "Ворон" but might be risky if in English keys, but we only apply to values
]

changed_lines = 0

for i in range(len(lines)):
    if '\t' not in lines[i]:
        continue
    parts = lines[i].split('\t')
    key = parts[0]
    val = parts[-1]
    
    if key.startswith("Item_") or key.startswith("Recipe_"):
        orig_val = val
        
        # Apply standard string replacements
        for old, new in item_replacements:
            val = val.replace(old, new)
        
        # Regex for "10 Разведка" without caret
        val = re.sub(r'(\d+)\s+Разведка', r'\1 Интеллект', val)
        val = re.sub(r'(\d+)\s+Прочность', r'\1 Сила', val)
        
        # "от ^* до ^g дальний тип атаки^* героев" -> "^* героям ^gдальнего боя^*"
        val = val.replace("от ^* до ^g дальний тип атаки^* героев", "^* героям ^gдальнего боя^*")
        
        if orig_val != val:
            parts[-1] = val
            lines[i] = '\t'.join(parts)
            changed_lines += 1

if changed_lines > 0:
    new_text = '\r\n'.join(lines)
    new_data = new_text.encode('utf-8')
    if has_bom:
        new_data = b'\xef\xbb\xbf' + new_data
    with open(entities_file, 'wb') as f:
        f.write(new_data)
    print(f"Fixed {changed_lines} lines in {entities_file}.")
else:
    print("No changes needed in entities_file.")
