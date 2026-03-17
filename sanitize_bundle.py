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
        # Version bump from whatever to 1.9.6
        if b'1.9.0' in data:
            data = data.replace(b'1.9.0', b'1.9.6')
            changed = True
            print(f"Bumped version to 1.9.6 in {filename}")
        if b'1.9.5' in data:
            data = data.replace(b'1.9.5', b'1.9.6')
            changed = True
            print(f"Bumped version to 1.9.6 in {filename}")

        # Corrupted Brightness/Vibrance Labels
        vibrance_pattern = b'options_label_vibrance[^\r\n]*\r\n'
        vibrance_target = b'options_label_vibrance                         \t\xd0\x9a\xd1\x80\xd0\xb0\xd1\x81\xd0\xbe\xd1\x87\xd0\xbd\xd0\xbe\xd1\x81\xd1\x82\xd1\x8c: ^w\r\n'
        if re.search(vibrance_pattern, data):
            data = re.sub(vibrance_pattern, vibrance_target, data)
            changed = True
            print(f"Fixed options_label_vibrance in {filename}")

        value_pattern = b'options_label_value[^\r\n]*\r\n'
        value_target = b'options_label_value                         \t\xd0\x9e\xd1\x81\xd0\xb2\xd0\xb5\xd1\x82\xd0\xbb\xd0\xb5\xd0\xbd\xd0\xb8\xd0\xb5: ^w\r\n'
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
