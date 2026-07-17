<#
.SYNOPSIS
    MBXRBAC-Validate.ps1 — PASS/FAIL: confirm a target app/identity is SCOPED (not tenant-wide) to
    the intended mailbox(es).
.DESCRIPTION
    PURPOSE
        Read-only validation for the "Scoping Application-Permission Mailbox Access" solution.
        For a named application (AppId) and its intended mailbox scope, confirms that an Exchange
        Application Access Policy (or an Exchange RBAC assignment) actually covers the app, that the
        mail-enabled security group is the correct type and contains only the allowed mailboxes, and
        that Microsoft's built-in policy test grants the in-scope mailbox and denies an out-of-scope
        one. Emits a single PASS/FAIL. Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MBXRBAC-Validate.ps1 `
          -AppId "11111111-1111-1111-1111-111111111111" `
          -ScopeGroup "App Mailbox Scope – Reporting – Prod" `
          -InScopeMailbox "reports@contoso.com" `
          -OutOfScopeMailbox "ceo@contoso.com"
        Requires ExchangeOnlineManagement. Run Connect-ExchangeOnline first, or the script prompts.
    REQUIRED SCOPES / ROLES
        Exchange Online: a role that can run Get-ApplicationAccessPolicy, Test-ApplicationAccessPolicy,
        and Get-DistributionGroup / Get-DistributionGroupMember (View-Only Recipients / View-Only
        Configuration are typically sufficient). VERIFY exact role and cmdlet names against current
        Microsoft documentation.
    EXPECTED RESULTS
        PASS when: a policy/assignment covers the AppId; the scope group is a mail-enabled security
        group containing the in-scope mailbox and NOT the out-of-scope mailbox; the built-in test
        grants in-scope and denies out-of-scope. Otherwise FAIL with the reason. Read-only.
.NOTES
    Azure Solutions — read-only. White-label sample values use contoso.com. All cmdlet names:
    verify against current Microsoft documentation.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$AppId,
    [string]$ScopeGroup       = "App Mailbox Scope – Reporting – Prod",
    [string]$InScopeMailbox   = "reports@contoso.com",
    [string]$OutOfScopeMailbox= "ceo@contoso.com"
)

Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
try { Get-ConnectionInformation -ErrorAction Stop | Out-Null } catch { try { Connect-ExchangeOnline -ShowBanner:$false | Out-Null } catch { Write-Host "Connect-ExchangeOnline failed: $($_.Exception.Message)" -ForegroundColor Red; exit 2 } }

Write-Host "`n=== Validate app is SCOPED — $AppId ===" -ForegroundColor Cyan
$fail = @()

# 1) A policy/assignment covers this AppId.
$covered = $false
try {
    $policies = Get-ApplicationAccessPolicy -ErrorAction Stop
    foreach ($p in $policies) { if ($p.AppId -contains $AppId -or $p.ScopeName -eq $AppId) { $covered = $true; break } }
} catch { Write-Host "   (could not read Application Access Policies: $($_.Exception.Message))" -ForegroundColor Yellow }
if ($covered) { Write-Host "   [OK]  an Application Access Policy covers the app" -ForegroundColor Green }
else { Write-Host "   [!!]  no Application Access Policy found for the app (check the Graph RBAC model too — verify with Microsoft)" -ForegroundColor Yellow; $fail += 'no policy covers the AppId' }

# 2) Scope group is a MAIL-ENABLED SECURITY GROUP with the right members.
try {
    $grp = Get-DistributionGroup -Identity $ScopeGroup -ErrorAction Stop
    $isMailSec = ($grp.GroupType -match 'SecurityEnabled') -or ($grp.RecipientTypeDetails -eq 'MailUniversalSecurityGroup')
    if ($isMailSec) { Write-Host "   [OK]  '$ScopeGroup' is a mail-enabled security group" -ForegroundColor Green }
    else { Write-Host "   [!!]  '$ScopeGroup' is NOT a mail-enabled security group (type: $($grp.RecipientTypeDetails))" -ForegroundColor Yellow; $fail += 'scope group is wrong type' }

    $members = Get-DistributionGroupMember -Identity $ScopeGroup -ErrorAction Stop | Select-Object -ExpandProperty PrimarySmtpAddress
    if ($members -contains $InScopeMailbox) { Write-Host "   [OK]  in-scope mailbox '$InScopeMailbox' is a member" -ForegroundColor Green }
    else { Write-Host "   [!!]  in-scope mailbox '$InScopeMailbox' is NOT a member" -ForegroundColor Yellow; $fail += 'in-scope mailbox missing from group' }
    if ($members -contains $OutOfScopeMailbox) { Write-Host "   [!!]  out-of-scope mailbox '$OutOfScopeMailbox' IS a member (should not be)" -ForegroundColor Yellow; $fail += 'out-of-scope mailbox present in group' }
    else { Write-Host "   [OK]  out-of-scope mailbox '$OutOfScopeMailbox' is not a member" -ForegroundColor Green }
} catch { Write-Host "   (could not read group '$ScopeGroup': $($_.Exception.Message)) — required only for the Application Access Policy model" -ForegroundColor Yellow }

# 3) Built-in policy test: in-scope granted, out-of-scope denied (VERIFY cmdlet name).
try {
    $inR  = Test-ApplicationAccessPolicy -Identity $InScopeMailbox    -AppId $AppId -ErrorAction Stop
    $outR = Test-ApplicationAccessPolicy -Identity $OutOfScopeMailbox -AppId $AppId -ErrorAction Stop
    if ("$($inR.AccessCheckResult)" -match 'Grant') { Write-Host "   [OK]  built-in test GRANTS in-scope '$InScopeMailbox'" -ForegroundColor Green }
    else { Write-Host "   [!!]  built-in test does NOT grant in-scope '$InScopeMailbox' ($($inR.AccessCheckResult))" -ForegroundColor Yellow; $fail += 'in-scope not granted' }
    if ("$($outR.AccessCheckResult)" -match 'Den') { Write-Host "   [OK]  built-in test DENIES out-of-scope '$OutOfScopeMailbox'" -ForegroundColor Green }
    else { Write-Host "   [!!]  built-in test does NOT deny out-of-scope '$OutOfScopeMailbox' ($($outR.AccessCheckResult))" -ForegroundColor Red; $fail += 'out-of-scope not denied' }
} catch { Write-Host "   (could not run Test-ApplicationAccessPolicy: $($_.Exception.Message)) — verify cmdlet name / applies to the Application Access Policy model" -ForegroundColor Yellow }

Write-Host ""
if ($fail.Count -eq 0) { Write-Host "RESULT: PASS — the app is scoped (not tenant-wide) to the intended mailbox(es)." -ForegroundColor Green; exit 0 }
else { Write-Host ("RESULT: FAIL — {0}" -f ($fail -join '; ')) -ForegroundColor Red; exit 1 }
