# Formatierungsart des Scripts festlegen bevor fortgefahren wird
$PSDefaultParameterValues = @{ '*:Encoding' = 'utf8' } 

################################################
###### HIER DOWNLOAD PFAD AENDERN !!
################################################

# Pfad zum Download (Beispiele: "C:\Users\USERNAME\Downloads" ; ".\downloaded" <- STANDARD:Verzeichnis in welchem das Skript ausgefuehrt wird)
$downloadpath = ".\downloaded" 










################################################
###### FUNKTIONEN
################################################

function CheckYTDLPPath{
    Param(
        # Pfad zum yt-dlp Verzeichnis
        $path 
        )
    Begin{
        # Auslesen aller Dateien im Verzeichnis
        $items = Get-ChildItem $ytdlppath
    }
    Process{
        # Schleife fuer jede Datei im Verzeichnis
        foreach ($file in $items) {
            # Ueberpruefeung ob yt-dlp.exe vorhanden ist
            if($file.Name -eq "yt-dlp.exe"){
                return $true, $file.FullName
            }
        }
        return $false
    }
}

################################################
###### INITIALISIERUNG / KONFIGURATION
################################################

#CLI aufraeumen
Clear-Host

# Ueberpruefe ob yt-dlp Verzeichnis fehlt
$ytdlppath = ".\yt-dlp"

# Funktionsaufruf
$CheckYTDLPPath = CheckYTDLPPath($ytdlppath)

# Rueckgabe-Wert ob YTDLPPath vorhanden ist
$YTDLPPathVorhanden = $CheckYTDLPPath[0] 

# Kompletter Pfad des YTDLPPath
$ytdlpfilepath = $CheckYTDLPPath[1] 

if( (Test-Path -path $ytdlppath -erroraction 'silentlycontinue') -and ($YTDLPPathVorhanden)) {
    Write-Host "yt-dlp existiert. Skript wird ausgefuehrt." -ForegroundColor Green
}
else {
    Write-Host "yt-dlp Verzeichnis oder exe fehlt, bitte das yt-dlp Verzeichnis erstellen und die yt-dlp.exe dort ablegen" -ForegroundColor Yellow
    Write-Host "Skript wird abgebrochen" -ForegroundColor Red
    Write-Host -NoNewLine 'Druecke beliebige Taste um fortzufahren...';
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
}

################################################
###### SCRIPT START
################################################

#CLI aufraeumen
Clear-Host

# Usereingabe und Speichern der Eingabe in "url" 
$url = Read-Host -Prompt 'Link zum Video eingeben'

# Erstelle Titel-Namen des Videos und 
$titlename = & $ytdlpfilepath -e $url.ToString()

# Regular Expression - Unicode - Matching Specific Code Points
# See http://unicode-table.com/en/
$titlename = $titlename -replace '[^\u0030-\u0039\u0041-\u005A\u0061-\u007A]+', ''

# Auslesen des vollstaendigen Downloadpaths
$fulldownloadpath = Resolve-Path -Path $downloadpath

# Erstelle Ordner mit Namen des Videos
New-Item -Path $downloadpath -Name $titlename -ItemType "directory" -erroraction 'silentlycontinue' 

# Umschreiben auf neuen Downloadpath
$fulldownloadpath = Resolve-Path -Path ($downloadpath + "\" + $titlename)

# Lade Audio herunter
& $ytdlpfilepath -P $fulldownloadpath $url.ToString() -x --audio-format "mp3" --windows-filenames --progress

# Lade Video herunter
& $ytdlpfilepath -P $fulldownloadpath $url.ToString() -f "bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4] / bv*+ba/b" --windows-filenames --progress

# Ende fuer DEBUG only
#Write-Host -NoNewLine 'Skript beendet. Druecke beliebige Taste um das Skript zu schliessen...';
#$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');