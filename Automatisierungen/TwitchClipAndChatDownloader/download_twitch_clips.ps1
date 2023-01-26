<#############################################################

 TODO: For myself ( YOU CAN IGNORE THAT )
 - Clips filtern
 - Diverse Ablaeufe mehr in Funktionen umziehen, damit der Code uebersichtlicher wird
 - Code aufraeumen
 - Kommentare ueberarbeiten!!

##############################################################>

<#
.DESCRIPTION
  A Powershell Script that downloads automaticly all twitch-clips from a channel to a desired local path
.INPUTS
  No Inputs from user needed. Only the Scripts need to get modified.
  TODO: Maybe get every user input that is needed through different questions and save them as a config?
.OUTPUTS
  Downloads all clips and skips the clips that is already downloaded into the disered local path.
.NOTES
  Version:        1.2
  Author:         Martin B. @MortysTerminal (at GitHub) 
  Creation Date:  19.01.2023 (Last change: 23.01.2023)
  Purpose/Change: Automation to download all your Twitch-Clips and skip the ones, that are already downloaded
#>

# Clear the CLI
Clear-Host

# Formatierungsart des Scripts festlegen bevor fortgefahren wird
$PSDefaultParameterValues = @{ '*:Encoding' = 'utf8' } 

# Logpath -- please dont modify this
# You can use the log file inside the Scripts-Folder to debug
#try{ New-Item -Path $pwd -Name "log.log" -ItemType File -ErrorAction 'silentlycontinue' | Out-Null }
#catch{ Write-Host "Fehler beim Erstellen der Log-Datei. Keine Berechtigung? - Ueberspringe Fehler!" -ForegroundColor Yellow }
$Logfile = ".\log\log"

# START LOG WRITING (just for debugging)
Start-Transcript -Path $Logfile

# Ueberpruefe ob TwitchDownloaderCLI.exe fehlt
$twitchdownloaderdatei = "TwitchDownloaderCLI.exe"
if( Get-Item $twitchdownloaderdatei -erroraction 'silentlycontinue' ) {
    Write-Host "TwitchDownloaderCLI.exe existiert, Skript wird ausgefuehrt." -ForegroundColor Green
}
else {
    Write-Host "TwitchDownloaderCLI.exe fehlt, bitte die EXE mit dem Skript zusammen in einen Ordner legen." -ForegroundColor Yellow
    Write-Host "Skript wird abgebrochen" -ForegroundColor Red
    anyKey
}

# create array with config-keywords
$MOTMConfig = @(
    "DOWNLOADPATH",
    "CHANNELNAME",
    "APPID",
    "APPSECRET",
    "CHATDOWNLOAD",
    "CLIPFILTERDAYS",
    "CLIPFILTERCREATOR",
    "CLIPFILTERSTARTDATE",
    "CLIPFILTERENDDATE",
    "CLIPFILTERGAMEID"
)

# config to add when config-file is missing
$contenttoAdd = @" 
# this is a comment which is ignored by the script
# Config for the TwitchClipAndChatDownloader

# Enter the Download path here
# You need to create the path first
# example: C:\twitch_download
DOWNLOADPATH=

# Enter the Channelname here
# example: mortys_welt
CHANNELNAME=

# Enter the Client-ID and Secret here
# Add a new Application in your Twitch-Dev
APPID=
APPSECRET=

# Enter YES or NO here to Download the Chat or not
CHATDOWNLOAD=

# FILTERS
# Enter the Days you want to go back
# LEAVE IT EMPTY IF YOU WANT TO USE START- AND END-DATE OR ALL CLIPS
# example: 7 (for 7 Days)
CLIPFILTERDAYS=

# Enter the Creator of the Clips here if you want
# LEAVE IT EMPTY TO CHOOSE ALL CLIPS
# example: mortys_welt
CLIPFILTERCREATOR=

# Enter the Start and End-Date here
# Format: 30.02.2022 (dd.MM.yyyy)
# Every Clip between this timespan will be chosen
# If EndDate is empty then today will be chosen automaticly
# ONLY WORKS WHEN CLIPFILTERDAYS IS EMPTY
# LEAVE IT EMPTY TO CHOOSE ALL CLIPS
# example startdate: 01.01.2023
# example enddate:                (empty to choose today automaticly)
CLIPFILTERSTARTDATE=
CLIPFILTERENDDATE=

# Enter the Game-ID if you want
# LEAVE IT EMPTY TO TAKE ALL GAMES AND CLIPS
# Here you can find a list: https://raw.githubusercontent.com/Nerothos/TwithGameList/master/game_info.csv (props to Nerothos)
# example: 33214 (fuer Fortnite!)
CLIPFILTERGAMEID=
"@

################################################
###### FUNCTIONS
################################################

function anyKey{
    Write-Host -NoNewline 'Druecke eine beliebige Taste um das Skript zu beenden...' -ForegroundColor Yellow;
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
    Exit;
}
<#
  .SYNOPSIS
  Get the User-ID from twitch directly through a web-request

  .INPUTS
  just the channelname is needed

  .OUTPUTS
  returns the user-id. If it's NULL then an ID couldn't be found. App-Config ok?
#>
function GetTwitchUserID{
    Param(
        $funcChannelname,
        $funcappID,
        $funcaccesstoken
    )
    Begin{
        # create URL that is needed to read the user-data
        $getIDRequestURL = "https://api.twitch.tv/helix/users?login="+ $funcChannelname
    }
    Process{
        # Start Web-Request to read the user-data
        $userObject = curl.exe --silent -X GET $getIDRequestURL -H "Authorization: Bearer $funcaccesstoken" -H "Client-ID: $funcappID" | ConvertFrom-Json 
    }
    End{
        # return broadcaster-id
        return $userObject.data.id
    }
}
function ReadAndValidateConfig {
    Param (
        $configpath = ".\config.motm"
    )
    Begin{
        Write-Host "=== Lade und validieren Konfiguration ====" -ForegroundColor Yellow
        Start-Sleep 1
    }
    Process{
        try{
            # check if config file is available
            $checkconfig = Get-Item -Path $configpath -ErrorAction Stop

            # read config ; split at '='
            $configinhalt = ((Get-Content $configpath) -split '=') | Where-Object { $_ -notmatch '^#.*' -and $_ -notmatch '^\s*$' } 

            # loop to get the important data from the file
            for ($i = 0; $i -lt $configinhalt.Count;$i++){
                #Write-Host $configinhalt[$i]
                switch ($configinhalt[$i])                         
                {
                    DOWNLOADPATH        {if($MOTMConfig.Contains($configinhalt[$i+1])){ $configdownloadpath = $null } else{$configdownloadpath = $configinhalt[$i+1]}}
                    CHANNELNAME         {if($MOTMConfig.Contains($configinhalt[$i+1])){ $configchannelname = $null } else{$configchannelname = $configinhalt[$i+1]}}
                    APPID               {if($MOTMConfig.Contains($configinhalt[$i+1])){ $configappid = $null } else{$configappid = $configinhalt[$i+1]}}
                    APPSECRET           {if($MOTMConfig.Contains($configinhalt[$i+1])){ $configappsecret = $null } else{$configappsecret = $configinhalt[$i+1]}}
                    CHATDOWNLOAD        {if($MOTMConfig.Contains($configinhalt[$i+1])){ $configchatdownload = $null } else{$configchatdownload = $configinhalt[$i+1]}}
                    CLIPFILTERDAYS      {if($MOTMConfig.Contains($configinhalt[$i+1])){ $configclipfilterdays = $null } else{$configclipfilterdays = $configinhalt[$i+1]}}
                    CLIPFILTERCREATOR   {if($MOTMConfig.Contains($configinhalt[$i+1])){ $configclipfiltercreator = $null } else{$configclipfiltercreator = $configinhalt[$i+1]}}
                    CLIPFILTERSTARTDATE {if($MOTMConfig.Contains($configinhalt[$i+1])){ $configclipfilterstartdate = $null } else{$configclipfilterstartdate = $configinhalt[$i+1]}}
                    CLIPFILTERENDDATE   {if($MOTMConfig.Contains($configinhalt[$i+1])){ $configclipfilterenddate = $null } else{$configclipfilterenddate = $configinhalt[$i+1]}}
                    CLIPFILTERGAMEID    {if($MOTMConfig.Contains($configinhalt[$i+1])){ $configclipfiltergameid = $null } else{$configclipfiltergameid = $configinhalt[$i+1]}}
                }
            }
        }
        catch{
            Write-Host "Keine Konfiguration gefunden!" -ForegroundColor Red
            #WriteLog -LogString "Keine Konfiguration gefunden!"
            try{ 


                $null = New-Item  -Name config.motm -ItemType File -ErrorAction Stop
                Add-Content $configpath $contenttoAdd
                <#
                Add-Content $configpath "DOWNLOADPATH="
                Add-Content $configpath "CHANNELNAME="
                Add-Content $configpath "APPID="
                Add-Content $configpath "APPSECRET="
                Add-Content $configpath "CHATDOWNLOAD="
                Add-Content $configpath "CLIPFILTERDAYS="
                Add-Content $configpath "CLIPFILTERCREATOR="
                Add-Content $configpath "CLIPFILTERSTARTDATE="
                Add-Content $configpath "CLIPFILTERENDDATE="
                Add-Content $configpath "CLIPFILTERGAMEID="
                #>
                Write-Host "Konfiguration erstellt. Bitte Daten dort hineinschreiben und Skript neustarten!"
                anyKey
            }
            catch{ 
                Write-Host "Konnte keine Konfiguration erstellen. Keine Schreibrechte im Verzeichnis?" 
                # EXIT TODO
                anyKey
            }
        }
        try{
            ValidateConfig -configdownloadpath $configdownloadpath -configchannelname $configchannelname -configappid $configappid -configappsecret $configappsecret -configchatdownload $configchatdownload -configclipfilterdays $configclipfilterdays -configclipfilterstartdate $configclipfilterstartdate -configclipfilterenddate $configclipfilterenddate -configclipfiltercreator $configclipfiltercreator -configclipfiltergameid $configclipfiltergameid
            return $configdownloadpath, $configchannelname, $configappid, $configappsecret, $configchatdownload, $configclipfilterdays, $configclipfiltercreator, $configclipfilterstartdate, $configclipfilterenddate, $configclipfiltergameid
        }
        catch{
            Write-Host "Validierungsfehler" -ForegroundColor Red
            # EXIT TODO
            anyKey
        }
    }
}
function ValidateConfig{
    Param(
        $configpath,
        $configdownloadpath,
        $configchannelname,
        $configappid,
        $configappsecret,
        $configchatdownload,
        $configclipfilterdays,
        $configclipfiltercreator,
        $configclipfilterstartdate,
        $configclipfilterenddate,
        $configclipfiltergameid
    )
    Process{
        Write-Host "Teste DOWNLOADPATH..."
        if(Test-Path $configdownloadpath){ Write-Host "DOWNLOADPATH --- OK" -ForegroundColor Green ; $ok += 1}
        else{ Write-Host "DOWNLOADPATH --- NICHT OK" -ForegroundColor Red ; $ok += 0}
        Write-Host "Teste APP-ID und APP-SECRET..."
            # creating the url that is needed to get the access token
            Write-Host "... generiere Test-Token durch Twitch API ..."
            $testtokenURL = "https://id.twitch.tv/oauth2/token?client_id=" + $configappid + "&client_secret=" + $configappsecret + "&grant_type=client_credentials"

            # invoke-Webrequest and convert it from json to pwsh-object
            try{ $testtokenObject = Invoke-WebRequest -Method POST $testtokenURL -ErrorAction Stop | ConvertFrom-Json }
            catch{ Write-Host "Invoke-error ..." }

            # read the accesstoken from the webrequest
            $testtoken = $testtokenObject.access_token # AccessToken speichern

        if($null -ne $testtoken){
            Write-Host "APP-ID und APP-SECRET --- OK" -ForegroundColor Green  
            $ok += 2
            Write-Host "Teste CHANNELNAME..."
            $checkuserid = GetTwitchUserID -funcChannelname $configchannelname -funcappID $configappid -funcaccesstoken $testtoken

            # TEST INVOKE with testtoken to see if the channel-name is a real user
            if(($null -ne $configchannelname) -and ($checkuserid -match “[0-9]”)){
                Write-Host "CHANNELNAME --- OK" -ForegroundColor Green 
                $ok += 1
            }
            else { 
                Write-Host "CHANNELNAME --- NICHT OK" -ForegroundColor Red  
                $ok += 0
            }
        }
        else { Write-Host "APP-ID und APP-SECRET --- NICHT OK" -ForegroundColor Red ; $ok += 0}

        if($null -ne $configchatdownload){
            switch($configchatdownload){
                YES { Write-Host "CHATDOWNLOAD --- OK" -ForegroundColor Green ; $ok += 1}
                NO  { Write-Host "CHATDOWNLOAD --- SKIP" -ForegroundColor Yellow ; $ok += 1}
                Default { Write-Host "CHATDOWNLOAD --- SKIP" -ForegroundColor Yellow ; $ok += 1}
            }
        }

        try{
            $testclipfilterdays = [int]$configclipfilterdays
            Write-Host "CLIPFILTERDAYS --- OK" -ForegroundColor Green; $ok += 1
        }catch{
            Write-Host "CLIPFILTERDAYS --- SKIP" -ForegroundColor Yellow ; $ok += 1
        }

        try{
            $testclipfiltergameid = [int]$configclipfiltergameid
            Write-Host "GAMEID --- OK" -ForegroundColor Green; $ok += 1
        }catch{
            Write-Host "GAMEID --- SKIP" -ForegroundColor Yellow ; $ok += 1
        }

        try {
            if($configclipfilterenddate -clt $configclipfilterstartdate ){ 
                Write-Host "End-Datum ist groesser als das Start-Datum! Bitte Konfiguration ueberpruefen!" -ForegroundColor Red
            }
            else{$ok += 1}
        }
        catch {
            Write-Host "Fehler bei der Ueberpruefung von End-Datum und Start-Datum" -ForegroundColor Red
        }

        # when the ok-variable equals 4, then every check was an "ok", so the config can be used to run the script
        if($ok -eq 8){
            Write-Host "=== KONFIGURATION IST OK === SKRIPT WIRD AUSGEFUEHRT ===" -ForegroundColor Green
        }
        else{
            Write-Host "=== FEHLER IN KONFIGURATION === SKRIPT WIRD ABGEBROCHEN ===" -ForegroundColor Red
            # TODO EXIT
            anyKey
        }
        
    }
}

<#
  .SYNOPSIS
  Write Log for DEBUG purposes ; the file location is defined at the start of the script

  .INPUTS
  Enter the Data (in String) that you want to add to the Log-file

  .OUTPUTS
  returns nothing. Only appends the input to the file
#>
function WriteLog{
  Param (
    [string]$LogString
    )
    Begin{
        # Get the Time-Stamp of the day
        $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
        # Get the message from params for the log-file
        $LogMessage = "$Stamp $LogString"
    }
    Process{
         Add-content $LogFile -value $LogMessage
    }
    End{}
}
<#
  .SYNOPSIS
  function to replace invalid characters inside a string. To get it move comfy for Windows

  .INPUTS
  input the string that is needed to get replaced

  .OUTPUTS
  return the full-string with replaced characters
#>
function ReplaceChars{
    Param(
        [parameter(ValueFromPipeline=$true)] $string,
        $replaceString='_'
        )
        
    Begin{
        # Create Regex
        $r = "[^\w\+\-\(\) ]"

    }
    Process{
        # Try to replace and trim the string to get it comfy
        if ($replaceString -match $r){
            Write-Error -Message "Parameter '-replaceString' contains invalid filename chars/sequences." -Category InvalidArgument -TargetObject $replaceString
            break
        }
        while($string -match $r){
            $string = ($string -replace $r,$replaceString).trim()
        }
    }
    End{
        # return replaced string
        return $string
    }
}
<#
  .SYNOPSIS
  This Function is needed to get a list of all Twitch-Clips of the channel

  .INPUTS
  it need 3 inputs, that are already available through the code
    broadcasterID   -> the broadcasterID of the channel, so we know where we get the clips form
    accesstoken     -> needed for the curl-command to get access
    appID           -> needed for the curl-command to get access

  .OUTPUTS
  every clip gets saved into an pwsh-Object and it will add every 100 Clips into a seperate object.
  After that it returns a combined object with contains all the seperates objects.
#>
function GetAllClipsFromTwitch{
    Param(
        $broadcasterID,
        $accessToken,
        $appID,
        $daysdate = $null,
        $creator = $null,
        $startdate = $null,
        $enddate = $null,
        $gameid = $null
    )
    Begin{
        #create empty object that we use to save the clips
        $clipsammlung = @()

        # save before building twtich-date out of our start and end-date
        # just for useroutput
        $writelineStartDate = $startdate
        $writelineEndDate = $enddate 
     

        # build strings
        if($null -ne $daysdate){ $dd = "&started_at=$daysdate"; $startdate = $null ; $enddate = $null}

        #build date format for twitch from startdate
        if($null -ne $startdate){ 
            $startdate = BuildTwitchDate -datumart "CLIPFILTERSTARTDATE" -btddate $startdate
            $sd = "&started_at=$startdate" 
            Write-Host "Filter von Datum: $writelineStartDate - "
        }
        else{ 
            #Write-Host "Startdatum geleert - Tage-Filter angewendet!" -ForegroundColor Yellow 
        }

        #build date format for twitch from enddate
        if($null -ne $enddate){ 
            $enddate = BuildTwitchDate -datumart "CLIPFILTERENDDATE" -btddate $enddate
            $ed = "&ended_at=$enddate" 
            Write-Host "Filter bis Datum: $writelineEndDate"
        }
        else{
            Write-Host "Enddatum - Wird auf HEUTE gesetzt." -ForegroundColor Yellow 
            $enddate = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
            $ed = "&ended_at=$enddate" 
        }
        #if($null -ne $gameid)       { $gd = "&game_id=$gameid"  } # crsiscoreid = 575087095

        #build date format for twitch from startdate
        #if($null -eq $startdate)  { Write-Host "Startdatum ist leer" -ForegroundColor Yellow }
        #else{ $startdate = BuildTwitchDate -datumart "CLIPFILTERSTARTDATE" -btddate $startdate }

        #build date format for twitch from end
        #if($null -eq $enddate)    { Write-Host "Enddatum ist leer - Wird auf HEUTE gesetzt." -ForegroundColor Yellow; $enddate = BuildTwitchDate -btddate (Get-Date -Format "dd.MM.yyyy") }
        #else{ $enddate = BuildTwitchDate -datumart "CLIPFILTERENDDATE" -btddate $enddate }

        $builturl = "https://api.twitch.tv/helix/clips?first=100$dd$sd$ed&broadcaster_id=$broadcasterID"
        
        ##$test = curl.exe -X GET "https://api.twitch.tv/helix/games?name=Crisis%20Core:%20Final%20Fantasy%20VII%20-%20Reunion" -H "Authorization: Bearer $accesstoken" -H "Client-ID: $appID" | ConvertFrom-Json

    }
    Process{
        # read first 100 clips
        $clips = curl.exe --silent -X GET $builturl.ToString() -H "Authorization: Bearer $accesstoken" -H "Client-ID: $appID" | ConvertFrom-Json
        #"https://api.twitch.tv/helix/clips?broadcaster_id=$broadcasterID&started_at=$datum"
        #$clips = curl.exe --silent -X GET "https://api.twitch.tv/helix/clips?first=100&broadcaster_id=$broadcasterID" -H "Authorization: Bearer $accesstoken" -H "Client-ID: $appID" | ConvertFrom-Json

        # read next pagination cursor
        $after = $clips.pagination.cursor
        # add object to our list
        $clipsammlung += $clips

        # if there is more then 100 clips then get the next 100 clips
        if($null -ne $after){
            do {
                #read the next 100 clips with after-cursor
                $rotatingURL = $builturl + "&after=$after"
                $clips = curl.exe --silent -X GET $rotatingURL.ToString() -H "Authorization: Bearer $accesstoken" -H "Client-ID: $appID" | ConvertFrom-Json
                # save new cursor
                $after = $clips.pagination.cursor
                # add object to our list
                $clipsammlung += $clips
            } until (
                $null -eq $after
            )
            return $clipsammlung
        }
        else{
            return $clipsammlung
        }

    }
    End{
        # LOG OUTPUT
        $length = $clipsammlung.data.length
        #WriteLog -LogString "$length Clips gefunden! ($broadcasterID)"
    }
}

function GetClipsFromTwitchByDate{
    Param(
        $broadcasterID,
        $accessToken,
        $appID,
        $daysdate = $null,
        $creator = $null,
        $startdate,
        $gameid = 0
    )
    Begin{
        #create empty object that we use to save the clips
        $clipsammlung = @()
    }
    Process{
        # read first 100 clips
        $clips = curl.exe --silent -X GET "https://api.twitch.tv/helix/clips?first=100&broadcaster_id=$broadcasterID" -H "Authorization: Bearer $accesstoken" -H "Client-ID: $appID" | ConvertFrom-Json
        # read next pagination cursor
        $after = $clips.pagination.cursor
        # add object to our list
        $clipsammlung += $clips

        # if there is more then 100 clips then get the next 100 clips
        if($null -ne $after){
            do {
                #read the next 100 clips with after-cursor
                $clips = curl.exe --silent -X GET "https://api.twitch.tv/helix/clips?first=100&after=$after&broadcaster_id=$broadcasterID" -H "Authorization: Bearer $accesstoken" -H "Client-ID: $appID" | ConvertFrom-Json
                # save new cursor
                $after = $clips.pagination.cursor
                # add object to our list
                $clipsammlung += $clips
            } until (
                $null -eq $after
            )
            return $clipsammlung
        }
        else{
            return $clipsammlung
        }

    }
    End{
        # LOG OUTPUT
        $length = $clipsammlung.data.length
        #WriteLog -LogString "$length Clips gefunden! ($broadcasterID)"
    }
}
function CleanUp{
    Param(
        $funcdownloadtempfile
        )
    Begin{
        try{
            Get-Item $funcdownloadtempfile -ErrorAction Stop | Out-Null
            Remove-Item $funcdownloadtempfile -Force -ErrorAction Stop | Out-Null
        }
        catch{
            Write-Host "Temporaere Dateien bereits aufgeraeumt"
        }
    }

}

function LadeChatRunter{
    Param(
        $ClipID,
        $funcClipDownloadPath,
        $funcClipName
    )
    Process{

        # Remove .mp4 from folder Path
        $toRemove = ".mp4"
        if($funcClipName.Contains($toRemove)){
            $funcClipName = $funcClipName.Replace($toRemove,'')
        }

        # needed filenames (json and mp4 for chat)
        $clipchatjsonfilename = $funcClipDownloadPath + "\" + $funcClipName + "_chat.json"
        $clipchatfilename = $funcClipDownloadPath + "\" + $funcClipName + "_chat.mp4"
        
        #CHAT RENDER
        if( Test-Path -Path $clipchatfilename ){
            Write-Host "Chat-Render existiert bereits - wird uebersprungen"
        }
        else{
            if(Test-Path -Path $clipchatjsonfilename){
                # create the rendered chat-video
                Write-Host "Erstelle Chat-Rendered Video"
                .\TwitchDownloaderCLI.exe chatrender -i $clipchatjsonfilename -h 1080 -w 422 --framerate 30 --update-rate 0 --font-size 18 -o $clipchatfilename
                Write-Host "Chat-Rendered Video erstellt!" -ForegroundColor Green
            } 
            else{
                # download raw chat-file (json) that we need to create the video
                Write-Host "Lade RAW-Chat herunter:" 
                try{
                    .\TwitchDownloaderCLI.exe chatdownload --id $ClipID -o $clipchatjsonfilename -E 
                    if(Test-Path -Path $clipchatjsonfilename){
                        Write-Host "RAW-Chat heruntergeladen!" -ForegroundColor Green
                    }
                    else{
                        Write-Host "Chat nicht mehr vorhanden - Ueberpringen ..."
                    }
                }
                catch{ Write-Host "Fehler beim Erstellen der Chat-RAW-Datei (json) - Chat nicht mehr vorhanden?" -ForegroundColor Red}
                

                # create the rendered chat-video
                Write-Host "Erstelle Chat-Rendered Video"
                try{ 
                    .\TwitchDownloaderCLI.exe chatrender -i $clipchatjsonfilename -h 1080 -w 422 --framerate 30 --update-rate 0 --font-size 18 -o $clipchatfilename 
                    if(Test-Path -Path $clipchatfilename){
                        Write-Host "Chat-Rendered Video erstellt!" -ForegroundColor Green
                    }
                }
                catch{Write-Host "Fehler beim Erstellen der Chat-RAW-Datei (json) - Chat nicht mehr vorhanden?" -ForegroundColor Red}
                
            }
        }        
    }
    End{
        Write-Host "Loesche JSON-Datei"
        Remove-Item $clipchatjsonfilename | Out-Null
    }
}

function Get-FreeSpace {
    Param(
        $path
    );

    $free = Get-WmiObject Win32_Volume -Filter "DriveType=3" |
            Where-Object { $path -like "$($_.Name)*" } |
            Sort-Object Name -Desc |
            Select-Object -First 1 FreeSpace |
            ForEach-Object { $_.FreeSpace / (1024*1024) }
    return ([int]$free)
}

function BuildTwitchDate {
    Param (
        $btddate,
        $datumart = $null
    )
    Process {
        try{
            $btd = [Datetime]::ParseExact($btddate, 'dd.MM.yyyy', $null)
            $btd = Get-Date $btd -Format "yyyy-MM-ddTHH:mm:ssZ"
        }
        catch{
            Write-Host "Wallah diese Datum nix gut. ($datumart  $btddate)"
            anyKey
            return $null
        }
    }    
    End {
        return $btd
    }
}

function FilterClipsForCreator {
    param (
        $fcfcclips,
        $fcfccreatorname
    )

    process {
        $fcfcnewcliplist = $fcfcclips  | Select-Object -ExpandProperty "data" | Where-Object {$_.creator_name -eq $fcfccreatorname}

        $fcfcObject = [PSCustomObject]@{
            data = $fcfcnewcliplist
        }
    }
    
    end {
        return $fcfcObject
    }
}

function FilterForGameID {
    param (
        $ffgiclips,
        $ffgigameid
    )    
    process {
        $ffginewcliplist = $ffgiclips  | Select-Object -ExpandProperty "data" | Where-Object {$_.game_id -eq $ffgigameid}

        $ffgiObject = [PSCustomObject]@{
            data = $ffginewcliplist
        }
    }
    
    end {
        return $ffgiObject
    }
}

################################################
###### SETUP
################################################




### Read and Validate Configuration (.\config.motm)
$config = ReadAndValidateConfig
$downloadpath = $config[0]
$channelname = $config[1]
$appID = $config[2]
$secret = $config[3]
$chatdownload = $config[4].ToLower()
$clipfilterdays = $config[5]
$clipfiltercreator = $config[6]
$clipfilterstartdate = $config[7]
$clipfilterenddate = $config[8]
$clipfiltergameid = $config[9]


# get items from the downloadpath
try{
    Write-Host "Versuche Download-Pfad auszulesen..."
    $downloadpathabsolut = Resolve-Path $downloadpath -ErrorAction Stop # Pfad zur Download - Datei
    $downloadfile = $downloadpathabsolut.path + "\file" # create path for temporary download-files
    $downloadpathfiles = Get-ChildItem -Path $downloadpathabsolut -ErrorAction Stop # read all files that are already in the download-path
    Write-Host "Downloadverzeichnis ist vorhanden und wurde ausgelesen. Fahre fort ..." # useroutput
}
catch{
    try {
        Write-Host "Angegebenes Download-Verzeichnis fehlt, versuche es zu erstellen...."
        # create new folder (downloadpath)
        New-Item -Path $downloadpath -ItemType Directory | Out-Null
        $downloadpathfiles = Get-ChildItem -Path $downloadpathabsolut
        Write-Host "Downloadverzeichnis erstellt!" -ForegroundColor Green
        # EXIT TODO
        anyKey
    }
    catch {
        Write-Host "Konnte den Download-Pfad nicht auslesen und nicht erstellen! Keine Berechtigung? Skript wird abgebrochen" -ForegroundColor Red
        # EXIT TODO
        anyKey
    }
    #TODO SKRIPT ABBRECHEN!!
}

### App-Configuration
# create a new developer-app on twitch and enter the app-id and secret here
# https://dev.twitch.tv/console/apps
# New Application
# Name: WHATEVER YOU WANT
# OAuth Redirect URLs : http://localhost
# Category: Other
# Then Click on the App in the List and on "Modify"
# You can see the "App-ID" or "Client-ID" there and you can create a secret - ADD THEM TO THE VARIABLES

# creating the url that is needed to get the access token
$accesstokenURL = "https://id.twitch.tv/oauth2/token?client_id=" + $appID + "&client_secret=" + $secret + "&grant_type=client_credentials"

# invoke-Webrequest and convert it from json to pwsh-object
$accesstokenObject = Invoke-WebRequest -Method POST $accesstokenURL | ConvertFrom-Json 

# read the accesstoken from the webrequest
$accesstoken = $accesstokenObject.access_token # AccessToken speichern



################################################
###### START
################################################

# read all data from the channel that is entered
Write-Host "" # empty space
Write-Host "Lese Benutzerdaten von angegebenen Channel aus ($channelname)"

# try to get the user-data and use the custom function
try {
    $broadcasterID = GetTwitchUserID -funcChannelname $channelname -funcappID $appID -funcaccesstoken $accesstoken
}
# catch all errors
catch{
    Write-Host "User ID vom Benutzer konnte nicht gelesen werden. App-ID in Ordnung?"
}

# output on console ; user-data are not empty, so it has data in it
Write-Host "Benutzerdaten gelesen! ID gespeichert. (ID=$broadcasterID)"

#$datumtemp = (Get-Date).AddDays(-7)
#$datum = Get-Date $datumtemp -Format "yyyy-MM-ddTHH:mm:ssZ"

#$object = curl.exe -X GET "https://api.twitch.tv/helix/clips?broadcaster_id=$broadcasterID" -H "Authorization: Bearer $accesstoken" -H "Client-ID: $appID" | ConvertFrom-Json


Write-Host "Erstelle Anfrage anhand der angegebenen Filter"
Start-Sleep 1

# DEBUG: ZEITMESSUNG
##$Startzeit = Get-Date

# VERSION 1.2
<#
switch($clipfilterdays){
    "7"     { Write-Host "Letzte 7 Tage werden gefiltert" ; $clipfilterdays =  Get-Date ((Get-Date).AddDays(-7)) -Format "yyyy-MM-ddTHH:mm:ssZ" }
    "30"    { Write-Host "Letzte 30 Tage werden gefiltert"; $clipfilterdays = Get-Date ((Get-Date).AddDays(-30)) -Format "yyyy-MM-ddTHH:mm:ssZ" }
    Default { Write-Host "Keine Filterung der Tage" -ForegroundColor Yellow ; $clipfilterdays = $null}
}
#>
# / VERSION 1.2


# Filter the needed days, if it is set in the config
try{
    if($clipfilterdays -ne 0){
        if($clipfilterdays -match "^\d+$"){
            #Write-Host "Passe an letzte $clipfilterdays Tag/e an."
            $days = -$clipfilterdays
            Write-Host "Letzte $clipfilterdays Tage werden gefiltert"
            $clipfilterdays =  Get-Date ((Get-Date).AddDays(($days))) -Format "yyyy-MM-ddTHH:mm:ssZ" 
        }
            else{ 
                $clipfilterdays = $null
            }
    }
}catch{
    #Write-Host "Keine Filterung der Tage - Fehler beim auslesen. Daten ueberpruefen! Filter wird nicht beachtet..." -ForegroundColor Yellow 
    $clipfilterdays = $null
}




try { 
    #build date format for twitch from startdate
    #if($null -eq $clipfilterstartdate)  { Write-Host "Startdatum ist leer" -ForegroundColor Yellow }
    #else{ $clipfilterstartdate = BuildTwitchDate -datumart "CLIPFILTERSTARTDATE" -btddate $clipfilterstartdate }

    #build date format for twitch from end
    #if($null -eq $clipfilterenddate)    { Write-Host "Enddatum ist leer" -ForegroundColor Yellow; $clipfilterenddate = BuildTwitchDate -btddate (Get-Date -Format "dd.MM.yyyy") }
    #else{ $clipfilterenddate = BuildTwitchDate -datumart "CLIPFILTERENDDATE" -btddate $clipfilterenddate }

    Write-Host "Lese Clips aus ... "
    $object = GetAllClipsFromTwitch -broadcasterID $broadcasterID -accessToken $accesstoken -appID $appID -daysdate $clipfilterdays -creator $clipfiltercreator -startdate $clipfilterstartdate -enddate $clipfilterenddate -gameid $clipfiltergameid
    $length = $object.data.length
    # DEBUG: ZEITMESSUNG
    ##$Endzeit = New-TimeSpan -Start $Startzeit -End (get-date)
    #Write-Host "$length Clips ausgelesen. Fahre fort ... (Zeit: $Endzeit)" -ForegroundColor Green
    # DEBUG: ZEITMESSUNG
    Write-Host "Insgesamt $length Clips ausgelesen. Fahre fort ... " -ForegroundColor Green

    # Filter Creator
    if($null -ne $clipfiltercreator){
        $object = FilterClipsForCreator -fcfcclips $object -fcfccreatorname $clipfiltercreator
        try{ $length = $object.data.length ; Write-Host "Clips nach Creator ($clipfiltercreator) gefiltert ($length Clips)"}
        catch{ Write-Host "Creator-Filterung: Objekt ist nach Anwendung leer - keine Clips zum Creator ($clipfiltercreator) gefunden!" ; $length = 0 }
    }

    # Filter game-id
    if(($null -ne $clipfiltergameid) -or ($clipfiltergameid -eq 0)){
        $object = FilterForGameID -ffgiclips $object -ffgigameid $clipfiltergameid
        try{ $length = object.data.length ; Write-Host "Game-ID in Konfig gefunden. Clips wurden nach Game-ID ($clipfiltergameid) gefiltert ($length Clips)"}
        catch{ Write-Host "GameID-Filterung: Objekt ist nach Filterung nach GameID ($clipfiltergameid) leer!"; $length = 0 }
    }
    Start-Sleep 1
}
catch{ 
    Write-Host "Fehler beim auslesen der Clips. Ueberpruefe nochmal alle Daten. Beende Skript..." 
}

# create webclient and prepare for the download
$WebClient = New-Object System.Net.WebClient

# start des downloads
for($i=0; $i -lt $object.data.Count; $i++)
{
    try 
    {
        # Reset File exists
        $fileexists = $false

        # build up the filename and path
        $filename = $object.data[$i].created_at + "_" + $object.data[$i].broadcaster_name + "_" + $object.data[$i].title
        $filename = $filename.Replace(":","-")
        $filename = ReplaceChars($filename)

        # we will use the name of the clip but without spaces (we replace spaces)
        $clipfoldername = $filename -replace '\s',''

        # to create a new folder inside the downloadpath with the name of the clip
        try{ 
            $null = New-Item $downloadpath -Name $clipfoldername -Type Directory -ErrorAction Stop 
        }
        catch { 
            Write-Host "Clip-Ordner bereits vorhanden. Fahre fort ..." -ForegroundColor Yellow
        }

        # Whatever happened, we need to read the files from the clipfolder
        $clipfolderpath = Join-Path $downloadpath -ChildPath $clipfoldername

        # save files from clipfolderpath into variable
        $clipfolderpathfiles = Get-ChildItem $clipfolderpath

        # add mp4 to the filename, for the clip that we want to download
        $filename = $filename + ".mp4"
        
        # more url editing, so we can get the right file from the twitch servers
        $download_URL = $object.data[$i].thumbnail_url -replace "-preview-480x272.jpg" , ".mp4"

        # for the correct Write-Host for the user (array starts normally at 0)
        # only used for write-host
        $iout = $i + 1

        # User-Output
        Write-Host "Vergleiche, ob Clip $iout bereits geladen wurde ..."

        # check if Clip already been loaded
        # loop is running through the download-path and compares the filename with the new filename
        foreach ($file in $clipfolderpathfiles) {
            if($file.Name -eq $filename){
                # file exists, so skip + User-Output
                Write-Host "Clip: $iout/$length bereits vorhanden. Überspringen ..." -ForegroundColor Yellow
                $fileexists = $true
            }
        }

        # if the file doesn't exist, then we start to download the clip
        if($fileexists -eq $false){

            # User-Output
            Write-Host "Lade $iout/$length Clip herunter ..."

            # User-Output
            Write-Host "$filename"

            # TODO: Lese verfuegbaren Speicher aus
            # TODO: Dateigroesse aus URL auslesen: (Invoke-WebRequest $download_URL -Method Head).Headers.'Content-Length'
            
            try{
                # size of the clip that will be downloaded
                $downloadsize = (((Invoke-WebRequest $download_URL -Method Head).Headers.'Content-Length') / (1024*1024))

                # free space of the downloadpath
                $freespace = Get-FreeSpace -path $downloadpath

                # if downloadsize bigger then free space (not enough space!)
                if($downloadsize -gt $freespace){
                    Write-Host "Nicht genügend freier Speicher vorhanden!" -ForegroundColor Red
                    Write-Host "==== SKRIPT WIRD ABGEBROCHEN! ====" -ForegroundColor Red
                    anyKey
                }
            }
            catch{
                Write-Host "Fehler beim auslesen des freien Speichers"
                anyKey
            }

            # start download to temp-file named "downloadfile" through our webclient
            $WebClient.DownloadFile($download_URL, $downloadfile)

            try 
            {
                # rename the temp-file to the filename of the Clip
                Rename-Item -Path $downloadfile -NewName $filename

                # move the downloaded file
                $tempfile = $downloadpath + "\" + $filename #temp
                Move-Item $tempfile -Destination $clipfolderpath
                Clear-Variable -Name tempfile # clear temp-file -variable
                
                # read all files from the download-path again, because we added a new file
                # we need the change inside the downloadpath for our next clip
                #$downloadpathfiles = Get-ChildItem -Path $downloadpathabsolut
                
                # User-Output
                Write-Host "Clip: $iout/$length Clip heruntergeladen!" -ForegroundColor Green
            }
            # catch IO-Exceptions
            catch [System.IO]
            {
                # User-Output
                WriteLog "Fehler beim umbennenen oder verschieben der temporaeren Datei..."
                # Remove temp-file
                Remove-Item $downloadfile
            }
        }

        # download chat if it is set to "yes"
        if($chatdownload.Equals("yes")){
            try{
                Write-Host "=== Starte Chat-Download ==="
                LadeChatRunter -ClipID $object.data[$i].id -funcClipDownloadPath $clipfolderpath -funcClipName $filename
            }
            catch{
                Write-Host "Fehler bei der Uebergabe der Clips zum ChatDownload!" -ForegroundColor Red
            }
        }
    }
    # catch Exception from the complete download-process
    catch 
    {
        WriteLog Fehler bei $i
        Add-Content $logfile "Fehler bei $i ; $filename"
    }

    # reset "exist" variable, so we can check again if the next clip exists
    $fileexists = $false
}

CleanUp -funcdownloadtempfile $downloadfile




# STOP LOG WRITING (just for debugging)
Stop-Transcript