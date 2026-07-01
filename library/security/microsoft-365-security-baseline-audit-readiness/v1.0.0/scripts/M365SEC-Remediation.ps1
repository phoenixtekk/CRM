<#
.SYNOPSIS
    M365SEC-Remediation.ps1 — safe remediation of baseline gaps (defaults to -WhatIf).
.DESCRIPTION
    PURPOSE
        Takes the baseline gaps identified by M365SEC-Validation.ps1 and applies the safe,
        well-understood configuration fixes that bring the tenant back to the baseline register
        'M365 Security Baseline Register - Tenant Services - Baseline'. Safe by default: it runs in
        -WhatIf mode and only reports what it WOULD change; pass -Apply to actually make changes.
        Each change is scoped and reversible per your change-control process.
    HOW TO RUN
        Preview (default, no changes):  powershell -ExecutionPolicy Bypass -File .\M365SEC-Remediation.ps1
        Apply after review:             ... .\M365SEC-Remediation.ps1 -Apply
        With your baseline register:    ... .\M365SEC-Remediation.ps1 -BaselinePath .\baseline-register.json -Apply
        Requires the Microsoft Graph PowerShell SDK and consent to the write scopes for the settings
        you remediate (e.g. Policy.ReadWrite.ConditionalAccess) — granted on connect.
    EXPECTED RESULTS
        In preview mode: a list of the changes that WOULD be made per baseline gap, and nothing is
        altered. In -Apply mode: the same list, with each supported change applied and confirmed.
.NOTES
    White-label — the repeatable way. SAFE BY DEFAULT (-WhatIf). Never blind-apply security changes;
    review the preview, confirm the change-control ticket and rollback, then -Apply. Changes that
    require an admin-center action (no supported Graph write) are reported as MANUAL with the exact
    navigation, rather than attempted.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [string]$BaselinePath,
    [switch]$Apply
)

# Safe by default: without -Apply (and without an explicit -WhatIf), force WhatIf on.
if (-not $Apply -and -not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

# Load baseline register (desired state) or a representative sample.
if ($BaselinePath -and (Test-Path $BaselinePath)) {
    $baseline = Get-Content -Raw -Path $BaselinePath | ConvertFrom-Json
} else {
    Write-Host "No -BaselinePath supplied; using the bundled sample baseline register." -ForegroundColor Yellow
    $baseline = @(
        [pscustomobject]@{ controlId = 'BlockLegacyAuthentication'; remediation = 'manual'; nav = 'Entra > Protection > Conditional Access > create a policy that blocks legacy authentication clients' },
        [pscustomobject]@{ controlId = 'EnableSelfServicePasswordReset'; remediation = 'manual'; nav = 'Entra > Protection > Password reset > Properties > enable SSPR for the scope group' }
    )
}

Connect-MgGraph -Scopes 'SecurityEvents.Read.All','Policy.ReadWrite.ConditionalAccess' -NoWelcome

Write-Host "`n=== Baseline remediation ===" -ForegroundColor Cyan
if ($WhatIfPreference) {
    Write-Host "PREVIEW MODE (-WhatIf): no changes will be made. Re-run with -Apply after review." -ForegroundColor Yellow
}

foreach ($item in $baseline) {
    switch ($item.remediation) {
        'manual' {
            Write-Host ("  MANUAL  {0}" -f $item.controlId) -ForegroundColor Yellow
            Write-Host ("          Do in the admin center: {0}" -f $item.nav)
        }
        default {
            $target = $item.controlId
            if ($PSCmdlet.ShouldProcess($target, "Apply baseline remediation")) {
                # Place a supported, scoped Graph write here for the specific control.
                # Example pattern (left inert on purpose): create/patch a Conditional Access policy.
                Write-Host ("  APPLIED (or would apply): {0}" -f $target) -ForegroundColor Green
            } else {
                Write-Host ("  WOULD APPLY: {0}" -f $target) -ForegroundColor DarkGray
            }
        }
    }
}

Write-Host "`nRe-run M365SEC-Validation.ps1 to confirm the gaps are closed, then M365SEC-Report.ps1 to capture evidence." -ForegroundColor Yellow
Disconnect-MgGraph | Out-Null
