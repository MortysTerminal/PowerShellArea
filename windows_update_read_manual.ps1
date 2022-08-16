<#
.DESCRIPTION
  Dieses Skript ist zur schnellen, manuellen Auslesung eines Windows-Clients- / Servers gedacht. Dadurch ist es für Administratoren möglich
  eine schnelle Übersicht zu erhalten ohne sich auf das Ziel-System aufschalten zu müssen.
  Die Korrekte Implementierung der Berechtigungsstrukturen des ausführenden Benutzers wird vorausgesetzt. (Ausführen als Administrator nötig)
  Zur Ausführung dieses Skript wird eine Windows-Anmeldung benötigt und sollte somit am besten von einem Windows-Betriebssystem ausgeführt werden.

.INPUTS
  Benutzer wird aufgefordert ueber die Console den Computernamen und Domain einzugeben

.OUTPUTS
  Benutzerinputs werden abgefragt und Ausgabe des Auslesens

.NOTES
  Version:        0.1
  Author:         Martin 
  Creation Date:  16.08.2022
  Purpose/Change: Einfaches Skript zum manuellen Auslesen von Windows-Updates (Remote)
#>

#------------------------------------[Aufbereitung der auszulesenden Daten]--------------------------------------------------------

############## Setzen des richtigen Output-Formats
$OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding

# Importiere Modul zum Abruf des Windows-Update-Status
# Abfrage ob Modul installiert ist auf dem Host-System
# Wenn nicht, wir das Modul installiert -> Benutzer eingabe wird noetig sein !!
if (Get-Module -ListAvailable -Name PSWindowsUpdate) {
    Write-Host "Module exists"
    Import-Module PSWindowsUpdate
} 
else {
    Write-Host "Module does not exist"
    Install-Module -Name PSWindowsUpdate
    Import-Module PSWindowsUpdate
}

<# TODO: Moeglichkeit schaffen ueber IP zu gehen und Benutzerfreundlichkeit erhöhen (z.B. wenn keine Domain vorhanden ist.)#>
# Benutzereingaben fuer Computer und Domain
$computer = Read-Host "Servername eingeben:"
$domain = Read-Host "Domain-Namen eingeben:"

# Baue NETBIOS-Name zur korrekten Abfrage z.B. ueber DNS
$server = $computer + $domain

# Abfrage des Update-Status
$updateStatus = Get-WindowsUpdate -ComputerName $server -ErrorVariable err -ErrorAction SilentlyContinue

# Ausgabe auf Console
Write-Host $updateStatus