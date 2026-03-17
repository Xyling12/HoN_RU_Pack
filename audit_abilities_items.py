import sys
sys.stdout.reconfigure(encoding='utf-8')

path = r'd:\HoN_RU_Pack\bundle\entities_en.str'
with open(path,'rb') as f: data=f.read()
bom = b'\xef\xbb\xbf'
text = data[3:].decode('utf-8','replace') if data.startswith(bom) else data.decode('utf-8','replace')
lines = text.split('\r\n')

DESC_SUFFIXES = ('_description_simple', '_description', '_IMPACT_effect', '_FRAME_effect', '_info', '_lore')
ITEM_PREFIX = 'Item_'
ABILITY_PREFIX = 'Ability_'

# --- 1. English artifacts in description values ---
import re
ENGLISH_PATTERNS = [
    r'\b(Stun(ned)?|Silence(d)?|Root(ed)?|Disarm(ed)?)\b',
    r'\b(ally|allies|enemy|enemies)\b',
    r'\b(Buff|Debuff)s?\b',
    r'\b(Unitwalking|Treewalking|Clearvision|Truestrike|Mana Steal)\b',
    r'\b(Attack Speed|Movement Speed|Magic Armor)\b',
    r'\bCD\b',
    r'\bDuration\b',
    r'\bRange\b',
    r'\bRadius\b',
    r'\bDamage\b',
    r'\bHealth\b',
    r'\bArmor\b',
    r'\bMana Cost\b',
    r'\blifesteal\b',
    r'\bCreep\b',
    r'\bCooldown\b',
    r'\bCasts?\b',
    r'\bUnit\b',
    r'\bSpell\b',
]

eng_pattern = re.compile('|'.join(ENGLISH_PATTERNS), re.IGNORECASE)

# --- 2. Very long lines (>350 chars in value) ---
LONG_THRESHOLD = 350

long_lines = []
eng_lines = []

for line in lines:
    if '\t' not in line: continue
    key = line.split('\t')[0].strip()
    if not any(key.endswith(s) for s in DESC_SUFFIXES): continue
    if not (key.startswith(ITEM_PREFIX) or key.startswith('Ability_') or key.startswith('State_')): continue
    # Skip variant keys like :ult_boost etc for now
    val = line.split('\t',1)[1].strip()
    if not val: continue
    
    # English artifact check (skip color tag internals)
    cleaned = re.sub(r'\^[a-z0-9*]+', '', val)  # strip color codes
    cleaned = re.sub(r'\{[^}]+\}', '', cleaned)  # strip {values}
    matches = eng_pattern.findall(cleaned)
    if matches:
        eng_lines.append((key, matches, val[:100]))
    
    # Long line check
    if len(val) > LONG_THRESHOLD:
        long_lines.append((key, len(val), val[:120]))

# Write report
with open(r'd:\HoN_RU_Pack\comprehensive_audit.txt', 'w', encoding='utf-8') as f:
    f.write('# Comprehensive Audit — Abilities & Items\n\n')
    
    f.write(f'## English Artifacts ({len(eng_lines)} entries)\n')
    for key, matches, preview in eng_lines:
        f.write(f'  [{key}]\n')
        f.write(f'    Found: {matches}\n')
        f.write(f'    Text:  {preview}\n\n')
    
    f.write(f'\n## Long Descriptions >350 chars ({len(long_lines)} entries)\n')
    for key, length, preview in sorted(long_lines, key=lambda x: -x[1]):
        f.write(f'  [{length:4}] {key}\n')
        f.write(f'         {preview[:100]}\n\n')

print(f'English artifacts: {len(eng_lines)}')
print(f'Long descriptions (>{LONG_THRESHOLD}): {len(long_lines)}')
print('Report: d:\\HoN_RU_Pack\\comprehensive_audit.txt')
