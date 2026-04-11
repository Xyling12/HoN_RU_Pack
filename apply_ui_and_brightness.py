import os
import re

interface_path = r'd:\HoN_RU_Pack\bundle\interface_en.str'

with open(interface_path, 'rb') as f:
    data = f.read()

replacements = [
    (b'hselect_label_hd_move_speed[^\r\n]*\r\n', 'hselect_label_hd_move_speed\tСкор. движ.\r\n'.encode('utf-8')),
    (b'hselect_label_hd_attack_range[^\r\n]*\r\n', 'hselect_label_hd_attack_range\tДальн. атак.\r\n'.encode('utf-8')),
    (b'tpp_attackspeed[^\r\n]*\r\n', 'tpp_attackspeed\tСкор. атак.\r\n'.encode('utf-8')),
    (b'tpp_movespeed[^\r\n]*\r\n', 'tpp_movespeed\tСкор. движ.\r\n'.encode('utf-8')),
    (b'hselect_label_hd_attack_speed[^\r\n]*\r\n', 'hselect_label_hd_attack_speed\t\tСкор. атак.\r\n'.encode('utf-8')),
    (b'options_label_value[^\r\n]*\r\n', 'options_label_value                         \tЯркость: ^w\r\n'.encode('utf-8')),
    (b'options_label_vibrance[^\r\n]*\r\n', 'options_label_vibrance                         \tКрасочность: ^w\r\n'.encode('utf-8'))
]

changed = 0
for pattern, target in replacements:
    if re.search(pattern, data):
        data = re.sub(pattern, target, data)
        changed += 1
        print("Replaced:", pattern.decode('utf-8'))
    else:
        # Note: If hselect_label_hd_attack_speed is totally missing (added in a later patch), we can just append it:
        if b'hselect_label_hd_attack_speed' not in data:
            data += b'\r\n' + target
            changed += 1
            print("Appended:", pattern.decode('utf-8'))
        else:
            print("Not found (Regex failed?):", pattern.decode('utf-8'))

with open(interface_path, 'wb') as f:
    f.write(data)

print(f"Applied {changed} UI replacements.")
