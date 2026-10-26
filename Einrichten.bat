@echo off
rem Richtet den MOReiter dieses Ordners auf diesem PC ein: beendet den laufenden MOReiter (Tray), kopiert
rem MOReiter.exe, MOReiter-Vorgaben.ini und MOReiter-Praxis.ini, wenn sie hier neuer sind, nach %APPDATA%\MOReiter (wie NVerb beim
rem Anmelden) und startet MOReiter von dort neu, z.B. nachdem die exe auf einem anderen PC kompiliert wurde.
rem Eigene Einstellungen dieses PCs gehoeren in %APPDATA%\MOReiter\MOReiter.ini, die Vorgaben dort werden ersetzt.
rem   Einrichten.bat           beenden und neu starten
rem   Einrichten.bat beenden   nur beenden (Kompilieren.bat, die exe laesst sich nicht ueberschreiben, solange sie laeuft)
rem   Einrichten.bat starten   nur starten
rem Achtung: beendet auch eine laufende Smart Pix-Liste (Strg+Umsch+S)
cd /d "%~dp0"
if /i "%~1"=="starten" goto starten
tasklist /fi "imagename eq MOReiter.exe" 2>nul | find /i "MOReiter.exe" >nul
if errorlevel 1 goto beendet
echo Beende den laufenden MOReiter ...
taskkill /im MOReiter.exe >nul 2>&1
for /l %%i in (1,1,10) do (
	tasklist /fi "imagename eq MOReiter.exe" 2>nul | find /i "MOReiter.exe" >nul || goto beendet
	timeout /t 1 /nobreak >nul
)
taskkill /f /im MOReiter.exe >nul 2>&1
timeout /t 1 /nobreak >nul
:beendet
if /i "%~1"=="beenden" goto :eof
:starten
if not exist MOReiter.exe (echo MOReiter.exe fehlt, bitte zuerst Kompilieren.bat aufrufen & pause & goto :eof)
echo Kopiere MOReiter nach %APPDATA%\MOReiter und starte es dort ...
if not exist "%APPDATA%\MOReiter" md "%APPDATA%\MOReiter"
xcopy /d /y /q MOReiter.exe "%APPDATA%\MOReiter\" >nul
if exist MOReiter-Vorgaben.ini xcopy /d /y /q MOReiter-Vorgaben.ini "%APPDATA%\MOReiter\" >nul
if exist MOReiter-Praxis.ini xcopy /d /y /q MOReiter-Praxis.ini "%APPDATA%\MOReiter\" >nul
rem Autostart: Verknuepfung im Autostart-Ordner des Benutzers (nicht mit [Allgemein] Autostart=0 in MOReiter-Praxis.ini,
rem z.B. wo ein Anmeldeskript MOReiter startet); MOReiter selbst schreibt sich nicht in den Autostart, das haelt der
rem Virenschutz bei einem Programm, das die Tastatur ueberwacht, fuer einen Keylogger
set AUTO=1
if exist MOReiter-Praxis.ini findstr /i /r /c:"^Autostart=0" MOReiter-Praxis.ini >nul && set AUTO=0
set LNK=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\MOReiter.lnk
if "%AUTO%"=="0" if exist "%LNK%" del "%LNK%"
if "%AUTO%"=="1" powershell -NoProfile -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut('%LNK%'); $s.TargetPath='%APPDATA%\MOReiter\MOReiter.exe'; $s.WorkingDirectory='%APPDATA%\MOReiter'; $s.Save()"
if "%AUTO%"=="1" echo Autostart: %LNK%
start "" /d "%APPDATA%\MOReiter" "%APPDATA%\MOReiter\MOReiter.exe"
echo MOReiter laeuft (Symbol im Infobereich der Taskleiste, ggf. unter dem kleinen Pfeil; Hilfe: Strg+Alt+F1).
timeout /t 5 >nul
