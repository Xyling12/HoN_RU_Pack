# extract_names_with_desc.py — outputs hero/ability/name/description for review
import sys, re
sys.stdout.reconfigure(encoding='utf-8')

path = r'd:\HoN_RU_Pack\bundle\entities_en.str'
with open(path,'rb') as f: data=f.read()
bom = b'\xef\xbb\xbf'
text = data[3:].decode('utf-8') if data.startswith(bom) else data.decode('utf-8')
lines = text.split('\r\n')

kv = {}
for line in lines:
    if '\t' not in line: continue
    key = line.split('\t')[0].strip()
    if ':' in key: continue
    kv[key] = line.split('\t',1)[1].strip()

# HERO abilities only (skip gadgets, pets, bosses for now)
SKIP_HEROES = {'Antking','Antlore','Bear','Catmanleader','Crazy_Alchemist',
    'DragonMaster','Ebula','Elemental','ElephantBoss','FlyingCourier',
    'Gadget_EmeraldWarden','Gadget_Monarch','Gadget_Scout','Gadget_Scout2_',
    'GrimmBoss','GroundFamiliar','HeadlessBoss','HunterInvis','Kongor',
    'ManiacLord','Malphas','Minotaur','NecroMelee_','NecroRanged_',
    'Ogre','OgreLeader','PhoenixBoss','Predasaur','Skrap_Vorax',
    'SmallPredasaur','SnotterBoss','Snowgoat','SotMCat','Sporespitter',
    'TowerGuardian','TowerMaster','Tremble','TremblePet','Tundra3_Pet',
    'Tundra3_Pet_Coeurl_Ability','Vagabond','VagabondAssassin','VagabondLeader',
    'Vorax','Vulture','VultureSummon','WarBeast_Ability1_Pet_Ability',
    'Werebeast','Wereboss','WinterBoss','Wolf','WolfCommander','Bephelgor3_Pet_Ability',
    'PyromancerTutorial','SkeletonBoss','Malphas'}

heroes = {}
pat = re.compile(r'^Ability_(.+?)(\d+)_(name|description_simple)$')
for key, val in kv.items():
    m = pat.match(key)
    if not m: continue
    hero, num, typ = m.group(1), m.group(2), m.group(3)
    if hero in SKIP_HEROES: continue
    ab_key = f"{hero}_{num}"
    if ab_key not in heroes: heroes[ab_key] = {'hero': hero, 'num': num}
    heroes[ab_key][typ] = val

out = []
for ab_key in sorted(heroes.keys()):
    ab = heroes[ab_key]
    name = ab.get('name','???')
    desc = ab.get('description_simple','')
    # Strip color codes for readability
    desc_clean = re.sub(r'\^[a-zA-Z!]', '', desc).replace('\\n', ' ').strip()
    out.append(f"[{ab['hero']}_{ab['num']}] {name}")
    if desc_clean:
        out.append(f"  DESC: {desc_clean[:200]}")
    out.append('')

with open(r'd:\HoN_RU_Pack\names_review2.txt','w',encoding='utf-8') as f:
    f.write('\n'.join(out))
print(f"Exported {len(heroes)} abilities")
