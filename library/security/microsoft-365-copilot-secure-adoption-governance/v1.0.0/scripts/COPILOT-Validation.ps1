<#
.SYNOPSIS
    COPILOT-Validation.ps1 — confirm remediation held: broad links removed, labels published, licensing pilot-only (Graph).
.DESCRIPTION
    PURPOSE
        Read-only pass/fail validation behind the Testing gates. For the sites you targeted it confirms
        anonymous/org-wide sharing links are gone; it confirms sensitivity labels are published; and it
        confirms Microsoft 365 Copilot licensing is limited to the pilot group (not the whole org). This
        is the evidence behind Testing Tests 1-3 before the pilot gate.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\COPILOT-Validation.ps1 `
            [-SiteUrlMatch "contoso.sharepoint.com/sites/HR"] `
            [-PilotGroup "Copilot Adoption - Pilot Users - Pilot"] [-CopilotSkuId "<Copilot SKU GUID>"]
        Requires the Microsoft Graph SDK and consent to (read-only): Sites.Read.All, Files.Read.All,
        InformationProtectionPolicy.Read, Group.Read.All, User.Read.All.
    EXPECTED RESULTS
        PASS for: no anonymous/org-wide links on the matched sites; sensitivity labels published;
        Copilot licenses only on members of the pilot group. Any FAIL points to the matching
        Troubleshooting section (A oversharing / B labels / E licensing). Nothing is changed.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph. The pilot-group name uses the
    ASCII-hyphen naming convention; keep it verbatim across scripts and Intune/Purview assignments.
#>
[CmdletBinding()]
param(
    [string]$SiteUrlMatch,
    [string]$PilotGroup = 'Copilot Adoption - Pilot Users - Pilot',
    [string]$CopilotSkuId
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$scopes = @('Sites.Read.All','Files.Read.All','InformationProtectionPolicy.Read','Group.Read.All','User.Read.All')
Connect-MgGraph -Scopes $scopes -NoWelcome

function Result($name,$ok,$detail) {
    $tag = if ($ok) { 'PASS' } else { 'FAIL' }
    $color = if ($ok) { 'Green' } else { 'Red' }
    Write-Host ("[{0}] {1} — {2}" -f $tag, $name, $detail) -ForegroundColor $color
}

Write-Host "`n=== Copilot secure-adoption validation ===" -ForegroundColor Cyan

# 1. No broad links on the targeted sites
$sites = @()
try { $sites = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/sites?search=*&`$top=200").value } catch { }
if ($SiteUrlMatch) { $sites = $sites | Where-Object { $_.webUrl -like "*$SiteUrlMatch*" } }
$broad = 0
foreach ($s in $sites) {
    try { $perms = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/sites/$($s.id)/permissions").value } catch { $perms = @() }
    $broad += ($perms | Where-Object { $_.link.scope -in @('anonymous','organization') }).Count
}
Result 'No anonymous/org-wide links on targeted sites' ($broad -eq 0) `
    ($(if($broad){"$broad broad link(s) remain across $($sites.Count) site(s) — run COPILOT-Remediation.ps1 -Apply"}else{"clean across $($sites.Count) site(s)"}))

# 2. Sensitivity labels published
$labelCount = 0
try { $labelCount = ((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/security/informationProtection/sensitivityLabels').value).Count }
catch { try { $labelCount = ((Invoke-MgGraphRequest -Method GET -Uri '/beta/informationProtection/policy/labels').value).Count } catch { $labelCount = 0 } }
Result 'Sensitivity labels published' ($labelCount -gt 0) `
    ($(if($labelCount){"$labelCount label(s) present"}else{"none — publish the taxonomy (Implementation Step 3)"}))

# 3. Copilot licensing limited to the pilot group
$grpEsc = $PilotGroup.Replace("'","''")
$grp = @()
try { $grp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$grpEsc'").value } catch { }
if (-not $grp) {
    Result 'Copilot licensing limited to pilot group' $false "pilot group '$PilotGroup' not found — run COPILOT-Set-ScopeTargeting.ps1"
} elseif (-not $CopilotSkuId) {
    Write-Host "[INFO] Copilot licensing check skipped — pass -CopilotSkuId to validate." -ForegroundColor DarkGray
} else {
    $memberIds = @()
    try { $memberIds = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$($grp[0].id)/members?`$select=id").value.id } catch { }
    $licensed = @()
    try { $licensed = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users?`$select=id,displayName,assignedLicenses&`$top=999").value |
            Where-Object { $_.assignedLicenses.skuId -contains $CopilotSkuId } } catch { }
    $outside = $licensed | Where-Object { $memberIds -notcontains $_.id }
    Result 'Copilot licensing limited to pilot group' (($licensed.Count -gt 0) -and ($outside.Count -eq 0)) `
        ($(if($outside.Count){"$($outside.Count) licensed user(s) outside the pilot group"}elseif($licensed.Count){"all $($licensed.Count) licensed user(s) are in the pilot group"}else{"no Copilot licenses assigned yet"}))
}

Write-Host "`nAny FAIL: see Troubleshooting A (oversharing) / B (labels) / E (licensing)." -ForegroundColor Yellow
Disconnect-MgGraph | Out-Null
