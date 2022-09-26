<#
.DESCRIPTION
  A PowerShell Script to upload and refresh an IP-Adress at the GoDaddy Server to create your own DYN-DNS Service
  
.INPUTS
  You need to configure the variables: "$mydomain, $myhostname, $gdapikey"

.OUTPUTS
  A few console-outputs are configured for debugging purposes. You can add more Logging-Information if needed.

.NOTES
  Version:        1.0
  Author:         Martin B. @MortysTerminal (at GitHub) 
  Creation Date:  17.08.2022
  Purpose/Change: A easy way to update your DNS-Entry on GoDaddy
#>

############################
### INIT
############################

# For Example, when your wish DNS-Adress looks like: "vpn.tester.com"
# You need to set the Informations on the following way

$mydomain   = "DOMAIN NAME HERE" # for example: tester.com (from vpn.tester.com)
$myhostname = "HOSTNAME" # for example: vpn (from vpn.tester.com)
$gdapikey   = "GODADDY API KEY HERE" # 58 char - key


############################
### START
############################

# Invoke-RestMethod to get the current external IP of the System
$myip = Invoke-RestMethod -Uri "https://api.ipify.org"

# Invoke-RestMethod to get the current external IP which is signed on the GoDaddy-DNS
$dnsdata = Invoke-RestMethod "https://api.godaddy.com/v1/domains/$($mydomain)/records/A/$($myhostname)" -Headers @{ Authorization = "sso-key $($gdapikey)" }
$gdip = $dnsdata.data # get the data in own variable - for better usage

# DEBUG -> Output of the current IP and the IP of the GoDaddy-DNS
Write-Output "$(Get-Date -Format 'u') - Current External IP is $($myip), GoDaddy DNS IP is $($gdip)"

# Compare if the IPs are the same
If (-NOT ($gdip -eq $myip)) {
  # IF NOT -> Then DEBUG for the user, that the IP has changed
  Write-Output "IP has changed!! Updating on GoDaddy"
  # PUT the new IP-Address into the GoDaddy-DNS
  Invoke-RestMethod -Method PUT -Uri "https://api.godaddy.com/v1/domains/$($mydomain)/records/A/$($myhostname)" -Headers @{ Authorization = "sso-key $($gdapikey)" } -ContentType "application/json" -Body "[{`"data`": `"$($myip)`"}]";
}