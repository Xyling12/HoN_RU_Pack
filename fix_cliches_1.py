import os

bundle_dir = r"d:\HoN_RU_Pack\bundle"
files_to_process = [f for f in os.listdir(bundle_dir) if f.endswith('.str')]

replacements = [
    ("Активируйте, чтобы ", "При активации: "),
    ("Выберите локацию и ", "Примените на область и "),
    ("Выберите локацию, чтобы ", "Примените на область, чтобы "),
    ("Выберите место, чтобы ", "Примените на область, чтобы "),
    ("Выберите область, чтобы ", "Примените на область, чтобы "),
    ("Выберите врага, чтобы ", "Примените на врага, чтобы "),
    ("Выберите врага, ", "Примените на врага, "),
    ("Выберите отряд, чтобы ", "Примените на юнита, чтобы "),
    ("Выберите отряд или позицию, чтобы ", "Примените на юнита или область, чтобы "),
    ("Выберите отряд или локацию, чтобы ", "Примените на юнита или область, чтобы "),
    ("Нацельтесь на ", "Примените на "),
    ("Выберите поддержание, чтобы ", "Прерываемая способность. Применяйте, чтобы "),
    ("Переключаемый^*", "Переключаемая способность^*"),
    ("Переключаемый^", "Переключаемая способность^"),
    ("Переключите, чтобы ", "При переключении: "),
    ("Переключитесь на ", "При переключении на "),
    (" обеспечивает видение ", " дает обзор "),
    ("Обеспечивает видение ", "Дает обзор "),
    ("Обеспечивает ауру ", "Дает ауру "),
    ("Обеспечивает ", "Дает "),
    ("Предоставляет видение", "Открывает обзор"),
    ("Предоставляет ", "Дает "),
    ("Дает вам ", "Дает "),
    ("Дает вашим атакам ", "Ваши атаки получают "),
    ("нацеливании на ", "применении на "),
    ("противрагов", "против врагов"),
    ("Обжог", "Ожог"),
]

audit_log = []

for filename in files_to_process:
    filepath = os.path.join(bundle_dir, filename)
    if not os.path.exists(filepath):
        print(f"Warning: {filepath} not found.")
        continue
        
    with open(filepath, 'r', encoding='utf-8-sig') as f:
        lines = f.readlines()
        
    new_lines = []
    changes_in_file = 0
    for line in lines:
        if '\t' not in line:
            new_lines.append(line)
            continue
            
        parts = line.split('\t')
        key = parts[0]
        val = parts[-1]
        
        if not val.strip() or val.strip().startswith('//'):
            new_lines.append(line)
            continue
            
        original_val = val
        for old_str, new_str in replacements:
            if old_str in val:
                val = val.replace(old_str, new_str)
                
        if val != original_val:
            changes_in_file += 1
            audit_log.append(f"[{key}]\n- {original_val.strip()}\n+ {val.strip()}\n")
            
        parts[-1] = val
        new_lines.append('\t'.join(parts))
        
    if changes_in_file > 0:
        with open(filepath, 'w', encoding='utf-8-sig') as f:
            f.writelines(new_lines)
        print(f"Updated {changes_in_file} lines in {filename}")

with open(r"d:\HoN_RU_Pack\cliche_fixes_audit.txt", 'w', encoding='utf-8') as f:
    f.write("=== АУДИТ ЗАМЕН КЛИШЕ ===\n\n")
    f.write("\n".join(audit_log))
    f.write(f"\nВсего изменено строк: {len(audit_log)}\n")

print(f"Done. Fixed {len(audit_log)} lines across all files.")
print(f"Audit log saved to d:\\HoN_RU_Pack\\cliche_fixes_audit.txt")
