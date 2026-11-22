#!/bin/sh
# von BmpLesen-Kompilieren.bat in der MSYS2-UCRT64-Umgebung aufgerufen.
# Die vorkompilierte libmupdf.a erwartet OpenJPEG als DLL (__imp_opj_...), und zxing-cpp verweist fuer das hier
# nicht gebrauchte Erzeugen von Codes auf zint: beides ueberbrueckt eine kleine Zwischendatei, damit alles statisch geht.
set -e
T=$(mktemp -d)
{
	echo '#include <openjpeg.h>'
	for s in $(nm -u "$MINGW_PREFIX/lib/libmupdf.a" 2>/dev/null | grep -o '__imp_opj_[a-z_]*' | sort -u | sed 's/__imp_//'); do
		echo "extern \"C\" { void *__imp_$s = (void *)&$s; }"
	done
	echo 'extern "C" void ZBarcode_Delete(void *p) { (void)p; }'
} > "$T/statisch.cpp"
g++ -O2 -std=c++20 -municode -Wall -Wno-unused-function BmpLesen.cpp "$T/statisch.cpp" -o BmpLesen.exe -static -s \
	$(pkg-config --static --cflags --libs mupdf libopenjp2) -lbrotlienc -lZXing -lshell32
rm -rf "$T"
