<#
.SYNOPSIS
    ENTPIM-Alerting.ps1 — verify break-glass protection and report PIM alert posture.
.DESCRIPTION
    PURPOSE
        Read-only safety check. For each break-glass account it confirms the account (1) still holds
        Global Administrator, (2) holds it as a PERMANENT ACTIVE assignment — not via PIM eligibility,
        and (3) is NOT listed as PIM-eligible for any role (break-glass must never be behind an
        activation/approval loop). It also surfaces the current count of permanent Global
        Administrators as a headline PIM-hygiene signal. Use it after every rollout batch and on a
        schedule. Configuring sign-in alert rules and PIM alert thresholds is done in the portal; this
        script reports the state you must keep true.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ENTPIM-Alerting.ps1
        Optional: -BreakGlassUpns 'bg-admin-01@contoso.onmicrosoft.com','bg-admin-02@contoso.onmicrosoft.com' (default)
        Consents to RoleManagement.Read.All, PrivilegedAccess.Read.AzureAD, Directory.Read.All (read-only).
    EXPECTED RESULTS
        PASS/FAIL per break-glass account against the three rules above, plus the permanent-GA count.
        FAIL means a break-glass account is mis-configured (e.g. made PIM-eligible) — fix immediately.
        No changes are made.
.NOTES
    White-label — Entra ID Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [string[]]$BreakGlassUpns = @('bg-admin-01@contoso.onmicrosoft.com','bg-admin-02@contoso.onmicrosoft.com')
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'RoleManagement.Read.All','PrivilegedAccess.Read.AzureAD','Directory.Read.All' -NoWelcome

Write-Host "`n=== Break-glass Protection & PIM Alert Posture — $(Get-Date -Format s) ===" -ForegroundColor Cyan

$gaRole = Get-MgRoleManagementDirectoryRoleDefinition -Filter "displayName eq 'Global Administrator'" -ErrorAction SilentlyContinue
$gaId = $gaRole.Id

$active   = Get-MgRoleManagementDirectoryRoleAssignmentScheduleInstance -All -ErrorAction SilentlyContinue
$eligible = Get-MgRoleManagementDirectoryRoleEligibilityScheduleInstance -All -ErrorAction SilentlyContinue

$fails = 0
foreach ($upn in $BreakGlassUpns) {
    $user = Get-MgUser -UserId $upn -ErrorAction SilentlyContinue
    if (-not $user) { Write-Host ("FAIL  {0}: account not found" -f $upn) -ForegroundColor Red; $fails++; continue }

    $ga  = @($active   | Where-Object { $_.PrincipalId -eq $user.Id -and $_.RoleDefinitionId -eq $gaId })
    $elg = @($eligible | Where-Object { $_.PrincipalId -eq $user.Id })

    $hasGA       = $ga.Count -gt 0
    $permanentGA = $hasGA -and ($ga | Where-Object { [string]::IsNullOrEmpty($_.EndDateTime) }).Count -gt 0
    $notEligible = $elg.Count -eq 0

    $issues = @()
    if (-not $hasGA)       { $issues += 'no Global Administrator' }
    if (-not $permanentGA) { $issues += 'GA not permanent/active' }
    if (-not $notEligible) { $issues += 'account is PIM-ELIGIBLE (must be excluded from PIM)' }

    if ($issues.Count -eq 0) {
        Write-Host ("PASS  {0}: permanent active GA, not PIM-eligible" -f $upn) -ForegroundColor Green
    } else {
        Write-Host ("FAIL  {0}: {1}" -f $upn, ($issues -join '; ')) -ForegroundColor Red; $fails++
    }
}

$permGA = @($active | Where-Object { $_.RoleDefinitionId -eq $gaId -and [string]::IsNullOrEmpty($_.EndDateTime) })
Write-Host ("`nPermanent Global Administrators tenant-wide: {0}" -f $permGA.Count) -ForegroundColor $(if($permGA.Count -gt $BreakGlassUpns.Count){'Yellow'}else{'Green'})
Write-Host "  Target: only the break-glass accounts. Investigate any extra permanent GA."

Write-Host "`nReminders (configure in the portal, keep true):" -ForegroundColor Cyan
Write-Host "  • Sign-in alert on each break-glass account (any sign-in = investigate)."
Write-Host "  • PIM -> Microsoft Entra roles -> Alerts: enable 'too many Global Administrators',"
Write-Host "    'roles activated too frequently', 'roles assigned outside of PIM', 'no MFA on activation'."

Write-Host ("`nBreak-glass checks failed: {0}" -f $fails) -ForegroundColor $(if($fails){'Red'}else{'Green'})
Disconnect-MgGraph | Out-Null
