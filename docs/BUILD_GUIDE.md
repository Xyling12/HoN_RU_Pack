# 🏗️ Сборка инсталлятора HoN RU Pack

## Требования

- Windows 10/11
- .NET Framework 4.x (обычно уже есть)
- PowerShell 5+
- Git

## Шаг 1: Подготовить bundle

Перед сборкой обязательно:
```powershell
python sanitize_bundle.py
```

Это:
- Прописывает версию из `version.txt` в `interface_en.str`
- Исправляет BOM в файлах
- Фиксирует некоторые специфические артефакты

## Шаг 2: Обновить версию (если нужно)

В файле `version.txt` — текущая версия (например `1.9.9l`).

После изменений по одной букве вверх: `1.9.9k` → `1.9.9l` → `1.9.9m` ...

**Важно:** в `sanitize_bundle.py` тоже обновить строку:
```python
TARGET_VERSION = b'1.9.9l'
```
Или запустить:
```powershell
python bump_version.py
```
(после редактирования `bump_version.py` с новой версией)

## Шаг 3: Собрать инсталлятор

```powershell
# Оба варианта: обычный + с DNS bypass
.\build_hon_ru_installer_exe.ps1

# Только деинсталлятор
.\build_hon_ru_uninstaller_exe.ps1
```

Результат в `dist/`:
- `HoN_RU_Pack_Installer.exe` — стандартный
- `HoN_RU_Pack_Installer_Bypass.exe` — с настройкой обхода блокировок
- `HoN_RU_Pack_Uninstaller.exe`

## Шаг 4: Тест локально

```powershell
.\install_hon_ru_pack.ps1
```

Запускает игру → проверяй тултипы умений, строку версии на экране логина.

## Шаг 5: Коммит и push

```bash
git add bundle/ version.txt sanitize_bundle.py
git commit -m "feat: описание изменений vX.X.Xy"
git tag vX.X.Xy
git push
git push origin vX.X.Xy
```

---

## Как работает сборка

Скрипты читают шаблоны `installer_template.cs` / `uninstaller_template.cs`, подставляют версию и полезную нагрузку (zip со .str файлами и PowerShell скриптами), компилируют через `csc.exe` в `.exe`.

**Важно:** `AssemblyVersion` в C# принимает только цифры — буква из версии (напр. `l`) автоматически стрипается для этого атрибута, но отображается в заголовке окна.
