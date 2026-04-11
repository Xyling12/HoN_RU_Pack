import re

with open(r'd:\Projects\HoN_RU_Pack\bundle\entities_en.str', 'rb') as f:
    text = f.read().decode('utf-8')
    lines = text.split('\r\n')

unclosed_tags = []
bad_abbreviations = []
double_spaces = []

abbrev_rules = {
    r'магического урона': 'маг. урона',
    r'физического урона': 'физ. урона',
    r'чистого урона': 'чист. урона',
    r'скорость передвижения': 'скор. движ.',
    r'скорость атаки': 'скор. атаки',
    r'максимального здоровья': 'макс. здоровья',
    r'текущего здоровья': 'тек. здоровья',
    r'регенерация здоровья': 'реген. ХП',
}

for i, line in enumerate(lines):
    if '\t' in line:
        k, v = line.split('\t', 1)
        
        # Check abbreviations
        for bad, good in abbrev_rules.items():
            if re.search(bad, v, re.IGNORECASE):
                bad_abbreviations.append(f"{k}: Found '{bad}', should be '{good}'")
        
        # Check unclosed tags roughly (e.g. string ends without ^*)
        # Actually a better heuristic: if there's a ^[a-zA-Z0-9] but no ^* at the end of the text block?
        # Let's just check if count of ^[a-zA-Z0-9] > count of ^*
        starts = len(re.findall(r'\^[a-wy-zA-Z0-9]', v)) # skip ^x which is not a standard color? Actually HoN colors are ^r ^g ^b ^c ^m ^y ^k ^w ^o ^p ^v
        ends = len(re.findall(r'\^\*', v))
        if starts > ends:
            # Maybe they didn't close it at all.
            unclosed_tags.append(f"{k}: Found {starts} colored tags but only {ends} resets (^*).")
            
        # Check double spaces
        # But ignore spaces inside tabs or leading/trailing
        clean_v = v.strip()
        if '  ' in clean_v:
            # Let's only record if it's double space between words
            if re.search(r'[а-яА-Яa-zA-Z][\.\,\!\?]*  +[а-яА-Яa-zA-Z]', clean_v):
                double_spaces.append(f"{k}: Double spaces found")

print(f"--- АУДИТ КАЧЕСТВА ---")
print(f"Нарушения сокращений: {len(bad_abbreviations)}")
print(f"Незакрытые цветовые теги (потенциально ломают UI): {len(unclosed_tags)}")
print(f"Двойные пробелы: {len(double_spaces)}")

with open('research_audit_results.txt', 'w', encoding='utf-8') as f:
    f.write("--- Нарушения сокращений ---\n")
    f.write('\n'.join(bad_abbreviations[:20]) + '\n...\n\n')
    f.write("--- Незакрытые цветовые теги ---\n")
    f.write('\n'.join(unclosed_tags[:20]) + '\n...\n')
