<#
.SYNOPSIS
    GWCONSOL-Set-ScopeTargeting.ps1 — Consolidation wave-scope targeting-group builder (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Creates and maintains the named Microsoft Entra security groups that scope each consolidation
        wave and its pilot, per the naming convention "<Purpose> - <Scope> - <Stage>":
            Consolidation Wave Scope - Baseline - Pilot / - Broad
            Consolidation Wave Scope - Collab   - Pilot / - Broad
            Consolidation Wave Scope - AI       - Pilot / - Broad
            Consolidation Wave Scope - Identity - Pilot / - Broad
            Consolidation Wave Scope - Decommission - Pilot / - Broad
        These groups drive waved consolidation, the pilot gate, and coexistence/decommission tracking.
        The script is idempotent: existing groups are left as-is. It is SAFE BY DEFAULT (-WhatIf); pass
        -Apply to create. Membership is populated separately (GWCONSOL-Remediation.ps1 -Mode
        AddPilotMembers, or your normal group-management process).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWCONSOL-Set-ScopeTargeting.ps1
        Required Graph scope: Group.ReadWrite.All (needed only to apply; preview still connects).
        Install once: Install-Module Microsoft.Graph -Scope CurrentUser
          Preview all wave groups (default, no changes):  .\GWCONSOL-Set-ScopeTargeting.ps1
          Create all wave groups:                         .\GWCONSOL-Set-ScopeTargeting.ps1 -Apply
          Only one wave:                                  .\GWCONSOL-Set-ScopeTargeting.ps1 -Scope AI -Apply
    EXPECTED RESULTS
        Without -Apply: a "WOULD CREATE" / "EXISTS" line per group and no changes. With -Apply: missing
        groups are created (with confirmation) and reported; existing ones are skipped. A summary of
        created/existing/failed groups prints at the end.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [ValidateSet('Baseline','Collab','AI','Identity','Decommission','All')]
    [string]$Scope = 'All',
    [string]$GroupNamePrefix = "Consolidation Wave Scope",
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$created = 0; $exists = 0; $failed = 0

if (-not $Apply) { $WhatIfPreference = $true }

$scopes = if ($Scope -eq 'All') { @('Baseline','Collab','AI','Identity','Decommission') } else { @($Scope) }

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes "Group.ReadWrite.All" -NoWelcome

function Get-GroupByName {
    param([string]$Name)
    Get-MgGroup -Filter "displayName eq '$Name'" -All -ErrorAction Stop | Select-Object -First 1
}

foreach ($sc in $scopes) {
    foreach ($stage in @('Pilot','Broad')) {
        $name = "$GroupNamePrefix - $sc - $stage"
        try {
            if (Get-GroupByName -Name $name) {
                Write-Host ("EXISTS: {0}" -f $name) -ForegroundColor DarkGray
                $exists++
                continue
            }
            if ($PSCmdlet.ShouldProcess($name, "Create Entra security group")) {
                $mailNick = ($name -replace '[^a-zA-Z0-9]', '')
                New-MgGroup -DisplayName $name -Description "Consolidation wave-scope targeting group ($sc / $stage)." `
                    -SecurityEnabled:$true -MailEnabled:$false -MailNickname $mailNick -GroupTypes @() -ErrorAction Stop | Out-Null
                Write-Host ("CREATED: {0}" -f $name) -ForegroundColor Green
                $created++
            } else {
                Write-Host ("WOULD CREATE: {0}" -f $name) -ForegroundColor Yellow
            }
        } catch {
            Write-Host ("FAILED: {0} :: {1}" -f $name, $_.Exception.Message) -ForegroundColor Red
            $failed++
        }
    }
}

Disconnect-MgGraph | Out-Null

Write-Host ("`nSummary - Created: {0}  Existing: {1}  Failed: {2}" -f $created, $exists, $failed) -ForegroundColor Cyan
if (-not $Apply) { Write-Host "Preview only. Re-run with -Apply to create the groups." -ForegroundColor Yellow }
Write-Host "Next: populate Pilot membership (GWCONSOL-Remediation.ps1 -Mode AddPilotMembers), then use these groups to scope each consolidation wave." -ForegroundColor Yellow
