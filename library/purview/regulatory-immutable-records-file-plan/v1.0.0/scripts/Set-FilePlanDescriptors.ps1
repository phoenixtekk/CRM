<#
.SYNOPSIS
    Create/verify file-plan descriptors from a JSON design (SAFE: -WhatIf/dry-run by default; writes only with -Commit).

.DESCRIPTION
    Reads a descriptor design (authority/category/sub-category/citation/department/reference ID) and
    creates any that are missing via the New-FilePlanProperty* cmdlets, reusing existing descriptors
    rather than duplicating them. Dry-run by default; pass -Commit to write.

.EXAMPLE
    .\Set-FilePlanDescriptors.ps1 -DesignPath .\records-design.json
    Dry-run: shows which descriptors would be created vs already exist. No changes made.

.EXAMPLE
    .\Set-FilePlanDescriptors.ps1 -DesignPath .\records-design.json -Commit
    Creates the missing descriptors.
    PowerShell 5.1+/7+. Connect first: Connect-IPPSSession (add -ConnectionUri for Gov clouds).

.NOTES
    Expected results (PASS): every descriptor in the design exists after -Commit; existing descriptors are
    reused, not duplicated. FAIL: a descriptor cannot be created (check the Records Management role and
    E5/E5 Compliance licensing). Design JSON shape:
      { "authority":["Authority - Records-Schedule-2026"],
        "category":["Contracts"], "subCategory":["Vendor-Contracts"],
        "citation":[{"name":"SOX","url":"https://contoso.example/citations/sox","jurisdiction":"US"}],
        "department":["Finance"], "referenceId":["REC-CON-001"] }
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$DesignPath,
    [switch]$Commit
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $DesignPath)) { throw "Design file not found: $DesignPath" }
$design = Get-Content $DesignPath -Raw | ConvertFrom-Json
$mode = if ($Commit) { 'COMMIT' } else { 'DRY-RUN (-WhatIf)' }
Write-Host ("== Set-FilePlanDescriptors [$mode] ==") -ForegroundColor Cyan

$plan = [System.Collections.Generic.List[object]]::new()

function Resolve-Existing([string]$GetCmd) {
    if (Get-Command $GetCmd -ErrorAction SilentlyContinue) {
        try { return @(& $GetCmd -ErrorAction Stop | Select-Object -ExpandProperty Name) } catch { return @() }
    }
    Write-Warning "$GetCmd not available — verify Records management licensing/role."
    return @()
}

# Simple string descriptors
$simple = @(
    @{ Field='authority';   New='New-FilePlanPropertyAuthority';   Get='Get-FilePlanPropertyAuthority' }
    @{ Field='category';    New='New-FilePlanPropertyCategory';    Get='Get-FilePlanPropertyCategory' }
    @{ Field='subCategory'; New='New-FilePlanPropertySubCategory'; Get='Get-FilePlanPropertySubCategory' }
    @{ Field='department';  New='New-FilePlanPropertyDepartment';  Get='Get-FilePlanPropertyDepartment' }
    @{ Field='referenceId'; New='New-FilePlanPropertyReferenceId'; Get='Get-FilePlanPropertyReferenceId' }
)

foreach ($s in $simple) {
    $values = @($design.$($s.Field))
    if (-not $values -or $values.Count -eq 0) { continue }
    $existing = Resolve-Existing $s.Get
    foreach ($v in $values) {
        if ($existing -contains $v) {
            $plan.Add([pscustomobject]@{ Kind=$s.Field; Name=$v; Action='REUSE (exists)' })
        } else {
            $plan.Add([pscustomobject]@{ Kind=$s.Field; Name=$v; Action='CREATE' })
            if ($Commit) {
                & $s.New -Name $v -ErrorAction Stop | Out-Null
            }
        }
    }
}

# Citations (may carry URL + jurisdiction)
$citations = @($design.citation)
if ($citations.Count -gt 0) {
    $existingCit = Resolve-Existing 'Get-FilePlanPropertyCitation'
    foreach ($c in $citations) {
        $name = if ($c -is [string]) { $c } else { $c.name }
        if ($existingCit -contains $name) {
            $plan.Add([pscustomobject]@{ Kind='citation'; Name=$name; Action='REUSE (exists)' })
        } else {
            $plan.Add([pscustomobject]@{ Kind='citation'; Name=$name; Action='CREATE' })
            if ($Commit) {
                $args = @{ Name = $name }
                if ($c.PSObject.Properties.Match('url').Count -and $c.url)                 { $args['CitationUrl'] = $c.url }
                if ($c.PSObject.Properties.Match('jurisdiction').Count -and $c.jurisdiction){ $args['CitationJurisdiction'] = $c.jurisdiction }
                New-FilePlanPropertyCitation @args -ErrorAction Stop | Out-Null
            }
        }
    }
}

$plan | Format-Table -AutoSize
$toCreate = @($plan | Where-Object Action -eq 'CREATE').Count
if ($Commit) {
    Write-Host ("Committed. Descriptors created: {0}; reused: {1}." -f $toCreate, (@($plan | Where-Object Action -like 'REUSE*').Count)) -ForegroundColor Green
} else {
    Write-Host ("DRY-RUN only. Would create {0} descriptor(s). Re-run with -Commit to apply." -f $toCreate) -ForegroundColor Yellow
}
