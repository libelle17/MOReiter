# MOReiter – Tastenkürzel für Medical Office

MOReiter läuft unauffällig im Hintergrund (Symbol im Infobereich der Taskleiste) und bedient Medical Office per
Tastatur an Stellen, wo es sonst nur die Maus gibt, und es erledigt darüber hinaus einige Routinearbeiten. Was davon
nutzbar ist, hängt davon ab, was die Praxis außer Medical Office hat. Die Funktionen sind deshalb in Stufen gegliedert,
von „geht überall“ bis „braucht eine Schattendatenbank“.

MOReiter ist kein Produkt der Indamed EDV-Entwicklung und Vertrieb GmbH und wird von ihr nicht
unterstützt. Benutzung auf eigene Verantwortung, ohne Gewährleistung (s. [LICENSE](LICENSE), GPL-3.0).

## 1. Medical Office-Standardinstallation

Medical Office, wie es üblicherweise eingerichtet ist (die Dokumente liegen verschlüsselt in .moc-Dateien).

Bedienung, ganz ohne Datenbankzugriff:

- Anwenderansicht wechseln: Strg+Alt+L (Krankenblatt), Strg+Alt+K (Kartei/Krankenblatt), Strg+Alt+P (ePA/ePAAbr),
- Krankenblattfilter (Filter-Reiter links oder unten): Strg+Alt+1, 2, 3 … bzw. Ziffernblock,
- Diagnose-Kurzwahl: Strg+Alt+1, 2, 3 … bzw. Ziffernblock,
- Termine des Patienten zeigen, solange Strg+Alt+T gehalten wird – aus jedem Programm,
- Tagesübersicht: Strg+Alt+A hakt die offene Aufgabe ab, auf der der Tastaturcursor sitzt (blau markiert),
  Alt+Pfeil wechselt den Bereich,
- Karteikarte: Strg+Umsch+G blättert zu einem abgefragten Datum (liest die Liste mit der Texterkennung von Windows),
- Editor von Medical Office (z.B. Autotext im Datenpflegesystem): F2 speichert und schließt zuverlässig (bzw.
  schließt, wenn nichts geändert wurde), Strg+Umsch+S „Speichern unter“, Alt+D öffnet das Datei-Menü; landet
  Alt+Tab auf dem gesperrten Fenster unter dem Editor, holt MOReiter den Editor wieder nach vorn,
- Metformin-Steigerungsplan im Dosierplan: Strg+Alt+M, dann P (privat) bzw. K (Kasse) – fragt den Therapiebeginn ab,
  dann vier Wochenstufen mit Datum, „(nach dem Essen)“ und Grund, Zeilen 2–4 als Fremdverordnung; im Medikamentenkatalog klappt Alt+W
  „Alle Wirkstärken“ auf,
- **Medikationsplan übernehmen aus Dateien:** Strg+Alt+Ü auf PDFs oder Bildern (Scan, Fax, aus der ePA gespeichert),
  auf denen im FreeCommander oder Windows-Explorer der Tastaturcursor sitzt (blau markiert; auch mehrere markierte
  Dateien), liest den Data-Matrix-Code des bundeseinheitlichen Medikationsplans und legt das XML wie ein
  Medikationsplan-Scanner im BMP-Ordner ab (`[BMP] Ordner=`, Vorgabe `P:\BMP`; ist er nicht erreichbar, der Ordner
  `BMP` unter „Dokumente“ des Benutzers). Von dort übernimmt Medical Office die Medikamente im Dosierplan mit Strg+L,
  wenn das an jedem Arbeitsplatz eingestellt ist (s. Einstellungen, „Für die Eintragung der
  Fremdmedikamentenpläne“). Gelesen wird mit `BmpLesen.exe` (s. Voraussetzungen),
- Briefversand, ePA-Hochladen, zuletzt geöffnete Patienten, Hauptmenü …,
- Strg+Alt zeigt farbig, welche Tasten in der aktuellen Ansicht was bewirken,
- Strg+Alt+F1 zeigt die Hilfe mit allen Tasten, die auf diesem PC eingerichtet sind,
- eigene Programme mit Name und Geburtsdatum des Patienten aufrufen (Abschnitt `[Aufrufe]`).

Mit Lesezugriff auf die Datenbank von Medical Office (MySQL ODBC 8.0 Unicode Driver und Zugangsdaten,
s. `[Allgemein] Zugang=` in `MOReiter-Vorgaben.ini`):

- Karteikarte: Strg+Umsch+F springt zum vorigen (bzw. von oben aus zum nächsten) Eintrag eines abgefragten Typs
  (auch nur dessen Anfang oder ein Teil davon), mit Blick in die Datenbank, ob es überhaupt einen gibt,
- BMI-Anzeige aus der Karteikarte: Strg+Alt+B, dann M zeigt den BMI nach dem jüngsten Gewicht mit Größe, Gewicht
  und deren Datum,
- **Diagnosesuche:** Strg+Alt+S in der Diagnoseerfassung, und von selbst, wenn deren Suche nach Enter nichts findet
  (z.B. „Fibularisvenenthrombose“, „Schultersyndrom“): fehlertolerante Suche beim Tippen in den eigenen
  Diagnosetexten der Praxis, im Alphabetischen Verzeichnis und im ICD-10-GM (Stammdaten von Medical Office), mit
  Vorgabetext; trägt ICD-Code, eigenen oder Vorgabetext und die Zusätze (Priorität, Zusatztext, Status, Sicherheit,
  Seite) in die 2. Stufe der Diagnoseerfassung ein, speichert und schließt die Diagnoseerfassung,
- Accu-Chek Smart Pix: Patient wählen bzw. Patientenliste mit Medical Office abgleichen.

## 2. Unverschlüsselter Dateispeicher

Falls der Dateispeicher von Medical Office (z.B. `c:\indamed\dat\files\` oder `c:\medoff\dat\files\`, im Netz
entsprechend auf dem Server) unverschlüsselt ist, geht zusätzlich:

- **Medikationsplan übernehmen aus der Karteikarte:** Strg+Alt+Ü auf der Zeile eines Dokuments, auf der in der
  Karteikarte der Tastaturcursor sitzt (blau markiert), z.B. eines aus der ePA übernommenen Medikationsplans: Datum
  und Uhrzeit der Zeile liest die Texterkennung, die Dateien dazu holt MOReiter aus der Datenbank (Lesezugriff nötig)
  und dem Dateispeicher (`[BMP] MODateien=`) und gibt sie an `BmpLesen.exe`; die Meldung warnt, wenn der Plan zu
  einem anderen Patienten gehört oder mehrere Dokumente derselben Minute Pläne enthalten,
- `BmpLesen.exe -e Datei.moc Ausgabe` entpackt beliebige .moc-Dateien von Medical Office (XPRESS-Huffman, schnell).

## 3. Gemeinsamer Dokumentenordner

Falls die Praxis außer Medical Office einen gemeinsamen Netzordner mit einem Unterordner je Patient hat, benannt
nach dessen Patientennummer (`[Dokumente] Dok=`, Vorgabe `p:\dok`, also z.B. `p:\dok\12345\`), geht zusätzlich:

- Strg+Alt+D öffnet den Ordner des Patienten, der in Medical Office geöffnet ist, im Explorer,
- abgerufene Laborbefunde und Zuckerberichte (Stufen 4 und 5) werden auf Wunsch in den Ordner des Patienten
  eingeordnet (`[Dokumente] Patientenordner=1`; ohne Patientennummer ein Ordner nach Name und Geburtsdatum),
- Strg+Alt+Ü im FreeCommander oder Explorer erkennt am Ordner, zu welchem Patienten eine Datei gehört, und warnt,
  wenn der Medikationsplan auf einen anderen Namen lautet.

## 4. Labor über Online-Portal

Für Praxen, deren Labor die Befunde etwa auf onlinebefunde.labor-staber.de bereitstellt:

- Strg+O ruft die Laborbefunde des Patienten im Firefox ab, legt die PDFs ab (`[Labor] Ablage=`) und ordnet sie auf
  Wunsch weiter ein (s. Stufe 3).

## 5. Zuckerwerte aus den Portalen

- Zuckerberichte aus LibreView, Dexcom Clarity, Glooko, YourLoops und EasyView (Strg+L, D, G, Y, E), Ablage und
  Umbenennung der PDFs (den Berichtszeitraum für den Dateinamen liest `pdftotext.exe` aus dem PDF),
- Strg+Z ruft alle Portale nach den Markierungen des Patienten in Medical Office ab (braucht den Datenbankzugriff).

## 6. Mit Schattendatenbank (quelle, Dateilese)

Für Praxen, die die Daten von Medical Office laufend mit Dateilese in eine eigene Datenbank „quelle“ übertragen:

- Einzelübertrag des Patienten von Medical Office nach quelle: Strg+Ü (Dateilese vonmo), mit Erfolgs- bzw. Fehlermeldung,
- Patientenlaufzettel, Arztbrief und FreeCommander mit dem Patientenordner (Strg+P, Strg+Umsch+P, Strg+A, Strg+I
  aus `[Aufrufe]`), auch in der Tagesübersicht mit dem Patienten der Zeile, auf der der Tastaturcursor sitzt,
- Arztbrief übernehmen: b, e schnell nacheinander in der Karteikarte kopiert den ganzen Text des jüngsten offenen
  Arztbriefs (Word oder LibreOffice, von Dateilese angelegt) des Patienten in einen neuen Brief aus der Vorlage
  eArztbrief (q, e, a) und speichert mit F2; nicht mitten im Tippen (vor dem b eine halbe Sekunde Ruhe), mit gesperrter
  Tastatur während des Ablaufs (Esc bricht ab) und denselben Brief ein zweites Mal nur nach Rückfrage,
- BMI-Anzeige aus der Karteikarte (Strg+Alt+B, M) nimmt Gewicht und Größe zuerst aus quelle, auch aus alten Anamnesebögen,
- Laborbefunde und andere abgelegte PDFs werden auf Wunsch auch in quelle eingetragen (`[Dokumente] Datenbank=1`),
- Smart Pix-Abgleich auch gegen die Patienten in quelle.

## Voraussetzungen

- Windows mit Medical Office
- nur wer selbst aus dem Quelltext kompiliert (s. Einrichten, Weg B): Internet beim ersten Kompilieren; fehlt
  AutoIt3, lädt `Kompilieren.bat` die portable Fassung von www.autoitscript.com in den Unterordner `AutoIt3`
  (ohne Installation, ohne Administratorrechte)
- ein beliebiger Browser für die Links „moreiter:…“ im Patientenlaufzettel (Stufe 6) und das Herunterladen
  von `pdftotext.exe`
- **Firefox** für das Labor über das Online-Portal (Strg+O, Stufe 4), die Zuckerportale (Strg+L, D, G, Y, E und
  Strg+Z, Stufe 5) und die Einrichtung der Benutzerskripte (Strg+Umsch+T); auch wenn dieselben Abrufe über einen
  Link im Patientenlaufzettel ausgelöst werden. MOReiter startet dafür `firefox.exe`, die Arbeit auf den
  Webseiten machen Benutzerskripte im Add-on Tampermonkey, und die Kennwörter kommen aus dem Kennwortspeicher von
  Firefox. Tampermonkey und die Benutzerskripte bietet MOReiter beim ersten Abruf selbst zur Installation an
- für den Berichtszeitraum in den Dateinamen der Zuckerberichte: `pdftotext.exe` aus den kostenlosen Xpdf-Werkzeugen
  (www.xpdfreader.com); fehlt es, lädt MOReiter es beim Einrichten auf Wunsch selbst herunter
- für Strg+Z, Strg+Umsch+F, Strg+Alt+D, BMI-Anzeige, Strg+Alt+Ü in der Karteikarte und den Smart Pix-Abgleich: Lesezugriff
  auf die Datenbank von Medical Office (MySQL ODBC 8.0 Unicode Driver und Zugangsdaten, s. `[Allgemein] Zugang=` in
  `MOReiter-Vorgaben.ini`)
- für Smart Pix: das Accu-Chek Smart Pix-Lesegerät; für das Scannen gedruckter Medikationspläne (unabhängig von
  MOReiter): ein 2D-Scanner, der die XML-Dateien ebenfalls in den BMP-Ordner legt
- für Strg+Alt+Ü: `BmpLesen.exe` neben `MOReiter.exe`. Sie ist in den fertigen ausführbaren Dateien enthalten (Einrichten, Weg A).
  Im Quelltext-Repo fehlt sie, weil sie mit den eingebundenen Bibliotheken rund 45 MB groß ist; wer selbst
  kompiliert, ruft einmal `BmpLesen-Kompilieren.bat` auf (dafür muss MSYS2 von www.msys2.org installiert sein, die
  nötigen Pakete holt die Datei selbst). Die exe ist statisch gebunden und läuft ohne weitere Dateien auf allen
  PCs; `Einrichten.bat` kopiert sie mit. Lizenzen der enthaltenen Bibliotheken: `Drittanbieter-Lizenzen.txt`

## Einrichten

Es gibt zwei Wege; für die meisten Praxen ist A der einfachere. Eine Anmeldung bei GitHub ist für beide nicht nötig.

**Weg A: Fertige ausführbare Dateien (ohne Kompilieren)**

1. **Herunterladen:** rechts auf der Repo-Seite unter „Releases“ das neueste „Fertige ausführbare Dateien – Stand …“ öffnen (oder direkt
   [https://github.com/libelle17/MOReiter/releases/latest](https://github.com/libelle17/MOReiter/releases/latest))
   und unter „Assets“ die Datei `MOReiter-<Datum>.zip` herunterladen. Sie enthält alle Dateien des Repos und
   dazu die fertigen `MOReiter.exe` und `BmpLesen.exe`.
2. **Freigeben und entpacken:** Rechtsklick auf das ZIP → Eigenschaften → unten „Zulassen“ anhaken → OK
   (sonst warnt Windows bei jeder Datei aus dem Internet). Dann entpacken, z.B. nach `C:\`; es entsteht der
   Ordner `C:\MOReiter`.
3. **Einrichten:** im Ordner `Einrichten.bat` doppelklicken. Meldet die Windows-Sicherheit bzw. SmartScreen eine
   „unbekannte App“: „Weitere Informationen“ → „Trotzdem ausführen“ (MOReiter überwacht die Tastatur für seine
   Kürzel, das wirkt auf Virenscanner manchmal verdächtig; der Quelltext liegt offen hier). Weiter mit Schritt 4.

**Weg B: aus dem Quelltext**

1. **Herunterladen:** den grünen Knopf „<> Code“ rechts über der Dateiliste aufklappen und „Download ZIP“
   wählen (nicht der Reiter „Code“ oben links), oder direkt über
   [https://github.com/libelle17/MOReiter/archive/refs/heads/main.zip](https://github.com/libelle17/MOReiter/archive/refs/heads/main.zip).
2. **Freigeben und entpacken:** wie bei Weg A, z.B. nach `C:\MOReiter`.
3. **Kompilieren:** `Kompilieren.bat` doppelklicken. Fehlt AutoIt3, lädt es die portable Fassung (einige
   Sekunden). Zur Meldung der Windows-Sicherheit s. Weg A. Für Strg+Alt+Ü außerdem einmal
   `BmpLesen-Kompilieren.bat` (braucht MSYS2, s. Voraussetzungen).

**Für beide Wege:**
4. **Einstellungen:** Beim ersten Mal öffnet sich das Fenster „MOReiter einrichten“. Ankreuzen, was die Praxis
   nutzt (Labor, Ablage und Einordnen der PDFs, Zuckerportale, Smart Pix, Patientenlaufzettel), die Pfade und
   Benutzerkennungen eintragen und OK drücken; was von einem Kästchen abhängt, ist grau, solange es aus ist.
   Gespeichert wird in `MOReiter-Praxis.ini`. Später lässt sich alles mit `Einstellungen.bat` ändern.
5. **Start:** MOReiter startet von `%APPDATA%\MOReiter` aus und erscheint als Symbol im Infobereich der
   Taskleiste (ggf. unter dem kleinen Pfeil). Für den Start beim Anmelden legt `Einrichten.bat` eine Verknüpfung
   im Autostart-Ordner des Benutzers an (abzuschalten im Fenster „MOReiter einrichten“), außerdem eine im
   Startmenü, so dass MOReiter nach der Windows-Taste beim Tippen von „MOR…“ zur Auswahl erscheint. Es läuft immer nur
   einmal gleichzeitig; ein Doppelaufruf beendet sich still.
   **Virenschutz:** Weil MOReiter die Tastatur auf seine Kürzel hin beobachtet, halten manche Virenscanner es
   für verdächtig und entfernen `MOReiter.exe` stillschweigend (dann läuft es nach `Einrichten.bat` nicht, und
   Strg+Alt+F1 tut nichts). Dann die Datei aus der Quarantäne zurückholen und für die Ordner von MOReiter
   (der entpackte Ordner und `%APPDATA%\MOReiter`) eine Ausnahme eintragen.
6. **Hilfe:** Strg+Alt+F1 zeigt alle Tasten, die auf diesem PC eingerichtet sind.

Auf weiteren PCs der Praxis: den Ordner samt `MOReiter.exe` und `MOReiter-Praxis.ini` kopieren und
`Einrichten.bat` starten. Es kopiert beides nach `%APPDATA%\MOReiter` und startet MOReiter von dort.

### Update

Die eigenen Einstellungen (`MOReiter-Praxis.ini` im Ordner, `%APPDATA%\MOReiter\MOReiter.ini` je PC) sind weder im
ZIP noch im Repo und bleiben bei einem Update erhalten.

- **Weg A:** das neue `MOReiter-<Datum>.zip` aus den Releases herunterladen, freigeben (Rechtsklick →
  Eigenschaften → „Zulassen“) und in denselben Ordner entpacken (also wieder nach `C:\`, wenn der Ordner
  `C:\MOReiter` ist), vorhandene Dateien ersetzen. Dann `Einrichten.bat` doppelklicken: Es beendet den laufenden
  MOReiter, kopiert die neueren Dateien nach `%APPDATA%\MOReiter` und startet ihn neu.
- **Weg B:** das neue Quelltext-ZIP ebenso in denselben Ordner entpacken und `Kompilieren.bat` doppelklicken
  (für Strg+Alt+Ü auch `BmpLesen-Kompilieren.bat`, wenn sich `BmpLesen.cpp` geändert hat).
- **Weitere PCs der Praxis:** dort `Einrichten.bat` aus dem aktualisierten Ordner aufrufen (liegt er im Netz)
  bzw. den Ordner erneut hinüberkopieren und `Einrichten.bat` starten.
- Ein Virenscanner, der `MOReiter.exe` beim ersten Mal beanstandet hat, kann das bei jeder neuen Fassung wieder tun
  (s. Virenschutz oben).

### Erster Abruf von Labor oder Zuckerportalen (Tampermonkey)

Die Arbeit auf den Webseiten machen kleine Benutzerskripte im Firefox-Add-on Tampermonkey. Beim ersten Abruf
(oder mit Strg+Umsch+T für alle auf einmal) richtet MOReiter beides ein; dabei öffnen sich mehrere Fenster:

1. **Tampermonkey hinzufügen:** Ein Tab mit Tampermonkey (aus der eingestellten .xpi-Datei oder von
   addons.mozilla.org, dort „Zu Firefox hinzufügen“ klicken). Oben erscheint ein **kleines Fenster**
   „Tampermonkey hinzufügen?“ mit den Berechtigungen: **„Hinzufügen“** klicken. Danach ein weiteres kleines
   Fenster „Tampermonkey wurde hinzugefügt“: das Häkchen „An Symbolleiste anheften“ ist nicht nötig,
   **„OK“** klicken.
2. **Begrüßungsseite:** Tampermonkey öffnet danach seine Seite auf tampermonkey.net; MOReiter schließt sie
   gleich wieder. Erscheint dort doch ein Fenster zur Einwilligung in Cookies und Werbung: „Alle ablehnen“
   bzw. alle Schalter aus (für MOReiter wird die Seite nicht gebraucht).
3. **Benutzerskripte:** Für jedes Skript öffnet sich ein **großer Tab** von Tampermonkey mit dem Quelltext des
   Skripts und dem Knopf **„Installieren“** (bei einer neueren Fassung „Aktualisieren“): anklicken, der Tab
   schließt sich. Ist ein Skript schon aktuell („Neu installieren“), den Tab einfach schließen.
4. **Anmelden:** Die Kennwörter kommen aus dem Kennwortspeicher von Firefox, MOReiter speichert keine. Also
   bei jedem Portal einmal von Hand anmelden und Firefox das Kennwort speichern lassen.
5. **Patientenlaufzettel** (nur mit Dateilese): Beim ersten Klick auf einen MOReiter-Link fragt der Browser, ob er
   MOReiter öffnen darf: dauerhaft erlauben (in Firefox „Immer erlauben“ anhaken und „Link öffnen“).

## Einstellungen

MOReiter liest drei Dateien gleichen Aufbaus, die erste, die einen Wert nennt, gilt:

| Datei | Inhalt |
|---|---|
| `%APPDATA%\MOReiter\MOReiter.ini` | Einstellungen und Kalibrierungen dieses PCs |
| `MOReiter-Praxis.ini` | Einstellungen der Praxis (schreibt `MOReiter.exe Praxis`; ein leerer Wert schaltet einen Eintrag der Vorgaben ab) |
| `MOReiter-Vorgaben.ini` | allgemeine Voreinstellungen aus diesem Repo, mit Erklärungen zu jedem Eintrag |

Bei einem Update werden nur `MOReiter.au3`, die Vorgaben und die übrigen Repo-Dateien ersetzt; die
eigenen Einstellungen bleiben erhalten. Fehlt `MOReiter-Vorgaben.ini`, legt MOReiter die in die exe
eingebettete Fassung wieder an.

### Für die Eintragung der Fremdmedikamentenpläne

Damit Medical Office die Medikationspläne aus dem BMP-Ordner (Strg+Alt+Ü bzw. 2D-Scanner) im Dosierplan mit Strg+L
übernimmt, muss an jedem Arbeitsplatz im MO-Datenpflegesystem → Arbeitsplatz → Allgemein, Reiter „Im-/Export“,
Abschnitt „Barcodescanner“

- „Dateiauswahl“ markiert und
- unter „Dateipfad (optional)“ der BMP-Ordner eingetragen sein (derselbe wie `[BMP] Ordner=`, z.B. `P:\BMP\`).

Medical Office speichert das je PC. Der BMP-Ordner muss deshalb auf allen PCs unter demselben Pfad erreichbar sein,
am besten als gemeinsamer Netzordner. Zur Vereinfachung kann ggf. das Skript `BMP-Einstellung-MO.ps1` verwendet
werden: Es trägt beides für alle Arbeitsplätze auf einmal in die Datenbank von Medical Office ein (Schreibzugriff
nötig; `medoff.med95ini` mit Änderungsprotokoll in `dbsprot` wie bei einer Eingabe in Medical Office). Ohne
`-Ausfuehren` zeigt es nur, was es ändern würde; für neue PCs lässt es sich wiederholen. Den Ordner liest es aus
denselben INI-Dateien wie MOReiter.

## Wenn ein Klick danebengeht

Manche Bedienelemente von Medical Office haben keine eigenen Fenster. Die Reiter der Anwenderansichten und die
Krankenblattfilter sucht MOReiter selbst am Bildschirm (Strg+Alt+L = 1. Reiter, K = 2., P = 3./4., einstellbar);
anderes klickt es an eingemessenen Stellen. Geht ein Klick daneben, die Maus auf das Element halten und
kalibrieren, z.B. Strg+Alt+Umsch+K auf dem Reiter „Kartei“ (s. Hilfe, Abschnitt „Kalibrieren“).

## Onlineportale

Die Benutzerskripte arbeiten in der eigenen, im Firefox angemeldeten Sitzung, wie ein schneller
Mensch; Kennwörter speichert MOReiter nicht (sie kommen aus dem Kennwortspeicher von Firefox). Bitte
prüfen Sie selbst, ob die Nutzungsbedingungen des jeweiligen Portals diese Art des Abrufs erlauben.

## Die Dateien im Repo

| Datei | wofür |
|---|---|
| `Kompilieren.bat` | erstellt `MOReiter.exe` (lädt bei Bedarf AutoIt3), fragt beim ersten Mal die Einstellungen ab und startet `Einrichten.bat` |
| `Einrichten.bat` | kopiert MOReiter nach `%APPDATA%\MOReiter`, legt die Verknüpfungen im Autostart und im Startmenü an und startet es |
| `Einstellungen.bat` | ändert später die Einstellungen der Praxis (Fenster „MOReiter einrichten“) und richtet neu ein |
| `MOReiter.au3` | Quelltext |
| `MOReiter-Hilfe.txt` | Hilfetext für Strg+Alt+F1, wird in die exe eingebettet |
| `MOReiter-Vorgaben.ini` | Voreinstellungen mit Erklärungen zu jedem Eintrag |
| `MOReiter.ico` | Programmsymbol |
| `MOReiter-*.user.js` | Benutzerskripte für Tampermonkey (Labor und Zuckerportale), installiert MOReiter selbst |
| `BmpLesen.cpp` | Quelltext von `BmpLesen.exe` (C++): Medikationsplan-Code aus PDFs und Bildern lesen, .moc-Dateien entpacken |
| `BmpLesen-Kompilieren.bat`, `.sh` | erstellen `BmpLesen.exe` mit MSYS2 (UCRT64, MuPDF, zxing-cpp, statisch gebunden) |
| `BMP-Einstellung-MO.ps1` | stellt in Medical Office für alle Arbeitsplätze das Einlesen aus dem BMP-Ordner ein |
| `Drittanbieter-Lizenzen.txt` | Bibliotheken in `BmpLesen.exe` mit Fassung, Lizenz und Bezugsquelle des Quelltexts |
| `Release-Erstellen.ps1` | baut beide exe und stellt die fertigen ausführbaren Dateien (Weg A) als Release auf GitHub bereit |
| `LICENSE` | Lizenz (GPL-3.0) |

## Fragen und Fehler

Bitte als Issue hier auf GitHub melden.
