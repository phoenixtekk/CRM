<#
.SYNOPSIS
    Validates the archiving strategy against pass/fail gates (READ-ONLY; changes nothing).
.DESCRIPTION
    For each pilot mailbox, checks archive provisioning, retention-policy assignment, MRM tag
    correctness, and archive item growth; optionally checks a Purview DLM retention policy's health
    and that no delete action is active. Emits PASS/FAIL per gate and an overall result.
.EXAMPLE
    .\Test-ArchiveStrategy.ps1 -PilotGroup grp-archive-pilot -PolicyName RP-Corp-Archive -OutputPath .\validation
    Runs on PowerShell 5.1+/7+. Connect first with Connect-ExchangeOnline and Connect-IPPSSession.
    Expected results: a PASS/FAIL table and a CSV; overall PASS means the pilot is validated.
.NOTES
    Expected results: all gates PASS = pilot validated, safe to expand. Any FAIL = see Troubleshooting.
    No credentials or secrets are used. Read-only.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$PilotGroup,
    [string]$PolicyName = 'RP-Corp-Archive',
    [string]$TagName    = 'MTA-2yr',
    [string]$DlmPolicy,
    [string]$OutputPath = '.\archive-validation'
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$gates = New-Object System.Collections.Generic.List[object]
function Add-Gate { param($Scope,$Gate,$Pass,$Detail)
    $gates.Add([pscustomobject]@{ Scope=$Scope; Gate=$Gate; Status=$(if($Pass){'PASS'}else{'FAIL'}); Detail=$Detail }) }

# Gate 3a — MRM tag correct (action = MoveToArchive, enabled)
try {
    $tag = Get-RetentionPolicyTag -Identity $TagName -ErrorAction Stop
    Add-Gate 'org' "MRM tag '$TagName'" `
        ($tag.RetentionAction -eq 'MoveToArchive' -and $tag.RetentionEnabled) `
        "Action=$($tag.RetentionAction); Age=$($tag.AgeLimitForRetention); Enabled=$($tag.RetentionEnabled)"
} catch { Add-Gate 'org' "MRM tag '$TagName'" $false "Not found: $($_.Exception.Message)" }

# Gate 3b — policy links the tag
try {
    $pol = Get-RetentionPolicy -Identity $PolicyName -ErrorAction Stop
    Add-Gate 'org' "Policy '$PolicyName' links tag" ($pol.RetentionPolicyTagLinks -match $TagName) `
        "Links=$($pol.RetentionPolicyTagLinks -join ', ')"
} catch { Add-Gate 'org' "Policy '$PolicyName'" $false "Not found: $($_.Exception.Message)" }

# Per-mailbox gates
$targets = Get-DistributionGroupMember -Identity $PilotGroup |
    Where-Object { $_.RecipientType -like '*Mailbox*' } | ForEach-Object { $_.PrimarySmtpAddress }

foreach ($mbx in $targets) {
    try {
        $m = Get-Mailbox -Identity $mbx
        # Gate 2 — archive provisioned
        Add-Gate $mbx 'Archive enabled' ($m.ArchiveStatus -eq 'Active' -and $m.ArchiveGuid -ne [guid]::Empty) `
            "ArchiveStatus=$($m.ArchiveStatus)"
        # Gate 3c — policy assigned
        Add-Gate $mbx 'Retention policy assigned' ($m.RetentionPolicy -eq $PolicyName) `
            "RetentionPolicy=$($m.RetentionPolicy)"
        # Gate 4 — archive has content (where aged mail exists)
        if ($m.ArchiveStatus -eq 'Active') {
            $as = Get-MailboxStatistics -Identity $mbx -Archive -ErrorAction SilentlyContinue
            $cnt = if ($as) { [int]$as.ItemCount } else { 0 }
            Add-Gate $mbx 'Archive item count > 0' ($cnt -gt 0) "ArchiveItemCount=$cnt (0 may mean MFA not yet run)"
        }
    } catch {
        Add-Gate $mbx 'Mailbox read' $false $_.Exception.Message
    }
}

# Gate 5/6 — DLM policy health + no-delete (optional)
if ($DlmPolicy) {
    try {
        $dp = Get-RetentionCompliancePolicy -Identity $DlmPolicy -ErrorAction Stop
        Add-Gate 'dlm' "DLM policy '$DlmPolicy' healthy" `
            ($dp.Enabled -and $dp.DistributionStatus -notmatch 'Error|Fail') `
            "Enabled=$($dp.Enabled); Distribution=$($dp.DistributionStatus)"
        $rules = Get-RetentionComplianceRule -Policy $DlmPolicy -ErrorAction Stop
        $hasDelete = $rules | Where-Object { $_.RetentionComplianceAction -match 'Delete' }
        Add-Gate 'dlm' 'No delete action in pilot' (-not $hasDelete) `
            "Actions=$(( $rules | ForEach-Object RetentionComplianceAction ) -join ', ')"
    } catch { Add-Gate 'dlm' "DLM policy '$DlmPolicy'" $false $_.Exception.Message }
}

$gates | Format-Table -AutoSize
$csv = Join-Path $OutputPath "validation-$stamp.csv"
$gates | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
Write-Host "  -> $csv" -ForegroundColor Green

$fails = ($gates | Where-Object Status -eq 'FAIL').Count
Write-Host ''
if ($fails -eq 0) {
    Write-Host 'OVERALL: PASS — pilot validated.' -ForegroundColor Green
} else {
    Write-Host "OVERALL: FAIL — $fails gate(s) failed. See Troubleshooting before expanding." -ForegroundColor Red
}
