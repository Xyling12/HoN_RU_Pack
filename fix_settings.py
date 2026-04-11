import os
import re

interface_path = r'd:\HoN_RU_Pack\bundle\interface_en.str'

with open(interface_path, 'rb') as f:
    data = f.read()

replacements = [
    # Typos and blatant errors
    (b'options_submen_vol\t\xd0\xa2\xd1\x80\xd0\xbe\xd0\xbc\xd0\xba\xd0\xbe\xd1\x81\xd1\x82\xd1\x8c', 'options_submen_vol\tГромкость'.encode('utf-8')),
    (b'options_useoldshop\t\xd0\x9d\xd0\xbe\xd0\xb2\xd1\x8b\xd0\xb9', 'options_useoldshop\tСтарый'.encode('utf-8')),
    (b'options_oldmaininterface\t\xd0\x9d\xd0\xbe\xd0\xb2\xd1\x8b\xd0\xb9', 'options_oldmaininterface\tСтарый'.encode('utf-8')),
    
    # Grammatical
    (b'options_checkbox_goldlerp\t\xd0\x90\xd0\xbd\xd0\xb8\xd0\xbc\xd0\xb8\xd1\x80\xd0\xbe\xd0\xb2\xd0\xb0\xd0\xbd\xd0\xbd\xd1\x8b\xd0\xb9', 'options_checkbox_goldlerp\tАнимированное'.encode('utf-8')),
    
    # Poor translations
    (b'options_checkbox_frame_queuing\t\xd0\x9e\xd1\x87\xd0\xb5\xd1\x80\xd0\xb5\xd0\xb4\xd1\x8c \xd0\xba\xd0\xb0\xd0\xb4\xd1\x80\xd0\xbe\xd0\xb2', 'options_checkbox_frame_queuing\tБуферизация кадров'.encode('utf-8')),
    (b'options_rim_lighting\t\xd0\x9e\xd0\xb1\xd0\xbe\xd0\xb4\xd0\xbe\xd0\xb2\xd0\xbe\xd0\xb5 \xd0\xbe\xd1\x81\xd0\xb2\xd0\xb5\xd1\x89\xd0\xb5\xd0\xbd\xd0\xb8\xd0\xb5', 'options_rim_lighting\tКонтурное освещение'.encode('utf-8')),
    (b'options_label_display\t\xd0\x94\xd0\xb8\xd1\x81\xd0\xbf\xd0\xbb\xd0\xb5\xd0\xb9', 'options_label_display\tЭкран'.encode('utf-8')),
    (b'options_submen_gameoverlays\t\xd0\x9d\xd0\xb0\xd0\xbb\xd0\xbe\xd0\xb6\xd0\xb5\xd0\xbd\xd0\xb8\xd1\x8f \xd0\xb8\xd0\xb3\xd1\x80\xd1\x8b', 'options_submen_gameoverlays\tОверлеи'.encode('utf-8')),
    (b'options_checkbox_hero_holdaftermove\t\xd0\x9e\xd1\x82\xd0\xba\xd0\xbb\xd1\x8e\xd1\x87\xd0\xb8\xd1\x82\xd1\x8c \xd0\xb0\xd0\xb2\xd1\x82\xd0\xbe\xd0\xbc\xd0\xb0\xd1\x82\xd0\xb8\xd0\xb7\xd0\xb0\xd1\x86\xd0\xb8\xd1\x8e \xd0\xb0\xd0\xb3\xd1\x80\xd0\xbe', 'options_checkbox_hero_holdaftermove\tОтключить автоатаку после движения'.encode('utf-8')),
    (b'options_checkbox_sound_mutePings\t\xd0\x9e\xd1\x82\xd0\xba\xd0\xbb\xd1\x8e\xd1\x87\xd0\xb5\xd0\xbd\xd0\xb8\xd0\xb5 \xd0\xb7\xd0\xb2\xd1\x83\xd0\xba\xd0\xb0 \xd0\xb4\xd0\xb8\xd0\xba\xd1\x82\xd0\xbe\xd1\x80\xd0\xb0', 'options_checkbox_sound_mutePings\tОтключить звуки пингов'.encode('utf-8')),

    # Keybinds (Shopper -> Courier)
    (b'options_label_next_shopper_keybind\t\xd0\xa1\xd0\xbb\xd0\xb5\xd0\xb4\xd1\x83\xd1\x8e\xd1\x89\xd0\xb8\xd0\xb9 \xd0\xbf\xd0\xbe\xd0\xba\xd1\x83\xd0\xbf\xd0\xb0\xd1\x82\xd0\xb5\xd0\xbb\xd1\x8c', 'options_label_next_shopper_keybind\tСледующий курьер'.encode('utf-8')),
    (b'options_label_previous_shopper_keybind\t\xd0\x9f\xd1\x80\xd0\xb5\xd0\xb4\xd1\x8b\xd0\xb4\xd1\x83\xd1\x89\xd0\xb8\xd0\xb9 \xd0\xbf\xd0\xbe\xd0\xba\xd1\x83\xd0\xbf\xd0\xb0\xd1\x82\xd0\xb5\xd0\xbb\xd1\x8c', 'options_label_previous_shopper_keybind\tПредыдущий курьер'.encode('utf-8')),
    (b'options_label_nshopper_center_keybind\t\xd0\xa1\xd0\xbb\xd0\xb5\xd0\xb4\xd1\x83\xd1\x8e\xd1\x89\xd0\xb8\xd0\xb9 \xd0\xbf\xd0\xbe\xd0\xba\xd1\x83\xd0\xbf\xd0\xb0\xd1\x82\xd0\xb5\xd0\xbb\xd1\x8c \xd0\xb2 \xd1\x86\xd0\xb5\xd0\xbd\xd1\x82\xd1\x80\xd0\xb5', 'options_label_nshopper_center_keybind\tЦентрировать (следующий курьер)'.encode('utf-8')),
    (b'options_label_pshopper_center_keybind\t\xd0\x9f\xd1\x80\xd0\xb5\xd0\xb4\xd1\x8b\xd0\xb4\xd1\x83\xd1\x89\xd0\xb8\xd0\xb9 \xd0\xbf\xd0\xbe\xd0\xba\xd1\x83\xd0\xbf\xd0\xb0\xd1\x82\xd0\xb5\xd0\xbb\xd1\x8c \xd0\xb2 \xd1\x86\xd0\xb5\xd0\xbd\xd1\x82\xd1\x80\xd0\xb5', 'options_label_pshopper_center_keybind\tЦентрировать (предыдущий курьер)'.encode('utf-8')),
]

changed = 0
for pattern, replacement in replacements:
    # First decode string slightly to understand exactly what to replace without matching full sentences easily
    # Using regex to match prefix and replace rest of line
    
    # Simple direct string replacement since the keys are unique
    key_prefix = pattern.split(b'\t')[0] + b'\t'
    target_pattern = key_prefix + b'[^\r\n]*\r\n'
    
    def replacer(match):
        return replacement + b'\r\n'
    
    if re.search(target_pattern, data):
        data = re.sub(target_pattern, replacer, data)
        changed += 1

# Additional fixes: Use decoded text for complex regex to avoid byte encoding nightmares
text = data.decode('utf-8')

text = re.sub(r'options_useoldshop\t[^\r\n]*\r\n', 'options_useoldshop\tСтарый интерфейс магазина\r\n', text)
text = re.sub(r'options_oldmaininterface\t[^\r\n]*\r\n', 'options_oldmaininterface\tСтарый главный интерфейс\r\n', text)
text = re.sub(r'options_checkbox_hero_holdaftermove\t[^\r\n]*\r\n', 'options_checkbox_hero_holdaftermove\tОтключить автоатаку после движения\r\n', text)

text = re.sub(r'Самостоятельный инвентарь (\d)', r'Инвентарь \1 (на себя)', text)
text = re.sub(r'Способность самостоятельного применения (\d)', r'Способность \1 (на себя)', text)
text = re.sub(r'Дополнительная способность для самостоятельного применения (\d)', r'Доп. способность \1 (на себя)', text)

text = re.sub(r'options_checkbox_sound_mutePings\t[^\r\n]*\r\n', 'options_checkbox_sound_mutePings\tОтключить звуки пингов\r\n', text)
text = re.sub(r' options_submen_vol\t[^\r\n]*\r\n', 'options_submen_vol\tГромкость\r\n', text)

with open(interface_path, 'wb') as f:
    f.write(text.encode('utf-8'))

print(f"Applied fixes to interface options.")
