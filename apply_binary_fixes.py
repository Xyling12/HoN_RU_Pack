import sys
import codecs
import re

report_path = r'd:\HoN_RU_Pack\shortened_descriptions_report.txt'
entities_path = r'd:\HoN_RU_Pack\bundle\entities_en.str'
interface_path = r'd:\HoN_RU_Pack\bundle\interface_en.str'

# Parse the report
replacements = {}
current_key = None
current_old = None
current_new = None

with codecs.open(report_path, 'r', 'utf-8-sig') as f:
    for line in f:
        line = line.strip()
        if line.startswith('--- ') and line.endswith(' ---'):
            current_key = line[4:-4].strip()
        elif line.startswith('БЫЛО:  '):
            current_old = line[7:]
        elif line.startswith('СТАЛО: '):
            current_new = line[7:]
            if current_key and current_new:
                replacements[current_key] = current_new
            current_key = None
            current_old = None
            current_new = None

print(f"Loaded {len(replacements)} replacements from report.")

def apply_binary_replacements(filepath):
    with open(filepath, 'rb') as f:
        data = f.read()

    changed = False
    
    # Custom fixes for interface_en.str
    if 'interface_en.str' in filepath:
        # We know that previous script corrupted options_label_vibrance to contain ": ^w\r\n"
        # We need to find the specific line and replace it
        # Since it's binary, let's use regex on bytes
        
        # Vibrance
        vibrance_pattern = b'options_label_vibrance[^\r\n]*\r\n'
        vibrance_target = b'options_label_vibrance                         \t\xd0\x9a\xd1\x80\xd0\xb0\xd1\x81\xd0\xbe\xd1\x87\xd0\xbd\xd0\xbe\xd1\x81\xd1\x82\xd1\x8c: ^w\r\n' # Красочность: ^w
        if re.search(vibrance_pattern, data):
            data = re.sub(vibrance_pattern, vibrance_target, data)
            changed = True
            print("Fixed options_label_vibrance")

        # Value (Lightness)
        value_pattern = b'options_label_value[^\r\n]*\r\n'
        value_target = b'options_label_value                         \t\xd0\x9e\xd1\x81\xd0\xb2\xd0\xb5\xd1\x82\xd0\xbb\xd0\xb5\xd0\xbd\xd0\xb8\xd0\xb5: ^w\r\n' # Осветление: ^w
        if re.search(value_pattern, data):
            data = re.sub(value_pattern, value_target, data)
            changed = True
            print("Fixed options_label_value")

    # Now apply the generic shortened replacements
    # Since we don't know the exact old spacing, it's safer to regex match the key and replace the whole line
    # Format is usually: key_name \t\t\t value \r\n
    applied = 0
    for key, new_val in replacements.items():
        key_b = key.encode('utf-8')
        new_val_b = new_val.encode('utf-8')
        
        # Regex to find: key followed by tabs/spaces, followed by old value, until \r\n
        # Warning: Python regex on large bytes can be slow or tricky, but it's 2MB so it's fine.
        pattern = key_b + b'[ \t]+[^\r\n]*\r\n'
        
        # We want to preserve the whitespace exactly, or just write a standard tab
        # Actually, let's just find the existing line and extract its prefix
        match = re.search(pattern, data)
        if match:
            # We found it! Let's reconstruct it
            original_line = match.group(0)
            prefix_match = re.match(key_b + b'[ \t]+', original_line)
            if prefix_match:
                prefix = prefix_match.group(0)
                new_line = prefix + new_val_b + b'\r\n'
                if new_line != original_line:
                    data = data.replace(original_line, new_line)
                    changed = True
                    applied += 1

    if changed:
        with open(filepath, 'wb') as f:
            f.write(data)
        print(f"Applied {applied} binary replacements to {filepath}")
    else:
        print(f"No replacements made in {filepath}")

apply_binary_replacements(entities_path)
apply_binary_replacements(interface_path)
