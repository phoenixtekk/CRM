<#
.SYNOPSIS
    GWARB-Remediation.ps1 — open and assign remediation actions for each open drift/gap finding.
.DESCRIPTION
    PURPOSE
        Turns the Gap Register (from GWARB-Report.ps1) into tracked remediation actions: for each open
        drift or missing-decision-record finding it drafts an action item (owner, due date, required
        board decision) and, where you keep the ARB tracker as a Microsoft List, creates the item via
        Microsoft Graph. Defaults to -WhatIf so nothing is created until you review the plan and re-run
        with -Confirm. This script never changes a target-system configuration; it only records the
        governance actions the board has decided to pursue.
    HOW TO RUN
        Preview (default, no change):
            powershell -ExecutionPolicy Bypass -File .\GWARB-Remediation.ps1 -GapCsv C:\Temp\gap-register.csv
        Create the action items in the ARB Microsoft List (after review):
            powershell -ExecutionPolicy Bypass -File .\GWARB-Remediation.ps1 -GapCsv C:\Temp\gap-register.csv -SiteId your-site-id -ListId your-actions-list-id -Confirm
        Graph mode requires the Microsoft Graph PowerShell SDK and the Sites.ReadWrite.All scope.
        GapCsv columns: DesignId,Gate,State,Gap,Owner
    EXPECTED RESULTS
        In -WhatIf: the remediation actions that WOULD be opened, with owner and due date — no change.
        With -Confirm: a CSV action plan is written, and (in Graph mode) one list item is created per
        finding. Pass = every open gap has an owned, dated remediation action.
.NOTES
    White-label — the repeatable way. Read-only where it reads live systems.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][string]$GapCsv,
    [string]$SiteId,
    [string]$ListId,
    [int]$DueInDays = 10,
    [string]$OutDir = '.'
)

# Default to a preview unless the caller explicitly confirms.
if (-not $PSBoundParameters.ContainsKey('Confirm') -and -not $WhatIfPreference) { $WhatIfPreference = $true }

if (-not (Test-Path $GapCsv)) { Write-Host "Gap CSV not found: $GapCsv (columns: DesignId,Gate,State,Gap,Owner)" -ForegroundColor Red; exit 2 }
$gaps = Import-Csv $GapCsv
if (-not $gaps) { Write-Host "No open gaps to remediate." -ForegroundColor Green; exit 0 }

$useGraph = $SiteId -and $ListId
if ($useGraph) {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes 'Sites.ReadWrite.All' -NoWelcome
}

Write-Host "`n=== Remediation actions for open gaps ===" -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host "PREVIEW MODE (-WhatIf) — no actions will be created. Re-run with -Confirm to apply." -ForegroundColor Yellow }

$due  = (Get-Date).AddDays($DueInDays).ToString('yyyy-MM-dd')
$plan = @()
foreach ($g in $gaps) {
    $decision = if ($g.Gap -match 'drift') { 'Adjudicate drift: approve exception or require rework to standard' }
                else { 'Record the missing decision record and close the gate' }
    $action = [pscustomobject]@{
        DesignId       = $g.DesignId
        Gate           = $g.Gate
        Gap            = $g.Gap
        RequiredAction = $decision
        Owner          = if ($g.Owner) { $g.Owner } else { 'ARB Chair (reassign)' }
        Due            = $due
    }
    $plan += $action

    $target = "$($g.DesignId) [$($g.Gate)]"
    if ($PSCmdlet.ShouldProcess($target, "Open remediation action")) {
        if ($useGraph) {
            try {
                $body = @{ fields = @{
                    Title       = "Remediate $($g.DesignId)"
                    DesignId    = $g.DesignId
                    Gate        = $g.Gate
                    Action      = $decision
                    AssignedTo  = $action.Owner
                    DueDate     = $due
                    Status      = 'Open'
                } } | ConvertTo-Json -Depth 5
                Invoke-MgGraphRequest -Method POST -Uri "/v1.0/sites/$SiteId/lists/$ListId/items" -Body $body -ContentType 'application/json' | Out-Null
                Write-Host "  Opened action for $target" -ForegroundColor Green
            } catch {
                Write-Host "  FAILED for $target : $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "  Opened (plan only) action for $target" -ForegroundColor Green
        }
    } else {
        Write-Host "  WOULD open action for $target -> $decision (owner $($action.Owner), due $due)" -ForegroundColor DarkYellow
    }
}

if (-not $WhatIfPreference) {
    if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }
    $planPath = Join-Path $OutDir 'remediation-plan.csv'
    $plan | Export-Csv -Path $planPath -NoTypeInformation
    Write-Host ("`nSaved {0}" -f $planPath) -ForegroundColor Green
}
Write-Host ("`nOpen gaps processed: {0}" -f $gaps.Count) -ForegroundColor Cyan
if ($useGraph) { Disconnect-MgGraph | Out-Null }
