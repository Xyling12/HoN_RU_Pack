@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build_hon_ru_installer_exe.ps1" -PackageRoot "%~dp0" -OutputExe "%~dp0dist\HoN_RU_Pack_Installer_NEW.exe"
echo.
pause
