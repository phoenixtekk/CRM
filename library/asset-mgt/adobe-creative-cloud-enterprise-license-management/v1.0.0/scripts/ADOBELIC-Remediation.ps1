<#
.SYNOPSIS
    ADOBELIC-Remediation.ps1 — flag (and optionally action) Adobe reclaim and downsize candidates.
.DESCRIPTION
    PURPOSE
        Reads the right-sizing register and lists the approved reclaim and downsize candidates. By
        default it runs in -WhatIf mode and changes nothing — it only shows what would be actioned.
        A removal is only ever attempted for rows that have a ConfirmationOwner recorded, and only
        when -WhatIf is explicitly disabled. This protects active users from losing access.
    HOW TO RUN
        Preview (default, no changes):
          powershell -ExecutionPolicy Bypass -File .\ADOBELIC-Remediation.ps1 -RegisterPath .\Right-Sizing-Register-Pilot-Validate.csv
        Execute approved removals (explicit):
          powershell -ExecutionPolicy Bypass -File .\ADOBELIC-Remediation.ps1 -RegisterPath .\Right-Sizing-Register-Pilot-Validate.csv -WhatIf:$false
    EXPECTED RESULTS
        In preview: a list of the seats that WOULD be reclaimed/downsized (only those with an owner).
        In execute: the same list with each removal attempted via the Adobe User Management API.
.NOTES
    White-label SAM tooling. Defaults to -WhatIf (safe).
    Adobe specifics: the actual remove-user-from-product-profile call is deferred to Adobe's official
    User Management API documentation. Complete Invoke-AdobeRemoveAssignment below per that doc; do not
    store secrets in this file. If no tested write path exists, perform removals in the Admin Console.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][string]$RegisterPath,
    [switch]$WhatIf = $true
)

if (-not (Test-Path $RegisterPath)) { throw "Register not found: $RegisterPath (run ADOBELIC-Validation.ps1)" }
$reg = Import-Csv -Path $RegisterPath

$candidates = $reg | Where-Object { $_.RecommendedAction -in @('reclaim','downsize') }
$approved   = $candidates | Where-Object { $_.ConfirmationOwner -and $_.ConfirmationOwner.Trim() }
$unapproved = $candidates | Where-Object { -not ($_.ConfirmationOwner -and $_.ConfirmationOwner.Trim()) }

Write-Host "=== ADOBELIC Remediation ===" -ForegroundColor Cyan
Write-Host ("Candidates: {0}   Approved (have ConfirmationOwner): {1}   Unapproved (skipped): {2}" -f $candidates.Count, $approved.Count, $unapproved.Count)
if ($unapproved.Count) { Write-Host "Unapproved rows are SKIPPED — add a ConfirmationOwner to action them." -ForegroundColor Yellow }

function Invoke-AdobeRemoveAssignment {
    # ADOBE-SPECIFIC: implement the remove-user-from-product-profile call here per Adobe's official
    # Adobe User Management API documentation. Read credentials from the environment. Do not invent
    # an endpoint — this stub blocks accidental changes until the call is completed.
    param([string]$User, [string]$ProductProfile, [string]$Action)
    throw "Adobe write call not implemented — complete Invoke-AdobeRemoveAssignment per Adobe's documentation, or perform the removal in the Admin Console."
}

foreach ($c in $approved) {
    $desc = "$($c.RecommendedAction) '$($c.User)' from profile '$($c.ProductProfile)'"
    if ($WhatIf) {
        Write-Host ("  [WhatIf] WOULD {0}  (owner: {1})" -f $desc, $c.ConfirmationOwner) -ForegroundColor Yellow
    }
    elseif ($PSCmdlet.ShouldProcess($c.User, $desc)) {
        try { Invoke-AdobeRemoveAssignment -User $c.User -ProductProfile $c.ProductProfile -Action $c.RecommendedAction; Write-Host ("  DONE: {0}" -f $desc) -ForegroundColor Green }
        catch { Write-Host ("  SKIPPED ({0}): {1}" -f $desc, $_.Exception.Message) -ForegroundColor Yellow }
    }
}

if ($WhatIf) { Write-Host "`nPreview only — no changes made. Re-run with -WhatIf:`$false to execute approved removals." -ForegroundColor Green }
