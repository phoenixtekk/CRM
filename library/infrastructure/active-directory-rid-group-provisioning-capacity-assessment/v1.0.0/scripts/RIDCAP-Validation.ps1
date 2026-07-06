<#
.SYNOPSIS
    RIDCAP-Validation.ps1 — Validate the group-provisioning guardrails against Active Directory.
.DESCRIPTION
    PURPOSE
        Checks that the approval guardrails are in place: a dedicated OU holding the project
        groups, conformance to the PRJ-project-id-role naming standard, correct AGDLP group
        scope (Domain Local resource groups), and presence of ownership metadata. Read-only.
        Point it at your-domain project-groups OU and review the pass/fail summary.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\RIDCAP-Validation.ps1 -ProjectGroupsOU "OU=ProjectGroups,OU=Provisioned,DC=your-domain-dn"
        Requires the RSAT ActiveDirectory module and domain read access.
        Optional: -MetadataPassPercent 95 to change the ownership-metadata gate.
    EXPECTED RESULTS
        Per-check PASS/FAIL for OU existence, naming conformance, group scope, and metadata
        coverage. Overall PASS only when every check passes.
.NOTES
    White-label — the repeatable way. Read-only against Active Directory.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectGroupsOU,

    [string]$NamingPattern = '^PRJ-[^-]+-(READ|WRITE|PRIV)$',

    [double]$MetadataPassPercent = 95
)

Import-Module ActiveDirectory -ErrorAction Stop

$results = [System.Collections.Generic.List[object]]::new()
function Add-Check([string]$Name, [bool]$Pass, [string]$Detail) {
    $results.Add([pscustomobject]@{ Check = $Name; Result = ($(if ($Pass) { 'PASS' } else { 'FAIL' })); Detail = $Detail })
}

Write-Host ""
Write-Host "=== RIDCAP Validation — guardrail checks ===" -ForegroundColor Cyan

# Check 1 — dedicated OU exists
$ouExists = $false
try {
    $null = Get-ADOrganizationalUnit -Identity $ProjectGroupsOU -ErrorAction Stop
    $ouExists = $true
    Add-Check "Dedicated OU exists" $true $ProjectGroupsOU
} catch {
    Add-Check "Dedicated OU exists" $false "OU not found: $ProjectGroupsOU"
}

if (-not $ouExists) {
    $results | Format-Table -AutoSize
    Write-Host "Cannot continue without the project-groups OU. Create it per requirement R5." -ForegroundColor Red
    exit 1
}

$groups = Get-ADGroup -SearchBase $ProjectGroupsOU -Filter * -Properties GroupScope, managedBy, info, whenCreated
$total  = @($groups).Count
Write-Host "Project groups found in OU: $total"

if ($total -eq 0) {
    Add-Check "Naming conformance" $false "No groups in OU to evaluate"
    Add-Check "AGDLP scope (DomainLocal)" $false "No groups in OU to evaluate"
    Add-Check "Ownership metadata coverage" $false "No groups in OU to evaluate"
    $results | Format-Table -AutoSize
    exit 1
}

# Check 2 — naming conformance
$nonConforming = @($groups | Where-Object { $_.Name -notmatch $NamingPattern })
$ncCount = $nonConforming.Count
Add-Check "Naming conformance ($NamingPattern)" ($ncCount -eq 0) "$ncCount of $total non-conforming"
if ($ncCount -gt 0) {
    Write-Host "  Non-conforming (first 10): $(@($nonConforming.Name | Select-Object -First 10) -join ', ')" -ForegroundColor Yellow
}

# Check 3 — AGDLP scope: resource groups should be Domain Local
$wrongScope = @($groups | Where-Object { $_.GroupScope -ne 'DomainLocal' })
$wsCount = $wrongScope.Count
Add-Check "AGDLP scope (DomainLocal resource groups)" ($wsCount -eq 0) "$wsCount of $total not DomainLocal"

# Check 4 — ownership metadata coverage
$withMeta = @($groups | Where-Object { ($_.managedBy) -or ($_.info) })
$withDate = @($groups | Where-Object { $_.whenCreated })
$metaPct  = [math]::Round(($withMeta.Count / $total) * 100, 1)
$datePct  = [math]::Round(($withDate.Count / $total) * 100, 1)
$metaPass = ($metaPct -ge $MetadataPassPercent) -and ($datePct -ge $MetadataPassPercent)
Add-Check "Ownership metadata coverage (>= $MetadataPassPercent%)" $metaPass "managedBy/info $metaPct% ; creation date $datePct%"

Write-Host ""
$results | Format-Table -AutoSize

$overall = ($results | Where-Object { $_.Result -eq 'FAIL' }).Count -eq 0
Write-Host ""
Write-Host ("Overall: " + $(if ($overall) { 'PASS' } else { 'FAIL' })) -ForegroundColor $(if ($overall) { 'Green' } else { 'Red' })
Write-Host ""

if ($overall) { exit 0 } else { exit 1 }
