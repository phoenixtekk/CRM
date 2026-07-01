<#
.SYNOPSIS
    GPORAT-Discovery.ps1 — export and inventory every Group Policy Object for rationalization.
.DESCRIPTION
    PURPOSE
        Uses the GroupPolicy module to enumerate all GPOs (Get-GPO) and export each one to an XML
        report (Get-GPOReport) into an output folder. The XML exports are the input for Intune's
        Group Policy analytics and are your retained rollback source. Also records each GPO's links,
        status, and last-modified date and seeds the rationalization register CSV
        ('Rationalization Register - All GPOs - Assess') with an empty Disposition column to fill in.
        Read-only against the domain.
    HOW TO RUN
        On a domain-joined admin workstation with RSAT Group Policy Management Tools installed:
        powershell -ExecutionPolicy Bypass -File .\GPORAT-Discovery.ps1 -OutputPath .\GPO-Export
    EXPECTED RESULTS
        One <GPOName>.xml per GPO in the output folder, a console inventory table (DisplayName, Id,
        GpoStatus, Links, Created/Modified, Export), and two CSVs: GPORAT-Inventory.csv and the
        register seed GPORAT-Rationalization-Register.csv (Disposition / Intent / Owner blank).
.NOTES
    Workplace Marketplace — Migrations. Read-only. Requires the GroupPolicy module
    (Add-WindowsCapability -Online -Name Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0).
#>
[CmdletBinding()]
param(
    [string] $OutputPath = ".\GPO-Export"
)

Write-Host "`n=== GPO discovery / export ($($env:USERDNSDOMAIN)) ===" -ForegroundColor Cyan

if (-not (Get-Module -ListAvailable -Name GroupPolicy)) {
    Write-Host "GroupPolicy module not found. Install RSAT Group Policy Management Tools first." -ForegroundColor Yellow
    return
}
Import-Module GroupPolicy -ErrorAction Stop

if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }

$gpos = Get-GPO -All | Sort-Object DisplayName
Write-Host ("Found {0} GPOs. Exporting XML reports to {1}" -f $gpos.Count, (Resolve-Path $OutputPath)) -ForegroundColor Green

$summary = foreach ($g in $gpos) {
    $safe = ($g.DisplayName -replace '[\\/:*?"<>|]', '_')
    $xml  = Join-Path $OutputPath ("{0}.xml" -f $safe)
    $links = $null
    try {
        Get-GPOReport -Guid $g.Id -ReportType Xml -Path $xml -ErrorAction Stop
        $status = "exported"
        # Count where this GPO is linked (read-only) for dead-link detection downstream.
        try {
            [xml]$rpt = Get-Content $xml -Raw
            $links = @($rpt.GPO.LinksTo).Count
        } catch { $links = "?" }
    } catch {
        $status = "FAILED: $($_.Exception.Message)"
    }
    [pscustomobject]@{
        DisplayName  = $g.DisplayName
        Id           = $g.Id
        GpoStatus    = $g.GpoStatus
        Links        = $links
        CreationTime = $g.CreationTime
        ModifiedTime = $g.ModificationTime
        Export       = $status
    }
}

$summary | Format-Table DisplayName, GpoStatus, Links, ModifiedTime, Export -AutoSize
$csv = Join-Path $OutputPath "GPORAT-Inventory.csv"
$summary | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
Write-Host ("`nInventory saved: {0}" -f $csv) -ForegroundColor Green

# Seed the rationalization register with blank decision columns to be filled by the owner.
$register = foreach ($s in $summary) {
    [pscustomobject]@{
        DisplayName    = $s.DisplayName
        Id             = $s.Id
        GpoStatus      = $s.GpoStatus
        Links          = $s.Links
        ModifiedTime   = $s.ModifiedTime
        ReadinessPct   = ''   # fill from Group Policy analytics (Step 3) or GPORAT-Report.ps1 -UseGraph
        Disposition    = ''   # keep | retire | consolidate | replace
        ConsolidateInto= ''   # surviving GPO name when Disposition = consolidate
        ReplaceSurface = ''   # platform script | proactive remediation | endpoint security (when replace)
        Intent         = ''   # one-line "what this is for" (keep/consolidate)
        Owner          = ''
    }
}
$regCsv = Join-Path $OutputPath "GPORAT-Rationalization-Register.csv"
$register | Export-Csv -Path $regCsv -NoTypeInformation -Encoding UTF8
Write-Host ("Register seed saved: {0}  ('Rationalization Register - All GPOs - Assess')" -f $regCsv) -ForegroundColor Green

$failed = @($summary | Where-Object { $_.Export -like 'FAILED*' })
if ($failed.Count) { Write-Host ("{0} GPO export(s) failed — see table above." -f $failed.Count) -ForegroundColor Yellow }

# Flag likely-dead GPOs (unlinked) as retire candidates (informational only).
$dead = @($summary | Where-Object { $_.Links -eq 0 })
if ($dead.Count) { Write-Host ("{0} GPO(s) appear unlinked — retire candidates to review." -f $dead.Count) -ForegroundColor Yellow }

Write-Host "Retain this export folder as your rollback source. Import the XML into Group Policy analytics next." -ForegroundColor Green
