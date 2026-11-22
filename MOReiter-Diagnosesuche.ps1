# MOReiter-Diagnosesuche.ps1 - fehlertolerante Diagnosesuche fuer MOReiter (Strg+Alt+S bzw. automatisch in der
# Diagnoseerfassung von Medical Office, wenn deren Suche nichts findet). Wird von MOReiter.exe eingebettet, nach %TEMP%
# geschrieben und als 32-bit-PowerShell gestartet (nur dort gibt es den MySQL-ODBC-Treiber); bleibt im Hintergrund und
# beantwortet Suchanfragen ueber stdin/stdout:
#   Eingabe:  S<Tab>Suchtext          Ausgabe: je Treffer eine Zeile, dann ENDE
#             Code<Tab>Herkunft<Tab>Anzahl<Tab>Treffertext<Tab>Vorgabetext<Tab>Hinweis<Tab>Unterschluessel
#             Herkunft: E = eigener Diagnosetext der Praxis (Anzahl = wie oft vergeben), A = Alphabet (Synonym),
#                       I = Text der ICD-10-GM; Hinweis: "nicht endstellig", "nicht abrechenbar" (z.B. Sternschluessel allein),
#                       "ungueltig" (nicht im heute gueltigen ICD-10-GM) oder leer; Unterschluessel: bei nicht endstelligen die
#                       endstelligen darunter ("Code Text; ...")
#             V<Tab>ICD-Code          Ausgabe: Vorgabetext<Tab>Hinweis, dann ENDE
# Datenquellen (medoff und die juengste Stammdaten-Datenbank mostat*): icd10 (ICD-10-GM, heute gueltige Fassung),
# icd10syn (Alphabetisches Verzeichnis), behgrund (eigene Diagnosetexte mit Haeufigkeit); zwischengespeichert in
# $Zwischen (tab-getrennt), erneuert, wenn aelter als $Stunden.
# Fehlertoleranz: Woerter werden vereinheitlicht (Umlaute, c/k/z, ph/f, th/t, y/i, Doppelbuchstaben, roemische Zahlen)
# und ueber Dreiergruppen von Buchstaben verglichen, so dass Tippfehler, andere Schreibweisen und zusammengesetzte
# Woerter (Fibularisvenenthrombose ~ Thrombose der Vena fibularis) trotzdem treffen.
param([string]$Zugang = 'C:\Program Files (x86)\Dateilesen\Zugang.ini', [string]$Server = 'wser,wres', [string]$Port = '2020',
      [string]$Zwischen = "$env:APPDATA\MOReiter\Diagnosen.tsv", [double]$Stunden = 20, [string]$Neu = '0')
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = New-Object Text.UTF8Encoding $false
[Console]::InputEncoding = New-Object Text.UTF8Encoding $false
$src = @"
using System; using System.Collections.Generic; using System.Text; using System.Globalization;
public class MorDiag {
  // Eintraege: Code, Herkunft (E/A/I), Anzahl, Text; je Eintrag die Dreiergruppen (sortiert, ohne Doppelte)
  List<string> code = new List<string>(), text = new List<string>(); List<char> herk = new List<char>(); List<int> anz = new List<int>();
  List<int> triZahl = new List<int>(); List<string[]> worte = new List<string[]>();
  Dictionary<int, List<int>> index = new Dictionary<int, List<int>>();
  Dictionary<string, string> vorgabe = new Dictionary<string, string>(); Dictionary<string, string> hinweis = new Dictionary<string, string>();
  public int Anzahl { get { return code.Count; } }

  public static string Norm(string s) {
    s = s.ToLowerInvariant().Replace("\u00e4", "ae").Replace("\u00f6", "oe").Replace("\u00fc", "ue").Replace("\u00df", "ss");
    s = s.Replace("\u00e9", "e").Replace("\u00e8", "e").Replace("\u00e0", "a");
    var b = new StringBuilder(s.Length + 4);
    foreach (char c in s) b.Append(char.IsLetterOrDigit(c) ? c : ' ');
    s = " " + b.ToString() + " ";
    s = s.Replace("ph", "f").Replace("th", "t").Replace("rh", "r").Replace("y", "i").Replace("ck", "k").Replace("tz", "z");
    s = s.Replace("ae", "e").Replace("oe", "o").Replace("ue", "u");  // Haematom = Hematom, oedem = odem
    b.Clear();
    for (int i = 0; i < s.Length; i++) {
      char c = s[i];
      if (c == 'c') {
        char n = i + 1 < s.Length ? s[i + 1] : ' ';
        if (n == 'h') { b.Append('x'); i++; continue; }   // ch als eigener Laut
        c = (n == 'e' || n == 'i') ? 'z' : 'k';
      }
      if (b.Length > 0 && b[b.Length - 1] == c && char.IsLetter(c)) continue; // Doppelbuchstaben
      b.Append(c);
    }
    s = b.ToString();
    // roemische Zahlen als Wort -> Ziffern (Adipositas Grad III = Grad 3)
    s = s.Replace(" iii ", " 3 ").Replace(" ii ", " 2 ").Replace(" iv ", " 4 ").Replace(" i ", " 1 ");
    return s.Trim();
  }
  static string[] Worte(string n) { return n.Split(new char[] { ' ' }, StringSplitOptions.RemoveEmptyEntries); }
  static int Tri(string w, int i) { return (w[i] << 16) ^ (w[i + 1] << 8) ^ w[i + 2]; }

  public void Vorgabe(string c, string t, string h) { vorgabe[c] = t; if (h != "") hinweis[c] = h; }
  public void Dazu(string c, char h, int n, string t) {
    int id = code.Count; var nw = Worte(Norm(t)); var set = new HashSet<int>();
    foreach (var w in nw) for (int i = 0; i + 2 < w.Length; i++) set.Add(Tri(w, i));
    code.Add(c); herk.Add(h); anz.Add(n); text.Add(t); worte.Add(nw); triZahl.Add(Math.Max(1, set.Count));
    foreach (int g in set) { List<int> l; if (!index.TryGetValue(g, out l)) { l = new List<int>(); index[g] = l; } l.Add(id); }
  }
  public string Unter(string c) {
    string b = Basis(c);
    if (Hinweis(c) != "nicht endstellig") return "";
    var l = new List<string>();
    foreach (var k in vorgabe.Keys) if (k.Length > b.Length && k.StartsWith(b) && !hinweis.ContainsKey(k)) l.Add(k);
    l.Sort(StringComparer.Ordinal);
    var sb = new StringBuilder();
    for (int i = 0; i < l.Count && i < 12; i++) { if (sb.Length > 0) sb.Append("; "); sb.Append(l[i] + " " + vorgabe[l[i]]); }
    if (l.Count > 12) sb.Append("; ...");
    return sb.ToString();
  }
  static string Basis(string c) { return c.TrimEnd('-', ' ', '!', '*', '+', '#', 'G', 'V', 'Z', 'A', 'R', 'L', 'B').TrimEnd(' '); }
  public string VorgabeText(string c) { string t; return vorgabe.TryGetValue(Basis(c), out t) ? t : ""; }
  public string Hinweis(string c) {
    string b = Basis(c), h;
    if (hinweis.TryGetValue(b, out h)) return h;
    return vorgabe.ContainsKey(b) ? "" : "ungueltig";
  }

  // Suche: je Suchwort der Anteil seiner Dreiergruppen, die im Eintrag vorkommen (Woerter unter 3 Zeichen: als ganzes
  // Wort vorhanden?), gewichtet nach Wortlaenge; dazu etwas Genauigkeit (Anteil der Eintragsgruppen, die getroffen
  // werden) und Haeufigkeit der eigenen Texte
  public List<string> Suche(string q, int max) {
    var erg = new List<string>();
    string nq = Norm(q); var qw = Worte(nq);
    if (qw.Length == 0) return erg;
    // ICD-Code oder dessen Anfang
    if (System.Text.RegularExpressions.Regex.IsMatch(q.Trim(), @"^[A-Za-z]\d\d(\.\d{0,2})?-?$")) {
      string p = q.Trim().ToUpperInvariant().TrimEnd('-'); var keys = new List<string>();
      foreach (var k in vorgabe.Keys) if (k.StartsWith(p)) keys.Add(k);
      keys.Sort(StringComparer.Ordinal);
      foreach (var k in keys) { if (erg.Count >= max) break; erg.Add(k + "\tI\t0\t" + vorgabe[k] + "\t" + vorgabe[k] + "\t" + Hinweis(k) + "\t" + Unter(k)); }
      if (erg.Count > 0) return erg;
    }
    int nw = qw.Length; var gew = new double[nw]; var tris = new List<int>[nw]; double sumG = 0;
    for (int j = 0; j < nw; j++) {
      var set = new HashSet<int>(); string w = qw[j];
      for (int i = 0; i + 2 < w.Length; i++) set.Add(Tri(w, i));
      tris[j] = new List<int>(set); gew[j] = w.Length >= 3 ? set.Count : 1.5; sumG += gew[j];
    }
    var treffer = new Dictionary<int, double[]>();  // Eintrag -> Treffer je Wort
    for (int j = 0; j < nw; j++) foreach (int g in tris[j]) {
      List<int> l; if (!index.TryGetValue(g, out l)) continue;
      foreach (int id in l) { double[] a; if (!treffer.TryGetValue(id, out a)) { a = new double[nw]; treffer[id] = a; } a[j] += 1; }
    }
    // kurze Woerter (re, li, 3): nur bei Eintraegen, die schon Treffer haben
    var liste = new List<KeyValuePair<double, int>>();
    foreach (var kv in treffer) {
      int id = kv.Key; double[] a = kv.Value; double s = 0, hits = 0;
      for (int j = 0; j < nw; j++) {
        if (qw[j].Length < 3) { if (Array.IndexOf(worte[id], qw[j]) >= 0) s += gew[j]; continue; }
        double cov = a[j] / tris[j].Count; if (cov > 1) cov = 1;
        // einzelne getroffene Gruppen sind meist Zufall
        if (a[j] < 2 && tris[j].Count > 3) cov = 0;
        s += gew[j] * cov; hits += a[j];
      }
      double recall = s / sumG; if (recall < 0.34) continue;
      double prec = Math.Min(1.0, hits / triZahl[id]);
      double score = 0.8 * recall + 0.2 * prec + (herk[id] == 'E' ? 0.02 + 0.02 * Math.Log10(1 + anz[id]) : 0) + (herk[id] == 'I' ? 0.005 : 0);
      // abgelaufene Codes nach hinten, nicht endstellige etwas
      string hw = Hinweis(code[id]); if (hw == "ungueltig") score -= 0.15; else if (hw == "nicht endstellig") score -= 0.08; else if (hw != "") score -= 0.03;
      liste.Add(new KeyValuePair<double, int>(score, id));
    }
    liste.Sort((x, y) => y.Key.CompareTo(x.Key));
    var jeCode = new Dictionary<string, int>(); var schon = new HashSet<string>();
    foreach (var kv in liste) {
      if (erg.Count >= max) break;
      int id = kv.Value; string c = code[id]; int z; jeCode.TryGetValue(c, out z);
      if (z >= 3) continue;
      string dop = c + "|" + Norm(text[id]); if (!schon.Add(dop)) continue;
      jeCode[c] = z + 1;
      erg.Add(c + "\t" + herk[id] + "\t" + anz[id] + "\t" + text[id] + "\t" + VorgabeText(c) + "\t" + Hinweis(c) + "\t" + Unter(c));
    }
    return erg;
  }
}
"@
# uebersetzte Fassung je Quelltext zwischenspeichern (spart beim naechsten Start rund eine Sekunde)
$hash = [BitConverter]::ToString((New-Object Security.Cryptography.MD5CryptoServiceProvider).ComputeHash([Text.Encoding]::UTF8.GetBytes($src))).Replace('-', '').Substring(0, 8)
$dll = Join-Path $env:TEMP "MOReiter-DiagSuche-$hash.dll"
if (Test-Path $dll) { try { Add-Type -Path $dll } catch { Remove-Item $dll -ErrorAction SilentlyContinue } }
if (-not ('MorDiag' -as [type])) {
  Get-ChildItem (Join-Path $env:TEMP 'MOReiter-DiagSuche-*.dll') -ErrorAction SilentlyContinue | Remove-Item -ErrorAction SilentlyContinue
  Add-Type -OutputAssembly $dll -OutputType Library -TypeDefinition $src
  Add-Type -Path $dll
}

function Laden([string]$datei) {
  $ini = Get-Content $Zugang -ErrorAction Stop; $in = $false; $uid = ''; $pw = ''
  foreach ($l in $ini) {
    if ($l -match '^\s*\[(.*)\]') { $in = ($matches[1] -eq 'medoff'); continue }
    if ($in -and $l -match '^\s*uid\s*=\s*(.*)$') { $uid = $matches[1].Trim() }
    if ($in -and $l -match '^\s*pwd\s*=\s*(.*)$') { $pw = $matches[1].Trim() }
  }
  if ($uid -eq '') { throw "keine Zugangsdaten [medoff] in $Zugang" }
  $cn = $null; $fehler = ''
  foreach ($srv in $Server.Split(',')) {
    try {
      $cn = New-Object System.Data.Odbc.OdbcConnection("DRIVER={MySQL ODBC 8.0 Unicode Driver};database=medoff;server=$srv;port=$Port;uid=$uid;pwd=$pw")
      $cn.ConnectionTimeout = 5; $cn.Open(); break
    } catch { $fehler += "$srv`: $($_.Exception.Message) "; $cn = $null }
  }
  if ($cn -eq $null) { throw "keine Verbindung zu medoff: $fehler" }
  function Abfrage([string]$sql) { $c = $cn.CreateCommand(); $c.CommandText = $sql; $c.CommandTimeout = 120; return ,($c.ExecuteReader()) }
  # juengste Stammdaten-Datenbank
  $r = Abfrage "select table_schema from information_schema.tables where table_name='icd10' and table_schema like 'mostat%' order by create_time desc limit 1"
  if (-not $r.Read()) { throw 'keine Stammdaten-Datenbank mostat* mit icd10' }
  $st = $r.GetString(0); $r.Close()
  $heute = ([DateTime]::Today - [DateTime]'1890-01-01').Days
  $sw = New-Object IO.StreamWriter(($datei + '.neu'), $false, (New-Object Text.UTF8Encoding $false))
  function Sauber([string]$s) { ($s -replace "[`t`r`n]", ' ').Trim([char]0, ' ') }
  $sw.WriteLine($Fassung)
  # V: Code (ohne '-'), Vorgabetext, Hinweis (FHas_children=1: nicht endstellig, FKeineAbrechnung=1: nicht abrechenbar)
  $r = Abfrage "select FICD_Code, FICD_Text, FKeineAbrechnung, FHas_children from $st.icd10 where FGueltig_ab<=$heute and (FGueltig_bis=0 or FGueltig_bis>=$heute)"
  while ($r.Read()) {
    $c = ([string]$r.GetValue(0)).TrimEnd('-')
    $h = if ([string]$r.GetValue(3) -eq '1') { 'nicht endstellig' } elseif ([string]$r.GetValue(2) -eq '1') { 'nicht abrechenbar' } else { '' }
    $sw.WriteLine("V`t$c`t$(Sauber $r.GetValue(1))`t$h")
  }
  $r.Close()
  $r = Abfrage "select FICD10, FText from $st.icd10syn"
  while ($r.Read()) { $sw.WriteLine("A`t$(Sauber $r.GetValue(0))`t1`t$(Sauber $r.GetValue(1))") }
  $r.Close()
  # eigene Texte: Endnull und vorangestelltes "gesichert " (aeltere Eintraege) weg, nur gueltig aussehende Codes
  $r = Abfrage ("select FIcdcode, trim(trailing char(0) from FText) t, count(*) from medoff.behgrund " +
    "where FIcdcode regexp '^[A-Z][0-9][0-9]' and FText<>'' group by FIcdcode, t")
  while ($r.Read()) {
    $t = (Sauber $r.GetValue(1)) -replace '^gesichert\s+', ''
    if ($t.Length -ge 3) { $sw.WriteLine("E`t$(Sauber $r.GetValue(0))`t$($r.GetValue(2))`t$t") }
  }
  $r.Close(); $cn.Close(); $sw.Close()
  Move-Item -Force ($datei + '.neu') $datei
}

# Kennung des Dateiaufbaus von $Zwischen (erste Zeile); eine aeltere Fassung wird neu geladen
$Fassung = '#MOReiter-Diagnosen 2'
# (ReadLines | Select -First 1 liesse die Datei offen, das spaetere Ersetzen scheiterte)
function ErsteZeile([string]$d) { $r = New-Object IO.StreamReader($d); try { $r.ReadLine() } finally { $r.Close() } }
try {
  $alt = (-not (Test-Path $Zwischen)) -or (ErsteZeile $Zwischen) -ne $Fassung -or ((Get-Date) - (Get-Item $Zwischen).LastWriteTime).TotalHours -gt $Stunden -or $Neu -eq '1'
  if ($alt) {
    $ordner = Split-Path $Zwischen; if (-not (Test-Path $ordner)) { New-Item -ItemType Directory $ordner | Out-Null }
    try { Laden $Zwischen } catch { if (-not (Test-Path $Zwischen)) { throw }; [Console]::Error.WriteLine("Neu laden fehlgeschlagen, nehme die alte Fassung: " + $_.Exception.Message) }
  }
  $d = New-Object MorDiag
  # eigene Texte zusammenfassen (gleicher Code und Text mit verschiedenen Endungen von FIcdcode wie G/V)
  $eigen = @{}
  foreach ($l in [IO.File]::ReadLines($Zwischen, [Text.Encoding]::UTF8)) {
    $f = $l.Split("`t")
    if ($f.Count -lt 3) { continue }
    if ($f[0] -eq 'V') { $d.Vorgabe($f[1], $f[2], $f[3]); $d.Dazu($f[1], [char]'I', 0, $f[2]) }
    elseif ($f[0] -eq 'A') { $d.Dazu($f[1], [char]'A', 1, $f[3]) }
    elseif ($f[0] -eq 'E') { $k = ($f[1] -replace '[ GVZA!*+#]+$', '') + "`t" + $f[3]; if ($eigen.ContainsKey($k)) { $eigen[$k] += [int]$f[2] } else { $eigen[$k] = [int]$f[2] } }
  }
  foreach ($k in $eigen.Keys) { $p = $k.Split("`t"); $d.Dazu($p[0], [char]'E', $eigen[$k], $p[1]) }
} catch { [Console]::Out.WriteLine('FEHLER: ' + $_.Exception.Message); [Console]::Out.Flush(); exit 1 }
[Console]::Out.WriteLine("BEREIT`t" + $d.Anzahl); [Console]::Out.Flush()
while ($null -ne ($ein = [Console]::In.ReadLine())) {
  try {
    $t = $ein.Split("`t", 2)
    if ($t[0] -eq 'S' -and $t.Count -eq 2) { foreach ($z in $d.Suche($t[1], 80)) { [Console]::Out.WriteLine($z) } }
    elseif ($t[0] -eq 'V' -and $t.Count -eq 2) { [Console]::Out.WriteLine($d.VorgabeText($t[1]) + "`t" + $d.Hinweis($t[1])) }
  } catch { [Console]::Out.WriteLine('FEHLER: ' + $_.Exception.Message) }
  [Console]::Out.WriteLine('ENDE'); [Console]::Out.Flush()
}
