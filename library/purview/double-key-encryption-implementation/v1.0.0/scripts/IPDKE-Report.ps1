<#
.SYNOPSIS
    IPDKE-Report.ps1 — summarize Double Key Encryption label usage and audience. Read-only.
.DESCRIPTION
    PURPOSE
        Produces a coverage summary for the DKE rollout: the sensitivity labels that use Double Key
        Encryption (and their endpoint URLs), the label policies that publish them and their audience,
        and a standing reminder of the cloud content-services that cannot process DKE content. Use it
        at the pilot gate and after each expansion to see exactly where DKE is applied. Read-only.
    HOW TO RUN
        Install-Module ExchangeOnlineManagement -Scope CurrentUser
        powershell -ExecutionPolicy Bypass -File .\IPDKE-Report.ps1
        Optional: -CsvPath .\dke-report.csv to also write the label rows to CSV.
        Sign in as a Compliance Administrator (or Information Protection Admin) when prompted.
    EXPECTED RESULTS
        A table of DKE labels (name, endpoint URL), a table of label policies (name, enabled), and a
        note listing the content-service exclusions to confirm the accepted trade-off.
.NOTES
    White-label — Purview Solutions. Read-only. No secrets. No changes to any object.
    Uses Get-Label / Get-LabelPolicy. Verify the current unsupported-services list in Microsoft docs.
#>
[CmdletBinding()] param(
    [string]$CsvPath = ''
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

Write-Host "`n=== Double Key Encryption — usage / coverage report ===" -ForegroundColor Cyan

$labels = Get-Label -ErrorAction SilentlyContinue
$dke = @()
foreach ($l in ($labels | Where-Object { $_.EncryptionEnabled })) {
    $url = $null
    foreach ($p in @('EncryptionDoubleKeyEncryptionUrl','DoubleKeyEncryptionUrl','EncryptionDoubleKeyEncryption')) {
        if ($l.PSObject.Properties.Name -contains $p -and $l.$p) { $url = $l.$p; break }
    }
    if ($url) { $dke += [pscustomobject]@{ Label = $l.DisplayName; DkeEndpointUrl = $url; Priority = $l.Priority } }
}

Write-Host "`n--- DKE labels ---" -ForegroundColor Cyan
if ($dke) {
    $dke | Sort-Object Priority | Format-Table -AutoSize
    if ($CsvPath) { $dke | Export-Csv -NoTypeInformation -Path $CsvPath; Write-Host ("  Written: {0}" -f $CsvPath) -ForegroundColor Green }
} else {
    Write-Host "  No DKE labels detected." -ForegroundColor Yellow
}

Write-Host "`n--- Label policies (publishers) ---" -ForegroundColor Cyan
$pols = Get-LabelPolicy -ErrorAction SilentlyContinue
if ($pols) { $pols | Select-Object Name, Enabled | Format-Table -AutoSize }
else { Write-Host "  No label policies found." -ForegroundColor Yellow }

Write-Host "`n--- Content-service exclusions for DKE (by design) ---" -ForegroundColor Cyan
Write-Host "  DKE-protected content CANNOT be processed by Microsoft cloud content services, including:" -ForegroundColor Gray
Write-Host "    - Content-based DLP inspection" -ForegroundColor Gray
Write-Host "    - eDiscovery content search / indexing" -ForegroundColor Gray
Write-Host "    - Microsoft 365 co-authoring / AutoSave / web editing" -ForegroundColor Gray
Write-Host "    - Copilot and other cloud content processing" -ForegroundColor Gray
Write-Host "  Confirm the CURRENT unsupported-services list for your tenant in Microsoft's DKE docs." -ForegroundColor Gray

Write-Host "`nReport complete." -ForegroundColor Green
Disconnect-ExchangeOnline -Confirm:$false | Out-Null
