<#
.SYNOPSIS
    WSMDI-Honeytoken-Lab.ps1 — read-only Lab 3 helper: list dormant candidate accounts and print
    the exact portal steps to tag a honeytoken. PREVIEW ONLY — tags nothing.
.DESCRIPTION
    PURPOSE
        Supports Lab 3 of the "Workshop — Microsoft Defender for Identity". It (1) lists dormant /
        no-recent-sign-in accounts that are safe honeytoken candidates, and (2) prints the precise,
        current portal navigation to TAG the chosen account as a honeytoken. Tagging is a deliberate
        facilitator action done in the portal — this script does NOT perform it (no write scope is
        requested), keeping the workshop read-only/preview-first.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WSMDI-Honeytoken-Lab.ps1
        powershell -ExecutionPolicy Bypass -File .\WSMDI-Honeytoken-Lab.ps1 -DormantDays 120
        Run as Security Reader / Security Administrator; consent the read-only scopes when prompted.
    EXPECTED RESULTS
        A shortlist of candidate accounts and a printed step-by-step for the portal honeytoken tag.
        The facilitator picks one candidate (e.g. svc-legacy-backup) and tags it in the portal.
.NOTES
    White-label. Read-only / preview-first. Requests NO write scopes and changes nothing.
    A honeytoken must be an account that should NEVER legitimately authenticate.
#>
[CmdletBinding()]
param(
    [int]$DormantDays = 90
)

$ErrorActionPreference = 'Continue'
foreach ($m in 'Microsoft.Graph.Authentication','Microsoft.Graph.Users') {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Write-Host "Installing Microsoft.Graph modules (one-time)..." -ForegroundColor Yellow
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber; break
    }
}
Import-Module Microsoft.Graph.Authentication -ErrorAction SilentlyContinue

Write-Host "`n=== Honeytoken Lab (Lab 3) — candidate discovery (READ-ONLY / PREVIEW) ===" -ForegroundColor Cyan
try { Connect-MgGraph -Scopes 'User.Read.All','AuditLog.Read.All' -NoWelcome -ErrorAction Stop }
catch { Write-Host "  Could not connect: $($_.Exception.Message)" -ForegroundColor Red; return }

$cutoff = (Get-Date).AddDays(-$DormantDays)
$candidates = @()
try {
    Import-Module Microsoft.Graph.Users -ErrorAction Stop
    $users = Get-MgUser -All -Property 'displayName','userPrincipalName','accountEnabled','signInActivity' -ErrorAction Stop
    foreach ($u in $users) {
        $last = $u.SignInActivity.LastSignInDateTime
        if (-not $last -or $last -lt $cutoff) {
            $candidates += [pscustomobject]@{ DisplayName=$u.DisplayName; UPN=$u.UserPrincipalName; Enabled=$u.AccountEnabled; LastSignIn=$last }
        }
    }
    Write-Host ("`nCandidate honeytoken accounts (no sign-in in {0} days):" -f $DormantDays) -ForegroundColor Green
    $candidates | Select-Object -First 20 | Format-Table DisplayName, UPN, Enabled, LastSignIn -AutoSize
} catch {
    Write-Host "  Could not enumerate sign-in activity: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "  (Needs AuditLog.Read.All and an Entra ID P1/P2 plan — verify availability.)" -ForegroundColor Yellow
}

Write-Host @"

------------------------------------------------------------------------------
NEXT (facilitator, in the portal — this script does NOT tag anything):
  1. Pick a decoy account that should NEVER sign in (e.g. svc-legacy-backup@contoso.com).
  2. Go to  https://security.microsoft.com
  3. Settings -> Identities -> Entity tags -> Honeytoken
  4. Click 'Add', add the chosen account, save.
  5. Record it as: Honeytoken - Identity Lab - Pilot
  6. In Advanced hunting, run Section 3 of WSMDI-LabQueries.kql (set the Honeytoken UPN)
     and Save as: Honeytoken - Identity Lab - Pilot
DO NOT sign in as the honeytoken in production. In a lab only, a benign auth attempt
will generate the 'Honeytoken activity' detection for demonstration.
------------------------------------------------------------------------------
"@ -ForegroundColor Cyan

Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
Write-Host "PREVIEW complete — nothing was tagged or changed." -ForegroundColor Green
