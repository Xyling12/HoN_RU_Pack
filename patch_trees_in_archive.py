"""
Патч resources0.jz — заменяем model.mdf деревьев на ссылку на stump.model.

Подход: читаем архив, перезаписываем только нужные .mdf файлы, остальное копируем as-is.
Работает через zipfile — архив использует стандартный Deflate (не Zstd для этих файлов).

ВНИМАНИЕ: делает backup resources0.jz.bak перед изменением.
"""

import zipfile
import shutil
import os
import sys

GAME_ROOT = r"C:\Users\Maxim\AppData\Local\Juvio\heroes of newerth"
ARCHIVE   = os.path.join(GAME_ROOT, "resources0.jz")
BACKUP    = os.path.join(GAME_ROOT, "resources0.jz.bak")
TMP_OUT   = os.path.join(GAME_ROOT, "resources0.jz.tmp")

TREE_TYPES = [
    "ashtree", "deadtree1", "deadtree2", "deepwoodpine", "deepwoodpine2",
    "deepwoodtree", "deepwoodtreeblue", "jungle1", "jungle2", "jungle3",
    "jungle4", "legion1", "legion2", "legion3", "legion4", "legion5",
    "lushtree2", "swamp1", "swamp2", "swamp3", "waterfalltree1"
]

# Пути которые нужно заменить
TARGET_MDFS = {
    f"world/rprops/trees/{t}/model.mdf" for t in TREE_TYPES
}

# Новое содержимое model.mdf (ссылается на stump.model в той же папке)
STUMP_MDF = b'<?xml version="1.0" encoding="UTF-8"?>\r\n<model name="stump" file="stump.model" type="K2">\r\n</model>\r\n'

# Стамп модель — извлечём её из архива и скопируем в каждое дерево
STUMP_SRC_PATH = "buildings/neutral/midwars_objective/legion/stump.model"

print(f"Archive: {ARCHIVE}")
print(f"Size: {os.path.getsize(ARCHIVE)/1024/1024:.1f} MB")

if not os.path.exists(BACKUP):
    print("Creating backup...")
    shutil.copy2(ARCHIVE, BACKUP)
    print(f"Backup: {BACKUP}")
else:
    print(f"Backup already exists: {BACKUP}")

# Читаем stump.model из архива
print("Reading stump.model from archive...")
with zipfile.ZipFile(ARCHIVE, 'r') as zin:
    stump_model_data = zin.read(STUMP_SRC_PATH)
print(f"stump.model size: {len(stump_model_data)} bytes")

# Проверим, читается ли нужный mdf
with zipfile.ZipFile(ARCHIVE, 'r') as zin:
    names = set(zin.namelist())
    found = [t for t in TARGET_MDFS if t in names]
    print(f"Tree model.mdf entries found in archive: {len(found)}/{len(TARGET_MDFS)}")
    if found:
        print(f"  Example: {found[0]}")
        sample = zin.read(found[0])
        print(f"  Current content: {sample[:200]}")

print("\nDo you want to patch? (y/n)")
answer = input().strip().lower()
if answer != 'y':
    print("Aborted.")
    sys.exit(0)

# Перезаписываем архив
print("\nPatching archive (this may take a few minutes for 3.7 GB)...")
patched = 0
stump_added = 0

with zipfile.ZipFile(ARCHIVE, 'r') as zin:
    with zipfile.ZipFile(TMP_OUT, 'w', compression=zipfile.ZIP_DEFLATED, allowZip64=True) as zout:
        total = len(zin.namelist())
        for i, item in enumerate(zin.infolist()):
            name = item.filename
            if i % 500 == 0:
                print(f"  {i}/{total} ({i*100//total}%)")

            if name in TARGET_MDFS:
                # Заменяем model.mdf → stump version
                zout.writestr(item, STUMP_MDF)
                patched += 1

                # Добавляем stump.model рядом
                tree_dir = name.rsplit('/', 1)[0]  # world/rprops/trees/legion1
                stump_dest = f"{tree_dir}/stump.model"
                if stump_dest not in {e.filename for e in zout.infolist()}:
                    stump_info = zipfile.ZipInfo(stump_dest)
                    stump_info.compress_type = zipfile.ZIP_DEFLATED
                    zout.writestr(stump_info, stump_model_data)
                    stump_added += 1
            else:
                # Копируем как есть (без перекомпрессии бинарных данных)
                try:
                    data = zin.read(name)
                    zout.writestr(item, data)
                except Exception as e:
                    print(f"  WARNING: skip {name}: {e}")

print(f"\nPatched {patched} model.mdf files, added {stump_added} stump.model files")

# Заменяем оригинал
print("Replacing original archive...")
os.replace(TMP_OUT, ARCHIVE)
print("Done! Restart HoN to see changes.")
print("To restore: copy resources0.jz.bak -> resources0.jz")
