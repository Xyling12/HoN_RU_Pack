import os
import re

bundle_dir = r'd:\HoN_RU_Pack\bundle'

def sanitize_file(filepath):
    filename = os.path.basename(filepath)
    with open(filepath, 'rb') as f:
        data = f.read()
    
    changed = False

    # 1) Handle BOM
    bom = b'\xef\xbb\xbf'
    has_bom = data.startswith(bom)
    needs_bom = (filename == 'entities_en.str')

    if needs_bom and not has_bom:
        data = bom + data
        changed = True
        print(f"Added BOM to {filename}")
    elif not needs_bom and has_bom:
        data = data[3:]
        changed = True
        print(f"Removed BOM from {filename}")

    # 2) Strip corrupted \r\r\n (Carriage Return Carriage Return Line Feed) which some python tools inject
    if b'\r\r\n' in data:
        data = data.replace(b'\r\r\n', b'\r\n')
        changed = True
        print(f"Fixed CRLF in {filename}")

    # 3) Specific Interface fixes
    if filename == 'interface_en.str':
        # Version bump
        # Version bump — replace ANY 1.9.x version with the current target
        import re as _re
        TARGET_VERSION = b'1.9.9h'
        new_data = _re.sub(rb'1\.9\.\d+[a-z]?', TARGET_VERSION, data)
        if new_data != data:
            data = new_data
            changed = True
            print(f"Bumped version to {TARGET_VERSION.decode()} in {filename}")

        # Vibrance label — correct translation: Насыщенность (not Красочность)
        vibrance_pattern = b'options_label_vibrance[^\r\n]*\r\n'
        # UTF-8: Насыщенность = \xd0\x9d\xd0\xb0\xd1\x81\xd1\x8b\xd1\x89\xd0\xb5\xd0\xbd\xd0\xbd\xd0\xbe\xd1\x81\xd1\x82\xd1\x8c
        vibrance_target = b'options_label_vibrance                         \t\xd0\x9d\xd0\xb0\xd1\x81\xd1\x8b\xd1\x89\xd0\xb5\xd0\xbd\xd0\xbd\xd0\xbe\xd1\x81\xd1\x82\xd1\x8c: ^w\r\n'
        if re.search(vibrance_pattern, data):
            data = re.sub(vibrance_pattern, vibrance_target, data)
            changed = True
            print(f"Fixed options_label_vibrance in {filename}")

        value_pattern = b'options_label_value[^\r\n]*\r\n'
        # UTF-8: Гамма = \xd0\x93\xd0\xb0\xd0\xbc\xd0\xbc\xd0\xb0
        value_target = b'options_label_value                         \t\xd0\x93\xd0\xb0\xd0\xbc\xd0\xbc\xd0\xb0: ^w\r\n'
        if re.search(value_pattern, data):
            data = re.sub(value_pattern, value_target, data)
            changed = True
            print(f"Fixed options_label_value in {filename}")

    if changed:
        with open(filepath, 'wb') as f:
            f.write(data)
        print(f"Saved {filename}")

# Process all .str files
for fname in os.listdir(bundle_dir):
    if fname.endswith('.str'):
        sanitize_file(os.path.join(bundle_dir, fname))

print("Sanitization complete.")
