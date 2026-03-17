# fix_settings_v2.py
# Fixes settings menu mistranslations in interface_en.str
# Uses ONLY byte replacement — no text re-encoding, no BOM tampering.
# interface_en.str must NOT have BOM.

import sys
sys.stdout.reconfigure(encoding='utf-8')

path = r'd:\HoN_RU_Pack\bundle\interface_en.str'

with open(path, 'rb') as f:
    data = f.read()

# Must NOT have BOM
bom = b'\xef\xbb\xbf'
if data.startswith(bom):
    data = data[3:]
    print("Stripped unexpected BOM!")

# ── Replacements (old_bytes -> new_bytes) ──────────────────────────────────────
# Each pair: (current Russian text, corrected Russian text)
FIXES = [
    # "Светлота" as a tooltip header (wrong — should be "Яркость")
    (
        'options_value_tip_header\t\t\t\t\t\t\t\t\t\tСветлота',
        'options_value_tip_header\t\t\t\t\t\t\t\t\t\tЯркость',
    ),
    # "Красочность" — more natural Russian: "Насыщенность" (color saturation)
    (
        'options_label_vibrance\t\t\t\t\t\t\t\t\t\tКрасочность: ^w',
        'options_label_vibrance\t\t\t\t\t\t\t\t\t\tНасыщенность: ^w',
    ),
    (
        'options_vibrance_tip_header\t\t\t\t\t\t\t\t\t\tКрасочность',
        'options_vibrance_tip_header\t\t\t\t\t\t\t\t\t\tНасыщенность цвета',
    ),
    # "Осветление" -> "Гамма" (standard gaming term for the value slider)
    (
        'options_label_value\t\t\t\t\t\t\t\t\t\tОсветление: ^w',
        'options_label_value\t\t\t\t\t\t\t\t\t\tГамма: ^w',
    ),
    # "Модификатор собственного применения" -> "Применить на себя"
    (
        'options_label_self_cast_keybind\t\t\t\t\t\t\t\t\t\tМодификатор собственного применения',
        'options_label_self_cast_keybind\t\t\t\t\t\t\t\t\t\tКлавиша: Применить на себя',
    ),
]

total = 0
for old_str, new_str in FIXES:
    old = old_str.encode('utf-8')
    new = new_str.encode('utf-8')
    count = data.count(old)
    if count:
        data = data.replace(old, new)
        total += count
        print(f"  [{count}x] fixed: {old_str.split(chr(9))[0]}")
    else:
        # Try with fewer tabs (tab count may vary)
        key = old_str.split('\t')[0]
        val_old = old_str.split('\t')[-1]
        val_new = new_str.split('\t')[-1]
        # Find the key in data and replace just the value
        key_bytes = key.encode('utf-8')
        val_old_bytes = val_old.encode('utf-8')
        val_new_bytes = val_new.encode('utf-8')
        if key_bytes in data and val_old_bytes in data:
            data = data.replace(val_old_bytes, val_new_bytes, 1)
            total += 1
            print(f"  [1x] fixed (fuzzy): {key}")
        else:
            print(f"  [SKIP] not found: {key}")

with open(path, 'wb') as f:
    f.write(data)

# Verify no BOM
with open(path, 'rb') as f:
    h = f.read(3)
print(f"\nBOM check: {'OK (no BOM)' if h != bom else 'ERROR - BOM present!'}")
print(f"Total fixes: {total}")
