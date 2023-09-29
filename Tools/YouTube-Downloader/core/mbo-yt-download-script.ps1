<# 
.SYNOPSIS
    Dieses Skript fragt den Benutzer nach einem Link von YouTube und lädt das Video hinter der URL herunter.
    Gespeichert wird dies automatisch im Downloads-Verzeichnis des anwendenden Users.
    Das Video wird im mp4 Format gespeichert, mit der hoechsten Qualitaet bei Video und Ton.

.DESCRIPTION 
    Der Benutzer wird nach einer URL gefragt, dies muss der Link des Videos sein. Sobald dies eingegeben wurde, muss dies mit ENTER bestaetigt werden.
    Das Skript wird dann das angegegebene Video herunterladen.
    
.COMPONENT 
    Diese Modul benoetigt die yt-dlp exe
    Link zum GitHub-Repo: https://github.com/yt-dlp/yt-dlp
    Dies EXE muss im selben Pfad liegen wie das Skript.

.LINK 
    https://github.com/yt-dlp/yt-dlp

.NOTES 
    Dies Funktioniert nur in einer Windows-Umgebung. (mind. Win 7 SP1)
    NAME: MBo-YouTube-Videodownloader
    AUTHOR: Martin Bosche, IT-Systemadministrator Gneuss
    LASTEDIT: 27.04.2023
#>

# Definition der Parameter
Param(
    [string]$ext
)

# PowerShell-Automatic variable um den Skriptpfad auszulesen
$scriptpath = $PSScriptRoot

##########
# Pruefe auf aktuelle yt-flp Version
##########

# Benoetigte Variablen zur Pruefung auf Version initialisieren
$repo = "yt-dlp/yt-dlp"
$file = "yt-dlp.exe"
$downloadfilepath = $scriptpath + "/yt-dlp.exe"
$versionfile = $scriptpath + "/version.motm"
#$releases = "https://api.github.com/repos/$repo/releases"
$releases = "https://github.com/$repo/releases/latest"
$aktuelleVersion = Get-Content $versionfile -erroraction 'silentlycontinue'
$ytdlpCheck = Test-Path -Path $downloadfilepath -PathType Leaf

# Webrequest um die Versionen aus Github-Repo auszulesen 
Write-Host "Ermitteln der neuesten Version"
$request = [System.Net.WebRequest]::Create($releases)
$response = $request.GetResponse()
$realTagUrl = $response.ResponseUri.OriginalString
$tag = $realTagUrl.split('/')[-1].Trim('v')
#$tag = (Invoke-WebRequest $releases | ConvertFrom-Json)[0].tag_name

# Pruefe ob Version identisch zur gespeicherten Version
if($tag.Equals($aktuelleVersion) -and (Test-Path -Path $downloadfilepath -PathType Leaf)){
    Write-Host "Aktuellste Version yt-dlp.exe bereits vorhanden!" -ForegroundColor Green
}
else
{
    Write-Host "Neue yt-dlp Version gefunden. Aktualisiere ..." -ForegroundColor Yellow
    $download = "https://github.com/$repo/releases/download/$tag/$file"

    Write-Host "Starte Download"
    #Get-FileFromWeb($download,$downloadfilepath)
    $webclient = New-Object System.Net.WebClient
    $webclient.DownloadFile($download,$downloadfilepath)

    # Speichere neue Versionsnummer in motm-datei
    Write-Host "Speichere neue Versionsnummer"
    $tag | Out-File $versionfile
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

Write-Host ""
Clear-Host
Write-Host "--- Skriptversion: 2023-09.-29 -- 0.6 -------------"
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