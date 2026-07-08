<#
.SYNOPSIS
    PURVIEW-Set-ScopeTargeting.ps1 — scope/health helper: -HealthCheck reports connectivity/roles/per-domain readability; otherwise builds the pilot group.
.DESCRIPTION
    PURPOSE
        Two safe roles. With -HealthCheck (read-only) it confirms Security & Compliance PowerShell and
        Microsoft Graph connectivity, reports the signed-in account's roles, and probes whether each of
        the ten maturity domains is READABLE (so no domain false-scores as Absent). Without -HealthCheck
        it creates/updates the pilot Microsoft Entra security group "Purview - Pilot Users" used to
        scope quick-win baseline objects — group changes only with -Commit.
    HOW TO RUN
        # read-only health + readability check:
        powershell -ExecutionPolicy Bypass -File .\PURVIEW-Set-ScopeTargeting.ps1 -HealthCheck
        # preview pilot-group changes:
        powershell -ExecutionPolicy Bypass -File .\PURVIEW-Set-ScopeTargeting.ps1 -Members alice@contoso.com,bob@contoso.com
        # apply pilot-group changes:
        powershell -ExecutionPolicy Bypass -File .\PURVIEW-Set-ScopeTargeting.ps1 -Members alice@contoso.com -Commit
    EXPECTED RESULTS
        -HealthCheck: PASS/FAIL for IPPS + Graph sign-in, a role list, and a readable/unreadable line per
        domain D1-D10. Group mode: the "Purview - Pilot Users" group present with the requested members
        (changes only under -Commit).
.NOTES
    White-label — Purview Solutions. -HealthCheck is READ-ONLY; group writes require -Commit.
    Uses Connect-IPPSSession / Connect-MgGraph; Get-MgGroup / New-MgGroup / New-MgGroupMember for the group.
#>
[CmdletBinding()]
param(
    [switch]$HealthCheck,
    [string]$GroupName = 'Purview - Pilot Users',
    [string[]]$Members = @(),
    [switch]$Commit
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop

# ---------------- HEALTH CHECK (read-only) ----------------
if ($HealthCheck) {
    Write-Host "`n=== Purview maturity — connectivity / role / readability health check (read-only) ===" -ForegroundColor Cyan

    $ippsOk = $false
    try { Connect-IPPSSession -ShowBanner:$false; $ippsOk = $true } catch {}
    Write-Host ("  {0}  Connect-IPPSSession" -f ($(if ($ippsOk) {'PASS'} else {'FAIL'}))) -ForegroundColor ($(if ($ippsOk){'Green'}else{'Red'}))

    $graphOk = $false
    try {
        if (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication) {
            Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
            Connect-MgGraph -Scopes 'Directory.Read.All','Group.ReadWrite.All' -NoWelcome -ErrorAction Stop
            $graphOk = $true
        }
    } catch {}
    Write-Host ("  {0}  Connect-MgGraph" -f ($(if ($graphOk) {'PASS'} else {'WARN'}))) -ForegroundColor ($(if ($graphOk){'Green'}else{'Yellow'}))

    # Per-domain read probes (safe, list-only). A caught error => unreadable/unlicensed.
    $probes = [ordered]@{
        'D1 Information Protection' = { Get-Label -ErrorAction Stop | Out-Null }
        'D2 Data Loss Prevention'   = { Get-DlpCompliancePolicy -ErrorAction Stop | Out-Null }
        'D3 Lifecycle & Records'    = { Get-RetentionCompliancePolicy -ErrorAction Stop | Out-Null }
        'D4 Insider Risk'           = { Get-InsiderRiskPolicy -ErrorAction Stop | Out-Null }
        'D5 Communication Compl.'   = { Get-SupervisoryReviewPolicyV2 -ErrorAction Stop | Out-Null }
        'D6 Audit'                  = { Get-AdminAuditLogConfig -ErrorAction Stop | Out-Null }
        'D7 eDiscovery'             = { Get-ComplianceCase -ErrorAction Stop | Out-Null }
    }
    Write-Host "`n  Domain readability (S&C PowerShell):" -ForegroundColor Cyan
    foreach ($d in $probes.Keys) {
        $ok = $true
        try { & $probes[$d] } catch { $ok = $false }
        Write-Host ("    {0}  {1}" -f ($(if ($ok){'readable  '}else{'UNREADABLE'}), $d)) -ForegroundColor ($(if ($ok){'Green'}else{'Yellow'}))
    }
    Write-Host "    D8 DSPM / D9 Data Governance / D10 Compliance Manager — portal/preview-surfaced: verify in the Purview portal." -ForegroundColor DarkGray

    Write-Host "`nHealth check complete. Fix any UNREADABLE domain (role or licensing) before scoring so it does not false-score as Absent." -ForegroundColor Green
    try { Disconnect-ExchangeOnline -Confirm:$false | Out-Null } catch {}
    return
}

# ---------------- PILOT GROUP (write gated by -Commit) ----------------
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Groups)) {
    Write-Host "Microsoft.Graph.Groups not installed. Install-Module Microsoft.Graph -Scope CurrentUser" -ForegroundColor Yellow
    return
}
Import-Module Microsoft.Graph.Groups -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','User.Read.All' -NoWelcome -ErrorAction Stop

Write-Host "`n=== Purview maturity — pilot scope group '$GroupName' ===" -ForegroundColor Cyan
$grp = Get-MgGroup -Filter "displayName eq '$GroupName'" -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not $grp) {
    if ($Commit) {
        $mailNick = ($GroupName -replace '[^A-Za-z0-9]','')
        $grp = New-MgGroup -DisplayName $GroupName -MailEnabled:$false -MailNickname $mailNick `
            -SecurityEnabled:$true -Description "Purview maturity assessment pilot scope" -ErrorAction Stop
        Write-Host "  DONE : created group '$GroupName'" -ForegroundColor Green
    } else {
        Write-Host "  WOULD: create security group '$GroupName' (re-run with -Commit)" -ForegroundColor Yellow
    }
} else { Write-Host "  OK   : group '$GroupName' already exists" -ForegroundColor Green }

foreach ($m in $Members) {
    if ($Commit -and $grp) {
        try {
            $user = Get-MgUser -Filter "userPrincipalName eq '$m'" -ErrorAction Stop | Select-Object -First 1
            New-MgGroupMember -GroupId $grp.Id -DirectoryObjectId $user.Id -ErrorAction Stop
            Write-Host ("  DONE : added {0}" -f $m) -ForegroundColor Green
        } catch { Write-Host ("  SKIP : {0} — {1}" -f $m, $_.Exception.Message) -ForegroundColor DarkYellow }
    } else {
        Write-Host ("  WOULD: add {0}" -f $m) -ForegroundColor Yellow
    }
}

if (-not $Commit) { Write-Host "`nPREVIEW only — re-run with -Commit to apply group changes." -ForegroundColor Yellow }
else { Write-Host "`nPilot scope ready. Use it when running PURVIEW-Remediation.ps1 -Commit." -ForegroundColor Green }
