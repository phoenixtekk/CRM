<#
.SYNOPSIS
    IPMANREC-Reporting.ps1 — export the mandatory-vs-recommended posture matrix across all label policies and labels to CSV (read-only).
.DESCRIPTION
    Builds two evidence artifacts for the governance owner: (1) a per-policy matrix — for every label
    policy, whether mandatory labeling is on, the default label, the downgrade-justification state, and
    the Outlook-relaxation state; and (2) a per-label matrix — for every sensitivity label, whether its
    Office-app auto-labeling mode is Recommend or Automatic (or off). Read-only — makes no changes.
    Writes timestamped CSVs to the folder you supply (or prints to the console if none is given).
.EXAMPLE
    .\IPMANREC-Reporting.ps1
    Prints the policy and label posture matrices to the console (no files written).
.EXAMPLE
    .\IPMANREC-Reporting.ps1 -CsvFolder C:\Purview\Evidence
    Exports IPMANREC-Policies-<timestamp>.csv and IPMANREC-Labels-<timestamp>.csv as governance evidence.
.NOTES
    Requires PowerShell 5.1+/7+ and ExchangeOnlineManagement (Connect-IPPSSession).
    Role: Information Protection Admin (read).
    Expected results: PASS = the CSVs (or console tables) list every policy and label with their resolved
    posture. FAIL = Connect-IPPSSession did not establish or an advanced-setting key is unavailable in
    your tenant (verify your licensing/tenant). Advanced-setting key names can differ by tenant/version —
    the report shows the raw resolved value so you can VERIFY IN YOUR TENANT.
#>
[CmdletBinding()]
param(
    [string]$CsvFolder
)

Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-LabelPolicy -ErrorAction SilentlyContinue)) {
    Connect-IPPSSession -ShowBanner:$false
}

function Get-AdvSetting($obj, [string]$key) {
    try {
        $s = $obj.Settings | Where-Object { $_ -match [regex]::Escape($key) }
        if ($s) { return ($s -join '; ') }
    } catch { }
    return ''
}

Write-Host "=== IPMANREC posture report (read-only) ===" -ForegroundColor Cyan

# --- Per-policy matrix ---
$policyRows = @()
foreach ($p in (Get-LabelPolicy -ErrorAction SilentlyContinue)) {
    $mand    = Get-AdvSetting $p 'Mandatory'
    $def     = Get-AdvSetting $p 'DefaultLabelId'
    $dg      = Get-AdvSetting $p 'Justification'
    $outlook = Get-AdvSetting $p 'DisableMandatoryInOutlook'
    $policyRows += [pscustomobject]@{
        Policy                 = $p.Name
        MandatoryLabeling      = if ($mand -match 'true') { 'ON' } else { 'off' }
        DefaultLabelId         = if ($def) { ($def -replace '.*=', '').Trim() } else { '(none)' }
        DowngradeJustification = if ($dg -match 'true') { 'ON' } else { 'off/verify-key' }
        OutlookRelaxed         = if ($outlook -match 'true') { 'yes' } else { 'no' }
        Enabled                = $p.Enabled
    }
}

# --- Per-label matrix (Recommend vs Automatic vs off) ---
$labelRows = @()
foreach ($l in (Get-Label -ErrorAction SilentlyContinue)) {
    $isRec  = ($l.ApplyAutoTaggingRecommendation -eq $true) -or ($l.Settings -match 'recommend')
    $isAuto = ($l.ApplyAutoTagging -eq $true) -or ($l.Settings -match 'autotagging')
    $mode   = if ($isRec) { 'Recommend' } elseif ($isAuto) { 'Automatic' } else { 'off/none' }
    $labelRows += [pscustomobject]@{
        Label            = $l.DisplayName
        Identity         = $l.Name
        AutoLabelingMode = $mode
        Encrypting       = [bool]$l.EncryptionEnabled
    }
}

Write-Host "`n--- Policies ($($policyRows.Count)) ---" -ForegroundColor Cyan
$policyRows | Format-Table -AutoSize | Out-Host
Write-Host "`n--- Labels ($($labelRows.Count)) ---" -ForegroundColor Cyan
$labelRows | Format-Table -AutoSize | Out-Host

if ($CsvFolder) {
    if (-not (Test-Path $CsvFolder)) { New-Item -ItemType Directory -Path $CsvFolder -Force | Out-Null }
    $ts = Get-Date -Format 'yyyyMMdd-HHmmss'
    $pPath = Join-Path $CsvFolder "IPMANREC-Policies-$ts.csv"
    $lPath = Join-Path $CsvFolder "IPMANREC-Labels-$ts.csv"
    $policyRows | Export-Csv -Path $pPath -NoTypeInformation -Encoding UTF8
    $labelRows  | Export-Csv -Path $lPath -NoTypeInformation -Encoding UTF8
    Write-Host "`nExported:" -ForegroundColor Green
    Write-Host "  $pPath" -ForegroundColor Green
    Write-Host "  $lPath" -ForegroundColor Green
} else {
    Write-Host "`n(No -CsvFolder supplied - console only. Add -CsvFolder <path> to export evidence CSVs.)" -ForegroundColor Yellow
}
Write-Host "`nNOTE: advanced-setting key names can differ by tenant/version - VERIFY IN YOUR TENANT." -ForegroundColor Yellow
