<#
.SYNOPSIS
    IPMANREC-Discovery.ps1 — read-only posture assessment of label-policy behaviour (mandatory / default / downgrade) and per-label recommend mode.
.DESCRIPTION
    Inventories the current label-policy posture via Security & Compliance PowerShell: every sensitivity
    label policy, its advanced settings (Mandatory, DisableMandatoryInOutlook, OutlookDefaultLabel,
    default-label configuration), the groups/locations it targets, and each sensitivity label's
    Office-app auto-labeling mode (Automatic vs Recommend). Read-only — makes no changes. Use it to
    build a baseline and to spot conflicting mandatory/default settings across overlapping policies.
.EXAMPLE
    .\IPMANREC-Discovery.ps1
    Connects with Connect-IPPSSession and prints the full label-policy + label posture to the console.
.EXAMPLE
    .\IPMANREC-Discovery.ps1 -CsvFolder C:\Temp\IPMANREC
    Also writes one CSV per object type to the folder.
.NOTES
    Requires PowerShell 5.1+/7+ and the ExchangeOnlineManagement module (Connect-IPPSSession).
    Role: Information Protection Admin (read is sufficient for discovery).
    Expected results: PASS = console/CSV inventory of every label policy (with its mandatory/default/
    Outlook settings and scope) and every label's recommend/automatic mode. FAIL = Connect-IPPSSession
    errors or a cmdlet is unavailable (verify your licensing/tenant).
#>
[CmdletBinding()]
param(
    [string]$CsvFolder
)

function Connect-SCC {
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        Write-Warning 'ExchangeOnlineManagement module not found. Install-Module ExchangeOnlineManagement -Scope CurrentUser'
        throw 'Module missing.'
    }
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    if (-not (Get-Command Get-LabelPolicy -ErrorAction SilentlyContinue)) {
        Write-Host 'Connecting to Security & Compliance PowerShell...' -ForegroundColor Cyan
        Connect-IPPSSession -ShowBanner:$false
    }
}

function Save-Csv($data, $name) {
    if ($CsvFolder -and $data) {
        if (-not (Test-Path $CsvFolder)) { New-Item -ItemType Directory -Path $CsvFolder -Force | Out-Null }
        $path = Join-Path $CsvFolder ("IPMANREC-{0}.csv" -f $name)
        $data | Export-Csv -Path $path -NoTypeInformation
        Write-Host ("  saved -> {0}" -f $path) -ForegroundColor DarkGray
    }
}

# Pull a named advanced setting off a policy object (settings surface as name/value pairs).
function Get-AdvSetting($policy, [string]$key) {
    try {
        $s = $policy.Settings | Where-Object { $_ -match [regex]::Escape($key) }
        if ($s) { return ($s -join '; ') }
    } catch { }
    return ''
}

Connect-SCC
Write-Host '=== IPMANREC posture assessment (read-only) ===' -ForegroundColor Cyan

# --- Label policies and their behaviour settings ---
Write-Host "`n--- Label policies (Get-LabelPolicy) ---" -ForegroundColor Cyan
$policies = Get-LabelPolicy -ErrorAction SilentlyContinue
$polView = foreach ($p in $policies) {
    [pscustomobject]@{
        Name                   = $p.Name
        Enabled                = $p.Enabled
        Mode                   = $p.Mode
        Mandatory              = Get-AdvSetting $p 'Mandatory'
        OutlookMandatoryOff    = Get-AdvSetting $p 'DisableMandatoryInOutlook'
        OutlookDefaultLabel    = Get-AdvSetting $p 'OutlookDefaultLabel'
        DowngradeJustification = Get-AdvSetting $p 'Justification'
        Labels                 = ($p.Labels -join ', ')
    }
}
$polView | Format-Table -AutoSize
Save-Csv $polView 'LabelPolicies'
Write-Host '  NOTE: blank Mandatory/Justification means the setting is not applied on that policy (default = not mandated).' -ForegroundColor Yellow

# --- Policy scope (who each policy targets) ---
Write-Host "`n--- Label policy scope (locations/groups) ---" -ForegroundColor Cyan
$scopeView = foreach ($p in $policies) {
    [pscustomobject]@{
        Policy            = $p.Name
        ExchangeLocation  = ($p.ExchangeLocation.Name -join ', ')
        ModernGroup       = ($p.ModernGroupLocation.Name -join ', ')
        SharePoint        = ($p.SharePointLocation.Name -join ', ')
    }
}
$scopeView | Format-Table -AutoSize
Save-Csv $scopeView 'LabelPolicyScope'

# --- Labels and their Office-app auto-labeling mode (Automatic vs Recommend) ---
Write-Host "`n--- Labels: Office-app auto-labeling mode (Get-Label) ---" -ForegroundColor Cyan
$labels = Get-Label -ErrorAction SilentlyContinue
$labView = $labels | Select-Object DisplayName, Name,
    @{n='Priority';e={$_.Priority}},
    @{n='Encryption';e={[bool]$_.EncryptionEnabled}},
    @{n='OfficeAutoLabel';e={
        # Recommend surfaces via the label's client-side auto-labeling settings; exact property names
        # can vary by tenant/version -- verify in your tenant.
        if ($_.ApplyAutoTaggingRecommendation -eq $true -or ($_.Settings -match 'recommend')) { 'Recommend' }
        elseif ($_.ApplyAutoTagging -eq $true -or ($_.Settings -match 'autotagging')) { 'Automatic' }
        else { 'None (manual)' }
    }}
$labView | Sort-Object Priority | Format-Table -AutoSize
Save-Csv $labView 'LabelsRecommendMode'
Write-Host '  NOTE: Recommend = suggests with a prompt; Automatic = force-applies. Verify exact property names in your tenant.' -ForegroundColor Yellow

Write-Host "`n=== Posture assessment complete (no changes made) ===" -ForegroundColor Green
