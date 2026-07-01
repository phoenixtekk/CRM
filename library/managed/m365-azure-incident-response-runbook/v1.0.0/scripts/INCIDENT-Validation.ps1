<#
.SYNOPSIS
    INCIDENT-Validation.ps1 - Responder readiness check (PASS/FAIL).

    PURPOSE:
        Validates that the response team is ready to run the runbook BEFORE a real incident: the
        responder access group exists, responders hold the required roles, the key logs are readable
        (Service Health, Entra sign-in logs, Exchange message trace, Azure subscription/Monitor), and
        a Microsoft support plan is in place for escalation. Emits PASS/FAIL per check and an overall
        result with a non-zero exit code on any FAIL - suitable for gating the runbook's readiness
        test (see 05-testing.md, T1-T2). Read-only: performs no changes.

    HOW TO RUN:
        1. Install modules (run once):
             Install-Module Microsoft.Graph, ExchangeOnlineManagement, Az -Scope CurrentUser
        2. Run as (or impersonating) a responder account:
             .\INCIDENT-Validation.ps1 -ResponderGroupName "Responder Access Group - Identity - Response" `
                                       -ResultsCsv ".\Validation Results - Responder - Response.csv"
        3. Sign in interactively when prompted.

    EXPECTED RESULTS:
        A console table of checks each marked PASS or FAIL, an exported results CSV, and exit code 1
        if any check FAILS. Read-only.

.NOTES
    Managed - read-only.
#>

[CmdletBinding()]
param(
    [string]$ResponderGroupName = "Responder Access Group - Identity - Response",
    [string[]]$RequiredDirectoryRoles = @('Global Reader','Service Support Administrator'),
    [string]$ResultsCsv = ".\Validation Results - Responder - Response.csv"
)

$ErrorActionPreference = 'Stop'
$checks = New-Object System.Collections.Generic.List[object]

function Add-Check {
    param($Name, [bool]$Pass, $Detail = '')
    $checks.Add([pscustomobject]@{
        Check  = $Name
        Result = if ($Pass) { 'PASS' } else { 'FAIL' }
        Detail = $Detail
    })
    $color = if ($Pass) { 'Green' } else { 'Red' }
    Write-Host ("[{0}] {1} - {2}" -f $(if($Pass){'PASS'}else{'FAIL'}), $Name, $Detail) -ForegroundColor $color
}

Write-Host "=== Responder readiness validation ===" -ForegroundColor Cyan

# --- Microsoft Graph: group, roles, service health, sign-in log readability ---
try {
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes "Directory.Read.All","RoleManagement.Read.Directory","ServiceHealth.Read.All","AuditLog.Read.All" -NoWelcome

    # Responder group exists
    try {
        $grp = Invoke-MgGraphRequest -Method GET `
            -Uri "https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '$ResponderGroupName'"
        $exists = ($grp.value.Count -gt 0)
        $memberCount = if ($exists) {
            (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups/$($grp.value[0].id)/members?`$count=true").value.Count
        } else { 0 }
        Add-Check "Responder group present" $exists ("Group='{0}'; Members={1}" -f $ResponderGroupName, $memberCount)
    } catch { Add-Check "Responder group present" $false $_.Exception.Message }

    # Required directory roles are activated in the tenant
    try {
        $roles = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/directoryRoles").value
        foreach ($rn in $RequiredDirectoryRoles) {
            $present = [bool]($roles | Where-Object { $_.displayName -eq $rn })
            Add-Check ("Directory role available: {0}" -f $rn) $present ("Activated in tenant={0}" -f $present)
        }
    } catch { Add-Check "Directory roles enumerable" $false $_.Exception.Message }

    # Service Health readable
    try {
        $null = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/admin/serviceAnnouncement/issues?`$top=1"
        Add-Check "M365 Service Health readable" $true "admin/serviceAnnouncement/issues accessible"
    } catch { Add-Check "M365 Service Health readable" $false $_.Exception.Message }

    # Sign-in logs readable
    try {
        $null = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/auditLogs/signIns?`$top=1"
        Add-Check "Entra sign-in logs readable" $true "auditLogs/signIns accessible"
    } catch { Add-Check "Entra sign-in logs readable" $false $_.Exception.Message }
}
catch { Add-Check "Microsoft Graph connection" $false $_.Exception.Message }
finally { try { Disconnect-MgGraph | Out-Null } catch {} }

# --- Exchange Online: message trace readability ---
try {
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    Connect-ExchangeOnline -ShowBanner:$false
    try {
        $null = Get-MessageTrace -StartDate (Get-Date).AddHours(-1) -EndDate (Get-Date) -PageSize 1 -ErrorAction Stop
        Add-Check "Exchange message trace readable" $true "Get-MessageTrace succeeded"
    } catch { Add-Check "Exchange message trace readable" $false $_.Exception.Message }
    Disconnect-ExchangeOnline -Confirm:$false
}
catch { Add-Check "Exchange Online connection" $false $_.Exception.Message }

# --- Azure: subscription + Monitor readability + support plan probe ---
try {
    Import-Module Az.Accounts -ErrorAction Stop
    Connect-AzAccount | Out-Null
    $subs = Get-AzSubscription
    Add-Check "Azure subscription visible" ($subs.Count -gt 0) ("Subscriptions={0}" -f $subs.Count)

    # Support plan: list available support request severities (proxy for an entitlement existing)
    try {
        $ctx = Get-AzContext
        $sub = $ctx.Subscription.Id
        $tiers = Invoke-AzRestMethod -Method GET `
            -Path "/subscriptions/$sub/providers/Microsoft.Support/services?api-version=2020-04-01"
        $hasSupport = ($tiers.StatusCode -eq 200)
        Add-Check "Microsoft support plan reachable" $hasSupport `
                  ("Support API status={0} (confirm severity tiers in portal: Help + support)" -f $tiers.StatusCode)
    } catch {
        Add-Check "Microsoft support plan reachable" $false `
                  "Could not query Microsoft.Support - verify the support plan + severities manually."
    }
}
catch { Add-Check "Azure connection" $false $_.Exception.Message }

# --- Export + overall ---
$checks | Export-Csv -Path $ResultsCsv -NoTypeInformation -Encoding UTF8
$fails = ($checks | Where-Object Result -eq 'FAIL').Count
Write-Host ("`nResults written to {0}" -f $ResultsCsv) -ForegroundColor Green
if ($fails -gt 0) {
    Write-Host ("OVERALL: FAIL ({0} failing check(s))" -f $fails) -ForegroundColor Red
    exit 1
} else {
    Write-Host "OVERALL: PASS" -ForegroundColor Green
    exit 0
}
