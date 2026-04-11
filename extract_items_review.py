import os

bundle_dir = r"d:\HoN_RU_Pack\bundle"
entities_file = os.path.join(bundle_dir, "entities_en.str")

with open(entities_file, 'rb') as f:
    data = f.read()

has_bom = data.startswith(b'\xef\xbb\xbf')
text = data[3:].decode('utf-8', errors='replace') if has_bom else data.decode('utf-8', errors='replace')
lines = text.split('\r\n')

items = {}

for line in lines:
    if '\t' not in line: continue
    key_part, val = line.split('\t', 1)
    key = key_part.strip()
    val = val.strip()
    
    if key.startswith("Item_"):
        parts = key.split('_')
        if len(parts) >= 3:
            item_name = parts[1]
            suffix = '_'.join(parts[2:])
            
            if item_name not in items:
                items[item_name] = {}
            items[item_name][suffix] = val

with open(r"d:\HoN_RU_Pack\items_review.txt", "w", encoding='utf-8') as f:
    f.write("=== ITEM REVIEW EXPORT ===\n\n")
    for item_name, data in items.items():
        name = data.get('name', '')
        desc = data.get('description', '')
        desc_simple = data.get('description_simple', '')
        
        # Only write items that actually have a description
        if desc or desc_simple:
            f.write(f"--- {item_name} ---\n")
            if name: f.write(f"NAME: {name}\n")
            if desc: f.write(f"DESC: {desc}\n")
            if desc_simple: f.write(f"SIMPLE: {desc_simple}\n")
            f.write("\n")

print(f"Extracted {len([i for i in items.values() if 'description' in i or 'description_simple' in i])} items with descriptions to items_review.txt")
