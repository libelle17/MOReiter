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
rem 1 s warten mit ping statt timeout: timeout bricht ohne Konsolenfenster sofort ab ("Eingabeumleitung wird nicht
rem unterstuetzt"), z.B. aus Claude Code oder einer Aufgabenplanung aufgerufen
for /l %%i in (1,1,10) do (
	tasklist /fi "imagename eq MOReiter.exe" 2>nul | find /i "MOReiter.exe" >nul || goto beendet
	ping -n 2 127.0.0.1 >nul
)
taskkill /f /im MOReiter.exe >nul 2>&1
ping -n 2 127.0.0.1 >nul
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
rem ueber Start-Process (ShellExecute) statt start: mit start erbt MOReiter die Handles des Aufrufers, auch eine Pipe,
rem und wer die Ausgabe liest (z.B. Claude Code), wartet dann, bis MOReiter beendet wird
powershell -NoProfile -Command "Start-Process -FilePath '%APPDATA%\MOReiter\MOReiter.exe' -WorkingDirectory '%APPDATA%\MOReiter'"
echo MOReiter laeuft (Symbol im Infobereich der Taskleiste, ggf. unter dem kleinen Pfeil; Hilfe: Strg+Alt+F1).
rem ohne Konsolenfenster bricht timeout sofort ab, dann eben ohne die 5 s zum Lesen
timeout /t 5 >nul 2>&1
exit /b 0
