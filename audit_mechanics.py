import re
import collections

ru_lines = []
with open(r'd:\Projects\HoN_RU_Pack\bundle\entities_en.str', 'rb') as f:
    data = f.read()
    bom = b''
    if data.startswith(b'\xef\xbb\xbf'):
        bom = b'\xef\xbb\xbf'
        data = data[3:]
    text = data.decode('utf-8')
    ru_lines = text.split('\r\n')

terms = [
    r'(?i)\bоглуш(ен[а-я]+|ает|ит)\b',
    r'(?i)\bнемот[ауеы]\b',
    r'(?i)\bбезмолви[еяю]\b',
    r'(?i)\bоцепенени[еяю]\b',
    r'(?i)\bкорн(и|ях|ями)\b',
    r'(?i)\bобезоружив(ани[ея]|ает)\b',
    r'(?i)\bнедоумени[еяю]\b',
]

stats = {term: [] for term in terms}

for line in ru_lines:
    if '\t' in line:
        k, v = line.split('\t', 1)
        for term in terms:
            match = re.search(term, v)
            if match:
                stats[term].append(match.group())

with open('mechanics_audit_results.txt', 'w', encoding='utf-8') as f:
    f.write("--- АУДИТ МЕХАНИК ---\n")
    for term in terms:
        counter = collections.Counter([w.lower() for w in stats[term]])
        f.write(f"Паттерн {term}:\n")
        for word, count in counter.most_common():
            f.write(f"  {word}: {count} раз\n")

