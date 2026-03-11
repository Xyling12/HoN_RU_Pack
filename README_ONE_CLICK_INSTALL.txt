HoN RU Pack - One-Click Installer

What this gives you:
- Install once from EXE.
- No manual BAT launch for every game start.
- Background auto-agent keeps translation files in place.
- Default install path is inside game folder.

Installer file:
- dist\HoN_RU_Pack_Installer_NEW.exe
  (or latest HoN_RU_Pack_Installer_v*.exe)

How to use:
1) Run HoN_RU_Pack_Installer_NEW.exe
2) Wait for "Installation completed."
3) Launch Juvio/HoN normally

What installer creates:
- %LOCALAPPDATA%\HoN_RU_Pack
  - bundle\*.str (master translation files)
  - hon_auto_agent.ps1
  - set_login_banner.ps1
  - hon_paths_override.example.ps1
  - version.txt
- <HoN game folder>\mod\HoN_RU_Pack
  - mirror copy (can be cleaned by updater; agent restores game stringtables from %LOCALAPPDATA%\HoN_RU_Pack)
- Startup entry:
  - %APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\HoN_RU_Pack_AutoAgent.cmd
  - Runs %LOCALAPPDATA%\HoN_RU_Pack\hon_auto_agent.ps1 at user logon

Optional custom paths:
- Edit:
  %LOCALAPPDATA%\HoN_RU_Pack\hon_paths_override.ps1
- Fill:
  $HoNDocsRoot
  $HoNLocalRoot
  $HoNArchivePath

Uninstall:
- Run:
  uninstall_hon_ru_pack.ps1
- This removes startup entry and installed files.

Rebuild installer EXE:
- Run:
  run_build_hon_ru_installer.bat
