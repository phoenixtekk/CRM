<#
.SYNOPSIS
    TUNMAMG-Remediation.ps1 — Safely remediate common Microsoft Tunnel for MAM misconfigurations on a GCC High / DoD tenant.
.DESCRIPTION
    PURPOSE
        Proposes and (only with -Commit) applies safe fixes to a Microsoft Tunnel for MAM deployment
        on a US sovereign-cloud (GCC High / DoD) tenant. It aligns assignment groups across the three
        Android MAM policies to a chosen group and flags duplicate Defender app-config policies. It
        never deletes Tunnel gateway infrastructure, sites, or server configurations. Defaults to
        -WhatIf: nothing changes until you pass -Commit. Replace placeholders like your-tenant-id and
        the pilot group name with real values.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\TUNMAMG-Remediation.ps1                 # preview (WhatIf)
        powershell -ExecutionPolicy Bypass -File .\TUNMAMG-Remediation.ps1 -Commit         # apply
        (Graph scopes: DeviceManagementApps.ReadWrite.All, Group.Read.All.
         Uses -Environment USGov for GCC High; pass -Environment USGovDoD for DoD.)
    EXPECTED RESULTS
        A list of proposed actions. Without -Commit, no change is made (WhatIf). With -Commit, the
        approved actions are applied and confirmed. PASS = actions previewed/applied cleanly.
.NOTES
    White-label — the repeatable way. Read-only unless -Commit is supplied; targets Microsoft Graph US Gov endpoints.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [ValidateSet('USGov', 'USGovDoD')]
    [string]$Environment = 'USGov',

    # Name of the Entra group the three Android MAM policies should all target.
    [string]$TargetGroupName = 'GRP-TUNMAMG-Pilot',

    # Apply changes. Omit for a safe WhatIf preview.
    [switch]$Commit
)

$ErrorActionPreference = 'Stop'
# Default to WhatIf preview unless -Commit is explicitly supplied.
if (-not $Commit) { $WhatIfPreference = $true }

function Connect-GovGraph {
    param([string]$Env)
    $scopes = @('DeviceManagementApps.ReadWrite.All', 'Group.Read.All')
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph PowerShell SDK not found. Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Write-Host "Connecting to Microsoft Graph (US Gov environment: $Env)..." -ForegroundColor Cyan
    Connect-MgGraph -Environment $Env -Scopes $scopes | Out-Null
    return Get-MgContext
}

function Invoke-GraphGet {
    param([string]$Uri)
    try { return Invoke-MgGraphRequest -Method GET -Uri $Uri -ErrorAction Stop }
    catch { Write-Warning "GET $Uri failed: $($_.Exception.Message)"; return $null }
}

try {
    $ctx   = Connect-GovGraph -Env $Environment
    $base  = if ($Environment -eq 'USGovDoD') { 'https://dod-graph.microsoft.us/beta' } else { 'https://graph.microsoft.us/beta' }
    $gbase = if ($Environment -eq 'USGovDoD') { 'https://dod-graph.microsoft.us/v1.0' } else { 'https://graph.microsoft.us/v1.0' }

    if ($ctx.Environment -notmatch 'USGov') { throw "Not a US Gov Graph context (Environment=$($ctx.Environment)). Reconnect with -Environment USGov/USGovDoD." }

    Write-Host ("Mode: {0}" -f $(if ($Commit) { 'COMMIT (changes will be applied)' } else { 'WHATIF (preview only)' })) -ForegroundColor $(if ($Commit) { 'Yellow' } else { 'Green' })

    # Resolve target group id
    $grp = Invoke-GraphGet "$gbase/groups?`$filter=displayName eq '$TargetGroupName'"
    $targetGroupId = ($grp.value | Select-Object -First 1).id
    if (-not $targetGroupId) {
        Write-Warning "Target group '$TargetGroupName' not found. Create it with TUNMAMG-Set-ScopeTargeting.ps1 first."
    } else {
        Write-Host "Target group '$TargetGroupName' id=$targetGroupId" -ForegroundColor Cyan
    }

    # Gather Android policies
    $appCfg = (Invoke-GraphGet "$base/deviceAppManagement/targetedManagedAppConfigurations").value
    $andAp  = (Invoke-GraphGet "$base/deviceAppManagement/androidManagedAppProtections").value
    $defAnd  = @($appCfg | Where-Object { $_.displayName -eq 'AC-TUNMAMG-Defender-Android' })
    $edgeAnd = @($appCfg | Where-Object { $_.displayName -eq 'AC-TUNMAMG-Edge-Android' })
    $apAnd   = @($andAp  | Where-Object { $_.displayName -eq 'AP-TUNMAMG-Edge-Android' })

    # FINDING 1 — duplicate Defender app-config policies (report only; deletion is a human decision)
    if ($defAnd.Count -gt 1) {
        Write-Host "`n[FINDING] $($defAnd.Count) Defender app-config policies named 'AC-TUNMAMG-Defender-Android' exist." -ForegroundColor Red
        Write-Host " Multiple Defender policies with different Sites cause a race condition (see 06-troubleshooting.md)."
        Write-Host " This script will NOT auto-delete policies. Review and remove duplicates manually in intune.microsoft.us."
        $defAnd | ForEach-Object { Write-Host ("   - id: {0}" -f $_.id) }
    } else {
        Write-Host "`n[OK] Single (or zero) Defender app-config policy present." -ForegroundColor Green
    }

    # FINDING 2 — align assignment groups across the three Android policies
    if ($targetGroupId) {
        $policyMap = @(
            @{ Name = 'AC-TUNMAMG-Defender-Android'; Segment = 'targetedManagedAppConfigurations'; Obj = ($defAnd  | Select-Object -First 1) },
            @{ Name = 'AC-TUNMAMG-Edge-Android';     Segment = 'targetedManagedAppConfigurations'; Obj = ($edgeAnd | Select-Object -First 1) },
            @{ Name = 'AP-TUNMAMG-Edge-Android';     Segment = 'androidManagedAppProtections';     Obj = ($apAnd   | Select-Object -First 1) }
        )
        foreach ($p in $policyMap) {
            if (-not $p.Obj) { Write-Warning "Policy '$($p.Name)' not found — skipping."; continue }
            $assignUri = "$base/deviceAppManagement/$($p.Segment)/$($p.Obj.id)/assign"
            $body = @{
                assignments = @(
                    @{ target = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $targetGroupId } }
                )
            } | ConvertTo-Json -Depth 6

            if ($PSCmdlet.ShouldProcess("$($p.Name)", "Set assignment -> group '$TargetGroupName'")) {
                try {
                    Invoke-MgGraphRequest -Method POST -Uri $assignUri -Body $body -ContentType 'application/json' -ErrorAction Stop | Out-Null
                    Write-Host "[APPLIED] $($p.Name) now targets '$TargetGroupName'." -ForegroundColor Green
                }
                catch { Write-Warning "Failed to assign $($p.Name): $($_.Exception.Message)" }
            }
        }
    }

    Write-Host "`nRemediation run complete ($(if ($Commit) { 'COMMIT' } else { 'WHATIF' }))." -ForegroundColor Green
    if (-not $Commit) { Write-Host "No changes were made. Re-run with -Commit to apply." -ForegroundColor Yellow }
}
catch {
    Write-Error "Remediation failed: $($_.Exception.Message)"
    exit 1
}
finally {
    if (Get-MgContext -ErrorAction SilentlyContinue) { Disconnect-MgGraph | Out-Null }
}
