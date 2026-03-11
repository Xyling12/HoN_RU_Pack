HoN RU Pack - Инструкция

Этот пакет работает в режиме "установил один раз и играешь".
BAT-файл перед каждым запуском больше не нужен.

Установка:
1) Запустите dist\HoN_RU_Pack_Installer_NEW.exe
2) Выберите 1 (автоопределение пути игры)
3) Дождитесь "Installation completed"
4) Запускайте Juvio/HoN как обычно

Что ставится:
- %LOCALAPPDATA%\HoN_RU_Pack (основные файлы перевода)
- Автозапуск агента:
  %APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\HoN_RU_Pack_AutoAgent.cmd

Как выпустить новую версию (для автора):
1) Обнови файлы перевода в папке bundle:
   - entities_en.str
   - interface_en.str
   - client_messages_en.str
   - game_messages_en.str
   - bot_messages_en.str
2) Подними версию в version.txt (например 1.1.1)
3) Собери новый установщик:
   run_build_hon_ru_installer.bat
4) Готовый файл:
   dist\HoN_RU_Pack_Installer_NEW.exe
5) Залей его в облако (Dropbox/Boosty)

Как работает обновление пакета:
1) Обнови update_config.json:
   - latest_zip_url
   - latest_version
   - latest_sha256 (по желанию, но лучше указывать)
2) Пользователь запускает update.bat
3) После обновления пользователь заново запускает установщик

Если путь игры нестандартный:
1) Открой:
   %LOCALAPPDATA%\HoN_RU_Pack\hon_paths_override.ps1
2) Заполни:
   $HoNDocsRoot
   $HoNLocalRoot
   $HoNArchivePath

Удаление:
- Запусти uninstall_hon_ru_pack.ps1
