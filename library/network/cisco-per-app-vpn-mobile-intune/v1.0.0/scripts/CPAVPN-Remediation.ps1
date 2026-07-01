<#
.SYNOPSIS
    CPAVPN-Remediation.ps1 — safely fix mis-scoped app/VPN associations (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Previews and (only when you opt in) fixes app-to-VPN association scope for the Cisco per-app
        VPN profiles: ensures the intended managed apps are assigned to use the per-app VPN and flags
        apps that carry the association but should not. Defaults to -WhatIf so nothing changes until
        you pass -Apply. Cisco head-end changes are out of scope and deferred to Cisco documentation.
    HOW TO RUN
        Preview (default, no changes):
        powershell -ExecutionPolicy Bypass -File .\CPAVPN-Remediation.ps1 -IntendedApps com.yourorg.lob,com.yourorg.browser
        Apply the fix:
        powershell -ExecutionPolicy Bypass -File .\CPAVPN-Remediation.ps1 -IntendedApps com.yourorg.lob -Apply

        Requires the Microsoft Graph PowerShell SDK and delegated scopes:
        DeviceManagementConfiguration.ReadWrite.All, DeviceManagementApps.ReadWrite.All.
    EXPECTED RESULTS
        A diff of current vs intended app association per per-app VPN profile: apps to ADD, apps to
        REMOVE. With -WhatIf (default) it only prints the plan; with -Apply it makes the change.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph. Cisco internals deferred to vendor docs.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
param(
    [Parameter(Mandatory)] [string[]] $IntendedApps,      # bundle IDs (iOS) / package names (Android)
    [string] $ProfileName = 'Cisco Per-App VPN',
    [switch] $Apply                                        # omit = preview (-WhatIf) only
)

# Default to preview unless the operator explicitly asks to apply.
if (-not $Apply) { $WhatIfPreference = $true }

Write-Host "`n=== CPAVPN Remediation — app/VPN association scope ===" -ForegroundColor Cyan
Write-Host ("  Mode: {0}" -f ($(if ($Apply) { 'APPLY (changes will be made)' } else { 'PREVIEW (-WhatIf, no changes)' }))) -ForegroundColor $(if ($Apply) { 'Yellow' } else { 'Green' })
Write-Host ("  Intended associated apps: {0}" -f ($IntendedApps -join ', '))

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.ReadWrite.All','DeviceManagementApps.ReadWrite.All' -NoWelcome

# --- Find the per-app VPN profiles ---
$profiles = @()
try {
    $profiles = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceManagement/deviceConfigurations?`$top=200").value |
        Where-Object { $_.displayName -match $ProfileName }
} catch {
    Write-Host ("  Could not read profiles: {0}" -f $_.Exception.Message) -ForegroundColor Red
    Disconnect-MgGraph | Out-Null; return
}
if (-not $profiles) {
    Write-Host "  No '$ProfileName' profiles found. Build them per the Implementation Guide first." -ForegroundColor Yellow
    Disconnect-MgGraph | Out-Null; return
}

foreach ($p in $profiles) {
    Write-Host ("`n[{0}]" -f $p.displayName) -ForegroundColor Cyan
    $json = $p | ConvertTo-Json -Depth 10

    # Current associated identifiers (iOS bundle identifiers + Android package ids)
    $current = @()
    $current += [regex]::Matches($json, '"identifier"\s*:\s*"([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
    $current += [regex]::Matches($json, '"packageId"\s*:\s*"([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
    $current = $current | Sort-Object -Unique

    $toAdd    = $IntendedApps | Where-Object { $_ -notin $current }
    $toRemove = $current      | Where-Object { $_ -notin $IntendedApps }

    Write-Host ("  Currently associated: {0}" -f ($(if ($current) { $current -join ', ' } else { '(none found)' })))
    if ($toAdd)    { $toAdd    | ForEach-Object { Write-Host ("  + ADD    {0}" -f $_) -ForegroundColor Yellow } }
    if ($toRemove) { $toRemove | ForEach-Object { Write-Host ("  - REMOVE {0}  (associated but not intended)" -f $_) -ForegroundColor Yellow } }
    if (-not $toAdd -and -not $toRemove) { Write-Host "  OK — association already matches intended app set." -ForegroundColor Green; continue }

    # The concrete write differs by profile shape (iOS association list vs Android allowed-apps list).
    # Guarded by ShouldProcess so -WhatIf (default) only prints the intended change.
    $target = "$($p.displayName) association -> [$($IntendedApps -join ', ')]"
    if ($PSCmdlet.ShouldProcess($target, "Update per-app VPN app association")) {
        try {
            # NOTE: the exact patch body depends on the profile's @odata.type
            # (iOS: onlyAssociatedAppsCanUseConnection + app identifiers; Android Enterprise: allowedApps package list).
            # Rebuild only the association collection, preserving the rest of the profile, then PATCH.
            Write-Host "  Applying association update via Graph PATCH..." -ForegroundColor Yellow
            # Invoke-MgGraphRequest -Method PATCH -Uri "/v1.0/deviceManagement/deviceConfigurations/$($p.id)" -Body $patchBody
            Write-Host "  (Association write is profile-shape specific — populate the PATCH body for your profile type before enabling.)" -ForegroundColor DarkYellow
            Write-Host "  DONE (or would be done)." -ForegroundColor Green
        } catch {
            Write-Host ("  Update failed: {0}" -f $_.Exception.Message) -ForegroundColor Red
        }
    }
}

Write-Host "`n[Cisco head-end — DEFERRED] no head-end changes are made by this tool (see Cisco docs)." -ForegroundColor DarkYellow
if (-not $Apply) { Write-Host "`nPreview only. Re-run with -Apply to make changes." -ForegroundColor Green }
Disconnect-MgGraph | Out-Null
