# MOReiter – Tastenkürzel für Medical Office

MOReiter läuft unauffällig im Hintergrund (Symbol im Infobereich der Taskleiste) und bedient
Medical Office per Tastatur, wo es sonst nur die Maus gibt, zum Beispiel:

- Reiter wechseln: Strg+Alt+K (Kartei/Krankenblatt), Strg+Alt+L (Krankenblatt), Strg+Alt+P (ePA/ePAAbr)
- Filter der Kartei und Diagnose-Kurzwahl: Strg+Alt+1, 2, 3 … bzw. Ziffernblock
- Termine des Patienten zeigen, solange Strg+Alt+T gehalten wird – aus jedem Programm
- Tagesübersicht: Strg+Alt+A hakt die markierte offene Aufgabe ab
- Briefversand, ePA-Hochladen, zuletzt geöffnete Patienten, Hauptmenü …
- Strg+Alt+F1 zeigt die Hilfe mit allen Tasten, die auf diesem PC eingerichtet sind

Zusatzfunktionen, je nach Praxis einzuschalten:

- Laborbefunde aus onlinebefunde.labor-staber.de (Strg+O)
- Zuckerberichte aus LibreView, Dexcom Clarity, Glooko, YourLoops und EasyView (Strg+L, D, G, Y, E;
  Strg+Z ruft alle Portale nach den Markierungen des Patienten ab), Ablage und Umbenennung der PDFs
- Accu-Chek Smart Pix: Patient wählen bzw. Patientenliste mit Medical Office abgleichen
- eigene Programme mit Name und Geburtsdatum des Patienten aufrufen (Abschnitt `[Aufrufe]`)

MOReiter ist kein Produkt der Indamed EDV-Entwicklung und Vertrieb GmbH und wird von ihr nicht
unterstützt. Benutzung auf eigene Verantwortung, ohne Gewährleistung (s. [LICENSE](LICENSE), GPL-3.0).

## Voraussetzungen

- Windows mit Medical Office
- Internet beim ersten Kompilieren: fehlt AutoIt3, lädt `Kompilieren.bat` die portable Fassung von
  www.autoitscript.com in den Unterordner `AutoIt3` (ohne Installation, ohne Administratorrechte)
- für Labor und Zuckerportale: Firefox; das Add-on Tampermonkey und die Benutzerskripte bietet MOReiter
  beim ersten Abruf selbst zur Installation an
- für Strg+Z, Strg+Alt+D und den Smart Pix-Abgleich: Lesezugriff auf die Datenbank von Medical Office
  (MySQL ODBC 8.0 Unicode Driver und Zugangsdaten, s. `[Allgemein] Zugang=` in `MOReiter-Vorgaben.ini`)

## Einrichten

1. **Herunterladen:** den grünen Knopf „<> Code“ rechts über der Dateiliste aufklappen und „Download ZIP“
   wählen (nicht der Reiter „Code“ oben links), oder direkt über
   [https://github.com/libelle17/MOReiter/archive/refs/heads/main.zip](https://github.com/libelle17/MOReiter/archive/refs/heads/main.zip);
   eine Anmeldung bei GitHub ist nicht nötig.
2. **Freigeben und entpacken:** Rechtsklick auf das ZIP → Eigenschaften → unten „Zulassen“ anhaken → OK
   (sonst warnt Windows bei jeder Datei aus dem Internet). Dann entpacken, z.B. nach `C:\MOReiter`.
3. **Kompilieren:** `Kompilieren.bat` doppelklicken. Fehlt AutoIt3, lädt es die portable Fassung (einige
   Sekunden). Meldet die Windows-Sicherheit bzw. SmartScreen eine „unbekannte App“: „Weitere Informationen“ →
   „Trotzdem ausführen“ (MOReiter überwacht die Tastatur für seine Kürzel, das wirkt auf Virenscanner manchmal
   verdächtig; der Quelltext liegt offen hier).
4. **Einstellungen:** Beim ersten Mal öffnet sich das Fenster „MOReiter einrichten“. Ankreuzen, was die Praxis
   nutzt (Labor, Ablage und Einordnen der PDFs, Zuckerportale, Smart Pix, Patientenlaufzettel), die Pfade und
   Benutzerkennungen eintragen und OK drücken; was von einem Kästchen abhängt, ist grau, solange es aus ist.
   Gespeichert wird in `MOReiter-Praxis.ini`. Später lässt sich alles mit `Einstellungen.bat` ändern.
5. **Start:** MOReiter startet von `%APPDATA%\MOReiter` aus, erscheint als Symbol im Infobereich der Taskleiste
   (ggf. unter dem kleinen Pfeil) und trägt sich in den Autostart des Benutzers ein (`[Allgemein] Autostart=0`
   schaltet das ab). Es läuft immer nur einmal; ein zweiter Start beendet sich still.
6. **Hilfe:** Strg+Alt+F1 zeigt alle Tasten, die auf diesem PC eingerichtet sind.

Auf weiteren PCs der Praxis: den Ordner samt `MOReiter.exe` und `MOReiter-Praxis.ini` kopieren und
`Einrichten.bat` starten. Es kopiert beides nach `%APPDATA%\MOReiter` und startet MOReiter von dort.

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
5. **Patientenlaufzettel** (nur mit Dateilese): Beim ersten Klick auf einen MOReiter-Link fragt Firefox, ob er
   MOReiter öffnen darf: „Immer erlauben“ anhaken und „Link öffnen“.

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

## Wenn ein Klick danebengeht

Manche Bedienelemente von Medical Office haben keine eigenen Fenster; MOReiter klickt dort an
eingemessenen Stellen. Passen sie bei Ihnen nicht, die Maus auf das Element halten und kalibrieren,
z.B. Strg+Alt+Umsch+K auf dem Reiter „Kartei“ (s. Hilfe, Abschnitt „Kalibrieren“).

## Onlineportale

Die Benutzerskripte arbeiten in der eigenen, im Firefox angemeldeten Sitzung, wie ein schneller
Mensch; Kennwörter speichert MOReiter nicht (sie kommen aus dem Kennwortspeicher von Firefox). Bitte
prüfen Sie selbst, ob die Nutzungsbedingungen des jeweiligen Portals diese Art des Abrufs erlauben.

## Fragen und Fehler

Bitte als Issue hier auf GitHub melden.
