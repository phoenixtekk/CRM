<#
.SYNOPSIS
    CLSFRAME-Discovery.ps1 — read-only posture assessment of the classification framework's control families (labels, DLP, retention).
.DESCRIPTION
    Inventories the current classification posture via Security & Compliance PowerShell: existing
    sensitivity labels and label policies, DLP policies and their mode (Enable vs Test vs Disable),
    and retention labels and retention policies. It then reports which of the framework tiers
    (Public / Internal / Confidential / Restricted) already have an artifact in each control family,
    so you extend the framework instead of colliding with what exists. Read-only — makes no changes.
.EXAMPLE
    .\CLSFRAME-Discovery.ps1
    Connects with Connect-IPPSSession and prints the full posture inventory to the console.
.EXAMPLE
    .\CLSFRAME-Discovery.ps1 -CsvFolder C:\Temp\CLSFRAME
    Also writes one CSV per object type to the folder.
.NOTES
    Requires PowerShell 5.1+/7+ and the ExchangeOnlineManagement module (Connect-IPPSSession).
    Role (read): Information Protection Reader / Compliance Administrator.
    Expected results: PASS = console/CSV inventory of every label, label policy, DLP policy (with
    mode), retention label, and retention policy, plus a per-tier coverage view. FAIL =
    Connect-IPPSSession errors or a cmdlet is unavailable (verify your licensing/tenant — advanced
    DLP conditions and reporting are E5 / E5 Compliance).
#>
[CmdletBinding()]
param(
    [string]$CsvFolder,
    [string[]]$Tiers = @('Public','Internal','Confidential','Restricted')
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
        $path = Join-Path $CsvFolder ("CLSFRAME-{0}.csv" -f $name)
        $data | Export-Csv -Path $path -NoTypeInformation
        Write-Host ("  saved -> {0}" -f $path) -ForegroundColor DarkGray
    }
}

Connect-SCC
Write-Host '=== CLSFRAME posture assessment (read-only) ===' -ForegroundColor Cyan

# --- Sensitivity labels ---
Write-Host "`n--- Sensitivity labels (Get-Label) ---" -ForegroundColor Cyan
$labels = Get-Label -ErrorAction SilentlyContinue
$labelView = $labels | Select-Object DisplayName, Name,
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

# --- DLP policies (mode matters: Test vs Enable) ---
Write-Host "`n--- DLP policies (Get-DlpCompliancePolicy) ---" -ForegroundColor Cyan
$dlp = Get-DlpCompliancePolicy -ErrorAction SilentlyContinue
if ($dlp) {
    $dlpView = $dlp | Select-Object Name, Mode, Enabled,
        @{n='Workloads';e={$_.Workload}}
    $dlpView | Format-Table -AutoSize
    Save-Csv $dlpView 'DlpPolicies'
    Write-Host '  NOTE: A framework DLP baseline should be a Test* mode until match reports are accepted; Enable = enforcing.' -ForegroundColor Yellow
} else {
    Write-Host '  (none found — or feature not licensed; verify your licensing/tenant for DLP)' -ForegroundColor Yellow
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
$rpView = $retPol | Select-Object Name, Enabled, Mode
$rpView | Format-Table -AutoSize
Save-Csv $rpView 'RetentionPolicies'

# --- Per-tier coverage snapshot (does each tier already have an artifact per family?) ---
Write-Host "`n--- Framework tier coverage (existing artifacts by tier) ---" -ForegroundColor Cyan
$labelNames = @($labels | ForEach-Object { $_.DisplayName })
$tagNames   = @($tags   | ForEach-Object { $_.Name })
$coverage = foreach ($t in $Tiers) {
    [pscustomobject]@{
        Tier            = $t
        HasLabel        = [bool]($labelNames -contains $t)
        HasRetention    = [bool]($tagNames | Where-Object { $_ -like "*$t*" })
        # DLP is tier-band (e.g. Tier2-3) rather than per-tier; reported at policy level above.
    }
}
$coverage | Format-Table -AutoSize
Save-Csv $coverage 'TierCoverage'
Write-Host '  NOTE: DLP is typically a tier-band baseline (e.g. Confidential/Restricted) — see the DLP policies above.' -ForegroundColor DarkGray

Write-Host "`n=== Posture assessment complete (no changes made) ===" -ForegroundColor Green
