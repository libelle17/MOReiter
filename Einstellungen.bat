@echo off
rem Einstellungen der Praxis aendern ("MOReiter.exe Praxis": was die Praxis nutzt, Ablage, Kennungen, Pfade) und
rem danach wie Einrichten.bat nach %APPDATA%\MOReiter uebernehmen und MOReiter neu starten
cd /d "%~dp0"
if not exist MOReiter.exe (echo MOReiter.exe fehlt, bitte zuerst Kompilieren.bat aufrufen & pause & goto :eof)
rem mit Pfad, s. Kompilieren.bat
start "" /wait "%~dp0MOReiter.exe" Praxis
call "%~dp0Einrichten.bat"
