<#
.SYNOPSIS
    CVPNMIG-Discovery.ps1 — current-state discovery of the Cisco VPN client, profile, and cert delivery.
.DESCRIPTION
    PURPOSE
        Read-only current-state map for the SCCM/GPO to Intune Cisco VPN migration. On THIS device it
        detects the installed Cisco Secure Client (AnyConnect) version, the VPN profile XML, the VPN
        client certificate, and whether each artifact was delivered by SCCM or GPO. Against Microsoft
        Graph it lists the Intune-side app and VPN/certificate profiles that will replace them.
        Cisco installer and profile-XML internals are deferred to Cisco documentation.
    HOW TO RUN
        Elevated on a target device (local checks); add -Graph for the Intune-side inventory:
        powershell -ExecutionPolicy Bypass -File .\CVPNMIG-Discovery.ps1
        powershell -ExecutionPolicy Bypass -File .\CVPNMIG-Discovery.ps1 -Graph -CsvPath C:\Temp\cvpnmig-discovery.csv
        Graph mode requires the Microsoft Graph SDK and scopes:
        DeviceManagementApps.Read.All, DeviceManagementConfiguration.Read.All

    EXPECTED RESULTS
        A local table showing client version, profile XML path, VPN certificate, and the delivery
        source (SCCM / GPO / Intune / Unknown). With -Graph, a list of the matching Intune app and
        profiles. Use it to confirm parity before cutover and to prove a cut-over device is Intune-only.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph for reads. Cisco internals deferred to vendor docs.
#>
[CmdletBinding()] param(
    [switch]$Graph,
    [string]$CsvPath
)

Write-Host "=== CVPNMIG Discovery — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
$rows = @()

# --- 1. Installed Cisco Secure Client / AnyConnect version (from the uninstall registry) ---
$uninstallKeys = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
                 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
$client = Get-ItemProperty $uninstallKeys -ErrorAction SilentlyContinue |
          Where-Object { $_.DisplayName -match 'Cisco (Secure Client|AnyConnect)' } |
          Select-Object -First 1
$clientVersion = if ($client) { $client.DisplayVersion } else { $null }
$rows += [pscustomobject]@{
    Artifact = 'Secure Client';  Present = [bool]$client
    Detail   = if ($client) { "$($client.DisplayName) $clientVersion" } else { 'not installed' }
    Source   = '(see delivery below)'
}

# --- 2. VPN profile XML (Cisco stores connection profiles as .xml under ProgramData) ---
$profileDirs = @(
    "$env:ProgramData\Cisco\Cisco Secure Client\VPN\Profile",
    "$env:ProgramData\Cisco\Cisco AnyConnect Secure Mobility Client\Profile"
)
$profileXml = Get-ChildItem -Path $profileDirs -Filter *.xml -ErrorAction SilentlyContinue | Select-Object -First 1
$rows += [pscustomobject]@{
    Artifact = 'VPN profile XML'; Present = [bool]$profileXml
    Detail   = if ($profileXml) { $profileXml.FullName } else { 'no profile found' }
    Source   = '(see delivery below)'
}

# --- 3. VPN client certificate (client-auth cert in the machine + user stores) ---
$certs = @()
foreach ($store in 'Cert:\LocalMachine\My','Cert:\CurrentUser\My') {
    $certs += Get-ChildItem $store -ErrorAction SilentlyContinue |
              Where-Object { $_.EnhancedKeyUsageList.FriendlyName -contains 'Client Authentication' }
}
$vpnCert = $certs | Select-Object -First 1
$rows += [pscustomobject]@{
    Artifact = 'VPN client cert'; Present = [bool]$vpnCert
    Detail   = if ($vpnCert) { "Subject=$($vpnCert.Subject); Issuer=$($vpnCert.Issuer)" } else { 'no client-auth cert' }
    Source   = '(see delivery below)'
}

# --- 4. Delivery source: is this device targeted by SCCM and/or GPO? ---
$sccmClient = Get-Service -Name CcmExec -ErrorAction SilentlyContinue
$sccmPresent = [bool]$sccmClient
$gpoApplied = $null
try {
    # gpresult scope: look for any policy referencing the VPN client / profile / cert enrolment
    $gp = & gpresult /r /scope:computer 2>$null | Out-String
    $gpoApplied = ($gp -match 'Cisco' -or $gp -match 'AnyConnect' -or $gp -match 'Secure Client')
} catch { $gpoApplied = $false }

$delivery = if     ($sccmPresent -and $gpoApplied) { 'SCCM + GPO (legacy — double source!)' }
            elseif ($sccmPresent)                  { 'SCCM client present (verify targeting in console)' }
            elseif ($gpoApplied)                   { 'GPO applying Cisco policy' }
            else                                   { 'No SCCM/GPO delivery detected (Intune-only candidate)' }

Write-Host "`n-- Artifacts on this device --" -ForegroundColor Cyan
$rows | Format-Table Artifact, Present, Detail -AutoSize -Wrap
Write-Host ("Legacy delivery: {0}" -f $delivery) -ForegroundColor $(if ($sccmPresent -or $gpoApplied) { 'Yellow' } else { 'Green' })

# --- 5. Optional: Intune-side inventory via Graph ---
$graphRows = @()
if ($Graph) {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All','DeviceManagementConfiguration.Read.All' -NoWelcome

    # matching Win32 app(s)
    $apps = @(); $uri = "/v1.0/deviceAppManagement/mobileApps?`$filter=isof('microsoft.graph.win32LobApp')"
    do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $apps += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
    foreach ($a in ($apps | Where-Object { $_.displayName -match 'Cisco|Secure Client|VPN' })) {
        $graphRows += [pscustomobject]@{ IntuneObject = 'Win32 app'; Name = $a.displayName; Id = $a.id }
    }
    # VPN + certificate configuration profiles
    $cfg = @(); $uri = '/v1.0/deviceManagement/deviceConfigurations'
    do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $cfg += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
    foreach ($c in ($cfg | Where-Object { $_.displayName -match 'VPN|Cisco|Cert|Trusted|SCEP|PKCS' })) {
        $graphRows += [pscustomobject]@{ IntuneObject = $c.'@odata.type'.Split('.')[-1]; Name = $c.displayName; Id = $c.id }
    }

    Write-Host "`n-- Intune-side objects (replacements) --" -ForegroundColor Cyan
    if ($graphRows) { $graphRows | Format-Table IntuneObject, Name -AutoSize } else { Write-Host '  (none found — build them per the Implementation Guide)' -ForegroundColor Yellow }
    Disconnect-MgGraph | Out-Null
}

if ($CsvPath) {
    $out = $rows | ForEach-Object { $_ | Select-Object Artifact, Present, Detail, @{n='Delivery';e={$delivery}} }
    $out | Export-Csv -Path $CsvPath -NoTypeInformation
    if ($graphRows) { $graphRows | Export-Csv -Path ($CsvPath -replace '\.csv$','-intune.csv') -NoTypeInformation }
    Write-Host "`nSaved $CsvPath" -ForegroundColor Green
}
