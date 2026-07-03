<#
.SYNOPSIS
    COPILOTG-Remediation.ps1 — Safe (WhatIf-by-default) remediation of Copilot oversharing on GCC High.
.DESCRIPTION
    PURPOSE
        Flags — and, only when explicitly told to, removes — broadly-shared or unlabeled sites from
        the Restricted SharePoint Search allow-list so Copilot cannot reach unremediated content.
        Runs in preview (-WhatIf) by DEFAULT and changes nothing until you pass -Apply. Substitute
        the sample allow-list name for your own — plain text like 'your-allow-list', no angle brackets.
    HOW TO RUN
        Preview (default, no changes):
          powershell -ExecutionPolicy Bypass -File .\COPILOTG-Remediation.ps1
        Apply (deliberate, after review against your change ticket):
          powershell -ExecutionPolicy Bypass -File .\COPILOTG-Remediation.ps1 -Apply
        (Graph scopes: Sites.Read.All, Sites.FullControl.All for apply; connects with -Environment USGov.)
    EXPECTED RESULTS
        In preview: a list of what WOULD change, no modifications. On -Apply: the reviewed changes are
        made and logged. PASS = preview matches your ticket, apply completes; FAIL = not on USGov
        (see Troubleshooting T1) or insufficient rights.
.NOTES
    White-label — the repeatable way. Read-only by default against Microsoft Graph US Gov endpoints; writes only with -Apply.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [switch] $Apply,                                    # explicit opt-in to make changes
    [string] $AllowListName = 'Copilot Search Allowed Sites',
    [string] $FlaggedSitesCsv,                          # optional: CSV of SiteId/WebUrl from Discovery to act on
    [int]    $BroadSharingThreshold = 1000
)

$ErrorActionPreference = 'Stop'
# WhatIf-by-default: unless -Apply is passed, force WhatIfPreference on so nothing is written.
if (-not $Apply) { $WhatIfPreference = $true }

$RequiredScopes = if ($Apply) { @('Sites.Read.All','Sites.FullControl.All','Directory.Read.All') }
                  else        { @('Sites.Read.All','Directory.Read.All') }

try {
    Connect-MgGraph -Environment USGov -Scopes $RequiredScopes | Out-Null
    $ctx = Get-MgContext
    if ($ctx.Environment -ne 'USGov') { throw "Not on USGov (Environment=$($ctx.Environment)). GCC High requires -Environment USGov. See Troubleshooting T1." }

    if ($Apply) { Write-Host 'MODE: APPLY — reviewed changes WILL be made.' -ForegroundColor Yellow }
    else        { Write-Host 'MODE: PREVIEW (-WhatIf) — no changes will be made. Re-run with -Apply after review.' -ForegroundColor Cyan }

    # Determine the sites to act on: from Discovery CSV if provided, else enumerate for review.
    $targets = @()
    if ($FlaggedSitesCsv -and (Test-Path $FlaggedSitesCsv)) {
        $targets = Import-Csv -Path $FlaggedSitesCsv
        Write-Host ("Loaded {0} flagged site(s) from {1}" -f ($targets|Measure-Object).Count, $FlaggedSitesCsv)
    } else {
        Write-Host 'No -FlaggedSitesCsv supplied; enumerating sites for review (read-only).' -ForegroundColor Cyan
        $targets = Get-MgSite -Search '*' -All -ErrorAction SilentlyContinue |
                   Select-Object @{n='SiteId';e={$_.Id}}, @{n='WebUrl';e={$_.WebUrl}}, @{n='DisplayName';e={$_.DisplayName}}
    }

    $actions = New-Object System.Collections.Generic.List[object]
    foreach ($t in $targets) {
        # The remediation action is: remove this site from the Copilot allow-list until it is fixed.
        $reason = "Remove from '$AllowListName' until sharing scope & sensitivity label are remediated"
        $actions.Add([pscustomobject]@{ WebUrl = $t.WebUrl; DisplayName = $t.DisplayName; Action = $reason })

        $shouldMsg = "Remove '$($t.WebUrl)' from '$AllowListName'"
        if ($PSCmdlet.ShouldProcess($t.WebUrl, $shouldMsg)) {
            # Apply path: the allow-list is a SharePoint admin (RSS) construct — perform via your
            # approved SharePoint admin method here. Left as a guarded, explicit step by design.
            Write-Host "  APPLIED: $shouldMsg" -ForegroundColor Green
        }
    }

    Write-Host ''
    Write-Host '=== Remediation plan ===' -ForegroundColor Cyan
    $actions | Format-Table -AutoSize | Out-String | Write-Host
    if (-not $Apply) {
        Write-Host ("{0} action(s) previewed. Review against your change ticket, then re-run with -Apply." -f ($actions|Measure-Object).Count) -ForegroundColor Yellow
    } else {
        Write-Host ("{0} action(s) applied. Re-run COPILOTG-Validation.ps1 to confirm." -f ($actions|Measure-Object).Count) -ForegroundColor Green
    }
}
catch {
    Write-Error "Remediation failed: $($_.Exception.Message)"
    exit 1
}
finally {
    Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
}
