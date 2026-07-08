<#
.SYNOPSIS
    IPTAX-Discovery.ps1 — read-only posture assessment of the existing sensitivity label taxonomy, structure, protection, and naming.
.DESCRIPTION
    Inventories the current sensitivity-label posture via Security & Compliance PowerShell: existing
    labels with their parent/sublabel structure and order, the protection/marking on each (encryption,
    header/footer/watermark), and published label policies. Flags naming-convention drift and any
    internal-name collision with a taxonomy you plan to build. Read-only — makes no changes. Use it to
    build a baseline before designing the taxonomy.
.EXAMPLE
    .\IPTAX-Discovery.ps1
    Connects with Connect-IPPSSession and prints the full inventory to the console.
.EXAMPLE
    .\IPTAX-Discovery.ps1 -PlannedNames SL-Public,SL-Internal,SL-Confidential -CsvFolder C:\Temp\IPTAX
    Also checks the planned internal names for collisions and writes CSVs.
.NOTES
    Requires PowerShell 5.1+/7+ and the ExchangeOnlineManagement module (Connect-IPPSSession).
    Role: Information Protection Reader / Information Protection Admin (read).
    Expected results: PASS = console/CSV inventory of every label (with structure + protection), every
    label policy, a naming-conformance view, and a collision report. FAIL = Connect-IPPSSession errors
    or Get-Label is unavailable (verify your licensing/tenant).
#>
[CmdletBinding()]
param(
    [string[]]$PlannedNames = @('SL-Public','SL-Internal','SL-Confidential','SL-Conf-AllEmp','SL-Conf-Trusted','SL-HighlyConf','SL-HighlyConf-AllEmp','SL-HighlyConf-Specified'),
    [string]$NamePrefix = 'SL-',
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
        $path = Join-Path $CsvFolder ("IPTAX-{0}.csv" -f $name)
        $data | Export-Csv -Path $path -NoTypeInformation
        Write-Host ("  saved -> {0}" -f $path) -ForegroundColor DarkGray
    }
}

Connect-SCC
Write-Host '=== IPTAX posture assessment (read-only) ===' -ForegroundColor Cyan

# --- Sensitivity labels: structure + protection ---
Write-Host "`n--- Sensitivity labels (Get-Label) ---" -ForegroundColor Cyan
$labels = Get-Label -ErrorAction SilentlyContinue
# Map ParentId (a GUID) back to a readable parent name where possible.
$byGuid = @{}
foreach ($l in $labels) { if ($l.Guid) { $byGuid[[string]$l.Guid] = $l.DisplayName } }
$labelView = $labels | Select-Object DisplayName, Name,
    @{n='Parent';e={ if ($_.ParentId) { $byGuid[[string]$_.ParentId] } else { '' } }},
    @{n='IsParent';e={ [bool]($labels | Where-Object { $_.ParentId -eq $_.Guid }) }},
    @{n='Encryption';e={ [bool]$_.EncryptionEnabled }},
    @{n='ContentMarking';e={ [bool]($_.ApplyContentMarkingHeaderEnabled -or $_.ApplyContentMarkingFooterEnabled -or $_.ApplyWaterMarkingEnabled) }},
    Priority
$labelView | Sort-Object Priority | Format-Table -AutoSize
Save-Csv $labelView 'Labels'

# --- Sensitivity label policies ---
Write-Host "`n--- Sensitivity label policies (Get-LabelPolicy) ---" -ForegroundColor Cyan
$labelPolicies = Get-LabelPolicy -ErrorAction SilentlyContinue
$lpView = $labelPolicies | Select-Object Name, Mode, Enabled,
    @{n='Labels';e={ ($_.Labels -join ', ') }}
$lpView | Format-Table -AutoSize
Save-Csv $lpView 'LabelPolicies'

# --- Naming-convention conformance ---
Write-Host "`n--- Naming-convention conformance (prefix '$NamePrefix') ---" -ForegroundColor Cyan
$conf = $labels | Select-Object Name, DisplayName,
    @{n='Conforms';e={ [bool]($_.Name -like ("{0}*" -f $NamePrefix)) }}
$nonConf = $conf | Where-Object { -not $_.Conforms }
if ($nonConf) {
    Write-Host ("  {0} label(s) do NOT match the '{1}*' internal-name convention:" -f $nonConf.Count, $NamePrefix) -ForegroundColor Yellow
    $nonConf | Format-Table -AutoSize
} else {
    Write-Host '  All existing internal names conform to the convention (or no labels exist).' -ForegroundColor Green
}
Save-Csv $conf 'NamingConformance'

# --- Collision check against planned names ---
Write-Host "`n--- Internal-name collision check (planned taxonomy) ---" -ForegroundColor Cyan
$existingNames = @($labels.Name)
$collisions = $PlannedNames | Where-Object { $existingNames -contains $_ }
if ($collisions) {
    Write-Host ('  COLLISION — these planned internal names already exist (choose different names or retire the old label):') -ForegroundColor Red
    $collisions | ForEach-Object { Write-Host ("    - {0}" -f $_) -ForegroundColor Red }
} else {
    Write-Host '  No collisions — every planned internal name is free.' -ForegroundColor Green
}

Write-Host "`n=== Posture assessment complete (no changes made) ===" -ForegroundColor Green
