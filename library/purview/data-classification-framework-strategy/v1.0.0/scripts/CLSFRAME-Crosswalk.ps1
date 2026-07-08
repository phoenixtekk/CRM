<#
.SYNOPSIS
    CLSFRAME-Crosswalk.ps1 — export the LIVE tier -> label / DLP / retention crosswalk from the tenant (read-only) to compare against the signed-off standard.
.DESCRIPTION
    Reads the current sensitivity labels, DLP policies, and retention labels via Security & Compliance
    PowerShell and builds one row per framework tier showing the mapped sensitivity label (and its
    protection), the DLP posture that covers the tier band, and the mapped retention label (and its
    action/duration). Output is the live crosswalk you compare to the classification standard document
    to detect drift. Read-only — makes no changes.
.EXAMPLE
    .\CLSFRAME-Crosswalk.ps1
    Prints the live crosswalk table to the console.
.EXAMPLE
    .\CLSFRAME-Crosswalk.ps1 -CsvPath .\crosswalk.csv
    Also writes the crosswalk to a CSV for side-by-side comparison with the standard.
.NOTES
    Requires PowerShell 5.1+/7+ and the ExchangeOnlineManagement module (Connect-IPPSSession).
    Role (read): Compliance Administrator / Information Protection Reader.
    Expected results: PASS = one row per tier with a label, a DLP posture, and a retention label that
    match the standard. FAIL = a tier row shows "(missing)" (an orphan/gap) or the live values differ
    from the standard (drift) — reconcile before expanding.
#>
[CmdletBinding()]
param(
    [string]$CsvPath,
    [string[]]$Tiers = @('Public','Internal','Confidential','Restricted'),
    [string]$DlpBaselineName = 'CLS DLP – Tier2-3 – Test'
)

function Connect-SCC {
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        Write-Warning 'ExchangeOnlineManagement module not found. Install-Module ExchangeOnlineManagement -Scope CurrentUser'
        throw 'Module missing.'
    }
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    if (-not (Get-Command Get-Label -ErrorAction SilentlyContinue)) {
        Write-Host 'Connecting to Security & Compliance PowerShell...' -ForegroundColor Cyan
        Connect-IPPSSession -ShowBanner:$false
    }
}

Connect-SCC
Write-Host '=== CLSFRAME live crosswalk (read-only) ===' -ForegroundColor Cyan

$labels = Get-Label -ErrorAction SilentlyContinue
$tags   = Get-ComplianceTag -ErrorAction SilentlyContinue
$dlp    = Get-DlpCompliancePolicy -ErrorAction SilentlyContinue

# The DLP baseline is a tier BAND (e.g. Confidential/Restricted), not per-tier.
$dlpPolicy = $dlp | Where-Object { $_.Name -eq $DlpBaselineName } | Select-Object -First 1
$dlpMode   = if ($dlpPolicy) { $dlpPolicy.Mode } else { '(missing)' }
$tierBand  = @('Confidential','Restricted')  # tiers the DLP baseline is expected to cover

$rows = foreach ($t in $Tiers) {
    $lbl = $labels | Where-Object { $_.DisplayName -eq $t } | Select-Object -First 1
    $tag = $tags   | Where-Object { $_.Name -like "*$t*" }  | Select-Object -First 1

    $protection = if (-not $lbl) { '(missing)' }
        elseif ($lbl.EncryptionEnabled -and ($lbl.ApplyWaterMarkingEnabled)) { 'Encrypt + watermark' }
        elseif ($lbl.EncryptionEnabled) { 'Encrypt' }
        elseif ($lbl.ApplyContentMarkingFooterEnabled -or $lbl.ApplyContentMarkingHeaderEnabled) { 'Marking only' }
        else { 'None' }

    $dlpPosture = if ($tierBand -contains $t) {
        if ($dlpPolicy) { "$DlpBaselineName ($dlpMode)" } else { '(missing)' }
    } else { 'Monitor / no block' }

    [pscustomobject]@{
        Tier            = $t
        SensitivityLabel= if ($lbl) { $lbl.DisplayName } else { '(missing)' }
        Protection      = $protection
        DlpPosture      = $dlpPosture
        RetentionLabel  = if ($tag) { $tag.Name } else { '(missing)' }
        RetentionAction = if ($tag) { "$($tag.RetentionAction)/$($tag.RetentionDuration)d" } else { '(missing)' }
    }
}

$rows | Format-Table -AutoSize
if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("  saved -> {0}" -f $CsvPath) -ForegroundColor DarkGray
}

$gaps = $rows | Where-Object { $_ -match '\(missing\)' -or $_.PSObject.Properties.Value -contains '(missing)' }
if ($gaps) {
    Write-Host "`n  WARNING: one or more tiers have a missing mapping (orphan/gap) — reconcile before expanding." -ForegroundColor Yellow
} else {
    Write-Host "`n  All tiers mapped. Compare this crosswalk to the signed-off standard to confirm no drift." -ForegroundColor Green
}
Write-Host '=== Crosswalk export complete (no changes made) ===' -ForegroundColor Green
