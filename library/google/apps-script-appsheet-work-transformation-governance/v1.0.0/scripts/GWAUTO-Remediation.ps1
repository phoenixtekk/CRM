<#
.SYNOPSIS
    GWAUTO-Remediation.ps1 — open owned, dated remediation actions for non-conformant automations.
.DESCRIPTION
    PURPOSE
        Turns the risk report (from GWAUTO-Report.ps1) or a findings CSV into tracked remediation
        actions: for each non-conformant automation — no owner, broad OAuth scope, external sharing,
        or missing sign-in — it drafts an action item (owner, due date, required fix) and, where you
        keep a governance tracker as a Microsoft List, creates the item via Microsoft Graph. Defaults
        to -WhatIf so nothing is created until you review the plan and re-run with -Confirm. It records
        the governance actions to take; it does not itself change an Apps Script/AppSheet setting.
    HOW TO RUN
        Preview (default, no change):
            powershell -ExecutionPolicy Bypass -File .\GWAUTO-Remediation.ps1 -FindingsCsv C:\Temp\automation-risk.csv
        Create the action items in a governance Microsoft List (after review):
            powershell -ExecutionPolicy Bypass -File .\GWAUTO-Remediation.ps1 -FindingsCsv C:\Temp\automation-risk.csv -SiteId your-site-id -ListId your-actions-list-id -Confirm
        Graph mode requires the Microsoft Graph PowerShell SDK and the Sites.ReadWrite.All scope.
        FindingsCsv columns: Platform,Name,Owner,Sharing,RiskScore,RiskBand (extra columns ignored).
    EXPECTED RESULTS
        In -WhatIf: the remediation actions that WOULD be opened, with owner, fix, and due date — no
        change. With -Confirm: a CSV action plan is written, and (in Graph mode) one list item is
        created per finding. Pass = every non-conformant automation has an owned, dated action.
.NOTES
    White-label — the repeatable way. Read-only where it reads live systems.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][string]$FindingsCsv,
    [string]$SiteId,
    [string]$ListId,
    [int]$DueInDays = 10,
    [string]$OutDir = '.'
)

# Default to a preview unless the caller explicitly confirms.
if (-not $PSBoundParameters.ContainsKey('Confirm') -and -not $WhatIfPreference) { $WhatIfPreference = $true }

if (-not (Test-Path $FindingsCsv)) {
    Write-Host "Findings CSV not found: $FindingsCsv (columns: Platform,Name,Owner,Sharing,RiskScore,RiskBand)" -ForegroundColor Red
    exit 2
}
$findings = Import-Csv $FindingsCsv | Where-Object { $_.RiskBand -in 'High','Medium' -or -not $_.Owner }
if (-not $findings) { Write-Host "No non-conformant automations to remediate." -ForegroundColor Green; exit 0 }

$useGraph = $SiteId -and $ListId
if ($useGraph) {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes 'Sites.ReadWrite.All' -NoWelcome
}

Write-Host "`n=== Remediation actions for non-conformant automations ===" -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host "PREVIEW MODE (-WhatIf) — no actions will be created. Re-run with -Confirm to apply." -ForegroundColor Yellow }

$due  = (Get-Date).AddDays($DueInDays).ToString('yyyy-MM-dd')
$plan = @()
foreach ($f in $findings) {
    $fixes = @()
    if ([string]::IsNullOrWhiteSpace($f.Owner))     { $fixes += 'Assign an owner of record' }
    if ($f.Sharing -in 'External','Anyone')         { $fixes += 'Restrict sharing to internal/approved domain or seek documented approval' }
    if ($f.RiskBand -eq 'High')                     { $fixes += 'Reduce OAuth scope to least-privilege / narrow connected source; route through Tier-2 review' }
    if (-not $fixes)                                { $fixes += 'Route through the review checklist before marking deployed' }
    $action = [pscustomobject]@{
        Platform       = $f.Platform
        Name           = $f.Name
        RiskBand       = $f.RiskBand
        RequiredFixes  = ($fixes -join '; ')
        Owner          = if ($f.Owner) { $f.Owner } else { 'Governance lead (reassign)' }
        Due            = $due
    }
    $plan += $action

    $target = "$($f.Platform): $($f.Name)"
    if ($PSCmdlet.ShouldProcess($target, "Open remediation action")) {
        if ($useGraph) {
            try {
                $body = @{ fields = @{
                    Title      = "Remediate $($f.Name)"
                    Platform   = $f.Platform
                    Artifact   = $f.Name
                    Fixes      = $action.RequiredFixes
                    AssignedTo = $action.Owner
                    DueDate    = $due
                    Status     = 'Open'
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
        Write-Host ("  WOULD open action for {0} -> {1} (owner {2}, due {3})" -f $target, $action.RequiredFixes, $action.Owner, $due) -ForegroundColor DarkYellow
    }
}

if (-not $WhatIfPreference) {
    if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }
    $planPath = Join-Path $OutDir 'automation-remediation-plan.csv'
    $plan | Export-Csv -Path $planPath -NoTypeInformation
    Write-Host ("`nSaved {0}" -f $planPath) -ForegroundColor Green
}
Write-Host ("`nNon-conformant automations processed: {0}" -f $findings.Count) -ForegroundColor Cyan
if ($useGraph) { Disconnect-MgGraph | Out-Null }
