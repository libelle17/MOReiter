@echo off
rem Kompiliert BmpLesen.cpp (Medikationsplan aus PDF/Bild/.moc lesen, s. Kopf von BmpLesen.cpp) zu BmpLesen.exe:
rem MSYS2 (www.msys2.org) mit der UCRT64-Umgebung, statisch gebunden, so dass die exe ohne weitere DLLs auf jedem PC laeuft.
rem Fehlende Pakete (gcc, MuPDF, zxing-cpp, OpenJPEG, mujs, Brotli) installiert pacman beim ersten Aufruf.
rem MSYS2-Ordner: MSYS2=... vorher setzen, sonst wird E:\msys64, C:\msys64, D:\msys64 gesucht.
cd /d "%~dp0"
if not defined MSYS2 for %%d in (E:\msys64 C:\msys64 D:\msys64) do if not defined MSYS2 if exist "%%d\usr\bin\bash.exe" set MSYS2=%%d
if not defined MSYS2 (echo MSYS2 nicht gefunden, bitte von www.msys2.org installieren oder MSYS2=Ordner setzen & pause & goto :eof)
tasklist /fi "imagename eq BmpLesen.exe" 2>nul | find /i "BmpLesen.exe" >nul && taskkill /f /im BmpLesen.exe >nul 2>&1
set MSYSTEM=UCRT64
set CHERE_INVOKING=1
"%MSYS2%\usr\bin\bash.exe" -lc "pacman -S --needed --noconfirm mingw-w64-ucrt-x86_64-gcc mingw-w64-ucrt-x86_64-pkgconf mingw-w64-ucrt-x86_64-libmupdf mingw-w64-ucrt-x86_64-mujs mingw-w64-ucrt-x86_64-zxing-cpp mingw-w64-ucrt-x86_64-openjpeg2 mingw-w64-ucrt-x86_64-brotli >/dev/null && sh ./BmpLesen-Kompilieren.sh"
if errorlevel 1 (echo Kompilieren fehlgeschlagen & pause & goto :eof)
echo BmpLesen.exe ist kompiliert.
