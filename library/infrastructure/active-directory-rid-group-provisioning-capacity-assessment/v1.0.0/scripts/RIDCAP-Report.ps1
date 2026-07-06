<#
.SYNOPSIS
    RIDCAP-Report.ps1 — Project-group growth & orphan report plus a projected RID lifetime.
.DESCRIPTION
    PURPOSE
        Counts provisioned project groups by parsed project id, flags groups whose project is
        not on the supplied active-projects list (orphans), and computes a projected RID pool
        lifetime from a supplied annual burn rate. Read-only.
        Run it against your-domain to quantify sprawl and to see the runway in years.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\RIDCAP-Report.ps1 -ProjectGroupsOU "OU=ProjectGroups,OU=Provisioned,DC=your-domain-dn" -ActiveProjectsFile .\active-projects.txt -AnnualBurn 6240
        active-projects.txt = one active project id per line.
        Requires the RSAT ActiveDirectory module and domain read access.
    EXPECTED RESULTS
        Total project-group count, top project ids by group count, an orphan list, and a
        projected years-to-exhaust from remaining RIDs divided by the supplied annual burn.
.NOTES
    White-label — the repeatable way. Read-only against Active Directory.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectGroupsOU,

    [string]$ActiveProjectsFile,

    [double]$AnnualBurn = 0,

    # Which hyphen-delimited field holds the project id in PRJ-projectid-role. Field 1 = index 1.
    [int]$ProjectIdField = 1
)

Import-Module ActiveDirectory -ErrorAction Stop

Write-Host ""
Write-Host "=== RIDCAP Report — project-group growth, orphans & projected lifetime ===" -ForegroundColor Cyan

$groups = Get-ADGroup -SearchBase $ProjectGroupsOU -Filter * -Properties whenCreated, managedBy, info
$total  = @($groups).Count
Write-Host "Total project groups: $total"

if ($total -gt 0) {
    Write-Host ""
    Write-Host "Top project ids by group count (first 20):" -ForegroundColor Yellow
    $byProject = $groups | Group-Object { ($_.Name -split '-')[$ProjectIdField] }
    $byProject |
        Select-Object @{N='ProjectId';E={$_.Name}}, Count |
        Sort-Object Count -Descending |
        Select-Object -First 20 |
        Format-Table -AutoSize
}

# Orphan detection against the active-projects list
if ($ActiveProjectsFile) {
    if (-not (Test-Path $ActiveProjectsFile)) {
        Write-Host "Active-projects file not found: $ActiveProjectsFile" -ForegroundColor Red
    } else {
        $activeIds = Get-Content $ActiveProjectsFile |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ -ne '' }
        $activeSet = [System.Collections.Generic.HashSet[string]]::new(
            [string[]]$activeIds, [System.StringComparer]::OrdinalIgnoreCase)

        $orphans = $groups | Where-Object {
            $projId = ($_.Name -split '-')[$ProjectIdField]
            -not $activeSet.Contains($projId)
        }
        $orphanCount = @($orphans).Count
        Write-Host ""
        Write-Host "Orphaned project groups (project id not on active list): $orphanCount" -ForegroundColor $(if ($orphanCount -gt 0) { 'Red' } else { 'Green' })
        if ($orphanCount -gt 0) {
            $orphans |
                Select-Object Name, whenCreated,
                    @{N='ProjectId';E={ ($_.Name -split '-')[$ProjectIdField] }} |
                Sort-Object whenCreated |
                Format-Table -AutoSize
            Write-Host "Feed these to RIDCAP-LifecycleCleanup.ps1 (preview first) to disable/stage/delete." -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "No -ActiveProjectsFile supplied; skipping orphan detection." -ForegroundColor Yellow
}

# Projected RID lifetime from supplied annual burn
if ($AnnualBurn -gt 0) {
    $domain     = Get-ADDomain
    $ridManager = Get-ADObject "CN=RID Manager$,CN=System,$($domain.DistinguishedName)" -Property rIDAvailablePool
    $pool       = [uint64]$ridManager.rIDAvailablePool
    $divisor    = [uint64]([math]::Pow(2, 32))
    $consumed   = [uint64]($pool -band ($divisor - 1))
    $maximum    = [uint64]([math]::Floor($pool / $divisor))
    $remaining  = $maximum - $consumed
    $years      = [math]::Round($remaining / $AnnualBurn, 0)

    Write-Host ""
    Write-Host "Projected RID lifetime:" -ForegroundColor Cyan
    [pscustomobject]@{
        RIDsRemaining         = $remaining
        SuppliedAnnualBurn    = $AnnualBurn
        ProjectedYearsToExhaust = $years
    } | Format-List
    Write-Host "annual burn = groups-per-project x projects-per-week x 52 (measure your own rate)."
} else {
    Write-Host "No -AnnualBurn supplied; skipping lifetime projection." -ForegroundColor Yellow
}

Write-Host ""
exit 0
