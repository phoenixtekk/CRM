<#
.SYNOPSIS
    CVPNMIG-Set-ScopeTargeting.ps1 — create/populate the Cisco VPN migration-wave Entra group(s).
.DESCRIPTION
    PURPOSE
        Creates (idempotently) the Microsoft Entra security groups used to assign the Intune-delivered
        Cisco Secure Client app, VPN profile, and certificate by migration wave — starting with
        "PILOT - VPN Migration Wave 1" and any additional waves you name. Optionally adds device object
        IDs to a wave so the same devices that used the legacy SCCM/GPO VPN get the Intune delivery in a
        controlled ring. This is the target-group builder for the wave cutover.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CVPNMIG-Set-ScopeTargeting.ps1
        powershell -ExecutionPolicy Bypass -File .\CVPNMIG-Set-ScopeTargeting.ps1 -WaveNames 'PILOT - VPN Migration Wave 1','VPN Migration - Wave 2'
        powershell -ExecutionPolicy Bypass -File .\CVPNMIG-Set-ScopeTargeting.ps1 -WaveName 'PILOT - VPN Migration Wave 1' -DeviceIds id-one,id-two
        Requires the Microsoft Graph SDK and Group.ReadWrite.All (+ Device.Read.All to add members).

    EXPECTED RESULTS
        Each named wave group exists (created if missing) with its object ID printed; any supplied
        device IDs are added to the specified wave. Assign the four Intune objects to the pilot wave
        first, then expand wave by wave after each parity gate passes.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph for reads. Cisco internals deferred to vendor docs.
#>
[CmdletBinding()] param(
    [string[]]$WaveNames = @('PILOT - VPN Migration Wave 1','VPN Migration - Wave 2'),
    [string]$WaveName,
    [string[]]$DeviceIds
)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','Device.Read.All' -NoWelcome

function Get-OrNew-Group([string]$Name) {
    $filter = "displayName eq '$($Name.Replace("'","''"))'"
    $found = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=$filter").value | Select-Object -First 1
    if ($found) { Write-Host ("Exists: {0}  [{1}]" -f $Name, $found.id) -ForegroundColor Green; return $found.id }
    $body = @{
        displayName     = $Name
        description     = 'Cisco VPN SCCM/GPO to Intune migration wave'
        mailEnabled     = $false
        mailNickname    = ($Name -replace '[^a-zA-Z0-9]','')
        securityEnabled = $true
    }
    $new = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($body | ConvertTo-Json)
    Write-Host ("Created: {0}  [{1}]" -f $Name, $new.id) -ForegroundColor Cyan
    return $new.id
}

# Ensure every named wave group exists
$ids = @{}
foreach ($w in $WaveNames) { $ids[$w] = Get-OrNew-Group $w }

# Add devices to a specific wave if requested
if ($WaveName -and $DeviceIds) {
    if (-not $ids.ContainsKey($WaveName)) { $ids[$WaveName] = Get-OrNew-Group $WaveName }
    $target = $ids[$WaveName]
    foreach ($devId in $DeviceIds) {
        try {
            $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$devId" }
            Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$target/members/`$ref" -Body ($ref | ConvertTo-Json)
            Write-Host ("  Added device {0} to '{1}'." -f $devId, $WaveName) -ForegroundColor Green
        } catch { Write-Host ("  Skipped {0}: {1}" -f $devId, $_.Exception.Message) -ForegroundColor Yellow }
    }
}

Write-Host "`n-- Wave groups --" -ForegroundColor Cyan
$ids.GetEnumerator() | ForEach-Object { Write-Host ("  {0}: {1}" -f $_.Key, $_.Value) }
Write-Host "Assign 'Cisco Secure Client - Win32', 'Cisco VPN - Profile', 'Cisco VPN - Client Cert (SCEP)', and 'Cisco VPN - Trusted Root CA' to the pilot wave first; expand after each parity gate passes." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
