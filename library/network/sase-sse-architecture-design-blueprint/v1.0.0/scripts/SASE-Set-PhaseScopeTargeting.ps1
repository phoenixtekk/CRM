<#
.SYNOPSIS
    SASE-Set-PhaseScopeTargeting.ps1 - Phase-scope targeting-group builder (default -WhatIf).

    PURPOSE:
        Creates and maintains the named Microsoft Entra security groups that scope each roadmap phase
        and its pilot, per the blueprint naming convention "<Purpose> - <Scope> - <Stage>":
            SASE Phase Scope - Baseline - Pilot / - Broad
            SASE Phase Scope - SWG      - Pilot / - Broad
            SASE Phase Scope - CASB     - Pilot / - Broad
            SASE Phase Scope - ZTNA     - Pilot / - Broad
            SASE Phase Scope - DataHook - Pilot / - Broad
        These groups drive phased adoption, the pilot gate, and identity-based policy targeting
        (Requirement R8 / global requirement G6). The script is idempotent: existing groups are left
        as-is. It is SAFE BY DEFAULT (-WhatIf); pass -Apply to create.

        Group membership is populated separately (SASE-Remediation.ps1 -Mode AddPilotMembers, or your
        normal group-management process). Netskope-side policy that consumes these groups is configured
        in the Netskope console per Netskope documentation.

    HOW TO RUN:
        Install once:  Install-Module Microsoft.Graph -Scope CurrentUser

        # Preview all phase groups (default, no changes):
        .\SASE-Set-PhaseScopeTargeting.ps1
        # Create all phase groups:
        .\SASE-Set-PhaseScopeTargeting.ps1 -Apply
        # Only one phase:
        .\SASE-Set-PhaseScopeTargeting.ps1 -Scope ZTNA -Apply

    EXPECTED RESULTS:
        Without -Apply: a "WOULD CREATE" / "EXISTS" line per group and no changes. With -Apply: missing
        groups are created (with confirmation) and reported; existing ones are skipped. A summary of
        created/existing/failed groups prints at the end.

.NOTES
    Network Solutions - safe by default (-WhatIf). The repeatable way.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [ValidateSet('Baseline','SWG','CASB','ZTNA','DataHook','All')]
    [string]$Scope = 'All',
    [string]$GroupNamePrefix = "SASE Phase Scope",
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$created = 0; $exists = 0; $failed = 0

if (-not $Apply) { $WhatIfPreference = $true }

$scopes = if ($Scope -eq 'All') { @('Baseline','SWG','CASB','ZTNA','DataHook') } else { @($Scope) }

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
                New-MgGroup -DisplayName $name -Description "SASE/SSE phase-scope targeting group ($sc / $stage)." `
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
Write-Host "Next: populate Pilot membership (SASE-Remediation.ps1 -Mode AddPilotMembers), then target these groups in Netskope policy (per Netskope docs)." -ForegroundColor Yellow
