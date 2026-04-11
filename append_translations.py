import sys

new_translations = {
    "Mode_SameHeroDraft": "Same Hero Draft",
    "Ability_Artesia4_description_simple": "Создает Проекцию на ^o20 сек.^*, дающую союзным героям рядом ^o{20,30,40} ХП^* или ^oманы^* в сек. (зависит от режима: Лечение или Урон).\\n\\nТакже Проекция копирует ваши выстрелы ^494Arcane Missile^* и получает заряды ^494Arcane Bolts^*.\\n\\nПроекцию ^oможно перемещать^* (перезарядка 8 сек.).\\n\\n^gПосох Мастера:^* увеличивает дальность применения до глобальной, снижает перезарядку до 60 сек., а также снижает перезарядку перемещения до 4 сек. (+2 сек. если слишком близко к Колодцу врага).",
    "State_Circe_Ability1_Immobilized_name": "Ловушка",
    "State_Circe_Ability1_Immobilized_description": "",
    "State_Circe_Ability1_Immobilized_description2": "",
    "State_Circe_Ability1_Immobilized_description_simple": "",
    "State_Circe_Ability1_Immobilized_FRAME_effect": "По окончании прыгает на ближайшего вражеского героя в радиусе 350, нанося {80,140,200,260} маг. урона и накладывая Обездвиживание на {2,2.5,3,3.5} сек.",
    "Ability_Cthulhuphant1_description2:ult_boost": "\\r",
    "Ability_Cthulhuphant1_description_simple:ult_boost": "Бросок в указанном направлении, наносящий ^o{80,140,200,260} маг. урона^* и ^oОглушение на {1.25,1.5,1.75,2} сек.^* врагам.\\n\\nЗадетые существа (не герои) отбрасываются вперед как снаряды, наносящие ^o{12,16,20,24} маг. урона^* и ^oОглушение на {1.25,1.5,1.75,2} сек.^* героям.",
    "Ability_Cthulhuphant2_description2:ult_boost": "^gЭта способность усиливается Посохом Мастера.^*\\n\\n^gЭффект посоха:^* Снижает перезарядку на 3 сек.",
    "Ability_Cthulhuphant2_description_simple:ult_boost": "Выпускает залп водных импульсов перед собой каждую секунду в течение ^o4 сек.^*\\n\\nУрон от каждого импульса начинается с ^o{30,40,50,60} маг. урона^* и увеличивается на ^o{5,10,15,20} маг. урона^* каждую секунду. Макс. общий урон: ^o{200,300,400,500}^*.\\n\\n^gЭта способность усиливается Посохом Мастера.^*",
    "Ability_Cthulhuphant3_name:ult_boost": "^gTimes of the End^*",
    "Ability_Cthulhuphant3_description2:ult_boost": "^gУвеличивает вашу Силу на 2 на 24 сек. при нанесении урона вражескому герою способностями Trample, Obliterate или Dreams of Madness. Эффект складывается, у каждого заряда свой таймер.^*",
    "Ability_Cthulhuphant3_description_simple:ult_boost": "При получении физ. урона (не периодического) вы наносите ему ^oфиз. урон^* равный ^o{20,30,40,50}% вашей Силы^* (x2 обычным существам, 0.33x сила от иллюзий).\\n\\nНападающие получают -{30,40,50,60}% к получаемому лечению на 0.1 сек. Вы получаете ^o{5,10,15,20} реген. ХП в секунду на 2 сек.^* при получении урона спереди.\\n\\n^gУвеличивает вашу Силу на 2 на 24 сек. при нанесении урона вражескому герою вашими навыками. Эффект складывается, каждый заряд имеет свой таймер.^*",
    "State_Ctuhlhuphant_Ability3_Strength_name": "Конец Времен",
    "Ability_Deadwood2_name:ult_boost": "^gOakbolt*^*",
    "Ability_Deadwood2_description:ult_boost": "Deadwood ^gпостоянно носит дерево, которое^* он может бросить во врага ^g(не теряя его)^* для микро-оглушения и замедления.",
    "Ability_Deadwood2_description2:ult_boost": "^gАтаки теперь наносят 50% физ. урона по области вокруг цели.^*",
    "Ability_Deadwood2_description_simple:ult_boost": "^gПостоянно носит дерево, которое увеличивает^* урон на ^o{15,30,45,60}.^*\\n\\n^gАтаки теперь наносят 50% физ. урона по области вокруг цели.^*\\n\\n^gКаждая 4-я атака наносит микро-оглушение и накладывает убывающее замедление на 1 сек.^*\\n\\nУкажите на врага, чтобы бросить в него дерево, нанеся физ. урон (равный Урону от Атаки), ^oмикро-оглушение^* и убывающее ^o-75% скор. движ.^*\\n\\n^gБросок дерева не ломает дерево героя.^*",
    "Ability_Deadwood2_effect_header:ult_boost": "Эффект Son of a Birch",
    "Ability_Deadwood2_IMPACT_effect:ult_boost": "Бросает дерево в цель, оглушая ее на 0.1 сек., нанося физ. урон (от Атаки), и накладывает Son of a Birch на {1.5,2,2.5,3} сек. Не действует на врагов с иммунитетом к магии.",
    "Ability_Deadwood2_tooltip_flavor:ult_boost": "Вдохновлено скиллом Stormbolt.",
    "State_Deadwood_Ability2_name:ult_boost": "Дерево покрепче!",
    "State_Deadwood_Ability2_description:ult_boost": "Атаки теперь наносят 50% физ. урона по области в радиусе 300 вокруг цели\\n\\nКаждая 4-я атака наносит микро-оглушение и убывающее замедление на 0.75 сек.",
    "State_Electrician_Ability4_Immobilized_name": "Удар током",
    "State_Electrician_Ability4_Immobilized_FRAME_effect": "",
    "State_EmeraldWarden_Ability3_Immobilized_name": "Зарастание",
    "State_EmeraldWarden_Ability3_Immobilized_FRAME_effect": "{60,70,80,90} маг. урона в секунду (1.5x не героям)",
    "State_Goldenveil_Ability2_Immobilized_name": "Прыжок Сверху",
    "Ability_Kinesis2_Lift_name": "Lift",
    "Ability_Kinesis2_Lift_description_simple": "Поднимает в воздух ^oближайшего крипа или дерево^*, делая их неуязвимыми на ^o8 сек.^*\\n\\nИмеет до ^o{1,2,3,4} зарядов^* (восстанавливаются по одному раз в ^o{4,3.3,2.6,2} сек.^*).",
    "Ability_Kinesis2_Launch_name": "Launch",
    "Ability_Kinesis2_Launch_description_simple": "Бросает все поднятые объекты, нанося ^o{85,90,95,100} маг. урона^* за объект и накладывая ^o- {10,15,20,25}% скор. движ. на 2 сек.^*",
    "State_Pearl_Ability3_Dazed_name": "Ошеломление",
    "State_Pearl_Ability3_Dazed_description": "Дальность прыжка Pearl уменьшена на 50% на 3 сек.",
    "Ability_AmunRa2_description_simple:ult_boost": "^rСтоит 10% от макс. здоровья.^* Дает ^o{0.7,1.4,2.1,2.8} реген. ХП^*.\\n\\nВыстреливает 8 снарядов звездой, каждый наносит ^o{10,20,30,40} + {1.2,1.3,1.4,1.5}% от макс. здоровья ед. маг. урона^* (-^o10%^* за каждый след. снаряд), накладывая ^o-0.5 маг. брони и -3% скор. движ.^* (стакается) на 3 сек. Затем останавливаются на 2 сек. и возвращаются с тем же эффектом.\\n\\n^gТакже пассивно выстреливает Снаряды в врагов рядом (в приоритете - герои) по 1 шт. в сек., если Ashes to Ashes заряжен полностью.^*",
    "Ability_AmunRa3_description_simple:ult_boost": "Дает ^o{0.7,1.4,2.1,2.8} реген. ХП.^*\\n\\nПри получении урона вы наносите до ^o{20,30,40,50} маг. урона в секунду^* врагам рядом (зависит от полученного урона). Эффект исчезает, если не получать урон 4 сек.\\n\\n^gПри полном заряде пассивно выстреливает Огненную Звезду во врагов рядом (в приоритете - герои) по 1 снаряду в сек.^*",
    "State_Riftwalker_Ability2_Immobilized_name": "Общее Существование",
    "Ability_Riptide1_name:ult_boost": "^gWatery Tomb^*",
    "Ability_Riptide1_description2": "^gЭта способность усиливается Посохом Мастера.^*\\n\\n^gЭффект посоха:^* Отскакивает к 2 дополнительным целям.",
    "Ability_Riptide1_description2:ult_boost": "\\r",
    "Ability_Riptide1_IMPACT_effect:ult_boost": "Наносит ^o{95,170,250,330} маг. урона^* и ^oзамедляет скор. движ. на 50% и скор. атаки на 20%^* на ^o{2,2.5,3,3.5} сек.^*^g, отскакивает дважды (Улучшение Посохом Мастера)^*.",
    "Ability_Riptide3_name:ult_boost": "^gIn My Domain^*",
    "Ability_Riptide3_description2": "^gЭта способность усиливается Посохом Мастера.^*\\n\\n^gЭффект посоха:^* Вы генерируете Щит (20 ХП в сек., макс. 340), пока стоите в воде. Пока есть щит, вы считаетесь находящимся в воде.",
    "Ability_Riptide3_description2:ult_boost": "\\r",
    "Ability_Riptide3_description_simple:ult_boost": "Дает баффы ^oв воде^*:\\n- Ловкость: ^o{20,30,40,50}^*\\n- Скор. движ.: ^o{15,30,45,60}^*\\n- Прохождение сквозь существ\\n^g- Генерирует Щит (до 340) по 20 ХП в сек. С щитом вы всегда 'в воде'.^*\\n\\nСоздает ^oпостоянную лужу воды с Беспрепятственным обзором^* (разрешена только 1 лужа).",
    "State_Riptide_Ability3_FRAME_effect:ult_boost": "Щит по 20 ХП в сек. (до 340). Вы 'в воде', пока есть щит.",
    "State_Riptide_Ability3_Staff_name": "Водяной Щит",
    "State_Riptide_Ability3_Staff_FRAME_effect": "Щит растет по 20 ХП в сек. (до 340).\\nВы 'в воде', пока есть щит.",
    "Ability_ShadowBlade1_description_simple": "Активируйте, чтобы нанести ^o{70,120,170,220} маг. урона и замедлить скор. движ. на 25%^* на ^o{2.5,3,3.5,4} сек.^* врагам рядом.\\n\\nЖизнь формы Gargantuan 15 сек. или до смены формы.\\nGargantuan дает ^o{4,8,12,16} Силы^*. Дает ^o{3,6,9,12} брони и {1,2,3,4} маг. брони^* первые 3.5 сек.",
    "State_Energizer_Active_Unitwalking_name": "Перезарядка Energizer",
    "State_Energizer_Buff_Unitwalking_name": "Energized",
    "Item_AbyssalFlower_name": "Abyssal Flower",
    "Item_AbyssalFlower_description": "Данный предмет можно ^tразобрать^*.",
    "Item_AbyssalFlower_description_simple": "Примените на врага, чтобы наложить Безмолвие.",
    "Item_AbyssalFlower_search_terms": "abyssalflower,flower,abyssal,orchidmalevolence,orchid,malevolence,af,om,intelligence,damage,dmg,attackspeed,as,manaregeneration,silence,amplify,regeneration,цветок,бездна,абиссал,цветокбездны",
    "Item_AbyssalFlower_effect_header": "Эффект Abyssal Flower",
    "Item_AbyssalFlower_shop_flavor": "Собранный в землях вне лучей Newerth, адский цветок пахнет смертью и покрыт обжигающими шипами. Несмотря на это, он ценится из-за боевого безумия, которое он вызывает. Уколы шипов ускоряют восстановление магических сил, а цветки сжигают душу врага.",
    "Item_AbyssalFlower_shop_categories": "Filter_Intelligence,Filter_Damage,Filter_AttackSpeed,Filter_Regeneration,Filter_Activatable",
    "Item_AbyssalFlower_IMPACT_effect": "Накладывает ^oAbyssal Flower^* на цель на ^o3 сек.^*.",
    "Item_AbyssalFlower_tooltip_flavor": "",
    "State_AbyssalFlower_name": "Abyssal Flower",
    "State_AbyssalFlower_FRAME_effect": "Оставляет видимый след за пораженной целью",
    "State_Stunned_name": "Оглушение",
    "State_Stunned_Knockdown_name": "Оглушение",
    "Shout_MyTeamSucks_name": "Моя команда — отстой",
    "Shout_MyTeamSucks_description": "Тьфу... Моя команда просто отстой!",
    "Shout_MyTeamSucks_description_simple": "Моя команда — отстой!",
    "Gesture_IQTest_name": "Тест на IQ",
    "Gesture_IQTest_description": "Проверить чей-то IQ с помощью этого точного сканера!",
    "Gesture_IQTest_description_simple": "Проверить чей-то IQ!",
    "Gesture_Questionmarks_name": "Вопросительный знак",
    "Gesture_Questionmarks_description": "Сложное поведение, что вы делаете??",
    "Gesture_Questionmarks_description_simple": "Что ты делаешь??",
    "Roast_Watergun_name": "Водяной пистолет",
    "Roast_Watergun_description": "Отпразднуй Сонгкран (Songkran) битвой на водяных пистолетах!",
    "Roast_Watergun_description_simple": "Битва на воде!",
    "Shout_SabaiSabai_name": "Сабай-Сабай!",
    "Shout_SabaiSabai_description": "Сабай-Сабай!",
    "Shout_SabaiSabai_description_simple": "Сабай-Сабай!"
}

# The keys from latest_changes.txt that are NOT in new_translations will be skipped, or saved exactly as english text.
with open('latest_changes.txt', 'r', encoding='utf-8') as f:
    raw_lines = f.read().splitlines()

formatted_lines = []
for line in raw_lines:
    if '\t' in line:
        k = line.split('\t')[0]
        original_prefix = line.split('\t', 1)[0]
        # count tabs correctly or just use the whole prefix
        tabs = ''
        if len(line.split('\t')) > 1:
            idx = line.find('\t')
            prefix_tabs = line[idx:line.find(line.split('\t')[-1])]
            # extract string of tabs
            tabs_chunk = line[len(k):line.find(line.split('\t')[-1])]
            # actually just replace everything after the tabs with translation
            v = new_translations.get(k, line.split('\t')[-1])
            formatted_lines.append(f"{k}{tabs_chunk}{v}")

target_file = r'd:\Projects\HoN_RU_Pack\bundle\entities_en.str'
with open(target_file, 'rb') as f:
    content = f.read()

# Make sure ends with crlf
if not content.endswith(b'\r\n'):
    content += b'\r\n'

append_content = '\r\n'.join(formatted_lines).encode('utf-8')
content += append_content

with open(target_file, 'wb') as f:
    f.write(content)

print(f"Successfully appended {len(formatted_lines)} lines to entities_en.str")
