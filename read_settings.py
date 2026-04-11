import sys, os
sys.stdout.reconfigure(encoding='utf-8')

path = r'd:\HoN_RU_Pack\bundle\interface_en.str'
with open(path, 'rb') as f:
    data = f.read()

# Remove BOM if present for decoding
bom = b'\xef\xbb\xbf'
text = data.lstrip(bom).decode('utf-8', errors='replace')

target_keys = [
    'options_checkbox_frame_queuing',
    'options_frame_queuing_tip',
    'options_checkbox_frame_queuing_enabled',
    'options_checkbox_frame_queuing_disabled_flush_frame_end',
    'options_checkbox_frame_queuing_disabled_flush_frame_start',
    'options_rim_lighting',
    'options_rim_lighting_tip',
    'options_simple_rim_a',
    'options_label_vibrance',
    'options_vibrance_tip_header',
    'options_vibrance_tip',
    'options_label_self_cast_keybind',
    'options_label_self_cast_keybind_tooltip',
    'options_label_value',
    'options_value_tip_header',
    'options_label_brightness',
]

for line in text.split('\r\n'):
    if '\t' not in line:
        continue
    key = line.split('\t')[0].strip()
    if key in target_keys:
        val = line.split('\t', 1)[1].strip()
        print(f"{key}:\n  CURRENT: {val}\n")
