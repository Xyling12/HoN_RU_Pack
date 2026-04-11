# audit_ability_names.py
# Extracts all Ability_*_name and Ability_*_description_simple keys
# grouped by hero, for quality audit

import sys, re, collections
sys.stdout.reconfigure(encoding='utf-8')

path = r'd:\HoN_RU_Pack\bundle\entities_en.str'
with open(path, 'rb') as f: data = f.read()
bom = b'\xef\xbb\xbf'
text = data[3:].decode('utf-8') if data.startswith(bom) else data.decode('utf-8')
lines = text.split('\r\n')

heroes = collections.OrderedDict()  # hero -> { ability_num -> {name, description} }

for line in lines:
    if '\t' not in line: continue
    key = line.split('\t')[0].strip()
    if ':' in key: continue  # skip variant keys
    if not key.startswith('Ability_'): continue

    val = line.split('\t', 1)[1].strip()

    # Parse key: Ability_HeroNameN_type
    m = re.match(r'^Ability_(.+?)(\d+)_(name|description_simple)$', key)
    if not m: continue
    hero, num, typ = m.group(1), m.group(2), m.group(3)
    if hero not in heroes: heroes[hero] = {}
    k = f"{hero}{num}"
    if k not in heroes[hero]: heroes[hero][k] = {}
    heroes[hero][k][typ] = val

# Output as readable report
out_lines = []
for hero, abilities in sorted(heroes.items()):
    out_lines.append(f"\n=== {hero} ===")
    for ab_key in sorted(abilities.keys(), key=lambda x: int(re.search(r'\d+$', x).group())):
        ab = abilities[ab_key]
        name = ab.get('name', '???')
        desc = ab.get('description_simple', '')
        num = re.search(r'\d+$', ab_key).group()
        # Flag potential issues
        flags = []
        # Machine translation patterns in name
        if re.search(r'\bof\b|\bthe\b|\bof the\b', name, re.I): flags.append('EN_WORD_IN_NAME')
        if len(name) > 30: flags.append('NAME_LONG')
        if re.search(r'[A-Za-z]{4,}', name): flags.append('HAS_LATIN')

        flag_str = ' [' + ','.join(flags) + ']' if flags else ''
        out_lines.append(f"  {num}. {name}{flag_str}")
        if desc:
            # Count chars and flag long descriptions
            clean_desc = desc[:80].replace('\\n', ' ')
            desc_flag = f' ({len(desc)}ch)' if len(desc) > 350 else ''
            out_lines.append(f"     → {clean_desc}...{desc_flag}")

report = '\n'.join(out_lines)
with open(r'd:\HoN_RU_Pack\ability_names_audit.txt', 'w', encoding='utf-8') as f:
    f.write(report)
print(f"Wrote audit for {len(heroes)} heroes")
print(f"Total abilities: {sum(len(v) for v in heroes.values())}")

# Summary: find names with issues
issues = [(h, k, ab.get('name','')) for h, abilities in heroes.items() for k, ab in abilities.items()
          if re.search(r'[A-Za-z]{4,}', ab.get('name',''))]
print(f"\nAbilities with Latin in name: {len(issues)}")
for hero, key, name in issues[:30]:
    print(f"  Ability_{key}_name: {name}")
