<#
.SYNOPSIS
    IPDKE-Discovery.ps1 — inventory sensitivity labels and flag Double Key Encryption (DKE) use. Read-only.
.DESCRIPTION
    PURPOSE
        Connects to Security & Compliance PowerShell and reports the tenant's sensitivity labels,
        highlighting which ones use encryption and, specifically, which use Double Key Encryption
        (with the configured DKE endpoint URL), plus the label policies that publish them. This is the
        "what exists today" read used to plan or validate a DKE rollout. It changes nothing.
    HOW TO RUN
        Install-Module ExchangeOnlineManagement -Scope CurrentUser
        powershell -ExecutionPolicy Bypass -File .\IPDKE-Discovery.ps1
        Sign in as a Compliance Administrator (or Information Protection Admin) when prompted.
    EXPECTED RESULTS
        A list of sensitivity labels (name, priority, encryption on/off), a DKE section listing any
        labels whose encryption is Double Key Encryption and their endpoint URLs, and the label
        policies (name, enabled). If no DKE label exists yet, that is reported as a normal starting
        state.
.NOTES
    White-label — Purview Solutions. Read-only. No secrets. Does not modify any label or policy.
    Uses Get-Label / Get-LabelPolicy. The DKE endpoint URL is read from the label's DKE property when
    present; property names can vary by tenant/module version — verify against Microsoft's current docs.
#>
[CmdletBinding()] param()

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

Write-Host "`n=== Double Key Encryption — configuration discovery ===" -ForegroundColor Cyan

$labels = Get-Label -ErrorAction SilentlyContinue

Write-Host "`n--- Sensitivity labels ---" -ForegroundColor Cyan
if ($labels) {
    $labels | Sort-Object Priority | Select-Object DisplayName, Priority,
        @{n='Encrypted';e={[bool]$_.EncryptionEnabled}}, ContentType | Format-Table -AutoSize
} else { Write-Host "  No sensitivity labels found." -ForegroundColor Yellow }

Write-Host "`n--- Double Key Encryption (DKE) labels ---" -ForegroundColor Cyan
# The DKE endpoint URL is exposed on the label under an Encryption* / DoubleKeyEncryption* property.
# Property naming can differ by module version; probe the likely names read-only and never assume.
$dkeFound = @()
foreach ($l in ($labels | Where-Object { $_.EncryptionEnabled })) {
    $url = $null
    foreach ($p in @('EncryptionDoubleKeyEncryptionUrl','DoubleKeyEncryptionUrl','EncryptionDoubleKeyEncryption')) {
        if ($l.PSObject.Properties.Name -contains $p -and $l.$p) { $url = $l.$p; break }
    }
    if ($url) { $dkeFound += [pscustomobject]@{ DisplayName = $l.DisplayName; DkeEndpointUrl = $url } }
}
if ($dkeFound) {
    $dkeFound | Format-Table -AutoSize
} else {
    Write-Host "  No label with a Double Key Encryption endpoint detected." -ForegroundColor Yellow
    Write-Host "  (If you expect one, verify the DKE property name for your module version.)" -ForegroundColor Yellow
}

Write-Host "`n--- Label policies ---" -ForegroundColor Cyan
$labelPols = Get-LabelPolicy -ErrorAction SilentlyContinue
if ($labelPols) { $labelPols | Select-Object Name, Enabled | Format-Table -AutoSize }
else { Write-Host "  No label policies found." -ForegroundColor Yellow }

Write-Host "`n--- DKE licensing signal ---" -ForegroundColor Cyan
Write-Host "  If the 'Use Double Key Encryption' option is absent when editing a label's encryption," -ForegroundColor Gray
Write-Host "  the tenant likely lacks the required plan (E5 / E5 Compliance) — see Requirement 2.1." -ForegroundColor Gray

Write-Host "`nDiscovery complete. Use IPDKE-Validation.ps1 to check the expected named objects." -ForegroundColor Green
Disconnect-ExchangeOnline -Confirm:$false | Out-Null
