<#
.SYNOPSIS
    M365LIC-Set-ScopeTargeting.ps1 — build/populate the Entra groups for the reclamation campaign (exclusions, pilot, broad).
.DESCRIPTION
    PURPOSE
        Creates (if missing) and populates the three security groups used to scope reclamation:
          - "Reclaim Exclusions - Shared+Service - AllStages"  (protected accounts; build first, never reclaimed)
          - "Reclaim Targets - Pilot - Stage1"                 (a small safe candidate subset for the pilot)
          - "Reclaim Targets - Broad - Stage2"                 (the remaining validated candidates)
        Also removes a user from a licensing group (the safe way to reclaim a group-assigned seat).
        Members are supplied as a UPN list or a candidate CSV from M365LIC-Validation.ps1.
    HOW TO RUN
        Build the exclusion group from a UPN list:
          .\M365LIC-Set-ScopeTargeting.ps1 -GroupName "Reclaim Exclusions - Shared+Service - AllStages" -Upn shared1@contoso.com,svc-app@contoso.com -Action Add
        Populate the pilot group from a candidate CSV:
          .\M365LIC-Set-ScopeTargeting.ps1 -GroupName "Reclaim Targets - Pilot - Stage1" -CandidateCsv C:\Temp\M365LIC-Candidates.csv -Action Add
        Reclaim a group-assigned seat by removing the user from the licensing group:
          .\M365LIC-Set-ScopeTargeting.ps1 -GroupName "M365-E5-Licensing" -Upn jdoe@contoso.com -Action Remove
        Requires the Microsoft Graph PowerShell SDK and scopes:
        Group.ReadWrite.All, GroupMember.ReadWrite.All, User.Read.All, Directory.Read.All.
    EXPECTED RESULTS
        The named group exists and the supplied users are added to (or removed from) it; a summary of
        members added/removed is printed.
.NOTES
    Asset Mgt — Microsoft 365 License Optimization & Reharvesting. Creates/edits Entra security groups only.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$GroupName,
    [string[]]$Upn,
    [string]$CandidateCsv,
    [ValidateSet('Add','Remove')][string]$Action = 'Add',
    [string]$CampaignTag = 'Savings Campaign - M365 - Recurring'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','GroupMember.ReadWrite.All','User.Read.All','Directory.Read.All' -NoWelcome

Write-Host ("=== Scope targeting [{0}] group: {1} (campaign: {2}) ===" -f $Action, $GroupName, $CampaignTag) -ForegroundColor Cyan

# --- Resolve the member UPN list ---
$members = @()
if ($Upn) { $members += $Upn }
if ($CandidateCsv) { $members += (Import-Csv -Path $CandidateCsv | Select-Object -ExpandProperty UserPrincipalName -Unique) }
$members = @($members | Where-Object { $_ } | Select-Object -Unique)
if ($members.Count -eq 0) { Write-Warning 'No members supplied (-Upn or -CandidateCsv). Nothing to do.'; Disconnect-MgGraph | Out-Null; return }

# --- Find or create the group (mail-disabled security group). Tag with the campaign in the description. ---
$grp = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter=displayName eq '{0}'&`$select=id,displayName" -f ($GroupName -replace "'","''"))).value | Select-Object -First 1
if (-not $grp) {
    if ($Action -eq 'Remove') { Write-Warning ("Group '{0}' not found." -f $GroupName); Disconnect-MgGraph | Out-Null; return }
    $nick = ('rcl-' + (($GroupName -replace '[^a-zA-Z0-9]','').ToLower())); if ($nick.Length -gt 60) { $nick = $nick.Substring(0,60) }
    $body = @{ displayName = $GroupName; description = $CampaignTag; mailEnabled = $false; mailNickname = $nick; securityEnabled = $true } | ConvertTo-Json
    $grp = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body $body -ContentType 'application/json'
    Write-Host ("Created group '{0}' ({1})" -f $GroupName, $grp.id) -ForegroundColor Green
}

$ok = 0; $skip = 0
foreach ($u in $members) {
    $usr = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/users/{0}?`$select=id,userPrincipalName" -f $u) -ErrorAction SilentlyContinue)
    if (-not $usr) { Write-Host ("SKIP  {0} — user not found" -f $u) -ForegroundColor DarkYellow; $skip++; continue }
    try {
        if ($Action -eq 'Add') {
            $ref = @{ '@odata.id' = ("https://graph.microsoft.com/v1.0/directoryObjects/{0}" -f $usr.id) } | ConvertTo-Json
            Invoke-MgGraphRequest -Method POST -Uri ("/v1.0/groups/{0}/members/`$ref" -f $grp.id) -Body $ref -ContentType 'application/json' | Out-Null
            Write-Host ("ADD   {0}" -f $u) -ForegroundColor Green
        } else {
            Invoke-MgGraphRequest -Method DELETE -Uri ("/v1.0/groups/{0}/members/{1}/`$ref" -f $grp.id, $usr.id) | Out-Null
            Write-Host ("REMOVE {0}" -f $u) -ForegroundColor Green
        }
        $ok++
    } catch {
        # "already exists"/"does not exist" are benign for idempotent runs.
        if ($_.Exception.Message -match 'already exist|added object references already|does not exist') { Write-Host ("NOOP  {0} (already in desired state)" -f $u) -ForegroundColor DarkGray; $skip++ }
        else { Write-Host ("ERROR {0}: {1}" -f $u, $_.Exception.Message) -ForegroundColor Red; $skip++ }
    }
}

Write-Host ("=== {0}: {1} applied, {2} skipped, group '{3}' ===" -f $Action, $ok, $skip, $GroupName) -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
