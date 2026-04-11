# apply_morning_glossary.py
# ENCODING RULE: Only byte replacement. No text encode/decode with BOM.
# entities_en.str MUST keep its BOM (EF BB BF).
# interface_en.str must NOT have BOM.

import os

def apply_replacements(filepath, replacements, needs_bom):
    with open(filepath, 'rb') as f:
        data = f.read()

    # Enforce BOM rules
    bom = b'\xef\xbb\xbf'
    if needs_bom and not data.startswith(bom):
        data = bom + data
    elif not needs_bom and data.startswith(bom):
        data = data[3:]

    total = 0
    for old_str, new_str in replacements:
        old = old_str.encode('utf-8')
        new = new_str.encode('utf-8')
        count = data.count(old)
        if count:
            data = data.replace(old, new)
            total += count
            print(f"  [{count}x] {old_str!r} -> {new_str!r}")

    with open(filepath, 'wb') as f:
        f.write(data)
    print(f"  Total: {total} replacements in {os.path.basename(filepath)}\n")
    return total

# ─────────────────────────────────────────────
# entities_en.str glossary
# ─────────────────────────────────────────────
entities_path = r'd:\HoN_RU_Pack\bundle\entities_en.str'

entities_replacements = [
    # Movement mechanics (in color tags and plain)
    ('^oTree/Unitwalking^*',     '^oпрохождение сквозь деревья и юнитов^*'),
    ('^oTeewalking^*',           '^oпрохождение сквозь деревья^*'),      # typo variant
    ('^oTeeWalking^*',           '^oпрохождение сквозь деревья^*'),
    ('^oTreewalking^*',          '^oпрохождение сквозь деревья^*'),
    ('^oUnitwalking^*',          '^oпрохождение сквозь юнитов^*'),
    ('^oUnitWalking^*',          '^oпрохождение сквозь юнитов^*'),
    ('^oTree walking^*',         '^oпрохождение сквозь деревья^*'),
    ('^oUnit walking^*',         '^oпрохождение сквозь юнитов^*'),
    # Without color tags
    ('Tree/Unitwalking',         'прохождение сквозь деревья и юнитов'),
    ('Treewalking',              'прохождение сквозь деревья'),
    ('TreeWalking',              'прохождение сквозь деревья'),
    ('Unitwalking',              'прохождение сквозь юнитов'),
    ('UnitWalking',              'прохождение сквозь юнитов'),

    # Vision mechanics
    ('^oClearvision^*',          '^oбеспрепятственный обзор^*'),
    ('^oClearVision^*',          '^oбеспрепятственный обзор^*'),
    ('Clearvision',              'беспрепятственный обзор'),
    ('ClearVision',              'беспрепятственный обзор'),

    # Attack mechanics
    ('^oTruestrike^*',           '^oТочный удар^*'),
    ('^oTrueStrike^*',           '^oТочный удар^*'),
    ('Truestrike',               'Точный удар'),
    ('TrueStrike',               'Точный удар'),

    # Mana mechanics
    ('^oMana Steal^*',           '^oПохищение маны^*'),
    ('Mana Steal',               'Похищение маны'),
    ('^oMana steal^*',           '^oПохищение маны^*'),
    ('Mana steal',               'Похищение маны'),

    # Shadow Walk (only in description text, not in state names)
    # We only replace when it appears in lowercased "shadow walk" context in descriptions
    ('^oShadow Walk^*',          '^oШаг в тень^*'),
    ('^oshadow walk^*',          '^oшаг в тень^*'),

    # Crowd Control - only in description text (not names)
    # Stun
    ('^oStunned^*',              '^oОглушён^*'),
    ('^ostunned^*',              '^oоглушён^*'),
    # Silence
    ('^oSilenced^*',             '^oПод Безмолвием^*'),
    ('^osilenced^*',             '^oпод Безмолвием^*'),
    # Root
    ('^oRooted^*',               '^oОцепенел^*'),
    ('^orooted^*',               '^oоцепенел^*'),
    # Disarm
    ('^oDisarmed^*',             '^oРазоружён^*'),
    ('^odisarmed^*',             '^oразоружён^*'),
]

print("=== entities_en.str ===")
apply_replacements(entities_path, entities_replacements, needs_bom=True)

# ─────────────────────────────────────────────
# Verify BOM state of both files
# ─────────────────────────────────────────────
for path, expect_bom in [
    (entities_path, True),
    (r'd:\HoN_RU_Pack\bundle\interface_en.str', False),
]:
    with open(path, 'rb') as f:
        header = f.read(3)
    has = header == b'\xef\xbb\xbf'
    status = "✓ OK" if has == expect_bom else "✗ WRONG!"
    print(f"BOM check [{os.path.basename(path)}]: has_bom={has}, expected={expect_bom} → {status}")

print("\nDone.")
