<#
.DESCRIPTION
  A Powershell Script that creats a new Task-Shedule for the 'TwitchClipAndChatDownloader'
.INPUTS
  No Inputs from user needed.
.OUTPUTS
  Creates a new Task with the name "Start TwitchClipAndChatDownloader" with action but no trigger!
.NOTES
  Version:        1.2
  Author:         Martin B. @MortysTerminal (at GitHub) 
  Creation Date:  23.01.2023
  Purpose/Change: First Creation to add it into the TwitchClipAndChatDownloader, for Task-Creation
#>

function anyKey{
    Write-Host -NoNewline 'Druecke eine beliebige Taste um das Skript zu beenden...' -ForegroundColor Yellow;
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
    Exit;
}

function GetScriptPath{
    # Get Parent Path
    $aktScriptPath = $PSScriptRoot
    $parentScriptPath = (Get-Item $aktScriptPath).Parent.FullName
    #Write-Host "PS-Path: $aktScriptPath Parent: $parentScriptPath"
    $scriptpath = $parentScriptPath + "\" + "download_twitch_clips.ps1"
    if (Test-Path $scriptpath){
        return $true, $scriptpath
    }
    else{ return $false, $scriptpath }

}

$myScript = GetScriptPath
$myScriptCheck = $myScript[0]
$myScriptPath = $myScript[1]
$myScriptFolder = (Get-Item $myScriptPath ).DirectoryName

# Aktion erstellen
$argument = "-NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -File $myScriptPath"
$Action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $argument -WorkingDirectory $myScriptFolder

#$Trigger = New-ScheduledTaskTrigger -Daily -At 3am
$Settings = New-ScheduledTaskSettingsSet

# Create Task itself
$Task = New-ScheduledTask -Action $Action  -Settings $Settings #-Trigger $Trigger

# Clear CLI
Clear-Host

Write-Host "Bereite Aufgabe vor ..." -ForegroundColor Yellow

if($myScriptCheck){ 

    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    $result = [System.Windows.Forms.MessageBox]::Show('Skript gefunden! Soll eine Aufgabe erstellt werden?' , "Info" , 4)
    if ($result -eq 'Yes') {
        try{ 
            Register-ScheduledTask -TaskName 'Start TwitchClipAndChatDownloader' -InputObject $Task -ErrorAction Stop  | Out-Null
            [System.Windows.Forms.MessageBox]::Show("Aufgabe erstellt!","Skript-Aufgabe hinzugefuegt",0) | Out-Null
            Write-Host "Aufgabe erstellt! ..." -ForegroundColor Green
        }
        catch{
            Write-Host "Konnte die Aufgabe nicht erstellen. Entweder schon vorhanden oder keine Berechtigung!" -ForegroundColor Red
            [System.Windows.Forms.MessageBox]::Show("Konnte die Aufgabe nicht erstellen. Entweder schon vorhanden oder keine Berechtigung!","Fehler bei der Erstellung",0) | Out-Null
        }
        
    }
}
else{ 
    Write-Host "Fehler beim Erstellen der Aufgabe. Skript konnte nicht gefunden werden." -ForegroundColor Red
    #anyKey
}
