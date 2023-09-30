<# 
.SYNOPSIS
    Dieses Skript fragt den Benutzer nach einem Link von YouTube und lädt das Video hinter der URL herunter.
    Gespeichert wird dies automatisch im Downloads-Verzeichnis des anwendenden Users.
    Das Video wird im mp4 Format gespeichert, mit der hoechsten Qualitaet bei Video und Ton.

.DESCRIPTION 
    Der Benutzer wird nach einer URL gefragt, dies muss der Link des Videos sein. Sobald dies eingegeben wurde, muss dies mit ENTER bestaetigt werden.
    Das Skript wird dann das angegegebene Video herunterladen. (Funktioniert auch mit Playlists)
    
.COMPONENT 
    Es wird vor der Abfrage des Links eine Versions- und Existenzpruefung der "yt-dlp.exe" Datei durchgefuehrt.
    Fehlt diese Datei, wird die exe-Datei vom GitHub-Repository heruntergeladen 
    Diese Modul benoetigt die yt-dlp.exe
    Link zum GitHub-Repo: https://github.com/yt-dlp/yt-dlp
    Dies EXE muss im selben Pfad liegen wie das Skript.

.LINK 
    https://github.com/yt-dlp/yt-dlp

.NOTES 
    Dies Funktioniert nur in einer Windows-Umgebung. (mind. Win 7 SP1)
    NAME: YouTube-Videodownloader
    AUTHOR: MortysTerminal
    LASTEDIT: 30.09.2023
#>

# Definition des Parameters, welcher beim Start des Skript ubernommmen wird
# Dieser ist entscheidend bei der Auswahl des Formates des Downloads
Param(
    [string]$ext
)

    <# 
    TODO: Code aufraeumen und Versionspruefung etc in mehr Funktionen umschreiben, damit der Code lesbarer ist
    #>

# PowerShell-Automatic variable um den Skriptpfad auszulesen
#$scriptpath = $PSScriptRoot
# DEBUG
$scriptpath = "F:\repos\PowerShellArea\Tools\YouTube-Downloader\core"
# CMD-Fenster aufraeumen
Clear-Host

function LadeFFMPEG {
    # https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip
    $ffmpegLatestReleaseURL = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"
    $ffmpegDownloadZIPPath = $scriptpath + "/ffmpeg-release-essentials.zip"
    $ffmpegunzippath = $scriptpath + "/ffmpeg-release-essentials/"


    Write-Host "Lade aktuelle FFMPEG-Version herunter"
    $webclient = New-Object System.Net.WebClient
    $webclient.DownloadFile($ffmpegLatestReleaseURL,$ffmpegDownloadZIPPath)

    Expand-Archive -LiteralPath $ffmpegDownloadZIPPath -DestinationPath $ffmpegunzippath
    $ffmpegfilelocation = Get-ChildItem -Path $ffmpegunzippath -Filter "ffmpeg.exe" -Recurse
    Move-Item -Path ($ffmpegfilelocation.FullName) -Destination $scriptpath -Force

    Remove-Item -Path $ffmpegunzippath -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
    Remove-Item -Path $ffmpegDownloadZIPPath -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue

    Write-Host "ffmpeg wurde erfolgreich heruntergeladen" -ForegroundColor Green
}

##########
# Pruefe auf aktuelle yt-flp Version
##########

# Benoetigte Variablen zur Pruefung auf Version initialisieren
$repo = "yt-dlp/yt-dlp"
$file = "yt-dlp.exe"
$downloadfilepath = $scriptpath + "/yt-dlp.exe"
$ffmpegfilepath = $scriptpath + "/ffmpeg.exe"
$versionfile = $scriptpath + "/version.motm"
#$releases = "https://api.github.com/repos/$repo/releases"
$releases = "https://github.com/$repo/releases/latest"
$aktuelleVersion = Get-Content $versionfile -erroraction 'silentlycontinue'

# Webrequest um die Versionen aus Github-Repo auszulesen 
Write-Host "Ermitteln der neuesten yt-dlp Version"
$request = [System.Net.WebRequest]::Create($releases)
$response = $request.GetResponse()
$realTagUrl = $response.ResponseUri.OriginalString
$tag = $realTagUrl.split('/')[-1].Trim('v')
#$tag = (Invoke-WebRequest $releases | ConvertFrom-Json)[0].tag_name


    <# 
    TODO: ffmpeg Datei ebenfalls pruefen und herunterladen, falls sie fehlen sollte
    ffmpeg wird benoetigt für die umwandlung in mp3 oder m4a
    #>

if(!(Test-Path -Path $ffmpegfilepath -PathType Leaf)){
    Write-Host "ffmpeg fehlt" -ForegroundColor Yellow
    LadeFFMPEG
}


# Pruefe ob Version identisch zur gespeicherten Version
if($tag.Equals($aktuelleVersion) -and (Test-Path -Path $downloadfilepath -PathType Leaf)){
    Write-Host "yt-dlp ist aktuell!" -ForegroundColor Green
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

##########
# Start des YouTube-Download-Skripts
##########

# Auslesen des User-Download-Pfads
#$downloadpath = $HOME + "/Downloads"
$downloadpath = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path

# Core-Pfad
$corepath = $scriptpath +"\core"

# yt-dlp Pfad
$ytdlppfad = $corepath +"\yt-dlp.exe"

Write-Host "--- Skriptversion: 2023-09.30 -- 0.7 -------------"

Write-Host ""
Write-Host ""
Write-Host ""


$url = Read-Host "Bitte YouTube-Link eingeben"

# WINDOWS

if($ext -eq "mp4"){ # DOWNLOAD MP4 ONLY
    .\core\yt-dlp.exe -P $downloadpath -S "ext:mp4:m4a" $url -o "%(title)s.%(ext)s" --compat-options no-certifi
}
if($ext -eq "mp3"){ # DOWNLOAD MP3 ONLY
    .\core\yt-dlp.exe -P $downloadpath -x --audio-format mp3 --audio-quality 0 $url -o "%(title)s.%(ext)s" --compat-options no-certifi
}
if($ext -eq "m4a"){ # DOWNLOAD MP3 ONLY
    .\core\yt-dlp.exe -P $downloadpath -x --audio-format m4a --audio-quality 0 $url -o "%(title)s.%(ext)s" --compat-options no-certifi
}
if($ext -eq "all"){ # DOWNLOAD MP4 UND MP3
    .\core\yt-dlp.exe -P $downloadpath -S "ext:mp4:m4a" $url -o "%(title)s.%(ext)s" --compat-options no-certifi
    .\core\yt-dlp.exe -P $downloadpath -x --audio-format mp3 --audio-quality 0 $url -o "%(title)s.%(ext)s" --compat-options no-certifi
}

# MAC DEBUG
#yt-dlp -P $downloadpath -x --audio-format mp3 --audio-quality 0 $url -o "%(title)s.%(ext)s" --compat-options no-certifi