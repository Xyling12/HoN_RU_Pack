# fix_fayde_sotm.py
# Fixes Ability_Fayde4_description2 which has incorrect double-escaped newlines
# and incorrect ult_boost variant that hides the SotM text.

import sys
sys.stdout.reconfigure(encoding='utf-8')

path = r'd:\HoN_RU_Pack\bundle\entities_en.str'
with open(path, 'rb') as f: data = f.read()
bom = b'\xef\xbb\xbf'
assert data.startswith(bom)

# The correct Staff of Master text for Fayde (with proper \n escaping as the game expects)
# HoN .str files use literal \n (backslash-n) in the byte stream, not actual newlines
CORRECT_SOTM = (
    '^gПосох Мастера:^* Первая атака в Отражении сохраняется 5 сек., '
    'если Отражение истекло без применения.'
    '\\n\\nОтражение превращается в ^g"Танец теней"^* (3 заряда): '
    'телепорт к врагу + Шаг в тень на 1 сек. '
    'Также наносит ^o0,6x^* DoT цели (не суммируется с основным DoT).'
)

total = 0

# Fix 1: Replace the double-escaped version with single-escaped
BAD_SOTM = (
    '^gПосох Мастера:^* Первая атака в Отражении сохраняется 5 сек., '
    'если Отражение истекло без применения.\\\\n\\\\nОтражение превращается в ^g"Танец теней"^* (3 заряда): '
    'телепорт к врагу + Шаг в тень на 1 сек. '
    'Также наносит ^o0,6x^* DoT цели (не суммируется с основным DoT).'
)
cnt = data.count(BAD_SOTM.encode('utf-8'))
if cnt:
    data = data.replace(BAD_SOTM.encode('utf-8'), CORRECT_SOTM.encode('utf-8'))
    total += cnt
    print(f"Fixed double-escaped description2: {cnt}x")
else:
    print("Double-escaped version not found — checking current state...")
    # Show current state
    idx = data.find('Ability_Fayde4_description2\t'.encode('utf-8'))
    if idx == -1:
        idx = data.find('Ability_Fayde4_description2'.encode('utf-8'))
    if idx != -1:
        print("Current:", data[idx:idx+300].decode('utf-8', errors='replace'))

# Fix 2: The :ult_boost variant = '\\r' hides the SotM text when Staff is purchased.
# It should show the SotM text too. Set it to the same correct text.
ULT_BOOST_KEY = 'Ability_Fayde4_description2:ult_boost\t'.encode('utf-8')
idx = data.find(ULT_BOOST_KEY)
if idx != -1:
    # Find end of this line
    end = data.find(b'\r\n', idx)
    current_line = data[idx:end]
    print(f"ult_boost current: {current_line.decode('utf-8', errors='replace')[:100]}")
    # Replace the entire line value with the correct text
    new_line = ULT_BOOST_KEY + CORRECT_SOTM.encode('utf-8')
    data = data[:idx] + new_line + data[end:]
    total += 1
    print("Fixed ult_boost variant")

with open(path, 'wb') as f: f.write(data)
with open(path, 'rb') as f: h = f.read(3)
print(f"BOM: {'OK' if h == bom else 'ERROR'}")
print(f"Total fixes: {total}")
