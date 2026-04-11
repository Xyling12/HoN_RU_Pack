# fix_ability_names_quality.py
# Comprehensive quality pass on all ability names and descriptions
# Rules:
#  - Names: natural Russian gaming language, not literal machine translation
#  - Hero names in descriptions: DO NOT translate
#  - Remove remaining English words from names
#  - Fix typos and awkward grammar

import sys, re
sys.stdout.reconfigure(encoding='utf-8')

path = r'd:\HoN_RU_Pack\bundle\entities_en.str'
with open(path, 'rb') as f: data = f.read()
bom = b'\xef\xbb\xbf'
assert data.startswith(bom)
text = data[3:].decode('utf-8')
lines = text.split('\r\n')

key_to_idx = {}
for i, line in enumerate(lines):
    if '\t' not in line: continue
    key = line.split('\t')[0].strip()
    if key not in key_to_idx:
        key_to_idx[key] = i

def get_val(key):
    idx = key_to_idx.get(key)
    if idx is None: return None
    parts = lines[idx].split('\t', 1)
    return parts[1].strip() if len(parts) > 1 else ''

def set_val(key, new_val):
    idx = key_to_idx.get(key)
    if idx is None: return False
    tab_prefix = lines[idx].split('\t', 1)[0]
    lines[idx] = tab_prefix + '\t' + new_val
    return True

fixes = 0

# ── Ability NAME fixes ──────────────────────────────────────────────────────
# Format: (key, new_name)
NAME_FIXES = [
    # Accursed
    ('Ability_Accursed3_name', 'Испепеление'),  # "Обжог" — неграмотно
    # Adrenaline
    ('Ability_Adrenaline3_name', 'Раскалённый осколок'),  # "Осколок тлеющего угля" — слишком длинно
    ('Ability_Adrenaline4_name', 'Нимб смерти'),  # OK, keep
    # Aluna
    ('Ability_Aluna4_name', 'Изумрудный всплеск'),  # "Изумрудно-красный" — бессмысленно
    # AmunRa
    ('Ability_AmunRa4_name', 'Пирокластическое возрождение'),  # "Пирокластическое перерождение" — ok but too literal
    # Arachna
    ('Ability_Arachna3_name', 'Меткость паука'),  # "Точность" — слишком общее
    # Armadon
    ('Ability_Armadon1_name', 'Слюнная бомба'),  # "Сопливый шторм" — грубо, неточно
    ('Ability_Armadon3_name', 'Броня армадилло'),  # "Армордилло" — непонятно
    # Artillery
    ('Ability_Artillery4_name', 'Самонаводящийся снаряд'),  # "Самонаводящаяся ракета"
    # Behemoth
    ('Ability_Behemoth4_name', 'Сейсмический удар'),  # "Ударная волна" — слишком общо
    # Berzerker
    ('Ability_Berzerker3_name', 'Похищение силы'),  # "Вытягивание силы" — awkward
    # Blacksmith
    ('Ability_Blacksmith3_name', 'Буйство'),  # "Бешенство" — слишком агрессивно для баффа
    ('Ability_Blacksmith4_name', 'Хаотичное горение'),  # "Хаотичное пламя"
    # Blitz
    ('Ability_Blitz2_name', 'Карманная кража'),  # "Воровство" — слишком просто
    ('Ability_Blitz3_name', 'Стремительность'),  # "Ускорение" — слишком общее
    # BloodHunter
    ('Ability_BloodHunter1_name', 'Кровавая рапсодия'),  # "Кровавое безумие" — ok but try
    ('Ability_BloodHunter3_name', 'Кровавый след'),  # "Чутье крови"
    # Bubbles
    ('Ability_Bubbles1_name', 'Серфинг на щите'),  # "Серфинг на панцире"
    # Calamity
    ('Ability_Calamity3_name', 'Костяное пламя'),  # "Погребальный костер"
    # Chi
    ('Ability_Chi2_name', 'Тысяча порезов'),  # OK
    ('Ability_Chi3_name', 'Просветление духа'),  # "Просветление" — слишком общее
    # Chipper
    ('Ability_Chipper3_name', 'Фокусирующий буфер'),  # "Буфер фокуса" — обратный порядок слов
    ('Ability_Chipper4_name', 'Лезвие пилы'),  # "Противостояние пилы" — неточно
    # Chronos
    ('Ability_Chronos4_name', 'Хронополе'),  # OK
    # Circe
    ('Ability_Circe4_name', 'Искажённый облик'),  # "Искаженный лик" — ok
    # CorruptedDisciple
    ('Ability_CorruptedDisciple2_name', 'Проводящий канал'),  # "Испорченный поддержание" — grammar error
    # Dampeer
    ('Ability_Dampeer1_name', 'Устрашение'),  # "Терроризирование" — too harsh
    ('Ability_Dampeer2_name', 'Вампирский бросок'),  # "Вампирский полет"
    # Deadlift
    ('Ability_Deadlift1_name', 'Нечестивый натиск'),  # "Нечестивая сила"
    ('Ability_Deadlift2_name', 'Сокрушительный таран'),  # "Натиск"
    # Deadwood
    ('Ability_Deadwood1_name', 'Гнилые корни'),  # "Гнилая хватка"
    ('Ability_Deadwood3_name', 'Лесоповал'),  # "Вырубка" — ok but too generic
    # Defiler
    ('Ability_Defiler2_name', 'Могильная тишь'),  # "Могильная тишина"
    ('Ability_Defiler3_name', 'Похищение души'),  # "Вытягивание души"
    # DementedShaman
    ('Ability_DementedShaman3_name', 'Несокрушимость'),  # "Несокрушимый"
    # Devourer
    ('Ability_Devourer1_name', 'Потрошащий крюк'),  # "Крюк мясника"
    ('Ability_Devourer2_name', 'Гнилостный яд'),  # "Разложение"
    # DoctorRepulsor
    ('Ability_DoctorRepulsor1_name', 'Магнитное устройство'),  # OK
    ('Ability_DoctorRepulsor4_name', 'Безумный разгон'),  # "Безумная скорость"
    # DrunkenMaster
    ('Ability_DrunkenMaster2_name', 'Пьяная поступь'),  # "Пошатывание" — слишком буквально
    ('Ability_DrunkenMaster3_name', 'Фляга'),  # "Питье" — слишком просто
    # Electrician
    ('Ability_Electrician1_name', 'Статическая хватка'),  # "Статический захват"
    ('Ability_Electrician3_name', 'Энергетический сифон'),  # "Поглощение энергии"
    ('Ability_Electrician4_name', 'Очищающий разряд'),  # "Очищающий удар" — это шок, не удар
    # EmeraldWarden
    ('Ability_EmeraldWarden1_name', 'Замолкающий выстрел'),  # "Обезмолвливающий выстрел" — неграмотно
    ('Ability_EmeraldWarden3_name', 'Капкан корней'),  # "Разраоглушениеие" — явная ошибка
    # Empath
    ('Ability_Empath4_name', 'Единение'),  # "Как один" — разговорно
    # Engineer
    ('Ability_Engineer3_name', 'Турбонаддув'),  # "Перегрузка" – used by multiple heroes
    # Fayde
    ('Ability_Fayde1_name', 'Жатва'),  # "Отсев" — неточно, это атака косой
    # FlintBeastwood
    ('Ability_FlintBeastwood2_name', 'Разрывные снаряды'),  # "Экспансивные снаряды"
    ('Ability_FlintBeastwood3_name', 'Зоркий глаз'),  # "Меткий стрелок"
    ('Ability_FlintBeastwood4_name', 'Золотой выстрел'),  # "Денежный выстрел"
    # Flux
    ('Ability_Flux2_name', 'Магнитный импульс'),  # "Магнитный выброс"
    ('Ability_Flux3_name', 'Переключение полюсов'),  # "Смена полярности"
    # ForsakenArcher
    ('Ability_ForsakenArcher2_name', 'Раздвоенный залп'),  # "Раздвоенный огонь"
    # Gadget_EmeraldWarden
    ('Ability_Gadget_EmeraldWarden3_name', 'Сработать корневой капкан'),  # "Активировать разраоглушениеие"
    # Gauntlet
    ('Ability_Gauntlet1_name', 'Адская зарядка'),  # "Адская нестабильность"
    # Geomancer
    ('Ability_Geomancer1_name', 'Нырок под землю'),  # "Подкоп"
    ('Ability_Geomancer3_name', 'Геологическое преследование'),  # "Гео-преследование"
    # Gladiator
    ('Ability_Gladiator2_name', 'Передышка'),  # "Противостояние" — used elsewhere too
    ('Ability_Gladiator4_name', 'Атака колесницей'),  # "Зов к оружию"
    # Goldenveil
    ('Ability_Goldenveil2_name', 'Насест'),  # "Присесть и нырнуть" — слишком длинно
    ('Ability_Goldenveil4_name', 'Золотой коготь'),  # "Жадюга" — разговорно
    # Grinex
    ('Ability_Grinex2_name', 'Охота из тени'),  # "Охота из разлома"
    ('Ability_Grinex3_name', 'Удар из бездны'),  # OK
    ('Ability_Grinex4_name', 'Теневой натиск'),  # "Иллюзорная атака"
    # Gunblade
    ('Ability_Gunblade4_name', 'Захватывающий крюк'),  # "Захватывающий выстрел"
    # Hammerstorm
    ('Ability_Hammerstorm3_name', 'Сокрушительный замах'),  # "Могучий замах"
    # Hellbringer
    ('Ability_Hellbringer3_name', 'Злобное присутствие'),  # "Злое присутствие"
    # Ichor
    ('Ability_Ichor1_name', 'Вампиризм'),  # "Пампиризм" — опечатка
    # Jeraziah
    ('Ability_Jeraziah2_name', 'Защитная аура'),  # "Защитный оберег"
    # Kane
    ('Ability_Kane2_name', 'Двойная аура'),  # "Баланс сил" — ok but not descriptive
    ('Ability_Kane4_name', 'Дуэль'),  # "Противостояние" — дублируется с Gladiator2
    # KeeperOfTheForest
    ('Ability_KeeperOfTheForest1_name', 'Покровительство природы'),  # "Руководство природы" — machine transl
    ('Ability_KeeperOfTheForest3_name', 'Единая сила'),  # "Сила в числах" — machine transl
    # Kinesis
    ('Ability_Kinesis2_name', 'Телекинез'),  # "Телекинетический контроль" — слишком длинно
    ('Ability_Kinesis3_name', 'Щит поглощения'),  # "Врожденная защита"
    ('Ability_Kinesis4_name', 'Стазисный удар'),  # "Удар стазиса" — обратный порядок
    # KingKlout
    ('Ability_KingKlout3_name', 'Призыв миньонов'),  # "Призыв" — слишком общее
    # Klanx
    ('Ability_Klanx2_name', 'Я.С.Т.Р.Е.Б.'),  # OK — acronym
    # Kraken
    ('Ability_Kraken4_name', 'Выпустить Кракена!'),  # "Выпустить кракена!" — capital K
    # Legionnaire
    ('Ability_Legionnaire2_name', 'Устрашающая атака'),  # "Устрашающий рывок"
    # Lodestone
    ('Ability_Lodestone2_name', 'Удар головой'),  # OK
    ('Ability_Lodestone3_name', 'Каменные пластины'),  # "Пластины Лодестоуна" — hero name untranslated correct
    # Madman
    ('Ability_Madman1_name', 'Выслеживание'),  # "Преследование" — used by Prophet too
    ('Ability_Madman3_name', 'Открытая рана'),  # "Рана" — слишком просто
    # Magebane
    ('Ability_Magebane2_name', 'Антимагический рывок'),  # "Вспышка анти-магии"
    ('Ability_Magebane3_name', 'Мантры мастера'),  # "Мастер мантры" — обратный порядок слов
    ('Ability_Magebane4_name', 'Разлом разума'),  # "Разлом маны" — ok but inaccurate
    # Magmus
    ('Ability_Magmus2_name', 'Паровая сауна'),  # "Паровая баня" — ok
    # Maliken
    ('Ability_Maliken3_name', 'Адское рвение'),  # "Рвение Хеллборна" — not translating hero name
    # ManiacLord
    ('Ability_ManiacLord1_name', 'Ужасающий яд'),  # "Жуткий яд"
    # Martyr
    ('Ability_Martyr3_name', 'Убеждение Сола'),  # OK — Sol is not a hero name
    # MasterOfArms
    ('Ability_MasterOfArms3_name', 'Смена оружия'),  # "Улучшение оружия"
    # Midas
    ('Ability_Midas3_name', 'Мистический прыжок'),  # "Стихийный варп" — machine transl
    # Mimix
    ('Ability_Mimix3_name', 'Эхо-атаки'),  # "Эхо-удары"
    # Monarch
    ('Ability_Monarch1_name', 'Ослепляющая пыльца'),  # "Калечащая пыльца" — she blinds, not maims
    # Moraxus
    ('Ability_Moraxus2_name', 'Мистическая броня'),  # "Мистический щит"
    ('Ability_Moraxus4_name', 'Боевая матрица'),  # "Матракс" — непонятно
    # Myrmidon
    ('Ability_Myrmidon2_name', 'Волшебный карп'),  # OK
    ('Ability_Myrmidon3_name', 'Волновой удар'),  # "Волновая форма" — скучно
    ('Ability_Myrmidon4_name', 'Принудительная эволюция'),  # OK
    # NightHound
    ('Ability_NightHound4_name', 'Вечная тень'),  # "Невидимость" — слишком общее
    # Nitro
    ('Ability_Nitro1_name', 'Баллистическая атака'),  # "Баллистический"
    ('Ability_Nitro3_name', 'Лишний вес'),  # "Третий лишний" — awkward
    # Nomad
    ('Ability_Nomad3_name', 'Кочевник'),  # "Странник" — character is a Nomad
    # Nymphora
    ('Ability_Nymphora1_name', 'Взрывной стручок'),  # "Нестабильный стручок" fixable
    ('Ability_Nymphora2_name', 'Огонёк Нимфоры'),  # "Рвение Нимфоры" — rвение means zeal not wisp
    # Oogie
    ('Ability_Oogie2_name', 'Смоляной огонь'),  # "Пожар" — too generic
    ('Ability_Oogie3_name', 'Раскалённая ярость'),  # "Разожженная ярость"
    # Ophelia
    ('Ability_Ophelia2_name', 'Суд природы'),  # "Суд Офелии" — hero name ok to keep
    # Pandamonium
    ('Ability_Pandamonium1_name', 'Ливень ударов'),  # "Шквал ударов"
    ('Ability_Pandamonium3_name', 'Пушечное ядро'),  # "Ядро пушки"
    # Parallax
    ('Ability_Parallax3_name', 'Тёмная энергия'),  # "Темная мана"
    # Parasite
    ('Ability_Parasite3_name', 'Высасывающий яд'),  # "Вытягивающий яд"
    # Pearl
    ('Ability_Pearl1_name', 'Удушающий пузырь'),  # "Удушение" — too generic
    ('Ability_Pearl3_name', 'Успокаивающая аура'),  # "Успокаивающее присутствие"
    # PlagueRider
    ('Ability_PlagueRider3_name', 'Жертва'),  # "Угасание" — not descriptive
    # PollywogPriest
    ('Ability_PollywogPriest3_name', 'Заморозка языком'),  # "Язык связан" — machine transl
    ('Ability_PollywogPriest4_name', 'Варды Вуду'),  # OK
    # Predator
    ('Ability_Predator3_name', 'Плотоядность'),  # "Плотоядный" — should be noun form
    # Prisoner
    ('Ability_Prisoner1_name', 'Ядро на цепи'),  # "Старое ядро на цепи" — too long
    ('Ability_Prisoner3_name', 'Несломленный'),  # "Бунт одиночки" — inaccurate
    # Prophet
    ('Ability_Prophet1_name', 'Карающий ворон'),  # "Изнурение" — not descriptive
    ('Ability_Prophet3_name', 'Проклятие пророка'),  # "Преследование" — too generic & used by Madman
    # PuppetMaster
    ('Ability_PuppetMaster1_name', 'Марионеточные путы'),  # "Захват кукловода"
    ('Ability_PuppetMaster2_name', 'Кукольный театр'),  # "Кукольный спектакль"
    # Pyromancer
    ('Ability_Pyromancer3_name', 'Пыл огня'),  # "Пыл" — слишком коротко
    # Rally
    ('Ability_Rally1_name', 'Боевой приказ'),  # "Принуждение" — inaccurate
    ('Ability_Rally2_name', 'Боевой рёв'),  # "Деморализующий рев"
    # Rampage
    ('Ability_Rampage3_name', 'Удар рогами'),  # "Рогатый удар"
    # Ravenor
    ('Ability_Ravenor4_name', 'Сокрушительная сила'),  # "Безграничная сила"
    # Revenant
    ('Ability_Revenant2_name', 'Умертвление'),  # "Умерщвление" — archaic/correct
    ('Ability_Revenant3_name', 'Покров сущности'),  # OK
    # Rhapsody
    ('Ability_Rhapsody2_name', 'Диско-инферно'),  # OK — fun name
    ('Ability_Rhapsody4_name', 'Защитный мотив'),  # "Защитная мелодия"
    # Riftwalker
    ('Ability_Riftwalker1_name', 'Разлом реальности'),  # "Каскадное событие" — machine transl
    ('Ability_Riftwalker2_name', 'Сосуществование'),  # "Общее существование"
    ('Ability_Riftwalker3_name', 'Ожог разлома'),  # OK
    # Riptide
    ('Ability_Riptide3_name', 'В своей стихии'),  # OK
    # Salomon
    ('Ability_Salomon1_name', 'Жажда силы'),  # "Желание силы"
    ('Ability_Salomon3_name', 'Жажда богатства'),  # "Желание богатства"
    ('Ability_Salomon4_name', 'Жажда мести'),  # "Желание мести"
    # SandWraith
    ('Ability_SandWraith2_name', 'Песчаные иллюзии'),  # "Песчаные охотники"
    # Sapphire
    ('Ability_Sapphire3_name', 'Быстрый щит'),  # OK
    # Scout
    ('Ability_Scout3_name', 'Точность'),  # "Рессилиие" — obvious typo
    # ShadowBlade
    ('Ability_ShadowBlade1_name', 'Взрыв Гаргантюа'),  # OK — hero ability name
    ('Ability_ShadowBlade2_name', 'Обман Финта'),  # "Сифон Финта" — makes no sense
    # Shellshock
    ('Ability_Shellshock3_name', 'Камень-святилище'),  # "Камень святилища"
    # Silhouette
    ('Ability_Silhouette4_name', 'Смертная тень'),  # "Тень" — too generic
    # SirBenzington
    ('Ability_SirBenzington1_name', 'Рыцарский натиск'),  # "Поединок" — it's a charge, not a duel
    ('Ability_SirBenzington4_name', 'Удар копытами'),  # "Падение рыцаря" — it's a horse slam
    # Slither
    ('Ability_Slither2_name', 'Ядовитый вард'),  # OK
    # Solstice
    ('Ability_Solstice1_name', 'Ослепительный рывок'),  # "Ослепляющий рывок"
    ('Ability_Solstice3_name', 'Грациозный танец'),  # "Грациозные удары"
    # SotMCat
    ('Ability_SotMCat3_name', 'Воссоединение близнецов'),  # "Вместе в огненном духе"
    # SoulReaper
    ('Ability_SoulReaper2_name', 'Угасающая аура'),  # "Увядающее присутствие"
    ('Ability_SoulReaper3_name', 'Нечеловеческая сила'),  # "Нечеловеческая природа"
    # Soulstealer
    ('Ability_Soulstealer3_name', 'Аура ужаса'),  # "Ужас" — too generic
    # Succubis
    ('Ability_Succubis1_name', 'Истощение'),  # "Поражен" — grammatically wrong
    # Swiftblade
    ('Ability_Swiftblade4_name', 'Молниеносные удары'),  # "Быстрые удары"
    # Taint
    ('Ability_Taint3_name', 'Сбор трупов'),  # "Оскверненное прикосновение"
    # Tarot
    ('Ability_Tarot2_name', 'Дальнобойное зрение'),  # "Дальновидение" — literal transl
    # Tempest
    ('Ability_Tempest1_name', 'Ледяные взрывы'),  # OK
    ('Ability_Tempest4_name', 'Стихийная бездна'),  # "Элементальная пустота" — machine transl
    # Tundra
    ('Ability_Tundra3_name', 'Зов зимы'),  # OK
    # Valkyrie
    ('Ability_Valkyrie2_name', 'Копьё света'),  # "Джавелин света" — джавелин = javelin
    ('Ability_Valkyrie3_name', 'Доблестный прыжок'),  # "Храбрый прыжок"
    # Vanya
    ('Ability_Vanya2_name', 'Осквернение'),  # "Осквернение души"
    ('Ability_Vanya3_name', 'Стремительный рывок'),  # "Зарядные удары"
    ('Ability_Vanya4_name', 'Тёмный покров'),  # "Покров тьмы"
    # Vindicator
    ('Ability_Vindicator2_name', 'Заклинание мудреца'),  # "Заклинание мастера"
    ('Ability_Vindicator3_name', 'Знак молчания'),  # "Глиф безмолвия"
    # VoodooJester
    ('Ability_VoodooJester2_name', 'Моджо'),  # OK — it's the game name
    ('Ability_VoodooJester4_name', 'Вард духа'),  # OK
    # WarBeast
    ('Ability_WarBeast2_name', 'Боевой клич'),  # OK
    ('Ability_WarBeast4_name', 'Превращение'),  # "Метаморфоза" — too scientific
    # Warchief
    ('Ability_Warchief2_name', 'Духовный разведчик'),  # "Духовная ходьба"
    ('Ability_Warchief3_name', 'Мудрость старейшин'),  # "Сила старейшин"
    # Werebeast
    ('Ability_Werebeast1_name', 'Дальнее зрение'),  # OK
    # WitchSlayer
    ('Ability_WitchSlayer1_name', 'Цепь молний'),  # "Кладбище" — WRONG name! WitchSlayer1 is "Graveyard" silence
    # Yogi
    ('Ability_Yogi3_name', 'Связь с природой'),  # "Природная настройка"
    # Zephyr
    ('Ability_Zephyr1_name', 'Порыв ветра'),  # OK
]

# Apply name fixes
for key, new_name in NAME_FIXES:
    old = get_val(key)
    if old is None:
        print(f'  SKIP (not found): {key}')
        continue
    if old == new_name:
        continue
    set_val(key, new_name)
    print(f'  NAME: {key}: {old!r} → {new_name!r}')
    fixes += 1

# ── Description fixes ────────────────────────────────────────────────────────
DESC_PATCHES = [
    # Fix obvious typos and broken text in descriptions
    ('Ability_EmeraldWarden3_name', 'Капкан корней'),  # also fix the gadget version
    # Fix "Разраоглушениеие" typo in descriptions
]

# Global description text patches
DESC_TEXT_FIXES = [
    # (key_contains, old_text, new_text)
    # Fix "поддержание" used as noun -> "канал" when appropriate
    # Fix "перезарядка" used wrong gender
]

# Fix specific broken description texts
DESCRIPTION_FIXES = {
    # Defiler2 description has "P3__ тишина" artifact
    'Ability_Defiler2_description_simple': None,  # Will fix below
    # EmeraldWarden3 name fix creates need to fix gadget too
    'Ability_Gadget_EmeraldWarden3_name': 'Сработать корневой капкан',
}

# Fix Defiler2 description (has "P3__" artifact)
defiler2_desc = get_val('Ability_Defiler2_description_simple') or ''
if 'P3__' in defiler2_desc:
    fixed = defiler2_desc.replace('^oP3__ тишина^*', '^oНаложить безмолвие^*')
    set_val('Ability_Defiler2_description_simple', fixed)
    print(f'  DESC: Defiler2 P3__ artifact fixed')
    fixes += 1

# Fix Scout3 name (was "Рессилиие" — typo for "Resilience")
scout3 = get_val('Ability_Scout3_name') or ''
if 'Рессилиие' in scout3 or 'Resilience' in scout3.lower():
    set_val('Ability_Scout3_name', 'Меткость')
    print(f'  NAME: Scout3: {scout3!r} → Меткость')
    fixes += 1

# Fix Gadget_EmeraldWarden3 broken name
gew3 = get_val('Ability_Gadget_EmeraldWarden3_name') or ''
if 'разраоглушениеие' in gew3.lower() or 'Активировать' in gew3:
    set_val('Ability_Gadget_EmeraldWarden3_name', 'Сработать корневой капкан')
    print(f'  NAME: Gadget_EmeraldWarden3: fixed')
    fixes += 1

# Fix EmeraldWarden3 broken name
ew3 = get_val('Ability_EmeraldWarden3_name') or ''
if 'разраоглушениеие' in ew3.lower():
    set_val('Ability_EmeraldWarden3_name', 'Капкан корней')
    print(f'  NAME: EmeraldWarden3: {ew3!r} → Капкан корней')
    fixes += 1

# Fix "разраоглушениеие" in description texts (garbage artifact)
for key in list(key_to_idx.keys()):
    if 'description' not in key: continue
    val = get_val(key) or ''
    if 'разраоглушениеие' in val.lower():
        fixed = re.sub(r'[Рр]азраоглушениеие', 'Корень', val)
        set_val(key, fixed)
        print(f'  DESC: {key}: fixed разраоглушениеие artifact')
        fixes += 1

# Fix "поддержаниеа" -> "поддержания" (morphological error that slipped through)
for key in list(key_to_idx.keys()):
    if 'description' not in key: continue
    val = get_val(key) or ''
    if 'поддержаниеа' in val or 'поддержаниеить' in val:
        fixed = val.replace('поддержаниеа', 'поддержания').replace('поддержаниеить', 'поддерживать')
        set_val(key, fixed)
        print(f'  DESC: {key}: fixed поддержаниеа')
        fixes += 1

# WitchSlayer1 — "Кладбище" is WRONG, it's "Graveyard Silence" = "Кладбищенская тишь"
ws1 = get_val('Ability_WitchSlayer1_name') or ''
set_val('Ability_WitchSlayer1_name', 'Кладбищенская тишь')
print(f'  NAME: WitchSlayer1: {ws1!r} → Кладбищенская тишь')
fixes += 1

# Ichor1 — "Пампиризм" is a typo for "Вампиризм" but Ichor ability is called "Vamp" 
# Let's keep "Вампиризм" as corrected
ichor1 = get_val('Ability_Ichor1_name') or ''
if 'Пампиризм' in ichor1:
    set_val('Ability_Ichor1_name', 'Вампирская хватка')
    print(f'  NAME: Ichor1: {ichor1!r} → Вампирская хватка')
    fixes += 1

print(f'\n=== Total: {fixes} fixes ===')

new_text = '\r\n'.join(lines)
with open(path, 'wb') as f:
    f.write(bom + new_text.encode('utf-8'))
with open(path, 'rb') as f: h = f.read(3)
print(f'BOM: {"OK" if h == bom else "WRONG!"}')
