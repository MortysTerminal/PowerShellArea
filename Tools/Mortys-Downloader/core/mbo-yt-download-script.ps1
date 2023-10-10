<# 
.SYNOPSIS
    Dieses Skript fragt den Benutzer nach einem Link von YouTube und lädt das Video hinter der URL herunter.
    Gespeichert wird dies automatisch im Downloads-Verzeichnis des anwendenden Users.
    Das Video wird im jeweiligen Format gespeichert, mit der hoechsten Qualitaet bei Video und Ton.

.DESCRIPTION 
    Der Benutzer wird nach einer URL gefragt, dies muss der Link des Videos sein. Sobald dies eingegeben wurde, muss dies mit ENTER bestaetigt werden.
    Das Skript wird dann das angegegebene Video herunterladen. (Funktioniert auch mit Playlists)
    
.COMPONENT 
    Es wird vor der Abfrage des Links eine Versions- und Existenzpruefung der "yt-dlp.exe" und "ffmpeg.exe" Datei durchgefuehrt.
    Fehlt diese Datei, wird die jeweilige exe-Datei vom GitHub-Repository heruntergeladen 
    Diese Modul benoetigt die yt-dlp.exe und ffmpeg
    Link zum GitHub-Repo: https://github.com/yt-dlp/yt-dlp

.LINK 
    https://github.com/MortysTerminal

.NOTES 
    Dies funktioniert nur in einer Windows-Umgebung. (mind. Win 7 SP1)
    NAME: Mortys-Downloader
    AUTHOR: MortysTerminal
    LASTEDIT: 09.10.2023
#>

# Definition des Parameters, welcher beim Start des Skript ubernommmen wird
# Dieser ist entscheidend bei der Auswahl des Formates des Downloads
Param(
    [string]$ext
)

##################################################
#
#   Alle benoetigten Variablen
#
##################################################
    
# PowerShell-Automatic variable um den Skriptpfad auszulesen
$scriptpath = $PSScriptRoot

# Benoetigte Variablen zur Pruefung auf Version initialisieren
$repo = "yt-dlp/yt-dlp"
$file = "yt-dlp.exe"
$downloadfilepath = $scriptpath + "/yt-dlp.exe"
$ffmpegfilepath = $scriptpath + "/ffmpeg.exe"
$versionfile = $scriptpath + "/version.motm"
$TageBisUpdateCheck = 7
$releases = "https://github.com/$repo/releases/latest"
$aktuelleVersion = Get-Content $versionfile -erroraction 'silentlycontinue'

# Pruefe ob Text aus version.motm ein Datum ist - wenn nicht dann leer machen
try{ [datetime]$aktuelleVersion } catch{ $aktuelleVersion = "" } 

# Auslesen des User-Download-Pfads
$downloadpath = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path

# Core-Pfad
$corepath = $scriptpath +"\core"

# yt-dlp Pfad
$ytdlppfad = $scriptpath +"\yt-dlp.exe"

Clear-Host

function VersionCheckAusfuehren{
    ##########
    # Pruefe auf aktuelle yt-flp Version
    ##########

    # Webrequest um die Versionen aus Github-Repo auszulesen 
    #Write-Host "Ermitteln der neuesten yt-dlp Version"
    $request = [System.Net.WebRequest]::Create($releases)
    $response = $request.GetResponse()
    $realTagUrl = $response.ResponseUri.OriginalString
    $tag = $realTagUrl.split('/')[-1].Trim('v')
    #$tag = (Invoke-WebRequest $releases | ConvertFrom-Json)[0].tag_name

    # Pruefe ob Version identisch zur gespeicherten Version
    if($tag.Equals($aktuelleVersion) -and (Test-Path -Path $downloadfilepath -PathType Leaf)){
        Write-Host "yt-dlp ist aktuell!" -ForegroundColor Green
        $tag | Out-File $versionfile               
    }
    else
    {
        Write-Host "Neue yt-dlp Version gefunden. Aktualisiere ..." -ForegroundColor Yellow
        $download = "https://github.com/$repo/releases/download/$tag/$file"

        Write-Host "Starte Download"
        #Get-FileFromWeb($download,$downloadfilepath)
        # Erstellt Web-Client und startet den Download der yt-dlp.exe
        $webclient = New-Object System.Net.WebClient
        $webclient.DownloadFile($download,$downloadfilepath)

        # Speichere neue Versionsnummer in motm-datei
        # Write-Host "Speichere neue Versionsnummer"
        $tag | Out-File $versionfile

        Write-Host "yt-dlp wurde erfolgreich aktualisiert - es kann losgehen!" -ForegroundColor Green
    }
}
function CheckVersionZeitpunkt{
    $zuletztGeladen = (Get-ChildItem $versionfile).LastWriteTime
    $Datumabstand = ((Get-Date) - $zuletztGeladen).Days
    if(($TagebisUpdateCheck -cle $Datumabstand) -or (Test-DateiLeer -Datei $versionfile) -or $aktuelleVersion.Equals("")){ VersionCheckAusfuehren }
}
function LadeFFMPEG {
    # https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip
    $ffmpegLatestReleaseURL = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"
    $ffmpegDownloadZIPPath = $scriptpath + "/ffmpeg-release-essentials.zip"
    $ffmpegunzippath = $scriptpath + "/ffmpeg-release-essentials/"

    Write-Host "Lade aktuelle FFMPEG-Version herunter" # Output
    $webclient = New-Object System.Net.WebClient
    $webclient.DownloadFile($ffmpegLatestReleaseURL,$ffmpegDownloadZIPPath)

    Expand-Archive -LiteralPath $ffmpegDownloadZIPPath -DestinationPath $ffmpegunzippath
    $ffmpegfilelocation = Get-ChildItem -Path $ffmpegunzippath -Filter "ffmpeg.exe" -Recurse
    Move-Item -Path ($ffmpegfilelocation.FullName) -Destination $scriptpath -Force

    Remove-Item -Path $ffmpegunzippath -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
    Remove-Item -Path $ffmpegDownloadZIPPath -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue

    Write-Host "ffmpeg wurde erfolgreich heruntergeladen" -ForegroundColor Green # Output
}
function LadeYTDLP{
    ##########
    # Pruefe auf aktuelle yt-flp Version
    ##########

    # Webrequest um die Versionen aus Github-Repo auszulesen 
    $request = [System.Net.WebRequest]::Create($releases)
    $response = $request.GetResponse()
    $realTagUrl = $response.ResponseUri.OriginalString
    $tag = $realTagUrl.split('/')[-1].Trim('v')
    $download = "https://github.com/$repo/releases/download/$tag/$file"

    Write-Host "Starte Download (yt-dlp)"
    $webclient = New-Object System.Net.WebClient
    $webclient.DownloadFile($download,$downloadfilepath)

    # Speichere neue Versionsnummer in motm-datei
    $tag | Out-File $versionfile
}
function Test-DateiLeer {
  Param ([Parameter(Mandatory = $true)][string]$datei)
  if ((Test-Path -LiteralPath $datei) -and !(([IO.File]::ReadAllText($datei)) -match '\S')) {return $true} else {return $false}
}

##################################################
#
#   Check ob noetige Dateien vorhanden
#
##################################################

# Pruefe ob ffmpeg vorhanden ist, wenn nicht dann herunterladen
if(!(Test-Path -Path $ffmpegfilepath -PathType Leaf)){
    Write-Host "ffmpeg fehlt - lade ffmpeg herunter" -ForegroundColor Yellow
    LadeFFMPEG
}

# Pruefe ob version.motm vorhanden ist, wenn nicht dann erstellen
if(!(Test-Path -Path $versionfile -PathType Leaf)){
    Write-Host "Versionsdatei fehlt - wird erstellt" -ForegroundColor Yellow
    Write-Host "" | Out-File $versionfile  
    # UpdateCheck
    CheckVersionZeitpunkt
}else{
    # UpdateCheck
    CheckVersionZeitpunkt
}

# Pruefe ob yt-dlp vorhanden ist, wenn nicht dann herunterladen
if(!(Test-Path -Path $ytdlppfad -PathType Leaf)){
    Write-Host "yt-dlp fehlt - lade yt-dlp herunter" -ForegroundColor Yellow
    LadeYTDLP
    Write-Host "yt-dlp wurde heruntergeladen - es kann losgehen!" -ForegroundColor Green
}





##################################################
#
#   Start des YouTube-Download-Skripts
#
##################################################

Write-Host "--- Skriptversion: 2023-10-09 -- v.1.1 -------------"

while (1)
{
    Write-Host ""
    Write-Host ""
    $url = Read-Host "Bitte YouTube-Link eingeben (wird als $ext gespeichert)"

    # WINDOWS

    if($ext -eq "mp4"){ # DOWNLOAD MP4 ONLY
        .\core\yt-dlp.exe -P $downloadpath -S "ext:mp4:m4a" $url -o "%(title)s.%(ext)s" --compat-options no-certifi --no-mtime
    }
    if($ext -eq "mp3"){ # DOWNLOAD MP3 ONLY
        .\core\yt-dlp.exe -P $downloadpath -x --audio-format mp3 --audio-quality 0 $url -o "%(title)s.%(ext)s" --compat-options no-certifi --no-mtime
    }
    if($ext -eq "m4a"){ # DOWNLOAD MP3 ONLY
        .\core\yt-dlp.exe -P $downloadpath -x --audio-format m4a --audio-quality 0 $url -o "%(title)s.%(ext)s" --compat-options no-certifi --no-mtime
    }
    if($ext -eq "all"){ # DOWNLOAD MP4 UND MP3
        .\core\yt-dlp.exe -P $downloadpath -S "ext:mp4:m4a" $url -o "%(title)s.%(ext)s" --compat-options no-certifi --no-mtime
        .\core\yt-dlp.exe -P $downloadpath -x --audio-format mp3 --audio-quality 0 $url -o "%(title)s.%(ext)s" --compat-options no-certifi --no-mtime
    }
}