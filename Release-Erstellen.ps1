# Release-Erstellen.ps1: fertiges Paket fuer andere Praxen auf GitHub (Releases) bereitstellen, damit dort niemand
# kompilieren muss: baut MOReiter.exe (Kompilieren.bat) und BmpLesen.exe (BmpLesen-Kompilieren.bat, MSYS2), packt
# den committeten Stand des Repos mit beiden exe in MOReiter-<Datum>.zip (Ordner MOReiter\) und legt mit der
# GitHub-CLI (gh, angemeldet) das Release "Fertige ausführbare Dateien – Stand <Datum>" an; ohne -Hochladen nur das ZIP im Ordner Release\.
#   powershell -ExecutionPolicy Bypass -File Release-Erstellen.ps1 [-Hochladen] [-OhneBmpLesen]
# Voraussetzung: alles committet und gepusht (das ZIP enthaelt den Stand von HEAD, nicht die Arbeitskopie).
param([switch]$Hochladen, [switch]$OhneBmpLesen)
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
function Invoke-Git { & git.exe -c safe.directory=* @args; if ($LASTEXITCODE) { throw "git $args fehlgeschlagen" } }

if (Invoke-Git status --porcelain) { throw "Es gibt nicht committete Aenderungen; bitte zuerst committen." }
Invoke-Git fetch -q origin
$hinten = Invoke-Git rev-list --count "HEAD..origin/main"; $vorn = Invoke-Git rev-list --count "origin/main..HEAD"
if ($hinten -ne "0" -or $vorn -ne "0") { throw "HEAD und origin/main sind verschieden (pull bzw. push fehlt)." }

Write-Host "Kompiliere MOReiter.exe ..."
# mit Pfad: ist NoDefaultCurrentDirectoryInExePath gesetzt, findet cmd die bat im aktuellen Ordner sonst nicht
cmd /c "`"$PSScriptRoot\Kompilieren.bat`" < nul"
if (-not (Test-Path MOReiter.exe) -or (Get-Item MOReiter.exe).LastWriteTime -lt (Get-Date).AddMinutes(-10)) { throw "MOReiter.exe wurde nicht neu kompiliert." }
if (-not $OhneBmpLesen) {
	Write-Host "Kompiliere BmpLesen.exe (MSYS2) ..."
	cmd /c "`"$PSScriptRoot\BmpLesen-Kompilieren.bat`" < nul"
	if (-not (Test-Path BmpLesen.exe) -or (Get-Item BmpLesen.exe).LastWriteTime -lt (Get-Date).AddMinutes(-30)) { throw "BmpLesen.exe wurde nicht neu kompiliert." }
}

$datum = Get-Date -Format "yyyy-MM-dd"
$tag = "stand-$datum"
New-Item -ItemType Directory -Force Release | Out-Null
$zip = Join-Path $PSScriptRoot "Release\MOReiter-$datum.zip"
if (Test-Path $zip) { Remove-Item $zip }
Invoke-Git archive --format=zip --prefix=MOReiter/ -o $zip HEAD
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
$z = [IO.Compression.ZipFile]::Open($zip, "Update")
try {
	$dateien = @("MOReiter.exe"); if (-not $OhneBmpLesen) { $dateien += "BmpLesen.exe" }
	foreach ($d in $dateien) { [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($z, (Join-Path $PSScriptRoot $d), "MOReiter/$d", "Optimal") }
} finally { $z.Dispose() }
Write-Host ("ZIP: {0} ({1:N1} MB)" -f $zip, ((Get-Item $zip).Length / 1MB))

if (-not $Hochladen) { Write-Host "Ohne -Hochladen: nichts veroeffentlicht."; exit 0 }
$commit = Invoke-Git rev-parse --short HEAD
$text = @"
Fertige ausführbare Dateien zum Entpacken, ohne Kompilieren: alle Dateien des Repos und dazu MOReiter.exe und BmpLesen.exe (Medikationsplan, Strg+Alt+Ü).

**Erstes Einrichten:** MOReiter-$datum.zip herunterladen, Rechtsklick > Eigenschaften > "Zulassen", entpacken (z.B. nach C:\, es entsteht C:\MOReiter), dort **Einrichten.bat** doppelklicken; beim ersten Mal öffnet sich das Fenster "MOReiter einrichten".

**Update:** das ZIP ebenso freigeben und in denselben Ordner entpacken, vorhandene Dateien ersetzen (die eigenen Einstellungen in MOReiter-Praxis.ini und %APPDATA%\MOReiter\MOReiter.ini sind nicht im ZIP und bleiben erhalten), dann **Einrichten.bat** doppelklicken; es beendet den laufenden MOReiter und startet den neuen. Auf den übrigen PCs der Praxis genügt danach Einrichten.bat aus diesem Ordner (bzw. den Ordner wieder dorthin kopieren).

Weiteres im README, Abschnitt "Einrichten". Stand des Quelltexts: $commit. Lizenzen der in BmpLesen.exe enthaltenen Bibliotheken: Drittanbieter-Lizenzen.txt im Paket.
"@
& gh release create $tag $zip --title "Fertige ausführbare Dateien – Stand $datum" --notes $text --target main
if ($LASTEXITCODE) { throw "gh release create fehlgeschlagen" }
Write-Host "Release $tag angelegt."
