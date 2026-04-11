import os
import re

entities_path = r'd:\HoN_RU_Pack\bundle\entities_en.str'

# Dictionary of safe, precise replacements (case-insensitive where appropriate, but we'll try to maintain case)
# We will use regex boundaries to ensure we don't break existing words
replacements = [
    (r'(?i)\bмагический урон\b', 'маг. урон'),
    (r'(?i)\bмагического урона\b', 'маг. урона'),
    (r'(?i)\bфизический урон\b', 'физ. урон'),
    (r'(?i)\bфизического урона\b', 'физ. урона'),
    (r'(?i)\bчистый урон\b', 'чист. урон'),
    (r'(?i)\bчистого урона\b', 'чист. урона'),
    
    (r'(?i)\bскорость передвижения\b', 'скор. движ.'),
    (r'(?i)\bскорости передвижения\b', 'скор. движ.'),
    (r'(?i)\bскорость атаки\b', 'скор. атак.'),
    (r'(?i)\bскорости атаки\b', 'скор. атак.'),
    
    (r'(?i)\bсопротивление магии\b', 'сопрот. магии'),
    (r'(?i)\bсопротивления магии\b', 'сопрот. магии'),
    (r'(?i)\bмагическая броня\b', 'маг. броня'),
    (r'(?i)\bмагической брони\b', 'маг. брони'),
    
    (r'(?i)\bвремя перезарядки\b', 'перезарядка'),
    (r'(?i)\bвремени перезарядки\b', 'перезарядки'),
    (r'(?i)\bвремя восстановления\b', 'перезарядка'),
    
    (r'(?i)Длительность:', 'Длит.:'),
    (r'(?i)Урон:', 'Урон:'),            # Keep
    (r'(?i)Перезарядка:', 'Перез.:'),
    (r'(?i)Радиус:', 'Рад.:'),
    (r'(?i)Стоимость маны:', 'Мана:'),
    (r'(?i)Расход маны:', 'Мана:'),
    
    # Time
    (r'(?i)\bсекунды\b', 'сек.'),
    (r'(?i)\bсекунд\b', 'сек.'),
    (r'(?i)\bсекунду\b', 'сек.'),
    (r'(?i)\bминуту\b', 'мин.'),
    (r'(?i)\bминуты\b', 'мин.'),
    (r'(?i)\bминут\b', 'мин.'),
    
    # HP / MP
    (r'(?i)\bмаксимального здоровья\b', 'макс. здоровья'),
    (r'(?i)\bмаксимальное здоровье\b', 'макс. здоровье'),
    (r'(?i)\bмаксимальной маны\b', 'макс. маны'),
    (r'(?i)\bмаксимальная мана\b', 'макс. мана'),
    
    # Misc
    (r'(?i)\bежесекундно\b', 'в сек.'),
    (r'(?i)\bкаждую секунду\b', 'в сек.'),
    (r'(?i)\bдополнительный\b', 'доп.'),
    (r'(?i)\bдополнительного\b', 'доп.'),
    (r'(?i)\bдополнительную\b', 'доп.'),
    (r'(?i)\bдополнительные\b', 'доп.'),
]

# Compile regexes
compiled_replacements = [(re.compile(pattern), replace_with) for pattern, replace_with in replacements]

with open(entities_path, 'rb') as f:
    data = f.read()

# Since the file has a BOM but is mostly UTF-8 encoded text that we can decode safely if we preserve the raw structure or carefully decode line by line
# It's safer to read the bytes, decode to string, replace, encode back, and re-add BOM.
try:
    text = data.decode('utf-8-sig') # strips BOM automatically
    original_text = text
    
    # We only want to replace in values, not keys. But these Russian words only appear in values anyway.
    # To be extremely safe, we only replace inside lines matching keys that end with description, description_simple, flavor, etc.
    lines = text.split('\r\n')
    changed_lines = 0
    
    def apply_regexes(line_text):
        for reg, rep in compiled_replacements:
            # Replicate original case if first letter was capitalized
            def match_case(m):
                original = m.group(0)
                if original[0].isupper():
                    return rep.capitalize()
                return rep
            
            line_text = reg.sub(match_case, line_text)
        return line_text

    for i, line in enumerate(lines):
        if '\t' in line:
            parts = line.split('\t', 1)
            key = parts[0].strip()
            # If it's a description string, apply shortening
            if 'description' in key or 'IMPACT' in key or 'FRAME' in key or 'flavor' in key or 'tooltip' in key:
                val = parts[1]
                new_val = apply_regexes(val)
                if new_val != val:
                    lines[i] = parts[0] + '\t' + new_val
                    changed_lines += 1

    if changed_lines > 0:
        new_text = '\r\n'.join(lines)
        bom = b'\xef\xbb\xbf'
        new_data = bom + new_text.encode('utf-8')
        
        with open(entities_path, 'wb') as f:
            f.write(new_data)
        
        print(f"Abbreviated text in {changed_lines} lines cleanly.")
    else:
        print("No lines matched for shortening.")

except Exception as e:
    print(f"Error: {e}")
