import os

bundle_dir = r"d:\HoN_RU_Pack\bundle"
entities_file = os.path.join(bundle_dir, "entities_en.str")

with open(entities_file, 'rb') as f:
    data = f.read()

has_bom = data.startswith(b'\xef\xbb\xbf')
text = data[3:].decode('utf-8', errors='replace') if has_bom else data.decode('utf-8', errors='replace')
lines = text.split('\r\n')

item_replacements = [
    ("Активируйте для возврата", "Активный эффект: возвращает"),
    ("Активируйте для", "Активно: "),
    ("Используйте для", "Активно: "),
    ("Установите для", "Активно: "),
    ("Применяйте для", "Активно: "),
    ("Активируйте, чтобы", "Активно: "),
    ("Используйте, чтобы", "Активно: "),
    ("Применяйте, чтобы", "Активно: "),
    ("-Магическая броня Aura\\nActive: получить временную броню", "Аура снижения маг. брони\\nАктивно: дает временную броню"),
    ("Active: ", "Активно: "),
    (" aura^*", " аура^*"),
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
        
        for old, new in item_replacements:
            val = val.replace(old, new)
        
        # Cleanup double spaces just in case
        val = val.replace("Активно:  ", "Активно: ")
        
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
    print(f"Fixed tooltip prefixes for {changed_lines} items.")
else:
    print("No changes needed in tooltips.")
