<#
.SYNOPSIS
    LICRPT-Set-ScopeTargeting.ps1 — build/update the reporting-scope and distribution audience groups.
.DESCRIPTION
    PURPOSE
        Creates (if missing) and populates the Entra security groups used by the reporting layer: the
        distribution audience 'License Reporting - Leadership & Procurement - Audience' that the
        published Power BI report is shared with. Members are added from a CSV of user principal names.
        This is the only script that writes (group membership); discovery/validation/report are read-only.
    HOW TO RUN
        Preview (default — shows what WOULD change, writes nothing):
            powershell -ExecutionPolicy Bypass -File .\LICRPT-Set-ScopeTargeting.ps1 -MembersCsv C:\Temp\audience.csv
        Apply the changes:
            powershell -ExecutionPolicy Bypass -File .\LICRPT-Set-ScopeTargeting.ps1 -MembersCsv C:\Temp\audience.csv -Apply
        MembersCsv must have a column: UserPrincipalName.
        Requires the Microsoft Graph SDK and the scopes Group.ReadWrite.All and User.Read.All.
    EXPECTED RESULTS
        Preview: the target group and the members that would be added.
        Apply: the group exists and the listed members are added; the group is then granted report access in Power BI.
.NOTES
    Software Asset Management — License Reporting. Writes group membership only when -Apply is supplied.
#>
[CmdletBinding()] param(
    [Parameter(Mandatory)][string]$MembersCsv,
    [string]$GroupName = 'License Reporting - Leadership & Procurement - Audience',
    [switch]$Apply
)

if (-not (Test-Path $MembersCsv)) { Write-Host "Members CSV not found: $MembersCsv" -ForegroundColor Red; exit 1 }
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','User.Read.All' -NoWelcome

$members = Import-Csv $MembersCsv
Write-Host "`n=== Reporting audience targeting — $(if($Apply){'APPLY'}else{'PREVIEW'}) ===" -ForegroundColor Cyan
Write-Host ("Target group : {0}" -f $GroupName)
Write-Host ("Members CSV  : {0} row(s)" -f $members.Count)

# Find or (optionally) create the group
$grp = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter=displayName eq '{0}'" -f $GroupName.Replace("'","''"))).value | Select-Object -First 1
if (-not $grp) {
    if ($Apply) {
        $mailNick = ($GroupName -replace '[^a-zA-Z0-9]','').Substring(0,[Math]::Min(40,($GroupName -replace '[^a-zA-Z0-9]','').Length))
        $body = @{ displayName = $GroupName; mailEnabled = $false; mailNickname = $mailNick; securityEnabled = $true }
        $grp = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($body | ConvertTo-Json)
        Write-Host ("Created group (id {0})" -f $grp.id) -ForegroundColor Green
    } else {
        Write-Host "Group does not exist — would be created on -Apply." -ForegroundColor Yellow
    }
}

foreach ($m in $members) {
    $upn = $m.UserPrincipalName
    if (-not $upn) { continue }
    $usr = $null
    try { $usr = Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/users/{0}" -f $upn) } catch {}
    if (-not $usr) { Write-Host ("  SKIP (not found): {0}" -f $upn) -ForegroundColor Yellow; continue }
    if ($Apply -and $grp) {
        $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$($usr.id)" }
        try {
            Invoke-MgGraphRequest -Method POST -Uri ("/v1.0/groups/{0}/members/`$ref" -f $grp.id) -Body ($ref | ConvertTo-Json)
            Write-Host ("  ADDED: {0}" -f $upn) -ForegroundColor Green
        } catch {
            Write-Host ("  exists/again: {0}" -f $upn) -ForegroundColor DarkGray
        }
    } else {
        Write-Host ("  would add: {0}" -f $upn)
    }
}

if (-not $Apply) { Write-Host "`nPREVIEW only — re-run with -Apply to write membership." -ForegroundColor Yellow }
else { Write-Host "`nDone. In Power BI, grant '$GroupName' access to the report/app." -ForegroundColor Cyan }
Disconnect-MgGraph | Out-Null
