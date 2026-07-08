<#
.SYNOPSIS
    DLPCJIS-Scope-Health.ps1 — read-only scope/health helper: reports available M365 workloads, endpoint onboarding status, and which DLP surfaces the licensing unlocks. Makes no changes.
.DESCRIPTION
    PURPOSE
        Produces the coverage map for the CJI DLP program so gaps are explicit, not assumed. Reports the M365
        workloads reachable for DLP (Exchange / SharePoint / OneDrive / Teams), whether Endpoint DLP is
        available (onboarded devices), and — via Graph subscribedSkus — whether the tenant appears to carry
        the licensing (E5 / E5 Compliance) that unlocks advanced DLP surfaces (Endpoint DLP, EDM, trainable
        classifiers). Read-only. Writes the map to console (+ optional CSV).
    HOW TO RUN
        Connect-IPPSSession                                   # for DLP/endpoint surface (no secrets in code)
        Connect-MgGraph -Scopes 'Organization.Read.All'       # optional, for the licensing hint (read-only)
        .\DLPCJIS-Scope-Health.ps1
        .\DLPCJIS-Scope-Health.ps1 -CsvPath .\Workload-Scope-CJISDLP.csv
        PowerShell 5.1+/7+; S&C PowerShell (Connect-IPPSSession) required; Microsoft.Graph optional for licensing.
    EXPECTED RESULTS
        A coverage table (Surface, Available, Note) covering Exchange/SharePoint/OneDrive/Teams/Endpoint and a
        licensing hint. Any required surface showing Available=No is a COVERAGE GAP to license/onboard or
        de-scope explicitly — never assume an un-onboarded surface is protected.
.NOTES
    CJIS DLP Pack — read-only. The licensing hint is a convenience only; confirm capability + portal paths
    for your own tenant (the portal evolves and features are plan-gated). Verify licensing/tenant.
#>
[CmdletBinding()]
param(
    [string]$CsvPath
)

$map = New-Object System.Collections.Generic.List[object]
function Add-Surface { param([string]$Surface,[string]$Available,[string]$Note)
    $map.Add([pscustomobject]@{ Surface=$Surface; Available=$Available; Note=$Note }) }

Write-Host "=== Workload Scope - CJIS DLP - Map ===" -ForegroundColor Cyan

# --- DLP core surface (requires S&C PowerShell) ---
$ippsOk = [bool](Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)
if ($ippsOk) {
    Add-Surface 'Exchange Online DLP'  'Yes' 'M365 workload — in scope by default for a DLP policy.'
    Add-Surface 'SharePoint Online DLP' 'Yes' 'M365 workload — in scope by default.'
    Add-Surface 'OneDrive DLP'         'Yes' 'M365 workload — in scope by default.'
    Add-Surface 'Teams DLP'            'Yes' 'M365 workload — in scope by default (chat/channel).'

    # Endpoint DLP availability — best-effort: presence of endpoint DLP settings / onboarded devices.
    $endpointNote = 'Requires E5 / E5 Compliance + onboarded devices (Purview > Settings > Device onboarding).'
    $endpointAvail = 'Unknown'
    try {
        $ecfg = Get-PolicyConfig -ErrorAction SilentlyContinue
        if ($ecfg) { $endpointAvail = 'Check'; $endpointNote = 'Endpoint DLP config surface present; confirm devices are onboarded before relying on Endpoint DLP.' }
    } catch { }
    Add-Surface 'Endpoint DLP (USB/print/cloud-upload)' $endpointAvail $endpointNote
} else {
    Write-Warning "Not connected to Security & Compliance PowerShell — workload availability not read. Run Connect-IPPSSession."
    Add-Surface 'DLP core surfaces' 'Unknown' 'Connect-IPPSSession to assess Exchange/SharePoint/OneDrive/Teams/Endpoint.'
}

# --- Licensing hint (optional, via Graph) ---
$licNote = 'Graph not connected — skipped. Connect-MgGraph -Scopes Organization.Read.All for a licensing hint.'
$licAvail = 'Unknown'
try {
    if (Get-Command Get-MgSubscribedSku -ErrorAction SilentlyContinue) {
        $ctx = $null; try { $ctx = Get-MgContext } catch {}
        if ($ctx) {
            $skus = Get-MgSubscribedSku -All -ErrorAction Stop
            $parts = ($skus | Select-Object -ExpandProperty SkuPartNumber -ErrorAction SilentlyContinue) -join ' '
            $hasE5 = $parts -match 'SPE_E5|ENTERPRISEPREMIUM|Microsoft_365_E5|INFORMATION_PROTECTION_COMPLIANCE|IP_COMPLIANCE'
            if ($hasE5) { $licAvail = 'Likely'; $licNote = 'A SKU matching E5 / E5 Compliance is present — advanced DLP (Endpoint/EDM/trainable classifiers) likely available. Confirm in-portal.' }
            else        { $licAvail = 'Basic';  $licNote = 'No E5 / E5 Compliance SKU matched — expect Exchange/SP/OneDrive/Teams DLP but NOT Endpoint DLP / EDM / trainable classifiers. Confirm in-portal.' }
        }
    }
} catch { $licNote = ("Licensing read failed: {0}" -f $_.Exception.Message) }
Add-Surface 'Advanced DLP licensing (E5 / E5 Compliance)' $licAvail $licNote

$map | Format-Table -AutoSize -Wrap

# Coverage-gap callout.
$gaps = @($map | Where-Object { $_.Available -in @('No','Unknown','Basic') })
if ($gaps.Count -gt 0) {
    Write-Host "`nCOVERAGE NOTES — review each; license/onboard or de-scope explicitly (do not assume protection):" -ForegroundColor Yellow
    $gaps | Select-Object Surface, Available, Note | Format-Table -AutoSize -Wrap
} else {
    Write-Host "`nAll assessed surfaces available. Still confirm capability + portal paths for your tenant." -ForegroundColor Green
}

if ($CsvPath) {
    $map | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Scope map written to {0}." -f $CsvPath) -ForegroundColor Green
}
