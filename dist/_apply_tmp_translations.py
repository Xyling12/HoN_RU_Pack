import os
import sys

bundle_path = r"D:\HoN_RU_Pack\bundle\interface_en.str"
tmp_path = r"D:\HoN_RU_Pack\$tmp\interface_en.str"

def parse_str(filepath):
    d = {}
    lines = []
    with open(filepath, 'r', encoding='utf-8') as f:
        for idx, line in enumerate(f):
            lines.append(line)
            if '\t' in line and not line.startswith('//'):
                parts = line.split('\t', 1)
                if len(parts) == 2:
                    k = parts[0].strip()
                    v = parts[1].rstrip('\n\r')
                    d[k] = (idx, v)
    return d, lines

bundle_dict, bundle_lines = parse_str(bundle_path)
tmp_dict, tmp_lines = parse_str(tmp_path)

# Keys we absolutely DO NOT want to translate from $tmp
BLOCKED_KEYS = {
    'BACKSPACE', 'TAB', 'ENTER', 'ESC', 'SPACE', 'CAPS_LOCK', 'SHIFT', 'LSHIFT', 'RSHIFT',
    'LCTRL', 'RCTRL', 'ALT', 'LALT', 'RALT', 'WIN', 'LWIN', 'RWIN', 'UP', 'LEFT', 'DOWN', 'RIGHT',
    'NUM_LOCK', 'DIVIDE', 'MULTIPLY', 'ADD', 'SUBTRACT', 'DECIMAL', 'NUM_ENTER',
    'general_win', 'general_rate_percent'
}

BLOCKED_PREFIXES = ('game_server_region_', 'options_region_', 'options_auto_region_')

# Specific fixes the user explicitly asked for
MANUAL_FIXES = {
    # Matchmaking Roles (Reverted to English due to UI limitations)
    'player_role_carry': 'Carry',
    'player_role_mid': 'Mid',
    'player_role_hardsupport': 'Hard Support',
    'player_role_offlane': 'Offlane',
    'player_role_softsupport': 'Soft Support',
    'player_role_jungle': 'Jungle',
    'roles_offlane': 'Offlane',
    'roles_solo': 'Solo-Offlane',
    
    # Matchmaking badge - shorten "ВЫСОКИЙ СПРОС" to fit button
    'rolepick_highdemand_badge': 'ВЫС. СПРОС',
    
    # Matchmaking tab label (multiple keys used in different UI contexts)
    'general_matchmaking': 'Подбор игры',
    'ht_lobby_prompt_right': 'Подбор игры',
    
    # Matchmaking Regions (Reverted to English/Abbreviations)
    'mm_region_code_unitedstateseast': 'USE',
    'mm_region_code_unitedstateswest': 'USW',
    'mm_region_code_southamerica': 'BR',
    'mm_region_code_southeastasia': 'SEA',
    'mm_region_code_europe': 'EU',
    'mm_region_code_australia': 'AU',
    'mm_region_code_thailand': 'TH',
    'mm_region_code_cis': 'CIS',
    
    # Matchmaking UI
    'mm_select_regions': 'Select Regions',
    'matchmaking_modes_title': 'Выбор игровых режимов',
    'mm3_ranked_queue_type': 'Рейтинг',
    'mm3_pvp_simplemaps_desc': 'Калдавар — это стандартная карта 5 на 5. \\nMidwars — это динамичная однополосовая карта.',
    
    # Plinko translations
    'plinko_drop': 'Бросить!',
    'plinko_board_change': 'Сменить доску',
    'plinko_ticket_cost': 'Стоимость билетов',
    'plinko_ticket_cost_desc': 'Цена увеличивается при ежедневных играх',
    'plinko_drops_1': 'Бросок 1 шт.',
    'plinko_drops_2': 'Бросок 2-9 шт.',
    'plinko_drops_10': 'Бросок 10+ шт.',
    'plinko_drops_today': 'Бросков сегодня: {value}',
    'plinko_drops_until_next': 'Остался {value} бросок до следующего уровня',
    'plinko_resets_in': 'Обновление через {time}',
    'plinko_jackpot_name': 'Джекпот',
    'plinko_jackpot_desc': 'Главный приз',
}

# Apply manual fixes
for mk, mv in MANUAL_FIXES.items():
    if mk in bundle_dict:
        b_idx, b_val = bundle_dict[mk]
        original_line = bundle_lines[b_idx]
        prefix = original_line.split('\t')[0]
        tabs = original_line[len(prefix):].split(b_val)[0] if b_val in original_line else '\t\t'
        if not tabs.strip('\t') == '':
            tabs = '\t\t'
        bundle_lines[b_idx] = f"{prefix}{tabs}{mv}\n"
        print(f"Applied manual fix: {mk} -> {mv}")
    else:
        # Append to the end of the file
        bundle_lines.append(f"{mk}\t\t{mv}\n")
        print(f"Appended missing fix to end of file: {mk} -> {mv}")

with open(bundle_path, 'w', encoding='utf-8') as f:
    f.writelines(bundle_lines)

print(f"Fixes applied successfully.")
