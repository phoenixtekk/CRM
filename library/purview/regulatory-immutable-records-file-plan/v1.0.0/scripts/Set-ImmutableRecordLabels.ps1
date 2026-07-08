<#
.SYNOPSIS
    Create/verify record (immutable) and regulatory-record labels, mapped to the file plan (SAFE: -WhatIf/dry-run by default; writes only with -Commit; regulatory writes also require -AllowRegulatory -SignOffRef).

.DESCRIPTION
    Reads a label design and creates record labels (New-ComplianceTag -IsRecordLabel) with their
    file-plan property attached from the descriptor names, and — only when explicitly authorized —
    regulatory-record labels (-Regulatory), which are ONE-WAY and irreversible. Refuses to create an
    UNMAPPED record label, and refuses any regulatory label without -AllowRegulatory -SignOffRef.

.EXAMPLE
    .\Set-ImmutableRecordLabels.ps1 -DesignPath .\records-design.json
    Dry-run: shows every label that would be created/verified and its file-plan mapping. No changes.

.EXAMPLE
    .\Set-ImmutableRecordLabels.ps1 -DesignPath .\records-design.json -Commit
    Creates the non-regulatory record labels (regulatory ones are skipped without -AllowRegulatory).

.EXAMPLE
    .\Set-ImmutableRecordLabels.ps1 -DesignPath .\records-design.json -Commit -AllowRegulatory -SignOffRef "LEGAL-2026-014"
    Also creates regulatory-record labels — IRREVERSIBLE; apply only to disposable test items in pilot.
    PowerShell 5.1+/7+. Connect first: Connect-IPPSSession (add -ConnectionUri for Gov clouds).

.NOTES
    Expected results (PASS): each designed record label exists with IsRecordLabel true and its file-plan
    descriptors attached; regulatory labels exist only when authorized. FAIL: a label is unmapped, or a
    regulatory label was requested without -AllowRegulatory -SignOffRef (the script refuses it). Design
    JSON label shape (array under "labels"):
      { "name":"Record Label - Contracts-7yr - Pilot", "regulatory":false,
        "action":"KeepAndDelete", "durationDays":2555, "retentionType":"ModificationAgeInDays",
        "reviewerEmail":"records-reviewers@contoso.com",
        "filePlan": { "authority":"Authority - Records-Schedule-2026", "category":"Contracts",
                      "subCategory":"Vendor-Contracts", "citation":"SOX",
                      "department":"Finance", "referenceId":"REC-CON-001" } }
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$DesignPath,
    [switch]$Commit,
    [switch]$AllowRegulatory,
    [string]$SignOffRef
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $DesignPath)) { throw "Design file not found: $DesignPath" }
$design = Get-Content $DesignPath -Raw | ConvertFrom-Json
$labels = @($design.labels)
if ($labels.Count -eq 0) { throw "No 'labels' array in design." }

$mode = if ($Commit) { 'COMMIT' } else { 'DRY-RUN (-WhatIf)' }
Write-Host ("== Set-ImmutableRecordLabels [$mode] ==") -ForegroundColor Cyan
if ($AllowRegulatory -and -not $SignOffRef) {
    throw "-AllowRegulatory requires -SignOffRef '<records/legal sign-off reference>'."
}

# Build the file-plan property object per Microsoft's documented Settings/Key-Value format.
function New-FilePlanPropertyObject($fp) {
    if (-not $fp) { return $null }
    $settings = @()
    $map = @{
        'FilePlanPropertyAuthority'   = $fp.authority
        'FilePlanPropertyCategory'    = $fp.category
        'FilePlanPropertySubcategory' = $fp.subCategory
        'FilePlanPropertyCitation'    = $fp.citation
        'FilePlanPropertyDepartment'  = $fp.department
        'FilePlanPropertyReferenceId' = $fp.referenceId
    }
    foreach ($k in $map.Keys) {
        if ($map[$k]) { $settings += @{ Key = $k; Value = "$($map[$k])" } }
    }
    if ($settings.Count -eq 0) { return $null }
    return (@{ Settings = $settings } | ConvertTo-Json -Depth 5 -Compress)
}

$report = [System.Collections.Generic.List[object]]::new()

foreach ($l in $labels) {
    $isReg = [bool]$l.regulatory
    $fppJson = New-FilePlanPropertyObject $l.filePlan
    $mapped = [bool]$fppJson

    # Guardrail 1: no unmapped record labels — an immutable record must trace to an authority/citation.
    if (-not $mapped) {
        $report.Add([pscustomobject]@{ Name=$l.name; Type=(if($isReg){'REGULATORY'}else{'record'}); Action='REFUSED'; Note='UNMAPPED — add filePlan (authority/citation) before creating.' })
        continue
    }

    # Guardrail 2: regulatory labels require explicit authorization + sign-off.
    if ($isReg -and -not $AllowRegulatory) {
        $report.Add([pscustomobject]@{ Name=$l.name; Type='REGULATORY'; Action='SKIPPED'; Note='Requires -AllowRegulatory -SignOffRef (IRREVERSIBLE).' })
        continue
    }

    $existing = Get-ComplianceTag -Identity $l.name -ErrorAction SilentlyContinue
    if ($existing) {
        $report.Add([pscustomobject]@{ Name=$l.name; Type=(if($isReg){'REGULATORY'}else{'record'}); Action='EXISTS'; Note=("IsRecord={0}; IsReg={1}" -f $existing.IsRecordLabel, $existing.IsRegulatory) })
        continue
    }

    $note = if ($isReg) { "ONE-WAY; sign-off=$SignOffRef" } else { 'immutable, reversible (un-declarable)' }
    $report.Add([pscustomobject]@{ Name=$l.name; Type=(if($isReg){'REGULATORY'}else{'record'}); Action='CREATE'; Note=$note })

    if ($Commit) {
        $args = @{
            Name             = $l.name
            RetentionAction  = $l.action
            RetentionDuration= $l.durationDays
            RetentionType    = $l.retentionType
            FilePlanProperty = $fppJson
        }
        if ($isReg) { $args['Regulatory'] = $true } else { $args['IsRecordLabel'] = $true }
        if ($l.PSObject.Properties.Match('reviewerEmail').Count -and $l.reviewerEmail) { $args['ReviewerEmail'] = $l.reviewerEmail }
        if ($l.PSObject.Properties.Match('eventType').Count -and $l.eventType)         { $args['EventType']     = $l.eventType }
        New-ComplianceTag @args -ErrorAction Stop | Out-Null
    }
}

$report | Format-Table -AutoSize
$refused = @($report | Where-Object Action -eq 'REFUSED')
if ($refused.Count -gt 0) {
    Write-Host ("{0} label(s) REFUSED as unmapped — every immutable record must trace to an authority/citation." -f $refused.Count) -ForegroundColor Red
}
if ($Commit) {
    Write-Host ("Committed. Created: {0}." -f (@($report | Where-Object Action -eq 'CREATE').Count)) -ForegroundColor Green
    if (-not $AllowRegulatory -and @($report | Where-Object Action -eq 'SKIPPED').Count -gt 0) {
        Write-Host "Regulatory labels were SKIPPED — re-run with -AllowRegulatory -SignOffRef to create them (IRREVERSIBLE)." -ForegroundColor Yellow
    }
} else {
    Write-Host "DRY-RUN only. Re-run with -Commit to apply." -ForegroundColor Yellow
}
