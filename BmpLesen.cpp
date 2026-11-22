// BmpLesen - Bundeseinheitlichen Medikationsplan (BMP) aus Dokumenten lesen. Copyright (C) 2026 Gerald Schade
// Freie Software unter der GNU General Public License, Version 3 oder spaeter (s. LICENSE); ohne jede Gewaehrleistung.
// Teil von MOReiter (https://github.com/libelle17/MOReiter); nutzt MuPDF (AGPL) und zxing-cpp (Apache 2.0).
//
// Sucht in PDF-Dateien und Bildern (Scans, Faxe, aus der ePA uebernommene Dokumente) auf jeder Seite den Data-Matrix-Code
// des Medikationsplans (Inhalt "<MP ...>...</MP>", ISO-8859-1) und speichert ihn als XML-Datei, benannt wie beim
// BMP-Scanner (BMP-Scanner.ps1): <Nachname>_<Vorname>_<TT.MM.JJJJ>[_Blatt<a>von<z>]_<JJJJ-MM-TT_hh-mm-ss>.xml in P:\BMP,
// ist P: nicht verbunden in \\linux1\daten\Patientendokumente\BMP, sonst in Dokumente\BMP. Von dort uebernimmt
// Medical Office die Medikamente wie nach dem Scannen des Plans.
// Dateien aus dem Dateispeicher von Medical Office (<MO-Daten>\files\...\<Jahr>_<Nummer>.<ext>[.moc]) gehen direkt:
// .moc-Dateien werden im Speicher entpackt (Format s. mo_dok_lesen.py in Dateilesen: uint32 4, uint32 Blockgroesse,
// uint32 Originallaenge, je Block uint32 gepackte und ungepackte Laenge, Daten MS-XPRESS-Huffman, entpackt von
// ntdll.dll RtlDecompressBufferEx). Eine Datei, die selbst schon mit "<MP" beginnt, wird unveraendert uebernommen.
//
// Aufruf:
//   BmpLesen.exe [-o Zielordner] [-p Nachname;Vorname;TT.MM.JJJJ] Datei ...
//       Ausgabe (UTF-8; ein gleicher Plan aus mehreren Dateien nur einmal) je gefundenem Blatt
//         "XML<Tab>Pfad<Tab>Nachname<Tab>Vorname<Tab>TT.MM.JJJJ<Tab>Blatt<Tab>Blattzahl<Tab>Quelldatei",
//       je Datei ohne Plan  "KEIN<Tab>Datei<Tab>Grund", bei Fehlern  "FEHLER<Tab>Datei<Tab>Grund";
//       -p: nur zur Pruefung, weicht der Patient im Plan davon ab, steht in der XML-Zeile zusaetzlich "<Tab>anderer Patient"
//       Rueckgabewert 0 = mindestens ein Plan gespeichert, 1 = keiner gefunden, 2 = Fehler beim Lesen oder Speichern
//   BmpLesen.exe -e Eingabe.moc Ausgabe    nur entpacken (zum schnellen Lesen beliebiger MO-Dokumente)
//   BmpLesen.exe -t Datei ...              nur pruefen, nichts speichern (Ausgabe wie oben, Pfad leer)
// Kompilieren: BmpLesen-Kompilieren.bat (MSYS2 UCRT64 mit MuPDF und zxing-cpp, statisch gebunden: eine exe ohne DLLs)

#include <windows.h>
#include <shlobj.h>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <ctime>
#include <string>
#include <vector>
#include <set>
#include <algorithm>
extern "C" {
#include <mupdf/fitz.h>
}
#include <ZXing/ReadBarcode.h>

using std::string;
using std::wstring;
using std::vector;
typedef vector<unsigned char> Bytes;

// ---------------------------------------------------------------- Ausgabe, Zeichensaetze

static void zeile(const wstring& s) {
	int n = WideCharToMultiByte(CP_UTF8, 0, s.c_str(), (int)s.size(), NULL, 0, NULL, NULL);
	string u(n, '\0');
	WideCharToMultiByte(CP_UTF8, 0, s.c_str(), (int)s.size(), &u[0], n, NULL, NULL);
	u += "\n";
	fwrite(u.data(), 1, u.size(), stdout);
	fflush(stdout);
}

static wstring latin1(const string& s) {
	wstring w;
	for (unsigned char c : s) w += (wchar_t)c;
	return w;
}

static string utf8(const wstring& w) {
	int n = WideCharToMultiByte(CP_UTF8, 0, w.c_str(), (int)w.size(), NULL, 0, NULL, NULL);
	string u(n, '\0');
	WideCharToMultiByte(CP_UTF8, 0, w.c_str(), (int)w.size(), &u[0], n, NULL, NULL);
	return u;
}

// ---------------------------------------------------------------- Dateien

static bool lesen(const wstring& pfad, Bytes& d) {
	FILE* f = _wfopen(pfad.c_str(), L"rb");
	if (!f) return false;
	unsigned char b[1 << 16];
	size_t n;
	while ((n = fread(b, 1, sizeof b, f)) > 0) d.insert(d.end(), b, b + n);
	fclose(f);
	return true;
}

static bool schreiben(const wstring& pfad, const void* p, size_t n) {
	FILE* f = _wfopen(pfad.c_str(), L"wb");
	if (!f) return false;
	bool ok = fwrite(p, 1, n, f) == n;
	return fclose(f) == 0 && ok;
}

// ---------------------------------------------------------------- .moc entpacken

typedef LONG(WINAPI* RtlDecompressBufferEx_t)(USHORT, PUCHAR, ULONG, PUCHAR, ULONG, PULONG, PVOID);
typedef LONG(WINAPI* RtlGetCompressionWorkSpaceSize_t)(USHORT, PULONG, PULONG);

// true, wenn d eine .moc-Datei ist (Kennung 4, plausible Laengen); out = Inhalt
static bool mocEntpacken(const Bytes& d, Bytes& out, string& fehler) {
	auto u32 = [&](size_t p) { uint32_t v; memcpy(&v, &d[p], 4); return v; };
	if (d.size() < 12 || u32(0) != 4) { fehler = "keine .moc-Datei"; return false; }
	uint32_t ulen = u32(8);
	if (ulen > 2000u * 1024 * 1024) { fehler = "unplausible Laenge"; return false; }
	static RtlDecompressBufferEx_t dec = NULL;
	static Bytes arbeit;
	if (!dec) {
		HMODULE nt = GetModuleHandleA("ntdll.dll");
		dec = (RtlDecompressBufferEx_t)GetProcAddress(nt, "RtlDecompressBufferEx");
		auto ws = (RtlGetCompressionWorkSpaceSize_t)GetProcAddress(nt, "RtlGetCompressionWorkSpaceSize");
		ULONG w1 = 0, w2 = 0;
		if (!dec || !ws || ws(4, &w1, &w2) != 0) { dec = NULL; fehler = "ntdll: RtlDecompressBufferEx fehlt"; return false; }
		arbeit.resize(std::max(w1, w2) + 16);
	}
	out.assign(ulen, 0);
	size_t pos = 12, o = 0;
	while (o < ulen) {
		if (pos + 8 > d.size()) { fehler = "Datei zu kurz"; return false; }
		uint32_t cl = u32(pos), ul = u32(pos + 4);
		pos += 8;
		if (pos + cl > d.size() || o + ul > ulen || ul == 0) { fehler = "Blocklaenge falsch"; return false; }
		if (cl == ul) {
			memcpy(&out[o], &d[pos], cl);
		} else {
			// 4 = COMPRESSION_FORMAT_XPRESS_HUFF
			ULONG fertig = 0;
			if (dec(4, &out[o], ul, (PUCHAR)&d[pos], cl, &fertig, arbeit.data()) != 0 || fertig != ul) {
				fehler = "Entpacken fehlgeschlagen";
				return false;
			}
		}
		o += ul;
		pos += cl;
	}
	return true;
}

// ---------------------------------------------------------------- Data-Matrix-Codes in Seiten suchen

static bool istPlan(const string& s) {
	size_t i = 0;
	while (i < s.size() && (unsigned char)s[i] <= ' ') i++;
	return s.compare(i, 3, "<MP") == 0;
}

// Codes "<MP..." einer Seite; skal = Pixel je PDF-Punkt (300 dpi = 300/72), hoechstens maxPx Pixel lange Seite
static void seiteLesen(fz_context* ctx, fz_document* doc, int nr, float dpi, float maxPx, vector<string>& plaene) {
	fz_page* pg = NULL;
	fz_pixmap* pix = NULL;
	fz_var(pg);
	fz_var(pix);
	fz_try(ctx) {
		pg = fz_load_page(ctx, doc, nr);
		fz_rect b = fz_bound_page(ctx, pg);
		float w = b.x1 - b.x0, h = b.y1 - b.y0, m = std::max(w, h), z = dpi / 72.0f;
		if (m * z > maxPx) z = maxPx / m;
		pix = fz_new_pixmap_from_page(ctx, pg, fz_scale(z, z), fz_device_gray(ctx), 0);
		ZXing::ImageView bild(fz_pixmap_samples(ctx, pix), fz_pixmap_width(ctx, pix), fz_pixmap_height(ctx, pix),
							  ZXing::ImageFormat::Lum, (int)fz_pixmap_stride(ctx, pix));
		ZXing::ReaderOptions opt;
		opt.setFormats(ZXing::BarcodeFormat::DataMatrix);
		opt.setTryHarder(true);
		opt.setTryRotate(true);
		for (auto& c : ZXing::ReadBarcodes(bild, opt)) {
			if (!c.isValid()) continue;
			auto by = c.bytes();
			string s(by.begin(), by.end());
			if (istPlan(s)) plaene.push_back(s);
		}
	}
	fz_always(ctx) {
		if (pix) fz_drop_pixmap(ctx, pix);
		if (pg) fz_drop_page(ctx, pg);
	}
	fz_catch(ctx) {
		// Seite unlesbar: die anderen trotzdem
	}
}

// alle Plaene eines Dokuments (PDF oder Bild) im Speicher; false + fehler, wenn MuPDF es nicht oeffnen kann
static bool dokumentLesen(fz_context* ctx, const Bytes& d, vector<string>& plaene, string& fehler, int& seiten) {
	const char* art = "application/pdf";
	if (d.size() >= 4) {
		if (!memcmp(d.data(), "\x89PNG", 4)) art = "image/png";
		else if (d[0] == 0xFF && d[1] == 0xD8) art = "image/jpeg";
		else if (!memcmp(d.data(), "II*\0", 4) || !memcmp(d.data(), "MM\0*", 4)) art = "image/tiff";
		else if (!memcmp(d.data(), "BM", 2)) art = "image/bmp";
		else if (!memcmp(d.data(), "GIF8", 4)) art = "image/gif";
	}
	fz_stream* st = NULL;
	fz_document* doc = NULL;
	bool ok = true;
	fz_var(st);
	fz_var(doc);
	fz_try(ctx) {
		st = fz_open_memory(ctx, d.data(), d.size());
		doc = fz_open_document_with_stream(ctx, art, st);
		seiten = fz_count_pages(ctx, doc);
		// zuerst 300 dpi (bis 3600 Pixel); findet sich so gar nichts, noch einmal mit 200 und 400 dpi
		for (int p = 0; p < seiten; p++) seiteLesen(ctx, doc, p, 300, 3600, plaene);
		if (plaene.empty())
			for (float dpi : {200.0f, 400.0f})
				for (int p = 0; p < seiten && plaene.empty(); p++) seiteLesen(ctx, doc, p, dpi, 5000, plaene);
	}
	fz_always(ctx) {
		if (doc) fz_drop_document(ctx, doc);
		if (st) fz_drop_stream(ctx, st);
	}
	fz_catch(ctx) {
		fehler = string("nicht lesbar (") + fz_caught_message(ctx) + ")";
		ok = false;
	}
	return ok;
}

// ---------------------------------------------------------------- XML-Attribute, Dateinamen

static string attribut(const string& xml, const string& tag, const string& name) {
	size_t a = xml.find("<" + tag + " ");
	if (a == string::npos) return "";
	size_t e = xml.find('>', a);
	string t = xml.substr(a, e == string::npos ? string::npos : e - a);
	size_t p = 0;
	while ((p = t.find(" " + name + "=\"", p)) != string::npos) {
		p += name.size() + 3;
		size_t q = t.find('"', p);
		if (q == string::npos) return "";
		return t.substr(p, q - p);
	}
	return "";
}

// XML-Entitaeten (&amp; &#246; &#xF6; ...) auflösen, Latin-1 -> UTF-16
static wstring entitaeten(const string& s) {
	wstring w;
	for (size_t i = 0; i < s.size(); i++) {
		if (s[i] == '&') {
			size_t e = s.find(';', i);
			if (e != string::npos && e - i <= 10) {
				string n = s.substr(i + 1, e - i - 1);
				long c = -1;
				if (n == "amp") c = '&';
				else if (n == "lt") c = '<';
				else if (n == "gt") c = '>';
				else if (n == "quot") c = '"';
				else if (n == "apos") c = '\'';
				else if (n.size() > 1 && n[0] == '#') c = (n[1] == 'x' || n[1] == 'X') ? strtol(n.c_str() + 2, NULL, 16) : strtol(n.c_str() + 1, NULL, 10);
				if (c > 0 && c < 0x10000) {
					w += (wchar_t)c;
					i = e;
					continue;
				}
			}
		}
		w += (wchar_t)(unsigned char)s[i];
	}
	return w;
}

static wstring dateinameTeil(const wstring& s) {
	wstring r;
	bool leer = false;
	for (wchar_t c : s) {
		if (c < 32 || wcschr(L"<>:\"/\\|?*", c)) continue;
		if (c == L' ' || c == L'\t') {
			leer = !r.empty();
			continue;
		}
		if (leer) r += L' ';
		leer = false;
		r += c;
	}
	return r;
}

static wstring gebText(const string& b) {
	if (b.size() == 8 && std::all_of(b.begin(), b.end(), ::isdigit))
		return latin1(b.substr(6, 2) + "." + b.substr(4, 2) + "." + b.substr(0, 4));
	return dateinameTeil(latin1(b));
}

// ---------------------------------------------------------------- Zielordner

static bool ordnerDa(const wstring& o) {
	DWORD a = GetFileAttributesW(o.c_str());
	if (a != INVALID_FILE_ATTRIBUTES) return (a & FILE_ATTRIBUTE_DIRECTORY) != 0;
	return SHCreateDirectoryExW(NULL, o.c_str(), NULL) == ERROR_SUCCESS;
}

static wstring zielOrdner(const wstring& vorgabe) {
	// zuerst der angegebene Ordner (-o), ist er nicht erreichbar, wie der BMP-Scanner
	if (!vorgabe.empty() && ordnerDa(vorgabe)) return vorgabe;
	for (const wchar_t* o : {L"P:\\BMP", L"\\\\linux1\\daten\\Patientendokumente\\BMP"})
		if (ordnerDa(o)) return o;
	wchar_t dok[MAX_PATH];
	if (SHGetFolderPathW(NULL, CSIDL_PERSONAL, NULL, 0, dok) == S_OK) {
		wstring o = wstring(dok) + L"\\BMP";
		if (ordnerDa(o)) return o;
	}
	return L"";
}

// ---------------------------------------------------------------- Hauptprogramm

static wstring kleinOhneAkzent(const wstring& s) {
	wstring r;
	for (wchar_t c : s) {
		c = towlower(c);
		if (c == L'\x00e4') r += L"ae";
		else if (c == L'\x00f6') r += L"oe";
		else if (c == L'\x00fc') r += L"ue";
		else if (c == L'\x00df') r += L"ss";
		else if (iswalnum(c)) r += c;
	}
	return r;
}

int wmain(int argc, wchar_t** argv) {
	if (argc >= 2 && !wcscmp(argv[1], L"-e")) {
		if (argc != 4) {
			fwprintf(stderr, L"Aufruf: BmpLesen.exe -e Eingabe.moc Ausgabe\n");
			return 2;
		}
		Bytes d, o;
		string fehler;
		if (!lesen(argv[2], d)) {
			fwprintf(stderr, L"%ls: nicht lesbar\n", argv[2]);
			return 2;
		}
		if (!mocEntpacken(d, o, fehler)) {
			fwprintf(stderr, L"%ls: %hs\n", argv[2], fehler.c_str());
			return 2;
		}
		if (!schreiben(argv[3], o.data(), o.size())) {
			fwprintf(stderr, L"%ls: nicht schreibbar\n", argv[3]);
			return 2;
		}
		return 0;
	}
	wstring ordnerVorgabe, patient;
	bool nurTest = false;
	vector<wstring> dateien;
	for (int i = 1; i < argc; i++) {
		if (!wcscmp(argv[i], L"-o") && i + 1 < argc) ordnerVorgabe = argv[++i];
		else if (!wcscmp(argv[i], L"-p") && i + 1 < argc) patient = argv[++i];
		else if (!wcscmp(argv[i], L"-t")) nurTest = true;
		else dateien.push_back(argv[i]);
	}
	if (dateien.empty()) {
		fwprintf(stderr, L"Aufruf: BmpLesen.exe [-o Zielordner] [-p Nachname;Vorname;TT.MM.JJJJ] [-t] Datei ...\n"
						 L"        BmpLesen.exe -e Eingabe.moc Ausgabe\n");
		return 2;
	}
	// erwarteter Patient (nur Vergleich): Nachname;Vorname;Geburtsdatum
	wstring pNach, pVor, pGeb;
	if (!patient.empty()) {
		size_t a = patient.find(L';'), b = a == wstring::npos ? a : patient.find(L';', a + 1);
		if (b != wstring::npos) {
			pNach = kleinOhneAkzent(patient.substr(0, a));
			pVor = kleinOhneAkzent(patient.substr(a + 1, b - a - 1));
			pGeb = patient.substr(b + 1);
		}
	}
	fz_context* ctx = fz_new_context(NULL, NULL, FZ_STORE_DEFAULT);
	if (!ctx) {
		zeile(L"FEHLER\t\tMuPDF nicht gestartet");
		return 2;
	}
	fz_register_document_handlers(ctx);
	// Warnungen von MuPDF (beschaedigte PDFs u.ae.) nicht auf die Konsole
	fz_set_warning_callback(ctx, [](void*, const char*) {}, NULL);
	fz_set_error_callback(ctx, [](void*, const char*) {}, NULL);

	// Plan, Nummer und Name der Quelldatei
	struct Plan { string xml; size_t nr; wstring quelle; };
	vector<Plan> alle;
	std::set<string> gesehen;
	bool fehler = false;
	for (size_t nr = 0; nr < dateien.size(); nr++) {
		const wstring& datei = dateien[nr];
		Bytes d;
		if (!lesen(datei, d)) {
			zeile(L"FEHLER\t" + datei + L"\tnicht lesbar");
			fehler = true;
			continue;
		}
		if (d.size() >= 12 && d[0] == 4 && d[1] == 0 && d[2] == 0 && d[3] == 0) {
			Bytes o;
			string f;
			if (!mocEntpacken(d, o, f)) {
				zeile(L"FEHLER\t" + datei + L"\t.moc: " + latin1(f));
				fehler = true;
				continue;
			}
			d.swap(o);
		}
		vector<string> plaene;
		int seiten = 1;
		string f;
		if (istPlan(string(d.begin(), d.begin() + std::min<size_t>(d.size(), 64)))) {
			// schon die XML des Plans (z.B. vom Scanner)
			plaene.push_back(string(d.begin(), d.end()));
		} else if (!dokumentLesen(ctx, d, plaene, f, seiten)) {
			zeile(L"FEHLER\t" + datei + L"\t" + latin1(f));
			fehler = true;
			continue;
		}
		if (plaene.empty()) {
			zeile(L"KEIN\t" + datei + L"\tkein Medikationsplan-Code auf " + std::to_wstring(seiten) + (seiten == 1 ? L" Seite" : L" Seiten"));
			continue;
		}
		for (auto& p : plaene)
			if (gesehen.insert(p).second) alle.push_back({p, nr, datei});
	}
	fz_drop_context(ctx);
	if (alle.empty()) return fehler ? 2 : 1;

	// je Quelldatei nach Blatt ordnen (a="1" .. z="n")
	std::stable_sort(alle.begin(), alle.end(), [](const Plan& x, const Plan& y) {
		if (x.nr != y.nr) return x.nr < y.nr;
		return atoi(attribut(x.xml, "MP", "a").c_str()) < atoi(attribut(y.xml, "MP", "a").c_str());
	});
	wstring ordner = nurTest ? L"" : zielOrdner(ordnerVorgabe);
	if (!nurTest && ordner.empty()) {
		zeile(L"FEHLER\t\tkein Zielordner (P:\\BMP, \\\\linux1\\daten\\Patientendokumente\\BMP, Dokumente\\BMP) schreibbar");
		return 2;
	}
	time_t jetzt = time(NULL);
	tm lt;
	localtime_s(&lt, &jetzt);
	wchar_t zeit[32];
	wcsftime(zeit, 32, L"%Y-%m-%d_%H-%M-%S", &lt);
	int gespeichert = 0;
	for (auto& e : alle) {
		const string& p = e.xml;
		wstring vor = dateinameTeil(entitaeten(attribut(p, "P", "g"))), nach = dateinameTeil(entitaeten(attribut(p, "P", "f")));
		wstring geb = gebText(attribut(p, "P", "b"));
		string a = attribut(p, "MP", "a"), z = attribut(p, "MP", "z");
		wstring name = nach.empty() ? L"Unbekannt" : nach;
		if (!vor.empty()) name += L"_" + vor;
		if (!geb.empty()) name += L"_" + geb;
		if (!a.empty() && !z.empty() && z != "1") name += L"_Blatt" + latin1(a) + L"von" + latin1(z);
		name += wstring(L"_") + zeit;
		wstring pfad;
		if (!nurTest) {
			pfad = ordner + L"\\" + name + L".xml";
			for (int n = 2; GetFileAttributesW(pfad.c_str()) != INVALID_FILE_ATTRIBUTES && n < 100; n++)
				pfad = ordner + L"\\" + name + L"_" + std::to_wstring(n) + L".xml";
			if (!schreiben(pfad, p.data(), p.size())) {
				zeile(L"FEHLER\t" + pfad + L"\tnicht schreibbar");
				fehler = true;
				continue;
			}
		}
		gespeichert++;
		wstring z2 = L"XML\t" + pfad + L"\t" + nach + L"\t" + vor + L"\t" + geb + L"\t" + latin1(a) + L"\t" + latin1(z) + L"\t" + e.quelle;
		if (!pNach.empty() && (kleinOhneAkzent(nach) != pNach || kleinOhneAkzent(vor).compare(0, pVor.size(), pVor) != 0 ||
							   (!pGeb.empty() && geb != pGeb)))
			z2 += L"\tanderer Patient";
		zeile(z2);
	}
	if (gespeichert == 0) return 2;
	return 0;
}
