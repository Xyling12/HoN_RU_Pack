# fix_fayde_format.py
# The Fayde description2 is missing the standard SotM header format that the game expects.
# ShadowBlade4 (works): ^gЭта способность может быть усилена Посохом Мастера.^*\n\n^gЭффект посоха:^* ...
# Fayde (doesn't show): ^gПосох Мастера:^* ... (missing standard prefix)
# Fix: rewrite Fayde description2 with the standard working format.

import sys
sys.stdout.reconfigure(encoding='utf-8')

path = r'd:\HoN_RU_Pack\bundle\entities_en.str'
with open(path, 'rb') as f: data = f.read()
bom = b'\xef\xbb\xbf'
assert data.startswith(bom)

# Standard SotM prefix that the game engine recognizes
# Use the exact same format as ShadowBlade4 which works:
# ^gЭта способность может быть усилена Посохом Мастера.^*\n\n^gЭффект посоха:^* [details]

FAYDE_CORRECT = (
    '^gЭта способность может быть усилена Посохом Мастера.^*\\n\\n'
    '^gЭффект посоха:^* Первая атака в Отражении сохраняется 5 сек., '
    'если Отражение истекло без применения.\\n\\n'
    'Отражение превращается в ^g"Танец теней"^* (3 заряда): '
    'телепорт к врагу + Шаг в тень на 1 сек. '
    'Также наносит ^o0,6x^* DoT цели (не суммируется с основным DoT).'
)

# Also fix Thunderbringer4 to use the same format prefix
TB4_CORRECT = (
    '^gЭта способность может быть усилена Посохом Мастера.^*\\n\\n'
    '^gЭффект посоха:^* Грозовое облако выпускает дополнительные '
    'молниеносные удары. Дальность цепной молнии и радиус действия '
    'Громоотвода увеличены. Замедление скор. движ. от Громоотвода '
    'увеличивается до ^o40%^*.'
)

total = 0

# Fix Fayde description2 (base + ult_boost)
FAYDE_OLD_BASE = (
    '^gПосох Мастера:^* Первая атака в Отражении сохраняется 5 сек., '
    'если Отражение истекло без применения.\\n\\nОтражение превращается в ^g"Танец теней"^* (3 заряда): '
    'телепорт к врагу + Шаг в тень на 1 сек. Также наносит ^o0,6x^* DoT цели (не суммируется с основным DoT).'
)
cnt = data.count(FAYDE_OLD_BASE.encode('utf-8'))
if cnt:
    data = data.replace(FAYDE_OLD_BASE.encode('utf-8'), FAYDE_CORRECT.encode('utf-8'))
    print(f"Fixed Fayde description2: {cnt}x")
    total += cnt
else:
    print("Fayde old text not found, trying variations...")
    # Try to find actual content
    idx = data.find('Первая атака в Отражении'.encode('utf-8'))
    if idx != -1:
        print(f"  Found at byte {idx}: {data[max(0,idx-20):idx+100].decode('utf-8','replace')}")

# Fix TB4 description2
TB4_OLD = (
    '^gПосох Мастера:^* Грозовое облако выпускает дополнительные '
    'молниеносные удары. Дальность цепной молнии и радиус действия '
    'Громоотвода увеличены. Замедление скор. движ. от Громоотвода '
    'увеличивается до ^o40%^*.'
)
cnt = data.count(TB4_OLD.encode('utf-8'))
if cnt:
    data = data.replace(TB4_OLD.encode('utf-8'), TB4_CORRECT.encode('utf-8'))
    print(f"Fixed Thunderbringer4 description2: {cnt}x")
    total += cnt

with open(path, 'wb') as f: f.write(data)
with open(path, 'rb') as f: h = f.read(3)
print(f"BOM: {'OK' if h == bom else 'WRONG!'}")
print(f"Total: {total}")
