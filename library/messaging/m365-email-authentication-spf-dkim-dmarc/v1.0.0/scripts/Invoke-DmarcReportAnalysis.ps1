<#
.SYNOPSIS
  Parse and analyze DMARC aggregate (RUA) reports — read-only; summarizes each sending source and
  whether it passes DMARC with SPF/DKIM alignment. Makes no changes.
.DESCRIPTION
  Ingests DMARC aggregate report XML (raw .xml, or .gz/.zip extracted first) from a folder, parses each
  <record>, and rolls the results up by source IP: message volume, DMARC disposition, and whether SPF
  and/or DKIM passed AND aligned with the header From domain. Flags any source that is failing DMARC so
  it can be reconciled against the sender inventory before enforcement. Purely local file parsing.
.EXAMPLE
  .\Invoke-DmarcReportAnalysis.ps1 -ReportPath .\dmarc-xml
  # summarize all aggregate reports in the folder

.EXAMPLE
  .\Invoke-DmarcReportAnalysis.ps1 -ReportPath .\dmarc-xml -FailingOnly
  # show only sources currently FAILING DMARC (the enforcement gate)
  (PowerShell 5.1+/7+; no Exchange connection required — this parses report XML on disk)
.NOTES
  Expected results: one row per source IP with pass/align flags. PASS signal for enforcement = every
  LEGITIMATE source shows Aligned=True and DMARC pass; the only failures are known spoof traffic.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $ReportPath,
    [Parameter()] [switch] $FailingOnly
)

if (-not (Test-Path $ReportPath)) { throw "ReportPath not found: $ReportPath" }

$xmlFiles = Get-ChildItem -Path $ReportPath -Filter *.xml -Recurse -ErrorAction SilentlyContinue
if (-not $xmlFiles) {
    Write-Warning "No .xml files found in $ReportPath. If reports are .gz/.zip, extract them first."
    return
}

$rows = New-Object System.Collections.Generic.List[object]

foreach ($file in $xmlFiles) {
    try { [xml]$xml = Get-Content -Path $file.FullName -Raw -ErrorAction Stop }
    catch { Write-Warning "Skipping unparseable file: $($file.Name)"; continue }

    $org       = $xml.feedback.report_metadata.org_name
    $policyDom = $xml.feedback.policy_published.domain

    foreach ($rec in $xml.feedback.record) {
        $sourceIp = $rec.row.source_ip
        $count    = [int]$rec.row.count
        $disp     = $rec.row.policy_evaluated.disposition
        $spfEval  = $rec.row.policy_evaluated.spf     # pass/fail (aligned result)
        $dkimEval = $rec.row.policy_evaluated.dkim    # pass/fail (aligned result)
        $spfAligned  = ($spfEval  -eq 'pass')
        $dkimAligned = ($dkimEval -eq 'pass')
        $dmarcPass   = ($spfAligned -or $dkimAligned)

        $rows.Add([pscustomobject]@{
            ReportOrg   = $org
            PolicyDomain= $policyDom
            SourceIp    = $sourceIp
            Count       = $count
            Disposition = $disp
            SpfAligned  = $spfAligned
            DkimAligned = $dkimAligned
            DmarcPass   = $dmarcPass
        })
    }
}

# Roll up by source IP.
$summary = $rows | Group-Object SourceIp | ForEach-Object {
    $g = $_.Group
    $total = ($g | Measure-Object Count -Sum).Sum
    $passVol = ($g | Where-Object DmarcPass | Measure-Object Count -Sum).Sum
    if (-not $passVol) { $passVol = 0 }
    [pscustomobject]@{
        SourceIp     = $_.Name
        Messages     = $total
        DmarcPassPct = if ($total) { [math]::Round(($passVol / $total) * 100, 1) } else { 0 }
        SpfAligned   = [bool]($g | Where-Object SpfAligned  | Select-Object -First 1)
        DkimAligned  = [bool]($g | Where-Object DkimAligned | Select-Object -First 1)
        Aligned      = ($passVol -gt 0)
        ReportOrgs   = (($g | Select-Object -ExpandProperty ReportOrg -Unique) -join ', ')
    }
} | Sort-Object Messages -Descending

if ($FailingOnly) { $summary = $summary | Where-Object { $_.DmarcPassPct -lt 100 } }

$summary | Format-Table SourceIp,Messages,DmarcPassPct,SpfAligned,DkimAligned,Aligned,ReportOrgs -AutoSize

$totalMsgs = ($rows | Measure-Object Count -Sum).Sum
$failing   = @($summary | Where-Object { $_.DmarcPassPct -lt 100 })
Write-Host "`nParsed $($xmlFiles.Count) report file(s), $totalMsgs message(s), $($summary.Count) unique source IP(s)." -ForegroundColor Cyan
if ($failing.Count -gt 0) {
    Write-Host "$($failing.Count) source(s) not at 100% DMARC pass — reconcile against the sender inventory BEFORE enforcing." -ForegroundColor Yellow
} else {
    Write-Host "All sources at 100% DMARC pass with alignment. Enforcement gate is GREEN." -ForegroundColor Green
}
$summary
