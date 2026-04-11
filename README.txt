HoN RU Pack - инструкция

Этот пакет работает по принципу "установил один раз и играешь".
Запускать BAT-файл перед каждым стартом игры больше не нужно.

Установка:
1. Запустите `dist\HoN_RU_Pack_Installer_NEW.exe`.
2. Выберите автоматическое определение папки игры.
3. Дождитесь сообщения `Установка завершена успешно`.
4. Запускайте Juvio/HoN как обычно.

Что устанавливается:
- `%LOCALAPPDATA%\HoN_RU_Pack` - основные файлы локализации и служебные скрипты.
- Автозапуск агента:
  `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\HoN_RU_Pack_AutoAgent.cmd`

Как выпустить новую версию:
1. Обновите файлы перевода в папке `bundle`:
   - `entities_en.str`
   - `interface_en.str`
   - `client_messages_en.str`
   - `game_messages_en.str`
   - `bot_messages_en.str`
2. Поднимите версию в `version.txt`, например до `1.1.1`.
3. Соберите новый установщик:
   `run_build_hon_ru_installer.bat`
4. Готовый файл появится здесь:
   `dist\HoN_RU_Pack_Installer_NEW.exe`
5. Загрузите его в облако или на площадку распространения.

Как работает обновление пакета:
1. Обновите `update_config.json`:
   - `latest_zip_url`
   - `latest_version`
   - `latest_sha256` по возможности
2. Пользователь запускает `update.bat`.
3. После обновления пользователь снова запускает установщик.

Если путь к игре нестандартный:
1. Откройте:
   `%LOCALAPPDATA%\HoN_RU_Pack\hon_paths_override.ps1`
2. Заполните переменные:
   - `$HoNDocsRoot`
   - `$HoNLocalRoot`
   - `$HoNArchivePath`

Удаление:
- Запустите `uninstall_hon_ru_pack.ps1`.
