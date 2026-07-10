<#
.SYNOPSIS
    DEFCSPM-Hunt.ps1 — query Defender for Cloud recommendations and attack paths via Azure Resource
    Graph (KQL). Read-only.
.DESCRIPTION
    PURPOSE
        Read-only hunting/reporting for the "Microsoft Defender for Cloud — CSPM & Secure Score
        Remediation" solution. Runs KQL against the Azure Resource Graph 'securityresources' table
        to list, by risk, the open security recommendations (-Mode Recommendations) or the attack
        paths / high-risk items (-Mode AttackPaths, a Defender CSPM feature). Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DEFCSPM-Hunt.ps1 -Mode Recommendations
        powershell -ExecutionPolicy Bypass -File .\DEFCSPM-Hunt.ps1 -Mode AttackPaths
        Requires Az.Accounts and Az.ResourceGraph. Run Connect-AzAccount first, or it will prompt.
    EXPECTED RESULTS
        Recommendations: a ranked list of unhealthy security assessments (name, severity, resource).
        AttackPaths: the attack-path / high-risk records from the cloud security graph (Defender
        CSPM). Empty AttackPaths output usually means Defender CSPM is not yet active or warmed up.
.NOTES
    White-label. Read-only. The embedded KQL only reads posture data via Resource Graph.
#>
[CmdletBinding()]
param(
    [ValidateSet('Recommendations','AttackPaths')]
    [string]$Mode = 'Recommendations',
    [int]$Top = 25
)

foreach ($m in 'Az.Accounts','Az.ResourceGraph') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Az -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.ResourceGraph -ErrorAction Stop

if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }

Write-Host "`n=== Defender for Cloud — Resource Graph hunt: $Mode (read-only) ===" -ForegroundColor Cyan

if ($Mode -eq 'Recommendations') {
    # KQL: open (unhealthy) security recommendations, ranked by severity.
    $kql = @"
securityresources
| where type == 'microsoft.security/assessments'
| extend status = tostring(properties.status.code)
| where status == 'Unhealthy'
| extend name = tostring(properties.displayName),
         severity = tostring(properties.metadata.severity),
         resourceId = tostring(properties.resourceDetails.Id)
| project name, severity, status, resourceId
| order by severity asc, name asc
"@
} else {
    # KQL: attack paths / high-risk items from the cloud security graph (Defender CSPM).
    $kql = @"
securityresources
| where type =~ 'microsoft.security/attackpaths'
| extend pathName = tostring(properties.displayName),
         riskLevel = tostring(properties.riskLevel),
         entryPoint = tostring(properties.attackPathType)
| project pathName, riskLevel, entryPoint, id
| order by riskLevel asc
"@
}

try {
    $rows = Search-AzGraph -Query $kql -First $Top -ErrorAction Stop
    $count = ($rows | Measure-Object).Count
    if ($count -gt 0) {
        $rows | Format-Table -AutoSize | Out-String | Write-Host
        Write-Host ("Returned {0} row(s) (top {1})." -f $count, $Top) -ForegroundColor Green
    } else {
        if ($Mode -eq 'AttackPaths') {
            Write-Host "No attack-path data returned." -ForegroundColor Yellow
            Write-Host "Confirm Defender CSPM is enabled (DEFCSPM-Validate.ps1) and allow the security graph to warm up." -ForegroundColor Yellow
        } else {
            Write-Host "No open recommendations returned (or assessments not yet populated)." -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host ("Resource Graph query failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    Write-Host "Confirm Az.ResourceGraph is installed and the account has read access at scope." -ForegroundColor Yellow
}
