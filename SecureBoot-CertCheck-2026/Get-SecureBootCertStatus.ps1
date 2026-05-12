<#
.SYNOPSIS
    Read-only inventory of Secure Boot CA 2023 certificate deployment status
    on the local Windows device.

.DESCRIPTION
    Aggregates everything needed to answer the single question:

        "Has this device received the new Secure Boot certificates that
         replace the 2011 CAs expiring in June 2026?"

    The script performs four diagnostic phases:

      1. Confirms Secure Boot is enabled (Confirm-SecureBootUEFI).
      2. Reads the Servicing registry values that Windows uses to track the
         rollout state (UEFICA2023Status, UEFICA2023Error, AvailableUpdates,
         WindowsUEFICA2023Capable, HighConfidenceOptOut,
         MicrosoftUpdateManagedOptIn).
      3. Inspects the UEFI DB and KEK variables directly to verify that the
         four 2023-generation certificates are physically present in firmware.
      4. Collects the relevant System event log entries
         (1795 / 1796 / 1800 / 1801 / 1802 / 1803 / 1808).

    Output is a single PSCustomObject summary, optionally exported to CSV
    and / or appended to a timestamped log file.

    NOTHING IS WRITTEN TO THE SYSTEM. This script does not trigger deployment.
    Triggering deployment requires setting:

        HKLM\SYSTEM\CurrentControlSet\Control\SecureBoot\AvailableUpdates = 0x5944

    which is deliberately NOT done here. See README.md for the deployment
    workflow.

.PARAMETER ExportCsv
    Optional path to a CSV file. Writes a single-row snapshot of the result.
    If the file exists, a new row is appended.

.PARAMETER LogPath
    Optional path to a plain-text log file. Receives a timestamped copy of
    the console summary.

.PARAMETER Quiet
    Suppress the formatted console summary. The result object is still
    emitted on the pipeline.

.EXAMPLE
    .\Get-SecureBootCertStatus.ps1

    Run an interactive check and print the summary to the console.

.EXAMPLE
    .\Get-SecureBootCertStatus.ps1 -ExportCsv .\status.csv -LogPath .\check.log

    Run the check, print the summary, append a CSV row, and write a log file.

.EXAMPLE
    $r = .\Get-SecureBootCertStatus.ps1 -Quiet
    if ($r.OverallState -ne 'Updated') { Write-Warning 'Action required' }

    Pipeline-friendly usage for embedding into other automation.

.NOTES
    Author      : MortysTerminal
    Repository  : github.com/MortysTerminal/PowerShellArea
    Compatible  : Windows PowerShell 5.1 and PowerShell 7.x
    Platform    : Windows 10 (22H2+) and Windows 11
    References  : https://aka.ms/GetSecureBoot
                  https://support.microsoft.com/help/5062713
                  https://support.microsoft.com/help/5068202

    This script is read-only and safe to run on production devices.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string] $ExportCsv,

    [Parameter(Mandatory = $false)]
    [string] $LogPath,

    [Parameter(Mandatory = $false)]
    [switch] $Quiet
)

# ----------------------------------------------------------------------------
#  Helpers
# ----------------------------------------------------------------------------

function Write-Banner {
    param([string] $Title)
    $line = '=' * 72
    Write-Host ''
    Write-Host $line                            -ForegroundColor DarkGray
    Write-Host (" {0}" -f $Title)               -ForegroundColor Cyan
    Write-Host (" Secure Boot CA 2023 Status  |  MortysTerminal / PowerShellArea") -ForegroundColor DarkGray
    Write-Host $line                            -ForegroundColor DarkGray
}

function Write-Status {
    param(
        [ValidateSet('OK','WARN','ERROR','INFO')]
        [string] $Level,
        [string] $Message
    )
    $tag, $color = switch ($Level) {
        'OK'    { '[ OK ]', 'Green'   }
        'WARN'  { '[WARN]', 'Yellow'  }
        'ERROR' { '[ERR ]', 'Red'     }
        'INFO'  { '[INFO]', 'Cyan'    }
    }
    Write-Host ("  {0}  {1}" -f $tag, $Message) -ForegroundColor $color
}

function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $pr = New-Object Security.Principal.WindowsPrincipal($id)
    return $pr.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-SecureBootEnabledSafe {
    try   { return [bool](Confirm-SecureBootUEFI -ErrorAction Stop) }
    catch { return $null }
}

function Get-RegistryValueSafe {
    param([string] $Path, [string] $Name)
    try {
        return (Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop).$Name
    } catch {
        return $null
    }
}

function Test-UefiVariableContains {
    param([string] $VariableName, [string[]] $SearchStrings)

    $result = [ordered]@{}
    try {
        $bytes = (Get-SecureBootUEFI -Name $VariableName -ErrorAction Stop).bytes
        $text  = [System.Text.Encoding]::ASCII.GetString($bytes)
        foreach ($s in $SearchStrings) {
            $result[$s] = $text -match [regex]::Escape($s)
        }
    } catch {
        foreach ($s in $SearchStrings) { $result[$s] = $null }
    }
    return [pscustomobject]$result
}

function Get-SecureBootEvents {
    $ids = 1795, 1796, 1800, 1801, 1802, 1803, 1808
    try {
        Get-WinEvent -FilterHashtable @{ LogName = 'System'; Id = $ids } -ErrorAction Stop |
            Sort-Object TimeCreated -Descending |
            Select-Object TimeCreated, Id, LevelDisplayName,
                          @{n='Message';e={ ($_.Message -split "`r?`n")[0] }}
    } catch {
        return @()
    }
}

# ----------------------------------------------------------------------------
#  Phase 0: preflight
# ----------------------------------------------------------------------------

if (-not $Quiet) { Write-Banner -Title 'Diagnostic run started' }

if (-not (Test-IsAdmin)) {
    Write-Warning 'Not running as Administrator. Registry and event log reads may fail or return partial data.'
}

$secureBootPath  = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot'
$servicingPath   = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\Servicing'
$deviceAttrPath  = "$servicingPath\DeviceAttributes"

# ----------------------------------------------------------------------------
#  Phase 1: Secure Boot enabled?
# ----------------------------------------------------------------------------

$secureBootEnabled = Get-SecureBootEnabledSafe
if (-not $Quiet) {
    if     ($secureBootEnabled -eq $true)  { Write-Status OK    'Secure Boot is enabled.' }
    elseif ($secureBootEnabled -eq $false) { Write-Status ERROR 'Secure Boot is disabled. Certificate rollout does not apply.' }
    else                                   { Write-Status WARN  'Secure Boot state could not be determined.' }
}

# ----------------------------------------------------------------------------
#  Phase 2: registry status
# ----------------------------------------------------------------------------

$reg = [pscustomobject]@{
    UEFICA2023Status              = Get-RegistryValueSafe $servicingPath  'UEFICA2023Status'
    UEFICA2023Error               = Get-RegistryValueSafe $servicingPath  'UEFICA2023Error'
    WindowsUEFICA2023Capable      = Get-RegistryValueSafe $servicingPath  'WindowsUEFICA2023Capable'
    AvailableUpdates              = Get-RegistryValueSafe $secureBootPath 'AvailableUpdates'
    HighConfidenceOptOut          = Get-RegistryValueSafe $secureBootPath 'HighConfidenceOptOut'
    MicrosoftUpdateManagedOptIn   = Get-RegistryValueSafe $secureBootPath 'MicrosoftUpdateManagedOptIn'
    OEMManufacturerName           = Get-RegistryValueSafe $deviceAttrPath 'OEMManufacturerName'
    OEMModelNumber                = Get-RegistryValueSafe $deviceAttrPath 'OEMModelNumber'
    FirmwareVersion               = Get-RegistryValueSafe $deviceAttrPath 'FirmwareVersion'
    FirmwareReleaseDate           = Get-RegistryValueSafe $deviceAttrPath 'FirmwareReleaseDate'
}

$availableUpdatesHex = if ($null -ne $reg.AvailableUpdates) {
    '0x{0:X}' -f [int]$reg.AvailableUpdates
} else { $null }

# ----------------------------------------------------------------------------
#  Phase 3: UEFI variable inspection (DB and KEK)
# ----------------------------------------------------------------------------

$dbCerts = Test-UefiVariableContains -VariableName 'db' -SearchStrings @(
    'Windows UEFI CA 2023',
    'Microsoft UEFI CA 2023',
    'Microsoft Option ROM UEFI CA 2023'
)

$kekCerts = Test-UefiVariableContains -VariableName 'KEK' -SearchStrings @(
    'Microsoft Corporation KEK 2K CA 2023'
)

# ----------------------------------------------------------------------------
#  Phase 4: event log
# ----------------------------------------------------------------------------

$events     = @(Get-SecureBootEvents)
$last1808   = $events | Where-Object Id -eq 1808 | Select-Object -First 1
$last1801   = $events | Where-Object Id -eq 1801 | Select-Object -First 1
$last1795   = $events | Where-Object Id -eq 1795 | Select-Object -First 1
$count1808  = ($events | Where-Object Id -eq 1808 | Measure-Object).Count
$count1801  = ($events | Where-Object Id -eq 1801 | Measure-Object).Count
$count1795  = ($events | Where-Object Id -eq 1795 | Measure-Object).Count

# ----------------------------------------------------------------------------
#  Derive overall state
# ----------------------------------------------------------------------------

$allDbPresent  = ($dbCerts.PSObject.Properties.Value  -notcontains $false) -and
                 ($dbCerts.PSObject.Properties.Value  -notcontains $null)
$allKekPresent = ($kekCerts.PSObject.Properties.Value -notcontains $false) -and
                 ($kekCerts.PSObject.Properties.Value -notcontains $null)

$overall = switch ($true) {
    ($secureBootEnabled -ne $true)                                { 'SecureBootDisabled'; break }
    ($null -ne $reg.UEFICA2023Error -and $reg.UEFICA2023Error -ne 0) { 'Error';          break }
    ($reg.UEFICA2023Status -eq 'Updated' -and $allDbPresent -and $allKekPresent) { 'Updated'; break }
    ($reg.UEFICA2023Status -eq 'InProgress')                      { 'InProgress';        break }
    ($reg.UEFICA2023Status -eq 'NotStarted' -or $null -eq $reg.UEFICA2023Status) { 'NotStarted'; break }
    default                                                       { 'Unknown' }
}

# ----------------------------------------------------------------------------
#  Build result object
# ----------------------------------------------------------------------------

$result = [pscustomobject]@{
    Hostname                       = $env:COMPUTERNAME
    CollectedAt                    = (Get-Date).ToString('o')
    OverallState                   = $overall
    SecureBootEnabled              = $secureBootEnabled
    UEFICA2023Status               = $reg.UEFICA2023Status
    UEFICA2023Error                = $reg.UEFICA2023Error
    WindowsUEFICA2023Capable       = $reg.WindowsUEFICA2023Capable
    AvailableUpdates               = $availableUpdatesHex
    HighConfidenceOptOut           = $reg.HighConfidenceOptOut
    MicrosoftUpdateManagedOptIn    = $reg.MicrosoftUpdateManagedOptIn
    DB_WindowsUEFICA2023           = $dbCerts.'Windows UEFI CA 2023'
    DB_MicrosoftUEFICA2023         = $dbCerts.'Microsoft UEFI CA 2023'
    DB_MicrosoftOptionROMCA2023    = $dbCerts.'Microsoft Option ROM UEFI CA 2023'
    KEK_MicrosoftCorpKEK2KCA2023   = $kekCerts.'Microsoft Corporation KEK 2K CA 2023'
    Event1808_Last                 = if ($last1808) { $last1808.TimeCreated.ToString('o') } else { $null }
    Event1808_Count                = $count1808
    Event1801_Last                 = if ($last1801) { $last1801.TimeCreated.ToString('o') } else { $null }
    Event1801_Count                = $count1801
    Event1795_Last                 = if ($last1795) { $last1795.TimeCreated.ToString('o') } else { $null }
    Event1795_Count                = $count1795
    OEMManufacturer                = $reg.OEMManufacturerName
    OEMModel                       = $reg.OEMModelNumber
    FirmwareVersion                = $reg.FirmwareVersion
    FirmwareReleaseDate            = $reg.FirmwareReleaseDate
    OSVersion                      = [System.Environment]::OSVersion.Version.ToString()
}

# ----------------------------------------------------------------------------
#  Console summary
# ----------------------------------------------------------------------------

if (-not $Quiet) {
    Write-Banner -Title ('Result: {0}' -f $overall)

    Write-Host '  Registry'                                            -ForegroundColor White
    Write-Status INFO ("UEFICA2023Status            : {0}" -f ($reg.UEFICA2023Status        | ForEach-Object { if ($_) { $_ } else { '<not present>' } }))
    Write-Status INFO ("UEFICA2023Error             : {0}" -f ($reg.UEFICA2023Error         | ForEach-Object { if ($null -ne $_) { $_ } else { '<not present (good)>' } }))
    Write-Status INFO ("WindowsUEFICA2023Capable    : {0}" -f ($reg.WindowsUEFICA2023Capable| ForEach-Object { if ($null -ne $_) { $_ } else { '<not present>' } }))
    Write-Status INFO ("AvailableUpdates            : {0}" -f ($availableUpdatesHex          | ForEach-Object { if ($_) { $_ } else { '<not present>' } }))
    Write-Status INFO ("HighConfidenceOptOut        : {0}" -f ($reg.HighConfidenceOptOut    | ForEach-Object { if ($null -ne $_) { $_ } else { '<not present>' } }))
    Write-Status INFO ("MicrosoftUpdateManagedOptIn : {0}" -f ($reg.MicrosoftUpdateManagedOptIn | ForEach-Object { if ($null -ne $_) { $_ } else { '<not present>' } }))

    Write-Host ''
    Write-Host '  Firmware DB (signature database)'                    -ForegroundColor White
    foreach ($p in $dbCerts.PSObject.Properties) {
        $lvl = if     ($p.Value -eq $true)  { 'OK'    }
               elseif ($p.Value -eq $false) { 'WARN'  }
               else                         { 'ERROR' }
        $val = if     ($p.Value -eq $true)  { 'present' }
               elseif ($p.Value -eq $false) { 'missing' }
               else                         { 'unreadable' }
        Write-Status $lvl ("{0,-40} : {1}" -f $p.Name, $val)
    }

    Write-Host ''
    Write-Host '  Firmware KEK (key exchange key)'                     -ForegroundColor White
    foreach ($p in $kekCerts.PSObject.Properties) {
        $lvl = if     ($p.Value -eq $true)  { 'OK'    }
               elseif ($p.Value -eq $false) { 'WARN'  }
               else                         { 'ERROR' }
        $val = if     ($p.Value -eq $true)  { 'present' }
               elseif ($p.Value -eq $false) { 'missing' }
               else                         { 'unreadable' }
        Write-Status $lvl ("{0,-40} : {1}" -f $p.Name, $val)
    }

    Write-Host ''
    Write-Host '  System event log'                                    -ForegroundColor White
    Write-Status INFO ("Event 1808 (success)  : count = {0}{1}" -f $count1808, $(if ($last1808) { ", last $($last1808.TimeCreated)" }))
    Write-Status INFO ("Event 1801 (error)    : count = {0}{1}" -f $count1801, $(if ($last1801) { ", last $($last1801.TimeCreated)" }))
    Write-Status INFO ("Event 1795 (firmware) : count = {0}{1}" -f $count1795, $(if ($last1795) { ", last $($last1795.TimeCreated)" }))

    Write-Host ''
    Write-Banner -Title 'Done'
}

# ----------------------------------------------------------------------------
#  Optional exports
# ----------------------------------------------------------------------------

if ($ExportCsv) {
    try {
        $exists = Test-Path -LiteralPath $ExportCsv
        $result | Export-Csv -LiteralPath $ExportCsv -NoTypeInformation -Append:$exists -Encoding UTF8
        if (-not $Quiet) { Write-Status OK ("CSV written to {0}" -f $ExportCsv) }
    } catch {
        Write-Warning ("CSV export failed: {0}" -f $_.Exception.Message)
    }
}

if ($LogPath) {
    try {
        $stamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        $lines = @()
        $lines += "==== Secure Boot CA 2023 status @ $stamp on $($env:COMPUTERNAME) ===="
        $lines += ($result | Format-List | Out-String).TrimEnd()
        $lines += ''
        Add-Content -LiteralPath $LogPath -Value $lines -Encoding UTF8
        if (-not $Quiet) { Write-Status OK ("Log appended to {0}" -f $LogPath) }
    } catch {
        Write-Warning ("Log write failed: {0}" -f $_.Exception.Message)
    }
}

# Emit the structured result on the pipeline regardless of -Quiet
$result