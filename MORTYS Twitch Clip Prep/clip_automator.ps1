# ======================================
# 🗂️ KONFIGURATION & PLATTFORMERKENNUNG
# ======================================

################################################
##         USER EINSTELLUNGEN
################################################
$WhisperLanguage = "German"
$TwitchUsername = "mortys_welt"

# 30 TAGE
#$ClipUrl = "https://www.twitch.tv/$TwitchUsername/clips?filter=clips&range=30d"

# ALLE
$ClipUrl = "https://www.twitch.tv/$TwitchUsername/clips?filter=clips&range=all"
$DebugMode = 0
################################################


# Betriebssytem auslesen
$IsOnWindows = $false
$IsOnMac = $false
$IsOnLinux = $false

if ($PSVersionTable.OS -match "Windows") {
    $IsOnWindows = $true
} elseif ($env:OSTYPE -match "darwin" -or $PSVersionTable.OS -match "Darwin") {
    $IsOnMac = $true
} elseif ($PSVersionTable.OS -match "Linux") {
    $IsOnLinux = $true
}
$UserHome = if ($IsOnWindows) { $env:USERPROFILE } else { $HOME }
$WhisperModelPath = Join-Path $UserHome ".cache/whisper/base.pt"
$BaseDir = Join-Path $UserHome "documents/source/MW"
$RawDir = Join-Path $BaseDir "RAW"
$YtDlp = "yt-dlp"


# ======================================
# 🧼 DATEINAMEN-BEREINIGUNG
# ======================================

function Get-CleanFilename {
    param (
        [string]$Title,
        [string]$UploadDate
    )

    $title = $Title
    $title = $title -replace 'ä', 'a'
    $title = $title -replace 'ö', 'o'
    $title = $title -replace 'ü', 'u'
    $title = $title -replace 'Ä', 'A'
    $title = $title -replace 'Ö', 'O'
    $title = $title -replace 'Ü', 'U'
    $title = $title -replace 'ß', 'ss'
    $title = $title -replace '[^\x00-\x7F]', ''
    $title = $title -replace '[^\w\-]', '_'
    $title = $title -replace '_+', '_'
    $title = $title.Trim('_')

    if ($title.Length -gt 40) {
        $title = $title.Substring(0, 40)
    }

    return "$UploadDate" + "_" + "$title" + ".mp4"
}

# ======================================
# 📁 KONFIG-DATEIEN
# ======================================

$ConfigDir = Join-Path $PSScriptRoot "config"
$ProcessedLogPath = Join-Path $ConfigDir "processed_clips.json"
$DownloadedLogPath = Join-Path $ConfigDir "downloaded_clips.json"

if (-not (Test-Path $ConfigDir)) {
    New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
}

function Get-JsonLogAsHashtable($Path) {
    if (Test-Path $Path) {
        $json = Get-Content $Path -Raw | ConvertFrom-Json
        $dict = @{}
        foreach ($key in $json.PSObject.Properties.Name) {
            $dict[$key] = $json.$key
        }
        return $dict
    } else {
        return @{}
    }
}

function Save-ToJsonLog($Path, $Dict) {
    $Dict | ConvertTo-Json -Depth 5 | Set-Content $Path -Encoding UTF8
}

function Save-DownloadedClip($clipId, $data) {
    $log = Get-JsonLogAsHashtable $DownloadedLogPath
    $log[$clipId] = $data
    Save-ToJsonLog $DownloadedLogPath $log
}

function Save-ProcessedClip($clipName, $data) {
    $log = Get-JsonLogAsHashtable $ProcessedLogPath
    $log[$clipName] = $data
    Save-ToJsonLog $ProcessedLogPath $log
}

function Undo-ProcessingIfFailed($folderPath, $tempPath) {
    if (Test-Path $folderPath) {
        Remove-Item -Path $folderPath -Recurse -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $tempPath) {
        Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ======================================
# 📥 TWITCH-CLIPS HERUNTERLADEN
# ======================================

Write-Host "`n📥 Lade Twitch-Clips herunter..."
Push-Location $RawDir

$DownloadedClips = Get-JsonLogAsHashtable $DownloadedLogPath
$ClipMetaList = (& $YtDlp $ClipUrl --dump-json --flat-playlist --quiet) | ConvertFrom-Json
$DownloadCounter = 0

foreach ($clip in $ClipMetaList) {
    $clipId = $clip.id
    $clipTitle = $clip.title
    $uploadDate = $clip.upload_date
    $ext = $clip.ext
    $clipUrlDirect = $clip.url
    $outputFilename = Get-CleanFilename -Title $clipTitle -UploadDate $uploadDate
    $targetPath = Join-Path $RawDir $outputFilename

    if ($DownloadedClips.ContainsKey($clipId)) {
        Write-Host "⏭ Bereits heruntergeladen: $clipId – $clipTitle"
        continue
    }

    Write-Host "`n🎬 Lade Clip: $clipTitle"

    & $YtDlp $clipUrlDirect `
        --recode-video mp4 `
        -S vcodec:h264 `
        --output $outputFilename `
        --no-part `
        --no-overwrites `
        --quiet `
        --progress `
        --no-warnings

    if (Test-Path $targetPath) {
        $downloadData = @{
            id         = $clipId
            title      = $clipTitle
            filename   = $outputFilename
            url        = $clipUrlDirect    # 🆕 Ursprüngliche URL merken
            downloaded = (Get-Date).ToString("s")
            size_bytes = (Get-Item $targetPath).Length
        }

        Save-DownloadedClip -clipId $clipId -data $downloadData
        Write-Host "✅ Heruntergeladen: $outputFilename"
        $DownloadCounter++
    } else {
        Write-Host "❌ Fehler beim Download von: $clipTitle"
    }

    if ($DebugMode -eq 1 -and $DownloadCounter -ge 1) {
        Write-Host "🛑 Debug-Modus aktiv – nur 1 Clip geladen."
        break
    }
}

Pop-Location

# ======================================
# 🎙️ CLIPS VERARBEITEN
# ======================================

Write-Host "`n🎬 Starte Verarbeitung der Clips..."
$ClipCounter = 0
$ProcessedClips = Get-JsonLogAsHashtable $ProcessedLogPath

Get-ChildItem -Path $RawDir -Filter *.mp4 | ForEach-Object {
    $Clip = $_
    $ClipName = $Clip.BaseName

    if ($ProcessedClips.ContainsKey($ClipName)) {
        Write-Host "⏭ Logbuch: $ClipName – bereits verarbeitet."
        return
    }

    $FinalClipFolder = Join-Path $BaseDir $ClipName
    $FinalMP4 = Join-Path $FinalClipFolder "$ClipName.mp4"
    $FinalSRT = Join-Path $FinalClipFolder "$ClipName.srt"
    $TempOutputDir = Join-Path $RawDir "_temp_$ClipName"

    New-Item -ItemType Directory -Path $TempOutputDir -Force | Out-Null
    Write-Host "🎙 Transkribiere: $ClipName"

    & python3 -m whisper $Clip.FullName `
        --model base `
        --output_format srt `
        --output_dir $TempOutputDir `
        --language $WhisperLanguage

    if ($LASTEXITCODE -eq 0) {
        try {
            if (-not (Test-Path $FinalClipFolder)) {
                New-Item -ItemType Directory -Path $FinalClipFolder | Out-Null
            }


            # Dateien verschieben
            Move-Item -Path $Clip.FullName -Destination $FinalMP4 -Force
            Move-Item -Path (Join-Path $TempOutputDir "$ClipName.srt") -Destination $FinalSRT -Force
            Remove-Item -Path $TempOutputDir -Recurse -Force

            $FinalZip = Join-Path $FinalClipFolder "$ClipName.zip"


            #### Zip-Datei erstellen
            if (Test-Path $FinalZip) {
                Remove-Item $FinalZip -Force
            }

            Compress-Archive -Path $FinalMP4, $FinalSRT -DestinationPath $FinalZip

            $now = Get-Date
            $logData = @{
                name       = $ClipName
                processed  = $now.ToString("s")
                mp4        = $FinalMP4
                srt        = $FinalSRT
                zip        = $FinalZip
                size_bytes = (Get-Item $FinalMP4).Length
            }

            #### Clip-Metadaten aus Download-Log (optional)
            $clipMeta = $DownloadedClips.GetEnumerator() | Where-Object { $_.Value.filename -like "$ClipName*" } | Select-Object -First 1
            if ($clipMeta) {
                $logData.title = $clipMeta.Value.title
                $logData.id    = $clipMeta.Key
            }

            Save-ProcessedClip -clipName $ClipName -data $logData


            $now = Get-Date
            $logData = @{
                name       = $ClipName
                processed  = $now.ToString("s")
                mp4        = $FinalMP4
                srt        = $FinalSRT
                size_bytes = (Get-Item $FinalMP4).Length
            }
            Save-ProcessedClip -clipName $ClipName -data $logData

            Write-Host "✅ Verarbeitet: $ClipName"
            $ClipCounter++

            if ($DebugMode -eq 1 -and $ClipCounter -ge 1) {
                Write-Host "🛑 Debug-Modus aktiv – nur 1 Clip verarbeitet."
                break
            }
        } catch {
            Write-Host "❌ Fehler beim Verschieben – Rückgängig..."
            Undo-ProcessingIfFailed -folderPath $FinalClipFolder -tempPath $TempOutputDir
        }
    } else {
        Write-Host "❌ Fehler bei Transkription: $ClipName – Rückgängig..."
        Undo-ProcessingIfFailed -folderPath $FinalClipFolder -tempPath $TempOutputDir
    }
}

Write-Host "`n🏁 Verarbeitung abgeschlossen. $ClipCounter Clip(s) verarbeitet."

Write-Host "`n📦 Prüfe auf fehlende ZIP-Dateien..."

$ProcessedClips = Get-JsonLogAsHashtable $ProcessedLogPath
$ZipNachgeholt = 0

foreach ($clipName in $ProcessedClips.Keys) {
    $entry = $ProcessedClips[$clipName]
    $folder = Split-Path $entry.mp4
    $zipPath = Join-Path $folder "$clipName.zip"

    if (-not (Test-Path $entry.mp4) -or -not (Test-Path $entry.srt)) {
        Write-Host "⚠️  Dateien fehlen für $clipName – übersprungen."
        continue
    }

    if (Test-Path $zipPath) {
        Write-Host "✅ ZIP vorhanden für $clipName"
        continue
    }

    try {
        Compress-Archive -Path $entry.mp4, $entry.srt -DestinationPath $zipPath -Force
        Write-Host "📦 ZIP nachgeholt: $clipName"
        # Konvertiere PSCustomObject in echte Hashtable
        $entryHash = @{}
        foreach ($prop in $entry.PSObject.Properties) {
            $entryHash[$prop.Name] = $prop.Value
        }

        # Füge ZIP-Pfad hinzu
        $entryHash["zip"] = $zipPath

        # Speichere aktualisiert
        Save-ProcessedClip -clipName $clipName -data $entryHash
        $ZipNachgeholt++
    } catch {
        Write-Host "❌ Fehler beim Nachholen der ZIP für $clipName : $_"
    }
}

Write-Host "`n✅ $ZipNachgeholt ZIP-Datei(en) nachträglich erstellt."