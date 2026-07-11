<#
.SYNOPSIS
    WSMDI-Discovery.ps1 — read-only discovery for the Defender for Identity workshop: MDI alerts,
    recent identity signal, and candidate honeytoken (dormant) accounts.
.DESCRIPTION
    PURPOSE
        Read-only environment discovery for the "Workshop — Microsoft Defender for Identity"
        enablement package. Confirms the tenant has identity telemetry to teach against: recent
        Defender for Identity alerts (via Microsoft Graph Security), a summary by severity, and a
        list of dormant / no-recent-sign-in accounts that are candidate honeytokens for Lab 3.
        Makes NO changes and tags nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WSMDI-Discovery.ps1
        powershell -ExecutionPolicy Bypass -File .\WSMDI-Discovery.ps1 -DormantDays 90 -OutputPath .\wsmdi-discovery.json
        Requires the Microsoft.Graph modules. The script connects with READ-ONLY delegated scopes;
        consent as a Security Reader / Security Administrator when prompted.
    EXPECTED RESULTS
        A console summary plus a JSON file: MDI alert count by severity, the most recent alerts, and
        candidate honeytoken accounts (no sign-in within -DormantDays). Use it in Lab 0 (readiness)
        and to pick the honeytoken in Lab 3.
.NOTES
    White-label. Read-only. Reports configuration/identifiers only; makes no changes.
    Feature/licensing facts are indicative — verify current availability in your tenant.
#>
[CmdletBinding()]
param(
    [int]$DormantDays = 90,
    [string]$OutputPath = ".\wsmdi-discovery.json"
)

$ErrorActionPreference = 'Stop'
$scopes = @('SecurityAlert.Read.All','SecurityEvents.Read.All','AuditLog.Read.All','User.Read.All')

foreach ($m in 'Microsoft.Graph.Authentication','Microsoft.Graph.Security','Microsoft.Graph.Users') {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Write-Host "Installing Microsoft.Graph modules (one-time)..." -ForegroundColor Yellow
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
        break
    }
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

Write-Host "`n=== Defender for Identity workshop — discovery (read-only) ===" -ForegroundColor Cyan
try {
    Connect-MgGraph -Scopes $scopes -NoWelcome
} catch {
    Write-Host "  Could not connect to Microsoft Graph: $($_.Exception.Message)" -ForegroundColor Red
    return
}

$result = [ordered]@{ Timestamp = (Get-Date).ToString('s'); DormantDays = $DormantDays }

# --- Defender for Identity alerts (read-only) ---
Write-Host "`n-- Recent Defender for Identity alerts --" -ForegroundColor Cyan
$mdiAlerts = @()
try {
    # Graph Security alerts_v2; filter to the Defender for Identity provider where available.
    $alerts = Get-MgSecurityAlertV2 -All -ErrorAction Stop |
        Where-Object { $_.ServiceSource -match 'Identity' -or $_.DetectionSource -match 'Identity' }
    foreach ($a in $alerts) {
        $mdiAlerts += [pscustomobject]@{
            Title = $a.Title; Severity = $a.Severity; Status = $a.Status; CreatedDateTime = $a.CreatedDateTime
        }
    }
    if ($mdiAlerts.Count -eq 0) {
        Write-Host "   No Defender for Identity alerts returned (tenant may be quiet — that is OK for teaching)." -ForegroundColor Yellow
    } else {
        $bySev = $mdiAlerts | Group-Object Severity | ForEach-Object { "{0}={1}" -f $_.Name, $_.Count }
        Write-Host ("   Total MDI alerts: {0}  ({1})" -f $mdiAlerts.Count, ($bySev -join ', ')) -ForegroundColor Green
        $mdiAlerts | Sort-Object CreatedDateTime -Descending | Select-Object -First 10 |
            Format-Table Title, Severity, Status, CreatedDateTime -AutoSize
    }
} catch {
    Write-Host "   Could not read Graph Security alerts: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "   (Confirm SecurityAlert.Read.All consent and that Defender for Identity is licensed.)" -ForegroundColor Yellow
}
$result.MdiAlertCount = $mdiAlerts.Count
$result.MdiAlerts = $mdiAlerts | Select-Object -First 25

# --- Candidate honeytoken accounts (dormant / no recent sign-in) ---
Write-Host "`n-- Candidate honeytoken accounts (dormant, read-only) --" -ForegroundColor Cyan
$cutoff = (Get-Date).AddDays(-$DormantDays)
$candidates = @()
try {
    Import-Module Microsoft.Graph.Users -ErrorAction Stop
    $users = Get-MgUser -All -Property 'displayName','userPrincipalName','accountEnabled','signInActivity' -ErrorAction Stop
    foreach ($u in $users) {
        $last = $u.SignInActivity.LastSignInDateTime
        if (-not $last -or $last -lt $cutoff) {
            $candidates += [pscustomobject]@{
                DisplayName = $u.DisplayName; UPN = $u.UserPrincipalName
                Enabled = $u.AccountEnabled; LastSignIn = $last
            }
        }
    }
    Write-Host ("   {0} account(s) with no sign-in in the last {1} days (candidate honeytokens)." -f $candidates.Count, $DormantDays) -ForegroundColor Green
    $candidates | Select-Object -First 15 | Format-Table DisplayName, UPN, Enabled, LastSignIn -AutoSize
    Write-Host "   NOTE: pick a service/decoy account that legitimately should NEVER sign in (e.g. svc-legacy-backup)." -ForegroundColor Yellow
} catch {
    Write-Host "   Could not enumerate sign-in activity: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "   (signInActivity needs AuditLog.Read.All and an Entra ID P1/P2 plan — verify availability.)" -ForegroundColor Yellow
}
$result.HoneytokenCandidates = $candidates | Select-Object -First 25

$result | ConvertTo-Json -Depth 6 | Out-File -FilePath $OutputPath -Encoding UTF8
Write-Host "`nSaved discovery to $OutputPath" -ForegroundColor Cyan
Write-Host "This script is READ-ONLY — it tagged nothing and changed nothing." -ForegroundColor Green
Disconnect-MgGraph | Out-Null
