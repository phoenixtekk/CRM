<#
.SYNOPSIS
    COPILOT-Report.ps1 — data-exposure + Copilot-readiness report across sites and labels (Graph).
.DESCRIPTION
    PURPOSE
        Read-only. Builds the data-exposure baseline (and the re-measure after remediation) that drives
        the pilot and expansion gates: for the sampled SharePoint sites it counts anonymous, org-wide,
        and external sharing, reports how many sensitivity labels exist, and how many pilot users hold a
        Microsoft 365 Copilot license. Compare the baseline against a post-remediation run to prove
        exposure went down before Copilot is expanded.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\COPILOT-Report.ps1 `
            [-Top 200] [-CopilotSkuId "<Copilot SKU GUID>"] [-CsvPath .\copilot-exposure.csv]
        Requires the Microsoft Graph SDK and consent to (read-only): Sites.Read.All, Files.Read.All,
        InformationProtectionPolicy.Read, User.Read.All, Organization.Read.All.
    EXPECTED RESULTS
        A summary: sites sampled, sites with anonymous/org-wide/external sharing, total sensitivity
        labels, and Copilot-licensed user count. Optional CSV of the per-site rows. Nothing is changed.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph. Exact per-item Copilot usage
    analytics are deferred to Microsoft's reporting; this reports the sharing/label/licensing exposure
    surface Copilot reasons over.
#>
[CmdletBinding()]
param(
    [int]$Top = 200,
    [string]$CopilotSkuId,
    [string]$CsvPath
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$scopes = @('Sites.Read.All','Files.Read.All','InformationProtectionPolicy.Read','User.Read.All','Organization.Read.All')
Connect-MgGraph -Scopes $scopes -NoWelcome

# Labels
$labelCount = 0
try {
    $labelCount = ((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/security/informationProtection/sensitivityLabels').value).Count
} catch {
    try { $labelCount = ((Invoke-MgGraphRequest -Method GET -Uri '/beta/informationProtection/policy/labels').value).Count } catch { $labelCount = 0 }
}

# Sites exposure
$sites = @()
try { $sites = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/sites?search=*&`$top=$Top").value } catch { }

$rows = @()
$anonSites = 0; $orgSites = 0; $extSites = 0
foreach ($s in $sites) {
    try { $perms = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/sites/$($s.id)/permissions").value } catch { $perms = @() }
    $anon = ($perms | Where-Object { $_.link.scope -eq 'anonymous' }).Count
    $org  = ($perms | Where-Object { $_.link.scope -eq 'organization' }).Count
    $ext  = ($perms | Where-Object { $_.grantedToIdentitiesV2.user.userType -eq 'Guest' -or $_.link.scope -eq 'users' }).Count
    if ($anon) { $anonSites++ }
    if ($org)  { $orgSites++ }
    if ($ext)  { $extSites++ }
    $rows += [pscustomobject]@{
        Site           = $s.displayName
        Url            = $s.webUrl
        AnonymousLinks = $anon
        OrgWideLinks   = $org
        ExternalGrants = $ext
    }
}

# Copilot licensing
$copilotLicensed = $null
if ($CopilotSkuId) {
    try {
        $u = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users?`$select=displayName,assignedLicenses&`$top=999").value
        $copilotLicensed = ($u | Where-Object { $_.assignedLicenses.skuId -contains $CopilotSkuId }).Count
    } catch { }
}

Write-Host "`n=== Copilot data-exposure & readiness report ===" -ForegroundColor Cyan
Write-Host ("  Sites sampled ................ {0}" -f $sites.Count)
Write-Host ("  Sites w/ anonymous links ..... {0}" -f $anonSites)     -ForegroundColor $(if($anonSites){'Yellow'}else{'Green'})
Write-Host ("  Sites w/ org-wide links ...... {0}" -f $orgSites)      -ForegroundColor $(if($orgSites){'Yellow'}else{'Green'})
Write-Host ("  Sites w/ external grants ..... {0}" -f $extSites)      -ForegroundColor $(if($extSites){'Yellow'}else{'Green'})
Write-Host ("  Sensitivity labels ........... {0}" -f $labelCount)    -ForegroundColor $(if($labelCount){'Green'}else{'Yellow'})
if ($null -ne $copilotLicensed) {
    Write-Host ("  Copilot-licensed users ....... {0} (keep pilot-scoped until expansion)" -f $copilotLicensed)
} else {
    Write-Host "  Copilot-licensed users ....... (pass -CopilotSkuId to measure)" -ForegroundColor DarkGray
}

if ($CsvPath -and $rows.Count) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("`nExported {0} site rows to {1}" -f $rows.Count, $CsvPath) -ForegroundColor Green
}

Write-Host "`nSave this baseline; re-run after remediation and confirm the exposure counts dropped (Testing Test 7)." -ForegroundColor Yellow
Disconnect-MgGraph | Out-Null
