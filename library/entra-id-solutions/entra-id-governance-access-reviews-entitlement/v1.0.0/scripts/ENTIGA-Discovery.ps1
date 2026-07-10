<#
.SYNOPSIS
    ENTIGA-Discovery.ps1 — inventory Entra ID Governance objects (read-only, Microsoft Graph).
.DESCRIPTION
    PURPOSE
        Baselines the current governance posture: entitlement-management catalogs, access packages and
        their assignment policies, access review definitions, and lifecycle workflows. Run before you
        configure anything to see your starting point (usually near-empty on a new tenant).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ENTIGA-Discovery.ps1 -CsvFolder C:\Temp\entiga
        Requires the Microsoft Graph SDK and the read scopes below (consented on first run).
    EXPECTED RESULTS
        Console tables for catalogs, packages+policies, access reviews, and workflows, plus optional
        CSVs. PASS = the objects you built (ENTIGA - *) appear with the expected configuration.
.NOTES
    White-label — Entra ID Solutions. Read-only against Microsoft Graph. No credentials stored.
.EXAMPLE
    .\ENTIGA-Discovery.ps1
#>
[CmdletBinding()] param([string]$CsvFolder)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'EntitlementManagement.Read.All','AccessReview.Read.All','LifecycleWorkflows.Read.All' -NoWelcome

function Get-AllPages([string]$Uri) {
    $items = @()
    do { $r = Invoke-MgGraphRequest -Method GET -Uri $Uri; $items += $r.value; $Uri = $r.'@odata.nextLink' } while ($Uri)
    return $items
}
function Save-Csv($rows, $name) {
    if ($CsvFolder -and $rows) {
        if (-not (Test-Path $CsvFolder)) { New-Item -ItemType Directory -Path $CsvFolder | Out-Null }
        $p = Join-Path $CsvFolder "$name.csv"; $rows | Export-Csv -Path $p -NoTypeInformation
        Write-Host "  saved $p" -ForegroundColor Green
    }
}

# --- Catalogs ------------------------------------------------------------------
Write-Host "`n=== Entitlement management: Catalogs ===" -ForegroundColor Cyan
$catalogs = Get-AllPages "/v1.0/identityGovernance/entitlementManagement/catalogs"
$catRows = $catalogs | ForEach-Object {
    [pscustomobject]@{ Catalog=$_.displayName; State=$_.state; ExternalUsers=$_.isExternallyVisible; Id=$_.id }
}
if ($catRows) { $catRows | Format-Table -AutoSize } else { Write-Host "  (none)" -ForegroundColor Yellow }
Save-Csv $catRows 'catalogs'

# --- Access packages + policies ------------------------------------------------
Write-Host "`n=== Access packages + assignment policies ===" -ForegroundColor Cyan
$pkgs = Get-AllPages "/v1.0/identityGovernance/entitlementManagement/accessPackages?`$expand=assignmentPolicies"
$pkgRows = @()
foreach ($p in $pkgs) {
    if (-not $p.assignmentPolicies -or $p.assignmentPolicies.Count -eq 0) {
        $pkgRows += [pscustomobject]@{ Package=$p.displayName; Policy='(no policy)'; ApprovalRequired=''; ExpiryDays=''; RequestorScope='' }
        continue
    }
    foreach ($pol in $p.assignmentPolicies) {
        $exp = $pol.expiration.duration; if (-not $exp) { $exp = $pol.expiration.type }
        $pkgRows += [pscustomobject]@{
            Package         = $p.displayName
            Policy          = $pol.displayName
            ApprovalRequired= $pol.requestApprovalSettings.isApprovalRequired
            ExpiryDays      = $exp
            RequestorScope  = $pol.requestorSettings.scopeType
        }
    }
}
if ($pkgRows) { $pkgRows | Format-Table -AutoSize } else { Write-Host "  (none)" -ForegroundColor Yellow }
Save-Csv $pkgRows 'access-packages'

# --- Access review definitions -------------------------------------------------
Write-Host "`n=== Access review definitions ===" -ForegroundColor Cyan
$reviews = Get-AllPages "/v1.0/identityGovernance/accessReviews/definitions"
$revRows = $reviews | ForEach-Object {
    [pscustomobject]@{
        Review     = $_.displayName
        Status     = $_.status
        AutoApply  = $_.settings.autoApplyDecisionsEnabled
        NoResponse = $_.settings.defaultDecision
        Recurrence = $_.settings.recurrence.pattern.type
    }
}
if ($revRows) { $revRows | Format-Table -AutoSize } else { Write-Host "  (none)" -ForegroundColor Yellow }
Save-Csv $revRows 'access-reviews'

# --- Lifecycle workflows -------------------------------------------------------
Write-Host "`n=== Lifecycle workflows ===" -ForegroundColor Cyan
$wfs = Get-AllPages "/v1.0/identityGovernance/lifecycleWorkflows/workflows"
$wfRows = $wfs | ForEach-Object {
    [pscustomobject]@{ Workflow=$_.displayName; Category=$_.category; Enabled=$_.isEnabled; Tasks=($_.tasks.Count); Trigger=$_.executionConditions.'@odata.type' }
}
if ($wfRows) { $wfRows | Format-Table -AutoSize } else { Write-Host "  (none)" -ForegroundColor Yellow }
Save-Csv $wfRows 'workflows'

Write-Host ("`nSummary: {0} catalogs | {1} packages | {2} reviews | {3} workflows" -f `
    $catalogs.Count, $pkgs.Count, $reviews.Count, $wfs.Count) -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
