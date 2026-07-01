<#
.SYNOPSIS
    WS1COEX-Set-CohortTargeting.ps1 — build a cohort Entra group and set its membership (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Creates (or reuses) a Microsoft Entra security group for one cutover cohort and adds the
        supplied members (user UPNs and/or device object IDs), so the cohort can be targeted by the
        Coexistence Guardrails, the cohort-scoped Conditional Access policy, and the Intune
        assignments. Name the group with the runbook convention, e.g.
        "Cutover Cohort - Pilot - Stage1".
        SAFETY: runs in -WhatIf mode BY DEFAULT — it only PREVIEWS the group creation and membership
        adds. Re-run with -Execute (and without -WhatIf) to apply them.
    HOW TO RUN
        Preview (default):
          powershell -ExecutionPolicy Bypass -File .\WS1COEX-Set-CohortTargeting.ps1 `
            -CohortGroupName "Cutover Cohort - Pilot - Stage1" -MemberUpn user1@contoso.com,user2@contoso.com
        Apply:
          ... -Execute
        Requires the Microsoft Graph PowerShell SDK. Scopes (write):
        Group.ReadWrite.All, User.Read.All.
    EXPECTED RESULTS
        In preview: the group that WOULD be created/reused and the members that WOULD be added. When
        applied: the cohort group exists with the requested membership; its object id is printed for
        use with WS1COEX-Validation.ps1 / WS1COEX-Report.ps1 / WS1COEX-Remediation.ps1.
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory)][string]$CohortGroupName,
    [string[]]$MemberUpn,
    [string[]]$MemberDeviceObjectId,
    [switch]$Execute
)

# Default to preview unless -Execute is explicitly supplied.
$WhatIfPreference = -not $Execute

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','User.Read.All' -NoWelcome

Write-Host ("=== WS1COEX Cohort Targeting — mode: {0} ===" -f $(if($Execute){'EXECUTE'}else{'WHATIF (preview only)'})) -ForegroundColor Cyan

# 1 — Create or reuse the cohort group
$existing = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter=displayName eq '{0}'" -f $CohortGroupName.Replace("'","''"))).value | Select-Object -First 1
if ($existing) {
    $groupId = $existing.id
    Write-Host "  Reusing existing cohort group '$CohortGroupName' ($groupId)." -ForegroundColor Green
} else {
    if ($PSCmdlet.ShouldProcess("Entra group '$CohortGroupName'","Create security group")) {
        $mailNick = ($CohortGroupName -replace '[^a-zA-Z0-9]','').ToLower()
        $body = @{ displayName=$CohortGroupName; mailEnabled=$false; mailNickname=$mailNick; securityEnabled=$true } | ConvertTo-Json
        $g = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body $body
        $groupId = $g.id
        Write-Host "  Created cohort group '$CohortGroupName' ($groupId)." -ForegroundColor Green
    } else { $groupId = '<new-group-id>'; Write-Host "  WHATIF: would create cohort group '$CohortGroupName'." -ForegroundColor Yellow }
}

# 2 — Resolve and add members
$objectIds = New-Object System.Collections.Generic.List[string]
foreach ($upn in @($MemberUpn)) {
    if (-not $upn) { continue }
    $u = Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/users/{0}?`$select=id,userPrincipalName" -f $upn) -ErrorAction SilentlyContinue
    if ($u.id) { $objectIds.Add($u.id) } else { Write-Host "  WARNING: user not found: $upn" -ForegroundColor Yellow }
}
foreach ($d in @($MemberDeviceObjectId)) { if ($d) { $objectIds.Add($d) } }

Write-Host ("  Members to add: {0}" -f $objectIds.Count) -ForegroundColor Cyan
foreach ($oid in $objectIds) {
    if ($PSCmdlet.ShouldProcess("cohort group $groupId","Add member $oid")) {
        $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$oid" } | ConvertTo-Json
        try { Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$groupId/members/`$ref" -Body $ref; Write-Host "    Added $oid" -ForegroundColor Green }
        catch { Write-Host "    Skipped $oid ($($_.Exception.Message))" -ForegroundColor DarkGray }
    }
}

Write-Host ("`nCohort group id: {0}" -f $groupId) -ForegroundColor Cyan
Write-Host "Use this id with WS1COEX-Validation.ps1 / WS1COEX-Report.ps1 / WS1COEX-Remediation.ps1." -ForegroundColor Cyan
if (-not $Execute) { Write-Host "`nThis was a PREVIEW. Re-run with -Execute to apply." -ForegroundColor Cyan }
Disconnect-MgGraph | Out-Null
