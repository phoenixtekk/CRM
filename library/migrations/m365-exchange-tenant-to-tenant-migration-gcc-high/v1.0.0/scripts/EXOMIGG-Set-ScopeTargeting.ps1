<#
.SYNOPSIS
    EXOMIGG-Set-ScopeTargeting.ps1 — Build pilot/wave target groups for a GCC High migration (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Creates and populates the named scope groups the migration is driven by (for example EXOMIGG-Pilot and
        EXOMIGG-Wave1..N) from a mapping CSV, so each phase moves a controlled, named set of mailboxes. It is SAFE
        BY DEFAULT: it previews with -WhatIf and creates/changes nothing until you pass -Execute. Placeholders use
        plain text like your-admin-upn and your-mapping.csv (columns: PrimarySmtpAddress, Wave).
    HOW TO RUN
        Preview (default, no changes):
          powershell -ExecutionPolicy Bypass -File .\EXOMIGG-Set-ScopeTargeting.ps1 -AdminUpn your-admin-upn -MappingCsv your-mapping.csv -Wave Pilot
        Apply (explicit):
          powershell -ExecutionPolicy Bypass -File .\EXOMIGG-Set-ScopeTargeting.ps1 -AdminUpn your-admin-upn -MappingCsv your-mapping.csv -Wave Pilot -Execute
        (Connects with -ExchangeEnvironmentName O365USGovGCCHigh)
    EXPECTED RESULTS
        In preview: the group name and the members that WOULD be added, with nothing created. With -Execute: the
        group EXOMIGG-<Wave> is created if absent and the mapped members are added; membership is read back.
        PASS = intended membership present; FAIL = surfaced error with troubleshooting ref.
.NOTES
    White-label — the repeatable way. Connects to EXO US Gov endpoints. Change-capable but DEFAULTS to -WhatIf.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)] [string] $AdminUpn,
    [Parameter(Mandatory = $true)] [string] $MappingCsv,     # columns: PrimarySmtpAddress, Wave (e.g. Pilot, Wave1)
    [Parameter(Mandatory = $true)] [string] $Wave,           # which wave value to build a group for (e.g. Pilot)
    [Parameter(Mandatory = $false)] [string] $GroupPrefix = 'EXOMIGG-',
    [Parameter(Mandatory = $false)] [switch] $Execute        # must be present to make changes; otherwise -WhatIf
)

$ErrorActionPreference = 'Stop'

if (-not $Execute) {
    $WhatIfPreference = $true
    Write-Host "RUNNING IN PREVIEW (-WhatIf) MODE — no groups created or modified. Re-run with -Execute to apply." -ForegroundColor Yellow
} else {
    Write-Host "EXECUTE MODE — the group and its membership WILL be created/modified." -ForegroundColor Red
}

if (-not (Test-Path $MappingCsv)) { throw "Mapping CSV not found: $MappingCsv" }
$map = Import-Csv $MappingCsv
$members = ($map | Where-Object { $_.Wave -eq $Wave }).PrimarySmtpAddress
if (-not $members) { throw "No rows in '$MappingCsv' with Wave = '$Wave'." }

$groupName  = "$GroupPrefix$Wave"
$groupAlias = ($groupName -replace '[^A-Za-z0-9]', '')

Import-Module ExchangeOnlineManagement -ErrorAction Stop
try {
    Connect-ExchangeOnline -ExchangeEnvironmentName O365USGovGCCHigh -UserPrincipalName $AdminUpn -ShowBanner:$false
} catch {
    Write-Host "FAIL: could not connect to GCC High Exchange Online (06-troubleshooting.md #1)." -ForegroundColor Red
    throw
}

Write-Host "`n=== Target group: $groupName ($([string]($members | Measure-Object).Count) member(s) from Wave '$Wave') ===" -ForegroundColor Cyan
$members | ForEach-Object { Write-Host "  would include: $_" }

# Create the mail-enabled security / distribution group if absent
$existing = Get-DistributionGroup -Identity $groupName -ErrorAction SilentlyContinue
if (-not $existing) {
    if ($PSCmdlet.ShouldProcess($groupName, "New-DistributionGroup (Type Security)")) {
        New-DistributionGroup -Name $groupName -Alias $groupAlias -Type Security -Confirm:$false | Out-Null
        Write-Host "Created group $groupName." -ForegroundColor Green
    }
} else {
    Write-Host "Group $groupName already exists — will reconcile membership." -ForegroundColor Yellow
}

# Add members
foreach ($m in $members) {
    if ($PSCmdlet.ShouldProcess("$groupName", "Add member $m")) {
        try {
            Add-DistributionGroupMember -Identity $groupName -Member $m -ErrorAction Stop -Confirm:$false
            Write-Host "  added: $m" -ForegroundColor Green
        } catch {
            if ($_.Exception.Message -match 'already a member') {
                Write-Host "  already a member: $m" -ForegroundColor DarkGray
            } else {
                Write-Host "  FAILED to add $m : $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}

# Read back membership (best effort; skipped in pure preview if group doesn't yet exist)
if ($Execute -and (Get-DistributionGroup -Identity $groupName -ErrorAction SilentlyContinue)) {
    Write-Host "`nCurrent membership of ${groupName}:" -ForegroundColor Cyan
    Get-DistributionGroupMember -Identity $groupName | Select-Object DisplayName, PrimarySmtpAddress | Format-Table -AutoSize
}

Write-Host "Use this group as the scope for the pilot/wave move (native New-MigrationBatch, or the vendor tool's group selector)." -ForegroundColor Yellow
Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
