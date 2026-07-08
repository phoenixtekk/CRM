<#
.SYNOPSIS
    IPCONT-Report-ContainerLabeling.ps1 — coverage + posture report across all Teams/Groups/Sites (SAFE: read-only).
.DESCRIPTION
    PURPOSE
        Read-only management report. Enumerates every M365 Group/Team (Graph) and SharePoint site (SPO)
        and summarizes CONTAINER-LABEL COVERAGE — how many containers carry a container label vs not,
        broken down by assigned label/tier — plus each container's privacy, guest, and external-sharing
        posture. Produces the evidence artifact (Container Inventory - Report). Run on a schedule to keep
        coverage healthy. Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\IPCONT-Report-ContainerLabeling.ps1 -CsvPath .\ContainerReport.csv -SPOAdminUrl https://contoso-admin.sharepoint.com
        Requires: Microsoft.Graph (read scopes) and, for sites, Microsoft.Online.SharePoint.PowerShell.
    EXPECTED RESULTS
        A CSV per container plus an on-screen coverage summary (labeled %, count per tier, unlabeled list).
        PASS = coverage of in-scope containers meets the agreed target; no container drifts from its tier.
.NOTES
    Purview — Container Labeling (Teams, Groups & Sites). Read-only reporting. No secrets in code;
    interactive modern-auth only.
#>
[CmdletBinding()]
param(
    [string]$CsvPath = ".\ContainerReport.csv",
    [string]$SPOAdminUrl,
    [string[]]$GraphScopes = @('Group.Read.All','Directory.Read.All','Sites.Read.All','InformationProtectionPolicy.Read')
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
try { $ctx = Get-MgContext } catch { $ctx = $null }
if (-not $ctx) { Connect-MgGraph -Scopes $GraphScopes | Out-Null }

$idToName = @{}
try { (Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/informationProtection/policy/labels').value | ForEach-Object { $idToName[$_.id] = $_.name } } catch {}

$rows = New-Object System.Collections.Generic.List[object]
$uri = "https://graph.microsoft.com/v1.0/groups?`$select=id,displayName,visibility,groupTypes,resourceProvisioningOptions,assignedLabels,allowExternalSenders&`$top=999"
do {
    $page = Invoke-MgGraphRequest -Method GET -Uri $uri
    foreach ($g in $page.value) {
        if (@($g.groupTypes) -notcontains 'Unified') { continue }
        $names = @(); foreach ($al in @($g.assignedLabels)) { $nm = if ($al.displayName) { $al.displayName } elseif ($idToName.ContainsKey($al.labelId)) { $idToName[$al.labelId] } else { $al.labelId }; if ($nm){ $names += $nm } }
        $lbl = ($names -join '; ')
        $rows.Add([pscustomobject]@{ Type=$(if(@($g.resourceProvisioningOptions) -contains 'Team'){'Team'}else{'M365 Group'}); Name=$g.displayName; Identity=$g.id; Privacy=$g.visibility; GuestSenders=$g.allowExternalSenders; Sharing=''; Label=$lbl; Labeled=[bool]($names.Count -gt 0) })
    }
    $uri = $page.'@odata.nextLink'
} while ($uri)

if ($SPOAdminUrl) {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Online.SharePoint.PowerShell)) { Install-Module Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser -Force -AllowClobber }
    Import-Module Microsoft.Online.SharePoint.PowerShell -ErrorAction Stop
    try {
        Connect-SPOService -Url $SPOAdminUrl -ErrorAction Stop
        foreach ($s in (Get-SPOSite -Limit All -ErrorAction Stop)) {
            $rows.Add([pscustomobject]@{ Type='SharePoint Site'; Name=$s.Title; Identity=$s.Url; Privacy=''; GuestSenders=''; Sharing=$s.SharingCapability; Label=[string]$s.SensitivityLabel; Labeled=[bool]([string]$s.SensitivityLabel) })
        }
    } catch { Write-Host ("  [warn] SharePoint enumeration skipped: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
}

$rows | Sort-Object Type, Name | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8

$total = $rows.Count
$labeled = @($rows | Where-Object { $_.Labeled }).Count
$pct = if ($total) { [math]::Round(100.0 * $labeled / $total, 1) } else { 0 }

Write-Host "=== Container Inventory - Report : coverage summary ===" -ForegroundColor Cyan
Write-Host ("  Containers total : {0}" -f $total) -ForegroundColor Gray
Write-Host ("  Labeled          : {0}  ({1}%)" -f $labeled, $pct) -ForegroundColor $(if($pct -ge 90){'Green'}elseif($pct -ge 60){'Yellow'}else{'Red'})
Write-Host ("  Unlabeled        : {0}" -f ($total-$labeled)) -ForegroundColor $(if(($total-$labeled) -eq 0){'Green'}else{'Yellow'})
Write-Host "`n  By assigned label/tier:" -ForegroundColor Cyan
$rows | Where-Object { $_.Labeled } | Group-Object Label | Sort-Object Name | ForEach-Object { Write-Host ("    {0,-40} {1}" -f $_.Name, $_.Count) -ForegroundColor Gray }
Write-Host ("`nWrote {0} to {1}" -f $total, $CsvPath) -ForegroundColor Green
Write-Host "PASS = labeled % meets the agreed coverage target for in-scope containers; investigate any unlabeled in-scope container as drift." -ForegroundColor Cyan
