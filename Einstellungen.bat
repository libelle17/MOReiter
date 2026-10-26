@echo off
rem Einstellungen der Praxis aendern ("MOReiter.exe Praxis": was die Praxis nutzt, Ablage, Kennungen, Pfade) und
rem danach wie Einrichten.bat nach %APPDATA%\MOReiter uebernehmen und MOReiter neu starten
cd /d "%~dp0"
if not exist MOReiter.exe (echo MOReiter.exe fehlt, bitte zuerst Kompilieren.bat aufrufen & pause & goto :eof)
start "" /wait MOReiter.exe Praxis
call Einrichten.bat
