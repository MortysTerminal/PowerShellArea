<#
.DESCRIPTION
  A Powershell Script to download youtube-videos and convert it to mp4 and mp3 automaticly. 
  All local and do a desired path.
.INPUTS
  The Script will ask for an Youtube-URL. This URL needs to be the "share"-Url from a YouTube Video
.OUTPUTS
  It shows a few progress bars and downloads-speeds inside the console and creates an folder, that is named like the video-title from the youtube-video in the desired path.
  Then it downloads the video and converts it in mp4 (video) and mp3(audio).
.NOTES
  Version:        1.0
  Author:         Martin B. @MortysTerminal (at GitHub) 
  Creation Date:  19.01.2023
  Purpose/Change: Automation to download YouTube Videos and convert it to mp4 (video) and mp3 (audio)
#>

################################################
###### INIT
################################################

# change the format that is used inside the script to utf8
$PSDefaultParameterValues = @{ '*:Encoding' = 'utf8' } 

################################################
###### CHANGE DOWNLOAD-PATH HERE!!! --- DOWNLOAD PFAD HIER AENDERN !!!
################################################

# downloadpath (Examples: "C:\Users\USERNAME\Downloads" ; ".\downloaded" <- STANDARD:root-folder where the scripts gets started)
$downloadpath = ".\downloaded" 

################################################
###### FUNCTIONS
################################################

<#
  .SYNOPSIS
  Check if the file "yt-dlp.exe" is available inside the "yt-dlp"-path

  .INPUTS
  It needs the path to the "yt-dlp"

  .OUTPUTS
  The function gives two values back.
  [0] -> returns true or false, if the file exists
  [1] -> returns the full file path

#>
function CheckYTDLPPath{
    Param(
        # path to yt-dlp exe
        $path 
        )
    Begin{
        # read all the files inside the folder
        $items = Get-ChildItem $ytdlppath
    }
    Process{
        # loop though every file inside the folder
        foreach ($file in $items) {
            # check if "yt-dlp.exe" exists, if it exists return TRUE and the full path
            if($file.Name -eq "yt-dlp.exe"){
                return $true, $file.FullName
            }
        }
        return $false
    }
}

################################################
###### CONFIGURATION
################################################

# clean-Up CLI
Clear-Host

# save yt-dlp path ; it's always a yt-dlp folder at the root folder
$ytdlppath = $PSScriptRoot + "\yt-dlp"

# use our function to check if the exe is available
$CheckYTDLPPath = CheckYTDLPPath($ytdlppath)

# save return value if it the exe is available (true or false)
$YTDLPPathVorhanden = $CheckYTDLPPath[0] 

# save return value of the full-path of the exe
$ytdlpfilepath = $CheckYTDLPPath[1] 

# check if path is available and if the exe is available
# abort the script if it's not!!
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

# clean-Up CLI
Clear-Host

# wait for user-input ; the user enters the URL to the YouTube-Video
$url = Read-Host -Prompt 'Link zum Video eingeben'

# read the youtube-video title and save it
$titlename = & $ytdlpfilepath -e $url.ToString()

# Regular Expression - Unicode - Matching Specific Code Points
# See http://unicode-table.com/en/
# replace characters if the title with regular expressions to avoid corrupt pathnames
$titlename = $titlename -replace '[^\u0030-\u0039\u0041-\u005A\u0061-\u007A]+', ''

# read the full downloadpath
$fulldownloadpath = Resolve-Path -Path $downloadpath

# create a folder with the name of the title of the video
New-Item -Path $downloadpath -Name $titlename -ItemType "directory" -erroraction 'silentlycontinue' 

# modify the downloadpath ; add the titlename-folder to the variable to use it as the full download-path for the files
$fulldownloadpath = Resolve-Path -Path ($downloadpath + "\" + $titlename)

# START download and convert it to mp3 (audio)
& $ytdlpfilepath -P $fulldownloadpath $url.ToString() -x --audio-format "mp3" --windows-filenames --progress

# START download and convert it to mp4 (audio)
& $ytdlpfilepath -P $fulldownloadpath $url.ToString() -f "bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4] / bv*+ba/b" --windows-filenames --progress

# Ende fuer DEBUG only
#Write-Host -NoNewLine 'Skript beendet. Druecke beliebige Taste um das Skript zu schliessen...';
#$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');