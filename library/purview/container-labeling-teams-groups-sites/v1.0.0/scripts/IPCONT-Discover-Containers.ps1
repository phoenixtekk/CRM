<#
.SYNOPSIS
    IPCONT-Discover-Containers.ps1 — read-only inventory of Teams/Groups/Sites with privacy, guest, sharing, and sensitivity-label state (SAFE: read-only).
.DESCRIPTION
    PURPOSE
        Enumerates every Microsoft 365 Group / Team (via Microsoft Graph) and SharePoint site (via the
        SharePoint Online Management Shell) and reports each container's current PRIVACY (visibility),
        GUEST-allowed status, EXTERNAL SHARING level, and assigned SENSITIVITY LABEL — flagging
        containers that carry no container label. This is the discovery baseline for container labeling.
        SAFE BY DEFAULT — read-only; makes no changes.
    HOW TO RUN
        # Connect first (read scopes) then run:
        powershell -ExecutionPolicy Bypass -File .\IPCONT-Discover-Containers.ps1 -CsvPath .\ContainerInventory.csv
        Requires: Microsoft.Graph (Connect-MgGraph) and Microsoft.Online.SharePoint.PowerShell
        (Connect-SPOService). PowerShell 5.1+/7+. Pass -SPOAdminUrl for the SharePoint enumeration.
    EXPECTED RESULTS
        A CSV (Container Inventory - Assess) listing each container with privacy/guest/sharing/label.
        PASS = complete inventory produced; unlabeled containers flagged for the tier-mapping exercise.
.NOTES
    Purview — Container Labeling (Teams, Groups & Sites). Read-only discovery. No secrets in code;
    interactive modern-auth only. Portal/Graph surfaces evolve — verify field availability in your tenant.
#>
[CmdletBinding()]
param(
    [string]$CsvPath = ".\ContainerInventory.csv",
    [string]$SPOAdminUrl,                       # e.g. https://contoso-admin.sharepoint.com
    [string[]]$GraphScopes = @('Group.Read.All','Directory.Read.All','Sites.Read.All','InformationProtectionPolicy.Read')
)

function Connect-GraphRead {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    try { $ctx = Get-MgContext } catch { $ctx = $null }
    if (-not $ctx) { Connect-MgGraph -Scopes $GraphScopes | Out-Null }
}

Connect-GraphRead

# Map published container-label ids -> display names (best-effort; requires InformationProtectionPolicy.Read)
$labelMap = @{}
try {
    $labels = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/informationProtection/policy/labels' -ErrorAction Stop
    foreach ($l in $labels.value) { $labelMap[$l.id] = $l.name }
} catch { Write-Host "  [info] Could not read label catalog (InformationProtectionPolicy.Read); label ids will be shown raw." -ForegroundColor DarkGray }

Write-Host "=== Container Inventory - Assess : Microsoft 365 Groups / Teams ===" -ForegroundColor Cyan
$rows = New-Object System.Collections.Generic.List[object]

$uri = "https://graph.microsoft.com/v1.0/groups?`$select=id,displayName,visibility,groupTypes,resourceProvisioningOptions,assignedLabels,allowExternalSenders&`$top=999"
do {
    $page = Invoke-MgGraphRequest -Method GET -Uri $uri
    foreach ($g in $page.value) {
        $isTeam  = @($g.resourceProvisioningOptions) -contains 'Team'
        $isM365  = @($g.groupTypes) -contains 'Unified'
        if (-not $isM365) { continue }
        $lblNames = @()
        foreach ($al in @($g.assignedLabels)) {
            $nm = if ($al.displayName) { $al.displayName } elseif ($labelMap.ContainsKey($al.labelId)) { $labelMap[$al.labelId] } else { $al.labelId }
            if ($nm) { $lblNames += $nm }
        }
        $rows.Add([pscustomobject]@{
            ContainerType = if ($isTeam) { 'Team' } else { 'M365 Group' }
            Name          = $g.displayName
            Identity      = $g.id
            Privacy       = $g.visibility
            AssignedLabel = ($lblNames -join '; ')
            Labeled       = [bool]($lblNames.Count -gt 0)
            GuestSenders  = $g.allowExternalSenders
            SiteUrl       = ''
            SharingLevel  = ''
        })
    }
    $uri = $page.'@odata.nextLink'
} while ($uri)

Write-Host ("  Groups/Teams found: {0}" -f $rows.Count) -ForegroundColor Gray

# SharePoint sites (external-sharing level) — optional, requires SPO admin URL + module
if ($SPOAdminUrl) {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Online.SharePoint.PowerShell)) {
        Install-Module Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module Microsoft.Online.SharePoint.PowerShell -ErrorAction Stop
    try {
        Connect-SPOService -Url $SPOAdminUrl -ErrorAction Stop
        Write-Host "=== SharePoint sites (external-sharing level) ===" -ForegroundColor Cyan
        $sites = Get-SPOSite -Limit All -ErrorAction Stop
        foreach ($s in $sites) {
            $rows.Add([pscustomobject]@{
                ContainerType = 'SharePoint Site'
                Name          = $s.Title
                Identity      = $s.Url
                Privacy       = ''
                AssignedLabel = $s.SensitivityLabel
                Labeled       = [bool]([string]$s.SensitivityLabel)
                GuestSenders  = ''
                SiteUrl       = $s.Url
                SharingLevel  = $s.SharingCapability
            })
        }
        Write-Host ("  SharePoint sites found: {0}" -f $sites.Count) -ForegroundColor Gray
    } catch {
        Write-Host ("  [warn] SharePoint enumeration skipped: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    }
} else {
    Write-Host "  [info] -SPOAdminUrl not supplied; SharePoint site sharing levels not enumerated." -ForegroundColor DarkGray
}

$rows | Sort-Object ContainerType, Name | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
$unlabeled = @($rows | Where-Object { -not $_.Labeled }).Count
Write-Host ("`nWrote {0} containers to {1}" -f $rows.Count, $CsvPath) -ForegroundColor Green
Write-Host ("Unlabeled containers (no container label): {0}" -f $unlabeled) -ForegroundColor $(if($unlabeled -gt 0){'Yellow'}else{'Green'})
Write-Host "PASS = inventory complete; map each unlabeled/in-scope container to a tier with your stakeholders." -ForegroundColor Cyan
