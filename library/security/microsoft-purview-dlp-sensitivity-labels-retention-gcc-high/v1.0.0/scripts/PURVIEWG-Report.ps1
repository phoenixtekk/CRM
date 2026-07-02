<#
.SYNOPSIS
    PURVIEWG-Report.ps1 — produce a Purview coverage / classification / DLP-event report (read-only, GCC High).
.DESCRIPTION
    PURPOSE
        Generates a review-friendly report of the Purview posture on a GCC High tenant: the
        sensitivity labels in the taxonomy, the designed policy objects and whether each is present,
        and pointers to the classification and DLP-event data an admin should review before
        expanding. Read-only — it collects and prints, it never changes configuration. Writes an
        optional CSV summary to the path you pass in OutputCsv.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PURVIEWG-Report.ps1
        powershell -ExecutionPolicy Bypass -File .\PURVIEWG-Report.ps1 -OutputCsv .\purviewg-report.csv

        Required Graph scopes (delegated): InformationProtectionPolicy.Read, Policy.Read.All,
        Directory.Read.All.
        GCC High: connects with Connect-MgGraph -Environment USGov (graph.microsoft.us). DLP-event and
        classification analytics live in compliance.microsoft.us (Activity Explorer, DLP Alerts) and
        Security & Compliance PowerShell; the report links you there for the data Graph does not expose.
        For DoD change USGov to USGovDoD.
    EXPECTED RESULTS
        An on-screen report (and optional CSV) listing labels, object presence, and review pointers.
        PASS = report generates and shows the taxonomy plus object presence. FAIL = wrong cloud or a
        connection/permission error (the report says which).
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph (US Gov endpoints for GCC High).
#>

[CmdletBinding()]
param(
    [string]   $OutputCsv        = '',
    [string[]] $LabelNames       = @('Public','General','Confidential','Confidential \ CUI'),
    [string]   $LabelPolicyName  = 'LP-Purview-Pilot',
    [string]   $AutoLabelName    = 'AL-CUI-ServiceSide',
    [string]   $DlpPolicyName    = 'DLP-CUI-Baseline',
    [string]   $RetentionLabel   = 'Ret-CUI-7yr',
    [ValidateSet('USGov','USGovDoD')]
    [string]   $GraphEnvironment = 'USGov'
)

$ErrorActionPreference = 'Stop'
$rows = New-Object System.Collections.Generic.List[object]

try {
    Connect-MgGraph -Environment $GraphEnvironment -Scopes @('InformationProtectionPolicy.Read','Policy.Read.All','Directory.Read.All') | Out-Null
    $ctx = Get-MgContext
    Write-Host ("Environment : {0}" -f $ctx.Environment)
    Write-Host ("Tenant      : {0}" -f $ctx.TenantId)
    if ($ctx.Environment -notin @('USGov','USGovDoD')) {
        Write-Warning 'Not a US Gov cloud — this report may reflect the wrong (Commercial) tenant. Reconnect with -Environment USGov.'
    }
}
catch {
    Write-Error ("Graph connect (US Gov) failed: {0}" -f $_.Exception.Message)
    return
}

Write-Host ''
Write-Host '=== Sensitivity label taxonomy ===' -ForegroundColor Cyan
try {
    $labels = Get-MgInformationProtectionPolicyLabel -All
    $have = @($labels | Select-Object -ExpandProperty Name)
    foreach ($n in $LabelNames) {
        $present = $have -contains $n
        $rows.Add([pscustomobject]@{ Category='Label'; Object=$n; Present=$present })
        Write-Host ("  [{0}] {1}" -f ($(if($present){'x'}else{' '})), $n)
    }
    $extra = $have | Where-Object { $_ -notin $LabelNames }
    if ($extra) { Write-Host ("  (Other labels present: {0})" -f ($extra -join ', ')) -ForegroundColor DarkGray }
}
catch {
    Write-Warning ("Could not read labels via Graph: {0}. Review in compliance.microsoft.us." -f $_.Exception.Message)
}

Write-Host ''
Write-Host '=== Designed policy objects ===' -ForegroundColor Cyan
$policyObjects = @(
    @{ Category='Label policy'; Object=$LabelPolicyName },
    @{ Category='Auto-label policy'; Object=$AutoLabelName },
    @{ Category='DLP policy'; Object=$DlpPolicyName },
    @{ Category='Retention label'; Object=$RetentionLabel }
)
$scc = Get-Command -Name Get-DlpCompliancePolicy -ErrorAction SilentlyContinue
foreach ($po in $policyObjects) {
    $present = $null
    if ($scc) {
        try {
            switch ($po.Category) {
                'DLP policy'        { $present = [bool](Get-DlpCompliancePolicy -ErrorAction Stop | Where-Object Name -eq $po.Object) }
                'Auto-label policy' { $present = [bool](Get-AutoSensitivityLabelPolicy -ErrorAction Stop | Where-Object Name -eq $po.Object) }
                'Retention label'   { $present = [bool](Get-ComplianceTag -ErrorAction Stop | Where-Object Name -eq $po.Object) }
                default             { $present = $null }
            }
        } catch { $present = $null }
    }
    $rows.Add([pscustomobject]@{ Category=$po.Category; Object=$po.Object; Present=$present })
    $mark = if ($present -eq $true) { 'x' } elseif ($present -eq $false) { ' ' } else { '?' }
    Write-Host ("  [{0}] {1}: {2}" -f $mark, $po.Category, $po.Object)
}
if (-not $scc) {
    Write-Host '  (DLP/auto-label/retention marked ? — connect Security & Compliance PowerShell (GCC High) to resolve.)' -ForegroundColor DarkGray
}

Write-Host ''
Write-Host '=== Review pointers (GCC High portals) ===' -ForegroundColor Cyan
Write-Host '  Classification analytics : compliance.microsoft.us -> Data classification -> Content/Activity explorer'
Write-Host '  DLP events / alerts       : compliance.microsoft.us -> Data Loss Prevention -> Alerts; Activity explorer'
Write-Host '  Retention / records       : compliance.microsoft.us -> Data Lifecycle Management; Records Management'
Write-Host '  Auto-label simulation     : compliance.microsoft.us -> Information Protection -> Auto-labeling (policy results)'

if ($OutputCsv) {
    try {
        $rows | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
        Write-Host ''
        Write-Host ("CSV written: {0}" -f $OutputCsv) -ForegroundColor Green
    } catch {
        Write-Warning ("Could not write CSV: {0}" -f $_.Exception.Message)
    }
}

Write-Host ''
Write-Host 'Report complete (read-only).' -ForegroundColor Green
