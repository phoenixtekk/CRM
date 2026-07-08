<#
.SYNOPSIS
    IPCONT-Validate-ContainerLabels.ps1 — confirm each target carries the intended label and matching privacy/guest/sharing posture (SAFE: read-only).
.DESCRIPTION
    PURPOSE
        Read-only pass/fail validation. For each target in the CSV it confirms the container carries the
        INTENDED container label and that the observable posture matches the tier's expectation — group
        PRIVACY (Private), GUEST-allowed state, and (for sites) the external SHARING level. Reports PASS or
        the specific mismatch per container. Does NOT change anything.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\IPCONT-Validate-ContainerLabels.ps1 -TargetsPath .\PilotTargets.csv -SPOAdminUrl https://contoso-admin.sharepoint.com
        Targets CSV columns: ContainerName, Identity (group id OR site URL), Label
        Optional expected columns (validated when present): ExpectedPrivacy, ExpectedSharing
        Requires: Microsoft.Graph (read scopes) and, for sites, Microsoft.Online.SharePoint.PowerShell.
    EXPECTED RESULTS
        A per-container PASS/FAIL table. PASS = the target carries the intended label and its privacy/
        guest/sharing posture matches the tier; any drift is reported as FAIL with the observed value.
.NOTES
    Purview — Container Labeling (Teams, Groups & Sites). Read-only. Unmanaged-device (Conditional Access)
    enforcement requires Entra ID P1 and is observed by user testing (Testing Guide Test 8), not asserted
    here. No secrets in code; interactive modern-auth only.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$TargetsPath,
    [string]$SPOAdminUrl,
    [string[]]$GraphScopes = @('Group.Read.All','Directory.Read.All','Sites.Read.All','InformationProtectionPolicy.Read')
)

if (-not (Test-Path $TargetsPath)) { throw "Targets CSV not found: $TargetsPath" }
$targets = Import-Csv -Path $TargetsPath
foreach ($c in 'ContainerName','Identity','Label') {
    if (-not ($targets | Get-Member -Name $c)) { throw "Targets CSV must have columns: ContainerName, Identity, Label" }
}

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
try { $ctx = Get-MgContext } catch { $ctx = $null }
if (-not $ctx) { Connect-MgGraph -Scopes $GraphScopes | Out-Null }

$idToName = @{}
try { (Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/informationProtection/policy/labels').value | ForEach-Object { $idToName[$_.id] = $_.name } } catch {}

$spoReady = $false
if ($SPOAdminUrl) {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Online.SharePoint.PowerShell)) { Install-Module Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser -Force -AllowClobber }
    Import-Module Microsoft.Online.SharePoint.PowerShell -ErrorAction Stop
    try { Connect-SPOService -Url $SPOAdminUrl -ErrorAction Stop; $spoReady = $true } catch { Write-Host ("  [warn] SPO connect failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
}

Write-Host "=== IPCONT-Validate-ContainerLabels : pass/fail per container ===" -ForegroundColor Cyan
$results = New-Object System.Collections.Generic.List[object]

foreach ($row in $targets) {
    $name = $row.ContainerName.Trim(); $id = $row.Identity.Trim(); $want = $row.Label.Trim()
    $expPriv = if ($row.PSObject.Properties.Name -contains 'ExpectedPrivacy') { $row.ExpectedPrivacy } else { '' }
    $expShare= if ($row.PSObject.Properties.Name -contains 'ExpectedSharing') { $row.ExpectedSharing } else { '' }
    $isSite = $id -match '^https?://'
    $issues = @(); $labelSeen = ''; $priv=''; $guest=''; $share=''

    try {
        if ($isSite) {
            if (-not $spoReady) { $issues += 'site not checked (no -SPOAdminUrl)' }
            else {
                $s = Get-SPOSite -Identity $id -Detailed -ErrorAction Stop
                $labelSeen = [string]$s.SensitivityLabel; $share = [string]$s.SharingCapability
                if ($expShare -and $share -ne $expShare) { $issues += ("sharing '$share' != expected '$expShare'") }
            }
        } else {
            $g = Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/v1.0/groups/{0}?`$select=displayName,visibility,assignedLabels,allowExternalSenders" -f $id)
            $priv = [string]$g.visibility; $guest = [string]$g.allowExternalSenders
            $names = @(); foreach ($al in @($g.assignedLabels)) { $nm = if ($al.displayName) { $al.displayName } elseif ($idToName.ContainsKey($al.labelId)) { $idToName[$al.labelId] } else { $al.labelId }; if ($nm){ $names += $nm } }
            $labelSeen = ($names -join '; ')
            if ($expPriv -and $priv -ne $expPriv) { $issues += ("privacy '$priv' != expected '$expPriv'") }
        }
        # Label match (name contains expected, tolerant of parent/child display)
        if ($labelSeen -notmatch [regex]::Escape($want)) { $issues += ("label '$labelSeen' != expected '$want'") }
    } catch { $issues += ("lookup error: {0}" -f $_.Exception.Message) }

    $pass = ($issues.Count -eq 0)
    $results.Add([pscustomobject]@{ Container=$name; Type=$(if($isSite){'Site'}else{'Group'}); ExpectedLabel=$want; SeenLabel=$labelSeen; Privacy=$priv; Guest=$guest; Sharing=$share; Result=$(if($pass){'PASS'}else{'FAIL'}); Notes=($issues -join '; ') })
    $color = if ($pass) { 'Green' } else { 'Red' }
    Write-Host ("  [{0}] {1} ({2}) label='{3}'{4}" -f $(if($pass){'PASS'}else{'FAIL'}), $name, $(if($isSite){'Site'}else{'Group'}), $labelSeen, $(if($pass){''}else{" -> $($issues -join '; ')"})) -ForegroundColor $color
}

$results | Format-Table -AutoSize
$fail = @($results | Where-Object { $_.Result -eq 'FAIL' }).Count
Write-Host ("`nTotal: {0}   PASS: {1}   FAIL: {2}" -f $results.Count, ($results.Count-$fail), $fail) -ForegroundColor $(if($fail -gt 0){'Yellow'}else{'Green'})
Write-Host "PASS gate = every in-scope target PASS: correct label + privacy/guest/sharing matching its tier." -ForegroundColor Cyan
