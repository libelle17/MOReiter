@echo off
rem Kompiliert MOReiter.au3 mit dem Reiter-Icon; beendet vorher den laufenden MOReiter dieses PCs (Tray) und
rem startet danach den neuen (Einrichten.bat; auf anderen PCs genuegt danach Einrichten.bat allein)
rem Achtung: beendet auch eine laufende Smart Pix-Liste (Strg+Umsch+S)
rem Gibt es noch keine MOReiter-Praxis.ini (erstes Einrichten), fragt "MOReiter.exe Praxis" danach, was die Praxis
rem nutzt (Labor, Zuckerportale, Smart Pix, Patientenlaufzettel, Einordnen) und welche praxiseigenen Werte gelten
rem Fehlt AutoIt3, laedt es die portable Fassung von autoitscript.com nach .\AutoIt3 (ohne Installation)
cd /d "%~dp0"
set A2E=%ProgramFiles(x86)%\AutoIt3\Aut2Exe\Aut2exe.exe
if not exist "%A2E%" set A2E=%ProgramFiles%\AutoIt3\Aut2Exe\Aut2exe.exe
if not exist "%A2E%" set A2E=%~dp0AutoIt3\install\Aut2Exe\Aut2exe.exe
if exist "%A2E%" goto autoitda
echo AutoIt3 nicht gefunden: lade die portable Fassung von www.autoitscript.com nach %~dp0AutoIt3 ...
curl.exe -L --fail -o "%TEMP%\autoit-v3.zip" https://www.autoitscript.com/files/autoit3/autoit-v3.zip
if errorlevel 1 (echo Herunterladen fehlgeschlagen, bitte AutoIt3 von www.autoitscript.com installieren & pause & goto :eof)
if not exist "%~dp0AutoIt3" md "%~dp0AutoIt3"
tar -xf "%TEMP%\autoit-v3.zip" -C "%~dp0AutoIt3"
del "%TEMP%\autoit-v3.zip"
if not exist "%A2E%" (echo Entpacken fehlgeschlagen, bitte AutoIt3 von www.autoitscript.com installieren & pause & goto :eof)
:autoitda
set ERST=
if not exist MOReiter-Praxis.ini set ERST=1
call Einrichten.bat beenden
"%A2E%" /in MOReiter.au3 /out MOReiter.exe /icon MOReiter.ico /x86
if errorlevel 1 (echo Kompilieren fehlgeschlagen & pause)
if defined ERST if exist MOReiter.exe start "" /wait MOReiter.exe Praxis
call Einrichten.bat starten
