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

1. Den grünen Knopf „<> Code“ rechts über der Dateiliste aufklappen und „Download ZIP“ wählen (nicht der
   Reiter „Code“ oben links), oder direkt über
   [https://github.com/libelle17/MOReiter/archive/refs/heads/main.zip](https://github.com/libelle17/MOReiter/archive/refs/heads/main.zip)
   herunterladen; eine Anmeldung bei GitHub ist nicht nötig. Vor dem Entpacken: Rechtsklick auf das ZIP →
   Eigenschaften → „Zulassen“ anhaken, sonst warnt Windows bei jeder Datei. Dann entpacken, z.B. nach `C:\MOReiter`.
2. `Kompilieren.bat` doppelklicken. Beim ersten Mal fragt MOReiter in einem Fenster, was die Praxis nutzt
   (Labor, Zuckerportale, Smart Pix, …) und welche Werte gelten (Ablageordner, Benutzerkennungen …),
   und speichert das in `MOReiter-Praxis.ini`. Ändern lässt es sich später jederzeit mit
   `MOReiter.exe Praxis`.
3. MOReiter startet und erscheint als Symbol im Infobereich der Taskleiste. Strg+Alt+F1 zeigt die Hilfe.

Auf weiteren PCs der Praxis: den Ordner samt `MOReiter.exe` und `MOReiter-Praxis.ini` kopieren und
`Einrichten.bat` starten. Es kopiert beides nach `%APPDATA%\MOReiter` und startet MOReiter von dort.

## Einstellungen

MOReiter liest drei Dateien gleichen Aufbaus, die erste, die einen Wert nennt, gilt:

| Datei | Inhalt |
|---|---|
| `%APPDATA%\MOReiter\MOReiter.ini` | Einstellungen und Kalibrierungen dieses PCs |
| `MOReiter-Praxis.ini` | Einstellungen der Praxis (schreibt `MOReiter.exe Praxis`; ein leerer Wert schaltet einen Eintrag der Vorgaben ab) |
| `MOReiter-Vorgaben.ini` | allgemeine Voreinstellungen aus diesem Repo, mit Erklärungen zu jedem Eintrag |

Bei einem Update werden nur `MOReiter.au3`, die Vorgaben und die übrigen Repo-Dateien ersetzt; die
eigenen Einstellungen bleiben erhalten.

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
