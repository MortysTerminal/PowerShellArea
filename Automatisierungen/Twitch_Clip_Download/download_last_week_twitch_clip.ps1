# Formatierungsart des Scripts festlegen bevor fortgefahren wird
$PSDefaultParameterValues = @{ '*:Encoding' = 'utf8' } 

# Logpath -- bitte nicht aendern
$Logfile = ".\log.log"

################################################
###### HIER DIE VARIABLEN AENDERN
################################################

# Pfad zum Download (Beispiele: "C:\Users\USERNAME\Downloads" ; ".\downloaded" <- STANDARD:Verzeichnis in welchem das Skript ausgefuehrt wird)
$downloadpath = ".\downloaded" 
$channelname = "MORTYS_WELT" # MeisterMortn ; DentuGaming
#$broadcasterID = "837493131" # mortnID = "87729567" ; dentuID = "59215867"

### App-Konfiguration

$appID =    "HIER APP ID EINGEBEN"
$secret =   "HIER APP SECRET EINGEBEN"
$accesstokenURL = "https://id.twitch.tv/oauth2/token?client_id=" + $appID + "&client_secret=" + $secret + "&grant_type=client_credentials"
$accesstokenObject = Invoke-WebRequest -Method POST $accesstokenURL | ConvertFrom-Json # Object vom Invoke erstellen
$accesstoken = $accesstokenObject.access_token # AccessToken speichern

# Daten vom angegebenen Channel auslesen durch Twitch
Write-Host ""
Write-Host "Lese Benutzerdaten von angegebenen Channel aus ($channelname)"
try {
    # Funktionsaufruf und Versuch die USER-ID von Twitch zu lesen
    $broadcasterID = GetTwitchUserID -funcChannelname $channelname
}
catch{
    Write-Host "User ID vom Benutzer konnte nicht gelesen werden. App-ID in Ordnung?"
}
Write-Host "Benutzerdaten gelesen! ID gespeichert. (ID=$userID)"

################################################
###### FUNKTIONEN
################################################

function GetTwitchUserID{
    Param(
        $funcChannelname
    )
    Begin{
        # URL Bauen um Benutzerdaten von Twitch auszulesen
        $getIDRequestURL = "https://api.twitch.tv/helix/users?login="+ $funcChannelname
    }
    Process{
        $userObject = curl.exe --silent -X GET $getIDRequestURL -H "Authorization: Bearer $accesstoken" -H "Client-ID: $appID" | ConvertFrom-Json 
    }
    End{
        return $userObject.data.id
    }
}
function WriteLog
{
  Param ([string]$LogString)
  $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
  $LogMessage = "$Stamp $LogString"
  Add-content $LogFile -value $LogMessage
}

function Replace-Chars([parameter(ValueFromPipeline=$true)]$string,$replaceString='_'){
    $r = "[^\w\+\-\(\) ]"
    if ($replaceString -match $r){
        Write-Error -Message "Parameter '-replaceString' contains invalid filename chars/sequences." -Category InvalidArgument -TargetObject $replaceString
        break
    }
    while($string -match $r){
        $string = ($string -replace $r,$replaceString).trim()
    }
    return $string
}


### TEST-Clips
#https://www.twitch.tv/meistermortn/clip/AcceptableMotionlessDogCoolCat-i0uWx7EgkjvM6POP?filter=clips&range=7d&sort=time






$downloadpath = "\\10.0.10.127\remote-share\$channelname\Clips" # Pfad zum Download
$downloadfile = $downloadpath + "\file" # Pfad zur Download - Datei
$logfile = "$downloadpath\$channelname" + "_download_log.txt" # Pfad zur Log-Datei
cmd.exe /c "net use $downloadpath /user:martin WSde2f***" # Verbinde mit Netzwerklaufwerk

#####py -3 $scriptpath clips meistermortn --period last_week --download
$appID = "b41biugu8gm9ebso2t2qx21s4dyndj" # Mortns_ClipDownloader - Appid
$secret = "zilgihgwe331ig19s0gj6gj9xw3y0c" # Mortns_ClipDownloader - Secret
# https://id.twitch.tv/oauth2/token?client_id=uo6dggojyb8d6soh92zknwmi5ej1q2&client_secret=nyo51xcdrerl8z9m56w9w6wg&grant_type=client_credentials
$accesstokenURL = "https://id.twitch.tv/oauth2/token?client_id=" + $appID + "&client_secret=" + $secret + "&grant_type=client_credentials"
$accesstokenObject = Invoke-WebRequest -Method POST $accesstokenURL | ConvertFrom-Json
$accesstoken = $accesstokenObject.access_token

#$test2 = curl.exe -X GET "https://id.twitch.tv/oauth2/validate" -H "Authorization: Bearer zilgihgwe331ig19s0gj6gj9xw3y0c"
# wird benoetigt: "2017-11-30T22:34:18Z"
$datumtemp = (Get-Date).AddDays(-7)
$datum = Get-Date $datumtemp -Format "yyyy-MM-ddTHH:mm:ssZ"

$object = curl.exe -X GET "https://api.twitch.tv/helix/clips?broadcaster_id=$broadcasterID&started_at=$datum" -H "Authorization: Bearer $accesstoken" -H "Client-ID: $appID" | ConvertFrom-Json
$WebClient = New-Object System.Net.WebClient

<#
######### Vorbereitung zu Chat-Download und Render
# C:\twitch_chatdownloader\TwitchDownloaderCLI.exe
###  DEBUG VARIABLE
### $clipid = "CuriousAlertGooseOpieOP-Ihz5UsAm2eX6CQDF"
foreach($clip in $object.data){ 
    Write-Host $clip.id 
    C:\twitch_chatdownloader\TwitchDownloaderCLI.exe -m ChatDownload --id $clip.id -o temp_chat.json
    C:\twitch_chatdownloader\TwitchDownloaderCLI.exe -m ChatRender -i temp_chat.json -h 1080 -w 422 -framerate 30 --update-rate 0 --font-size 18 -o temp_chat_video.mp4
    # TODO: temp_chat_video.mp4 ---> UMBENENNEN UND VERSCHIEBEN
}
#>

for($i=0; $i -lt $object.data.Count; $i++)
{
    try 
    {
        $filename = $object.data[$i].created_at + "_" + $object.data[$i].broadcaster_name + "_" + $object.data[$i].title
        $filename = $filename.Replace(":","-")
        $filename = Replace-Chars($filename)
        $filename = $filename + ".mp4"
        $download_URL = $object.data[$i].thumbnail_url -replace "-preview-480x272.jpg" , ".mp4"
        $WebClient.DownloadFile($download_URL, $downloadfile)

        try 
        {
            Rename-Item -Path $downloadfile -NewName $filename
        }
        catch [System.IO]
        {
            WriteLog "Fehler Datei wahrscheinlich schon vorhanden"
            Remove-Item $downloadfile
        }
        WriteLog $i + " geladen"

    }
    catch 
    {
        WriteLog Fehler bei $i
        Add-Content $logfile "Fehler bei $i ; $filename"

    }
}


Exit







#######---------START
<#
$object = Get-Content -Raw -Path C:\temp\dentu_clips\all_dentugaming_clips.json | ConvertFrom-Json
$WebClient = New-Object System.Net.WebClient
for($i=0; $i -lt $object.Count; $i++)
{
    try 
    {
        $filename = $object[$i].created_at + "_" + $object[$i].broadcaster_name + "_" + $object[$i].title
        $filename = $filename.Replace(":","-")
        $filename = Replace-Chars($filename)
        $filename = $filename + ".mp4"
        $WebClient.DownloadFile($object[$i].download_url,"C:\temp\dentu_clips\downloaded\file")
        Rename-Item -Path "C:\temp\dentu_clips\downloaded\file" -NewName $filename
        Write-Host $i + " geladen"
    }
    catch 
    {
    Write-Host Fehler bei $i
    Add-Content C:\temp\dentu_clips\downloaded\dentu_download_log.txt "Fehler bei " + $i
    }
}

### EINZELAUSFUERHUNG

$i = 23
$PSDefaultParameterValues = @{ '*:Encoding' = 'utf8' }
$object = Get-Content -Raw -Path C:\temp\mortn_clips\all_meistermortn_clips.json | ConvertFrom-Json
$WebClient = New-Object System.Net.WebClient

$filename = $object[$i].created_at + "_" + $object[$i].broadcaster_name + "_" + $object[$i].title + ".mp4"
$filename = $filename.Replace(":","-")
$WebClient.DownloadFile($object[$i].download_url,"C:\temp\mortn_clips\downloaded\file")
Rename-Item -Path "C:\temp\mortn_clips\downloaded\file" -NewName $filename
Write-Host $i + " geladen"

#>




