<#
.SYNOPSIS
    IPDKE-Remediation.ps1 — safely fix low-risk DKE publishing gaps (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Remediates only the safe, low-risk gap in a DKE rollout: enabling a DKE label policy that
        exists but is disabled. It NEVER creates or alters Double Key Encryption on a label, never
        changes the endpoint URL, and never touches the key service or the Entra app registration —
        those are deliberate portal / infrastructure decisions. Runs in -WhatIf by default; pass
        -Apply to make the single safe change.
    HOW TO RUN
        Preview (safe, default): powershell -ExecutionPolicy Bypass -File .\IPDKE-Remediation.ps1
        Apply:                   powershell -ExecutionPolicy Bypass -File .\IPDKE-Remediation.ps1 -Apply
        Sign in as a Compliance Administrator (or Information Protection Admin) when prompted.
    EXPECTED RESULTS
        Reports whether the DKE label policy exists and is enabled; in -Apply it enables a
        published-but-disabled policy. If the label or policy is missing, it points to the
        Implementation Guide step to create it (never auto-creates DKE encryption).
.NOTES
    White-label — Purview Solutions. Default is a dry run. No secrets. Never enables/edits DKE
    encryption on a label. Uses Get-/Set-LabelPolicy and reads Get-Label.
#>
[CmdletBinding()] param(
    [switch]$Apply,
    [string]$LabelName  = 'Sensitivity Label - Ultra Confidential (DKE) - Named Group',
    [string]$PolicyName = 'Label Policy - DKE Ultra Confidential - DKE Pilot'
)
$WhatIf = -not $Apply
$mode = $(if($WhatIf){'WHATIF (preview only)'}else{'APPLY'})

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

Write-Host ("`n=== DKE remediation [{0}] ===" -f $mode) -ForegroundColor Cyan

# 0. Report the DKE label (never auto-create or alter its encryption)
$label = Get-Label -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq $LabelName } | Select-Object -First 1
if ($label) {
    Write-Host ("  DKE label '{0}' exists (encryption enabled: {1})." -f $LabelName,[bool]$label.EncryptionEnabled) -ForegroundColor Green
} else {
    Write-Host ("  DKE label '{0}' not found — create it in the portal (Implementation Step 6). This script never creates DKE encryption." -f $LabelName) -ForegroundColor Yellow
}

# 1. Enable the label policy if it exists but is disabled (the only safe auto-fix)
$pol = Get-LabelPolicy -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $PolicyName } | Select-Object -First 1
if ($pol) {
    if (-not $pol.Enabled) {
        Write-Host ("  Label policy '{0}' is disabled -> enable it." -f $PolicyName) -ForegroundColor Yellow
        if (-not $WhatIf) {
            Set-LabelPolicy -Identity $PolicyName -Enabled $true
            Write-Host "    enabled." -ForegroundColor Green
        }
    } else {
        Write-Host ("  Label policy '{0}' already enabled — no action." -f $PolicyName) -ForegroundColor Green
    }
} else {
    Write-Host ("  Label policy '{0}' not found — publish the label (Implementation Step 7)." -f $PolicyName) -ForegroundColor Yellow
}

Write-Host "`n  NOTE: this script never creates/edits DKE encryption, the endpoint URL, the key service, or the app registration." -ForegroundColor Yellow
if ($WhatIf) { Write-Host "`nPreview only. Re-run with -Apply to make the change above." -ForegroundColor Cyan }
else         { Write-Host "`nRemediation applied. Re-run IPDKE-Validation.ps1 to confirm." -ForegroundColor Green }

Disconnect-ExchangeOnline -Confirm:$false | Out-Null
