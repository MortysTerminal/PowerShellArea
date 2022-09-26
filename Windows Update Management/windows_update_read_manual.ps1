<#
.DESCRIPTION
  Dieses Skript ist zur schnellen, manuellen Auslesung eines Windows-Clients- / Servers gedacht. Dadurch ist es für Administratoren möglich eine schnelle Übersicht zu erhalten ohne sich auf das Ziel-System aufschalten zu müssen.
  Zur Ausführung dieses Skripts wird eine Windows-Anmeldung benötigt und sollte somit am besten von einem Windows-Betriebssystem ausgeführt werden.
  Die korrekte Implementierung der Berechtigungsstrukturen des ausführenden Benutzers wird vorausgesetzt. (Ausführen als Administrator nötig)
  

.INPUTS
  Benutzer wird aufgefordert über die Console den Computernamen und die Domäne einzugeben

.OUTPUTS
  Benutzerinputs werden abgefragt und Ausgabe der ausgelesenen Daten

.NOTES
  Version:        0.1
  Author:         Martin 
  Creation Date:  16.08.2022
  Purpose/Change: Einfaches Skript zum manuellen Auslesen von anstehenden Windows-Updates auf einem angegebenen Remote-PC
#>

############################
### INIT
############################

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

############################
### START
############################

<# TODO: Moeglichkeit schaffen ueber IP zu gehen und Benutzerfreundlichkeit erhöhen (z.B. wenn keine Domain vorhanden ist.)#>

# Eingabe von Computername und Domäne durch den Benutzer
$computer = Read-Host "Servername eingeben:"
$domain = Read-Host "Domain-Namen eingeben:"

# Baue NETBIOS-Name zur korrekten Abfrage z.B. über DNS
$server = $computer + $domain

# Abfrage des Update-Status
$updateStatus = Get-WindowsUpdate -ComputerName $server -ErrorVariable err -ErrorAction SilentlyContinue

# Ausgabe auf Console
Write-Host $updateStatus