<#
.SYNOPSIS
    WIFIDX-Remediation.ps1 — guarded helper to apply the corrected-replacement-profile pattern.
.DESCRIPTION
    PURPOSE
        Supports the reliable remediation from Branch A: rather than editing a Wi-Fi profile in place,
        you deploy a corrected REPLACEMENT profile and clear the stale saved network so it re-adds
        cleanly. This helper does two guarded things, each defaulting to -WhatIf (preview only):
          (a) -RemoveStaleOnDevice : on THIS Windows device, delete the stale saved network for -Ssid
              (netsh wlan delete profile) so the corrected Intune profile re-creates it on next sync.
          (b) -CreatePilotGroup    : create the Assigned Entra group 'WIFIDX - Pilot Devices' (Graph)
              used to scope the corrected pilot profile.
        It does NOT edit or delete Intune profiles for you — creating the corrected profile is a
        deliberate console step (document 3) so you own its exact settings. Nothing changes until you
        re-run with -WhatIf:$false.
    HOW TO RUN
        Preview (default):   powershell -ExecutionPolicy Bypass -File .\WIFIDX-Remediation.ps1 -RemoveStaleOnDevice -Ssid CORP-WIFI
        Apply on device:     powershell -ExecutionPolicy Bypass -File .\WIFIDX-Remediation.ps1 -RemoveStaleOnDevice -Ssid CORP-WIFI -WhatIf:$false
        Create pilot group:  powershell -ExecutionPolicy Bypass -File .\WIFIDX-Remediation.ps1 -CreatePilotGroup -Environment USGov -WhatIf:$false
        On-device action needs elevation; -CreatePilotGroup needs Group.ReadWrite.All.
    EXPECTED RESULTS
        In -WhatIf: prints exactly what it WOULD do and changes nothing. Applied: removes the stale
        saved network (then advises a sync) and/or creates the Assigned pilot group, echoing the id.
.NOTES
    Intune Solutions — GUARDED. Default -WhatIf. Cloud-aware (Global | USGov | USGovDoD). Confirm the
    corrected replacement profile exists BEFORE removing a stale saved network.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [switch]$RemoveStaleOnDevice,
    [string]$Ssid,
    [switch]$CreatePilotGroup,
    [ValidateSet('Global','USGov','USGovDoD')]
    [string]$Environment = 'Global',
    [switch]$WhatIf = $true
)
# make -WhatIf the default while still honouring an explicit -WhatIf:$false
if ($PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = [bool]$WhatIf } else { $WhatIfPreference = $true }

Write-Host "=== WIFIDX Remediation (guarded) ===" -ForegroundColor Cyan
Write-Host "Reminder: build the corrected REPLACEMENT profile in Intune first (document 3, Branch A)." -ForegroundColor Yellow

if (-not $RemoveStaleOnDevice -and -not $CreatePilotGroup) {
    Write-Host "Nothing to do. Pass -RemoveStaleOnDevice (with -Ssid) and/or -CreatePilotGroup." -ForegroundColor Yellow
    return
}

# (a) Remove the stale saved network on THIS device so the corrected profile re-adds it.
if ($RemoveStaleOnDevice) {
    if (-not $Ssid) { Write-Host "  -RemoveStaleOnDevice requires -Ssid." -ForegroundColor Red; return }
    $saved = (netsh wlan show profiles) 2>$null | Select-String ([regex]::Escape($Ssid))
    if (-not $saved) {
        Write-Host ("  SSID '{0}' is not a saved network on this device — nothing to remove." -f $Ssid) -ForegroundColor Green
    } elseif ($PSCmdlet.ShouldProcess("$Ssid on $($env:COMPUTERNAME)", "netsh wlan delete profile (clear stale saved network)")) {
        netsh wlan delete profile name="$Ssid" | Out-Null
        Write-Host ("  Removed stale saved network '{0}'. Now trigger a sync so the corrected profile re-adds it:" -f $Ssid) -ForegroundColor Green
        Write-Host "    Settings > Accounts > Access work or school > Info > Sync   (or deviceenroller /c /AutoEnrollMDM)" -ForegroundColor Gray
    } else {
        Write-Host ("  WHATIF: would run  netsh wlan delete profile name=`"{0}`"  (no change made)." -f $Ssid) -ForegroundColor Gray
    }
}

# (b) Create the Assigned pilot group used to scope the corrected pilot profile.
if ($CreatePilotGroup) {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $groupName = 'WIFIDX - Pilot Devices'
    if ($PSCmdlet.ShouldProcess($groupName, "Create Assigned Entra security group (Graph, $Environment)")) {
        Connect-MgGraph -Environment $Environment -Scopes 'Group.ReadWrite.All' -NoWelcome
        $body = @{
            displayName     = $groupName
            mailEnabled     = $false
            mailNickname    = 'WIFIDX-Pilot-Devices'
            securityEnabled = $true
            description     = 'WIFIDX pilot scope for the corrected Wi-Fi replacement profile (Assigned).'
        }
        try {
            $g = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($body | ConvertTo-Json)
            Write-Host ("  Created Assigned group '{0}'  id: {1}" -f $groupName, $g.id) -ForegroundColor Green
            Write-Host "  Add your pilot devices, then assign the corrected profile to this group only." -ForegroundColor Gray
        } catch {
            Write-Host "  Failed to create group: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        Disconnect-MgGraph | Out-Null
    } else {
        Write-Host ("  WHATIF: would create Assigned Entra security group '{0}' ({1}). No change made." -f $groupName, $Environment) -ForegroundColor Gray
    }
}
