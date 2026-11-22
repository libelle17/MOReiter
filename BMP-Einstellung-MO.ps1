# BMP-Einstellung-MO.ps1 (22.11.26): in Medical Office fuer alle Arbeitsplaetze das Einlesen von Medikationsplaenen
# (bundeseinheitlicher Medikationsplan) aus dem BMP-Ordner einstellen, wie in der Datenpflege "Barcodescanner:
# Dateiauswahl" und Dateipfad (dort legen der BMP-Scanner und Strg+Alt+Ue von MOReiter die XML-Dateien ab).
# Der Ordner ist derselbe, den MOReiter nimmt: [BMP] Ordner= aus MOReiter-Praxis.ini, sonst MOReiter-Vorgaben.ini (beide
# neben diesem Skript), sonst P:\BMP; eingetragen mit "\" am Ende, verglichen ohne Ruecksicht auf Gross/Klein.
# Gespeichert ist das in medoff.med95ini je Arbeitsplatz (FClientname), FBereich DOSIERPLAN:
#   BarcodeScanner = 4 (Dateiauswahl), BarcodePfad = z.B. p:\bmp\   (FVarvalue endet bei MO mit \0, aeltere Zeilen ohne)
# Geaendert wird nur, was abweicht; fehlende Zeilen werden angelegt (FSurogat aus med95ini_fsurogat_seq). Wie bei einer
# Aenderung in MO selbst kommt je Zeile ein dbsprot-Eintrag dazu (wie Dateilesen KorrNachMO/DiagNachMO): FTyp 0 beim
# Anlegen (FXmlinhalt NULL), FTyp 1 beim Aendern (<Varvalue>alter Wert</Varvalue> CRLF \0), FPatnr = FSurogat der Zeile,
# FSurogat aus dbsprot_fsurogat_seq, FEpoch = hoechste + 1, FVersion und FOrigdbid wie der letzte eigene Eintrag,
# damit der Abgleich mit dem Reserveserver die Aenderung mitbekommt. Je Arbeitsplatz eine Transaktion.
# Arbeitsplaetze = alle FClientname in med95ini ausser #GLOBAL# und #DEL#...; ein neuer PC erscheint dort, sobald MO
# auf ihm einmal etwas gespeichert hat, das Skript kann dann einfach noch einmal laufen.
# Wirksam auf einem PC vermutlich erst nach dem naechsten Start von MO.
# Aufruf (32-Bit-PowerShell wegen des 32-Bit-ODBC-Treibers):
#   C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -File BMP-Einstellung-MO.ps1 [-Ausfuehren]
#   ohne -Ausfuehren nur anzeigen, was geaendert wuerde. Vorher werden die DOSIERPLAN-Zeilen nach
#   %APPDATA%\MOReiter\med95ini-DOSIERPLAN-<Zeit>.txt gesichert.
param(
    [switch]$Ausfuehren,
    [string]$Server = "wser",
    [int]$Port = 2020,
    [int]$Nutzer = 32,       # MO-Nutzer (nutzerneu.FSurogat) fuer dbsprot.FUserid, wie bei einer Einstellung von Hand
    [string]$Zugang = "C:\Program Files (x86)\Dateilesen\Zugang.ini"
)
$ErrorActionPreference = "Stop"

# Wert aus einer INI-Datei (wie IniRead), $null wenn Datei, Abschnitt oder Schluessel fehlen
function IniWert([string]$datei, [string]$abschnitt, [string]$schluessel) {
    if (-not (Test-Path $datei)) { return $null }
    $ab = ""
    foreach ($l in Get-Content $datei) {
        if ($l -match '^\s*\[(.+)\]') { $ab = $matches[1].Trim(); continue }
        if ($ab -eq $abschnitt -and $l -match ('^\s*' + [regex]::Escape($schluessel) + '\s*=(.*)$')) { return $matches[1].Trim() }
    }
    return $null
}
$ordner = $null
foreach ($d in @("MOReiter-Praxis.ini", "MOReiter-Vorgaben.ini")) {
    $ordner = IniWert (Join-Path $PSScriptRoot $d) "BMP" "Ordner"
    if ($null -ne $ordner) { break }
}
if ([string]::IsNullOrEmpty($ordner)) { $ordner = "P:\BMP" }
$ordner = $ordner.TrimEnd("\") + "\"
Write-Host "BMP-Ordner: $ordner"
$Soll = [ordered]@{ "BarcodeScanner" = "4"; "BarcodePfad" = $ordner }

if ([IntPtr]::Size -ne 4) { throw "bitte mit der 32-Bit-PowerShell aufrufen (C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe)" }
$uid = ""; $kennwort = ""; $abschnitt = ""
foreach ($l in Get-Content $Zugang) {
    if ($l -match '^\[(.+)\]') { $abschnitt = $matches[1] }
    elseif ($abschnitt -eq 'medoff' -and $l -match '^uid=(.*)') { $uid = $matches[1] }
    elseif ($abschnitt -eq 'medoff' -and $l -match '^pwd=(.*)') { $kennwort = $matches[1] }
}
if (-not $uid) { throw "keine Zugangsdaten [medoff] in $Zugang" }
$cn = New-Object System.Data.Odbc.OdbcConnection("DRIVER={MySQL ODBC 8.0 Unicode Driver};database=medoff;server=$Server;port=$Port;uid=$uid;pwd=$kennwort")
$cn.Open()

function Abfrage([string]$sql, $tr = $null) {
    $c = $cn.CreateCommand(); $c.CommandText = $sql; if ($tr) { $c.Transaction = $tr }
    $r = $c.ExecuteReader(); $erg = @()
    while ($r.Read()) { $z = @(); for ($i = 0; $i -lt $r.FieldCount; $i++) { $z += , $r.GetValue($i) }; $erg += , $z }
    $r.Close(); return , $erg
}
function Befehl([string]$sql, $tr) {
    $c = $cn.CreateCommand(); $c.CommandText = $sql; $c.Transaction = $tr; return $c.ExecuteNonQuery()
}
# SQL-Text; medoff laeuft mit NO_BACKSLASH_ESCAPES, also nur Hochkommas verdoppeln
function Q([string]$s) { "'" + $s.Replace("'", "''") + "'" }
function Xml([string]$s) { $s.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;").Replace('"', "&quot;") }

$nbe = (Abfrage "SELECT @@sql_mode LIKE '%NO_BACKSLASH_ESCAPES%'")[0][0]
if ([int]$nbe -ne 1) { throw "medoff-Sitzung ohne NO_BACKSLASH_ESCAPES, Abbruch" }

$zeilen = Abfrage "SELECT FSurogat, FClientname, FVarname, CAST(FVarvalue AS CHAR) FROM med95ini WHERE FBereich='DOSIERPLAN' ORDER BY FClientname, FVarname, FSurogat"
$sicherung = Join-Path $env:APPDATA ("MOReiter\med95ini-DOSIERPLAN-" + (Get-Date -Format "yyyy-MM-dd_HH-mm-ss") + ".txt")
New-Item -ItemType Directory -Force (Split-Path $sicherung) | Out-Null
($zeilen | ForEach-Object { "{0}`t{1}`t{2}`t{3}" -f $_[0], $_[1], $_[2], ([string]$_[3]).Replace([string][char]0, "\0") }) | Set-Content -Encoding UTF8 $sicherung
Write-Host "gesichert: $sicherung"

$plaetze = Abfrage "SELECT DISTINCT FClientname FROM med95ini WHERE FClientname <> '#GLOBAL#' AND FClientname NOT LIKE '#DEL#%' AND FClientname <> '' ORDER BY FClientname"
$aenderungen = 0
foreach ($p in $plaetze) {
    $platz = [string]$p[0]
    $plan = @()
    foreach ($var in $Soll.Keys) {
        $treffer = @($zeilen | Where-Object { $_[1] -ceq $platz -and $_[2] -eq $var })
        $wert = $Soll[$var]
        if ($treffer.Count -eq 0) { $plan += , @("neu", $var, $wert, $null, ""); continue }
        foreach ($t in $treffer) {
            $alt = ([string]$t[3]).TrimEnd([char]0)
            # Pfade ohne Ruecksicht auf Gross/Klein (P:\BMP\ = p:\bmp\)
            if (($var -eq "BarcodePfad" -and $alt -ne $wert) -or ($var -ne "BarcodePfad" -and $alt -cne $wert)) { $plan += , @("aendern", $var, $wert, $t[0], $alt) }
        }
    }
    if ($plan.Count -eq 0) { Write-Host ("{0,-18} schon richtig" -f $platz); continue }
    foreach ($x in $plan) {
        if ($x[0] -eq "neu") { Write-Host ("{0,-18} {1} = {2} anlegen" -f $platz, $x[1], $x[2]) }
        else { Write-Host ("{0,-18} {1}: '{2}' -> '{3}' (Zeile {4})" -f $platz, $x[1], $x[4], $x[2], $x[3]) }
    }
    if (-not $Ausfuehren) { continue }
    $tr = $cn.BeginTransaction()
    try {
        $letzte = Abfrage "SELECT FVersion, FOrigdbid FROM dbsprot WHERE FServersrcid=0 ORDER BY FSurogat DESC LIMIT 1" $tr
        $epoch = (Abfrage "SELECT COALESCE(MAX(FEpoch),0)+1 FROM dbsprot FOR UPDATE" $tr)[0][0]
        $jetzt = Get-Date
        $tag = [int]($jetzt.Date - [datetime]"1890-01-01").TotalDays
        $sek = [int]$jetzt.TimeOfDay.TotalSeconds
        foreach ($x in $plan) {
            if ($x[0] -eq "neu") {
                $id = (Abfrage "SELECT NEXT VALUE FOR med95ini_fsurogat_seq" $tr)[0][0]
                [void](Befehl ("INSERT INTO med95ini(FSurogat,FServerid,FClientname,FBereich,FVarname,FVarvalue) VALUES(" + $id + ",0," + (Q $platz) + ",'DOSIERPLAN'," + (Q $x[1]) + ",CONCAT(" + (Q $x[2]) + ",CHAR(0 USING latin1)))") $tr)
                $typ = 0; $xml = "NULL"
            } else {
                $id = $x[3]
                $n = Befehl ("UPDATE med95ini SET FVarvalue=CONCAT(" + (Q $x[2]) + ",CHAR(0 USING latin1)) WHERE FSurogat=" + $id + " AND FVarvalue IN (CONCAT(" + (Q $x[4]) + ",CHAR(0 USING latin1)), " + (Q $x[4]) + ")") $tr  # alte Zeilen ohne \0
                if ($n -ne 1) { throw "Zeile $id inzwischen geaendert" }
                $typ = 1; $xml = "CONCAT(" + (Q ("<Varvalue>" + (Xml $x[4]) + "</Varvalue>`r`n")) + ",CHAR(0 USING latin1))"
            }
            $prid = (Abfrage "SELECT NEXT VALUE FOR dbsprot_fsurogat_seq" $tr)[0][0]
            $zufall = Get-Random -Minimum ([int]::MinValue) -Maximum ([int]::MaxValue)
            [void](Befehl ("INSERT INTO dbsprot(FSurogat,FPrimarykey,FTablename,FTyp,FDatum,FUhrzeit,FServersrcid,FUserid,FVersion,FPatnr,FXmlinhalt,FEpoch,FEpochtime," +
                    "FPrio,FSourceepoch,FOrigsurogat,FOrigdbid,FRandomid) VALUES(" + $prid + "," + (Q ('"' + $id + '"')) + ",'med95ini'," + $typ + "," + $tag + "," + $sek + ",0," +
                    $Nutzer + "," + $letzte[0][0] + "," + $id + "," + $xml + "," + $epoch + ",NOW(),-1,0," + $prid + "," + $letzte[0][1] + "," + $zufall + ")") $tr)
            $aenderungen++
        }
        $tr.Commit()
    } catch {
        $tr.Rollback()
        Write-Host ("{0,-18} NICHT geaendert: {1}" -f $platz, $_.Exception.Message)
    }
}
$cn.Close()
if ($Ausfuehren) { Write-Host "$aenderungen Zeilen geaendert bzw. angelegt" } else { Write-Host "Probelauf, nichts geaendert (mit -Ausfuehren eintragen)" }
