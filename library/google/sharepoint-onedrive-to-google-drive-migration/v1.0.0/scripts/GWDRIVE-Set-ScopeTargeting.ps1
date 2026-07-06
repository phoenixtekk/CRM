<#
.SYNOPSIS
    GWDRIVE-Set-ScopeTargeting.ps1 — build a Drive migration wave's target group in Microsoft Entra.
.DESCRIPTION
    PURPOSE
        Creates (or reuses) the Microsoft Entra security group that defines a migration wave — the
        pilot (Wave 0) first, then each expansion wave — so every wave runs against a bounded,
        well-understood population of OneDrive owners and site members, and validation/reporting can
        key off it. Optionally seeds members from a CSV of user UPNs (the OneDrive owners and site
        members in the wave's scope). This is the only included script that writes to the tenant: it
        creates a group and adds members, nothing else — no content moved, no permissions changed.
        Runs with -WhatIf by default. Placeholders use plain text such as your-domain.example, not
        angle brackets.
    HOW TO RUN
        Preview (default):  powershell -ExecutionPolicy Bypass -File .\GWDRIVE-Set-ScopeTargeting.ps1 `
                                -GroupName "GWDRIVE Wave - Wave 0 - Pilot" -MembersCsv .\wave0-users.csv
        Apply:              ...\GWDRIVE-Set-ScopeTargeting.ps1 `
                                -GroupName "GWDRIVE Wave - Wave 0 - Pilot" -MembersCsv .\wave0-users.csv `
                                -WhatIf:$false
        MembersCsv is a CSV with an 'Upn' column. Requires the Microsoft Graph PowerShell SDK and
        Group.ReadWrite.All (and User.Read.All to resolve UPNs).
    EXPECTED RESULTS
        In preview: the group that would be created/reused and the members that would be added. When
        applied: the security group exists and contains the listed members, ready to target with the
        wave's migrate-and-validate runbook.
.NOTES
    White-label — the repeatable way. Writes to Microsoft Entra; -WhatIf by default.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][string]$GroupName,
    [string]$MembersCsv
)

# Default to preview unless the caller turns -WhatIf off explicitly.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','User.Read.All' -NoWelcome

Write-Host "=== Drive migration — wave scope targeting ===" -ForegroundColor Cyan

# Find or plan the group.
$mailNick = ($GroupName -replace '[^a-zA-Z0-9]', '')
$existing = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter=displayName eq '{0}'" -f ($GroupName -replace "'","''"))).value
$groupId = $null
if ($existing) {
    $groupId = $existing[0].id
    Write-Host ("Group exists: {0} ({1})" -f $GroupName, $groupId) -ForegroundColor Green
} else {
    if ($PSCmdlet.ShouldProcess($GroupName, "Create Entra security group")) {
        $body = @{ displayName = $GroupName; mailEnabled = $false; mailNickname = $mailNick; securityEnabled = $true }
        $new = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($body | ConvertTo-Json)
        $groupId = $new.id
        Write-Host ("Created group: {0} ({1})" -f $GroupName, $groupId) -ForegroundColor Green
    } else {
        Write-Host ("Would create group: {0}" -f $GroupName) -ForegroundColor Yellow
    }
}

# Seed members from CSV (users by UPN).
if ($MembersCsv -and (Test-Path $MembersCsv)) {
    $members = Import-Csv -Path $MembersCsv
    foreach ($m in $members) {
        if (-not $m.Upn) { continue }
        $user = $null
        try { $user = Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/users/{0}?`$select=id,userPrincipalName" -f $m.Upn) } catch {}
        if (-not $user) { Write-Host ("  skip (not found): {0}" -f $m.Upn) -ForegroundColor Yellow; continue }
        if ($groupId -and $PSCmdlet.ShouldProcess($m.Upn, "Add to $GroupName")) {
            $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$($user.id)" }
            try {
                Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$groupId/members/`$ref" -Body ($ref | ConvertTo-Json)
                Write-Host ("  added: {0}" -f $m.Upn) -ForegroundColor Green
            } catch { Write-Host ("  add failed {0}: {1}" -f $m.Upn, $_.Exception.Message) -ForegroundColor Yellow }
        } else {
            Write-Host ("  would add: {0}" -f $m.Upn) -ForegroundColor Yellow
        }
    }
} elseif ($MembersCsv) {
    Write-Host ("MembersCsv not found: {0}" -f $MembersCsv) -ForegroundColor Yellow
}

if ($WhatIfPreference) { Write-Host "`nPreview only (-WhatIf). Re-run with -WhatIf:`$false to apply." -ForegroundColor Cyan }
Disconnect-MgGraph | Out-Null
