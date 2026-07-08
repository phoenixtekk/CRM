<#
.SYNOPSIS
    PURVLABEL-Discovery.ps1 — read-only posture assessment of sensitivity + retention labels, publishing, auto-labeling, and adaptive scopes.
.DESCRIPTION
    Inventories the current label posture via Security & Compliance PowerShell: existing sensitivity
    labels and label policies, service-side auto-labeling policies and their mode, retention labels
    (compliance tags), retention label policies, and adaptive scopes. Read-only — makes no changes.
    Use it to build a baseline before designing the taxonomy and to avoid name collisions.
.EXAMPLE
    .\PURVLABEL-Discovery.ps1
    Connects with Connect-IPPSSession and prints the full inventory to the console.
.EXAMPLE
    .\PURVLABEL-Discovery.ps1 -CsvFolder C:\Temp\PURVLABEL
    Also writes one CSV per object type to the folder.
.NOTES
    Requires PowerShell 5.1+/7+ and the ExchangeOnlineManagement module (Connect-IPPSSession).
    Role: Information Protection Reader / Compliance Administrator (read).
    Expected results: PASS = console/CSV inventory of every label, policy, auto-label policy (with
    mode), retention policy, and adaptive scope. FAIL = Connect-IPPSSession errors or a cmdlet is
    unavailable (verify your licensing/tenant — some features are E5 / E5 Compliance).
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
    if (-not (Get-Command Get-Label -ErrorAction SilentlyContinue)) {
        Write-Host 'Connecting to Security & Compliance PowerShell...' -ForegroundColor Cyan
        Connect-IPPSSession -ShowBanner:$false
    }
}

function Save-Csv($data, $name) {
    if ($CsvFolder -and $data) {
        if (-not (Test-Path $CsvFolder)) { New-Item -ItemType Directory -Path $CsvFolder -Force | Out-Null }
        $path = Join-Path $CsvFolder ("PURVLABEL-{0}.csv" -f $name)
        $data | Export-Csv -Path $path -NoTypeInformation
        Write-Host ("  saved -> {0}" -f $path) -ForegroundColor DarkGray
    }
}

Connect-SCC
Write-Host '=== PURVLABEL posture assessment (read-only) ===' -ForegroundColor Cyan

# --- Sensitivity labels ---
Write-Host "`n--- Sensitivity labels (Get-Label) ---" -ForegroundColor Cyan
$labels = Get-Label -ErrorAction SilentlyContinue
$labelView = $labels | Select-Object DisplayName, Name,
    @{n='HasParent';e={[bool]$_.ParentId}},
    @{n='Encryption';e={[bool]$_.EncryptionEnabled}},
    @{n='ContentMarking';e={[bool]($_.ApplyContentMarkingHeaderEnabled -or $_.ApplyContentMarkingFooterEnabled -or $_.ApplyWaterMarkingEnabled)}},
    Priority
$labelView | Sort-Object Priority | Format-Table -AutoSize
Save-Csv $labelView 'SensitivityLabels'

# --- Sensitivity label policies ---
Write-Host "`n--- Sensitivity label policies (Get-LabelPolicy) ---" -ForegroundColor Cyan
$labelPolicies = Get-LabelPolicy -ErrorAction SilentlyContinue
$lpView = $labelPolicies | Select-Object Name, Mode, Enabled,
    @{n='Labels';e={($_.Labels -join ', ')}}
$lpView | Format-Table -AutoSize
Save-Csv $lpView 'LabelPolicies'

# --- Service-side auto-labeling policies (mode matters: simulation vs enable) ---
Write-Host "`n--- Auto-labeling policies (Get-AutoSensitivityLabelPolicy) ---" -ForegroundColor Cyan
$autoPol = Get-AutoSensitivityLabelPolicy -ErrorAction SilentlyContinue
if ($autoPol) {
    $apView = $autoPol | Select-Object Name, Mode,
        @{n='ApplySensitivityLabel';e={$_.ApplySensitivityLabel}},
        @{n='SharePoint';e={($_.SharePointLocation.Name -join ',')}},
        @{n='Exchange';e={($_.ExchangeLocation.Name -join ',')}}
    $apView | Format-Table -AutoSize
    Save-Csv $apView 'AutoLabelPolicies'
    Write-Host '  NOTE: Mode should be a TestWithout/WithNotifications (simulation) value until precision is validated.' -ForegroundColor Yellow
} else {
    Write-Host '  (none found — or feature not licensed; verify your licensing/tenant for service-side auto-labeling, typically E5)' -ForegroundColor Yellow
}

# --- Retention labels (compliance tags) ---
Write-Host "`n--- Retention labels (Get-ComplianceTag) ---" -ForegroundColor Cyan
$tags = Get-ComplianceTag -ErrorAction SilentlyContinue
$tagView = $tags | Select-Object Name, RetentionAction, RetentionDuration, RetentionType,
    @{n='IsRecord';e={[bool]$_.IsRecordLabel}}
$tagView | Format-Table -AutoSize
Save-Csv $tagView 'RetentionLabels'

# --- Retention (label) policies ---
Write-Host "`n--- Retention policies (Get-RetentionCompliancePolicy) ---" -ForegroundColor Cyan
$retPol = Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue
$rpView = $retPol | Select-Object Name, Enabled, Mode,
    @{n='IsAdaptiveScope';e={$_.IsAdaptiveScopeSelected}}
$rpView | Format-Table -AutoSize
Save-Csv $rpView 'RetentionPolicies'

# --- Adaptive scopes ---
Write-Host "`n--- Adaptive scopes (Get-AdaptiveScope) ---" -ForegroundColor Cyan
$scopes = Get-AdaptiveScope -ErrorAction SilentlyContinue
if ($scopes) {
    $scView = $scopes | Select-Object Name, LocationType, RawQuery
    $scView | Format-Table -AutoSize
    Save-Csv $scView 'AdaptiveScopes'
} else {
    Write-Host '  (none found — or feature not licensed; verify your licensing/tenant for adaptive scopes)' -ForegroundColor Yellow
}

Write-Host "`n=== Posture assessment complete (no changes made) ===" -ForegroundColor Green
