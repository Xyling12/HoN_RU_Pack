HoN RU Pack - установка в один клик

Что это дает:
- Достаточно один раз запустить EXE-файл установщика.
- Не нужно вручную запускать BAT-файл перед каждым стартом игры.
- Фоновый автоагент следит, чтобы файлы локализации оставались на месте.
- По умолчанию мод ставится в папку игры.

Файл установщика:
- `dist\HoN_RU_Pack_Installer_NEW.exe`
- или актуальный `HoN_RU_Pack_Installer_v*.exe`

Как использовать:
1. Запустите `HoN_RU_Pack_Installer_NEW.exe`.
2. Дождитесь сообщения `Установка завершена успешно`.
3. Запускайте Juvio/HoN как обычно.

Что создает установщик:
- `%LOCALAPPDATA%\HoN_RU_Pack`
  - `bundle\*.str` - основные файлы перевода
  - `hon_auto_agent.ps1`
  - `set_login_banner.ps1`
  - `hon_paths_override.example.ps1`
  - `version.txt`
- `<папка игры HoN>\mod\HoN_RU_Pack`
  - зеркальная копия файлов; обновлятор может ее очистить, а агент восстановит строки из `%LOCALAPPDATA%\HoN_RU_Pack`
- Запись автозапуска:
  - `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\HoN_RU_Pack_AutoAgent.cmd`
  - запускает `%LOCALAPPDATA%\HoN_RU_Pack\hon_auto_agent.ps1` при входе пользователя в Windows

Пользовательские пути:
- Откройте:
  `%LOCALAPPDATA%\HoN_RU_Pack\hon_paths_override.ps1`
- Заполните:
  - `$HoNDocsRoot`
  - `$HoNLocalRoot`
  - `$HoNArchivePath`

Удаление:
- Запустите `uninstall_hon_ru_pack.ps1`.
- Скрипт удалит автозапуск и установленные файлы.

Пересборка установщика:
- Запустите:
  `run_build_hon_ru_installer.bat`
