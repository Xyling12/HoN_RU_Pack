import re

ru_lines = []
with open(r'd:\Projects\HoN_RU_Pack\bundle\entities_en.str', 'rb') as f:
    data = f.read()
    bom = b''
    if data.startswith(b'\xef\xbb\xbf'):
        bom = b'\xef\xbb\xbf'
        data = data[3:]
    text = data.decode('utf-8')
    ru_lines = text.split('\r\n')

# Rules defining machine translated cliches vs Gamer Russian
word_replacements = {
    r'(?i)\bвражески[ехмй]\s+единиц[а-я]*': 'враги / юниты',
    r'(?i)\bсоюзны[ехмй]\s+единиц[а-я]*': 'союзники / юниты',
    r'(?i)\bнаносит\s+повреждения\b': 'наносит урон',
    r'(?i)\bвремя\s+восстановления\b': 'перезарядка',
    r'(?i)\bв\s+течение\s+(\{?[^\}]+\}?)\s+секунд[a-я]*': 'на X сек.',
    r'(?i)\bскорость\s+перемещения\b': 'скор. движ.',
    r'(?i)\bзаклинани[еяю]\b': 'способность / умение',
    r'(?i)\bочко(в)?\s+здоровья\b': 'ед. здоровья / ХП',
    r'(?i)\bбросить\s+вызов\b': 'провокация (taunt)', # common bad translation for taunt
    r'(?i)\bобласть\s+действия\b': 'радиус / AoE',
}

counts = {k: 0 for k in word_replacements.keys()}

for line in ru_lines:
    if '\t' in line:
        k, v = line.split('\t', 1)
        for pattern in word_replacements.keys():
            if re.search(pattern, v):
                counts[pattern] += 1

with open('cliche_analysis_results.txt', 'w', encoding='utf-8') as f:
    f.write("--- АНАЛИЗ 'МАШИННОГО' ПЕРЕВОДА ---\n")
    for pattern, suggestion in word_replacements.items():
        if counts[pattern] > 0:
            clean_p = pattern.replace('(?i)', '')
            f.write(f"[{counts[pattern]} раз] Найдено: '{clean_p}' -> Рекомендуется: '{suggestion}'\n")


