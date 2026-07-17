<#
.SYNOPSIS
    LAMIMAIL-Test-MailboxAccess.ps1 — prove the security boundary: the identity can read the IN-scope
    mailbox and is DENIED reading an OUT-of-scope mailbox.
.DESCRIPTION
    PURPOSE
        The boundary test for the "Exchange Online Mailbox Automation with Logic Apps Managed Identity
        (Graph)" solution. Using APPLICATION authentication as the managed identity's app registration
        (app-only Graph, the same identity the Logic App uses), it attempts to read messages from:
          * the IN-scope mailbox  (automation-inbox@contoso.com)  — MUST succeed;
          * an OUT-of-scope mailbox (a control mailbox you name)   — MUST be denied (403 / ErrorAccessDenied).
        A correctly scoped deployment PASSES only when the in-scope read works AND the out-of-scope read
        is denied. Read-only: it only reads (or is refused); it never writes or deletes mail.

        App-only auth here uses the identity's AppId with either a certificate (recommended) or a
        client secret you supply, so this script exercises the SAME application-permission + mailbox
        scope that governs the Logic App. (A managed identity itself has no secret you can hand to a
        script; verify your app-only connection method against current Microsoft Graph documentation.)
    HOW TO RUN
        # certificate-based app-only auth (recommended)
        powershell -ExecutionPolicy Bypass -File .\LAMIMAIL-Test-MailboxAccess.ps1 `
            -TenantId '<tenant-guid>' -AppId '<identity-appId>' -CertThumbprint '<thumbprint>' `
            -InScopeMailbox 'automation-inbox@contoso.com' `
            -OutOfScopeMailbox 'ceo@contoso.com'
    REQUIRED GRAPH PERMISSION (application, on the app being tested)
        Mail.Read (application) — scoped to ONE mailbox by Application Access Policy or Graph RBAC.
        (verify the exact permission name against current Microsoft Graph documentation)
    EXPECTED RESULTS
        PASS: in-scope read returns messages; out-of-scope read is refused (Access Denied). Any other
        combination is a FAIL — in particular, an out-of-scope read that SUCCEEDS means the mailbox
        scope is not in place (the identity still has tenant-wide read).
.NOTES
    Azure Solutions — read-only boundary test. The repeatable way.
    Reads (or is denied) mail only; never writes/deletes. A successful out-of-scope read = scope FAIL.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$TenantId,
    [Parameter(Mandatory)] [string]$AppId,               # the managed identity's / app registration's AppId
    [string]$CertThumbprint,                             # certificate app-only auth (recommended)
    [string]$ClientSecret,                               # OR client-secret app-only auth
    [Parameter(Mandatory)] [string]$InScopeMailbox,      # e.g. automation-inbox@contoso.com  (MUST succeed)
    [Parameter(Mandatory)] [string]$OutOfScopeMailbox    # e.g. ceo@contoso.com                (MUST be denied)
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Write-Host "Microsoft.Graph module not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser" -ForegroundColor Red
    return
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

# --- App-only connect (the same app-permission + scope the Logic App identity uses) ---
try {
    if ($CertThumbprint) {
        Connect-MgGraph -TenantId $TenantId -ClientId $AppId -CertificateThumbprint $CertThumbprint -NoWelcome -ErrorAction Stop
    } elseif ($ClientSecret) {
        $sec  = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
        $cred = [System.Management.Automation.PSCredential]::new($AppId, $sec)
        Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $cred -NoWelcome -ErrorAction Stop
    } else {
        Write-Host "Provide -CertThumbprint (recommended) or -ClientSecret for app-only auth." -ForegroundColor Red
        return
    }
} catch {
    Write-Host ("App-only Connect-MgGraph failed: {0}" -f $_.Exception.Message) -ForegroundColor Red
    return
}

function Test-MailboxRead([string]$mailbox) {
    try {
        $uri = "https://graph.microsoft.com/v1.0/users/$mailbox/messages?`$top=1&`$select=id,subject"
        $r   = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
        return [pscustomobject]@{ Mailbox = $mailbox; ReadSucceeded = $true;  Detail = "returned $((@($r.value)).Count) message(s)" }
    } catch {
        return [pscustomobject]@{ Mailbox = $mailbox; ReadSucceeded = $false; Detail = $_.Exception.Message }
    }
}

Write-Host "`n=== LAMIMAIL — mailbox-access boundary test ===" -ForegroundColor Cyan
$inRes  = Test-MailboxRead $InScopeMailbox
$outRes = Test-MailboxRead $OutOfScopeMailbox

Write-Host ("`nIN-scope  {0}: {1} ({2})"  -f $InScopeMailbox,  $(if($inRes.ReadSucceeded){'READ OK'}else{'DENIED'}), $inRes.Detail)  -ForegroundColor $(if($inRes.ReadSucceeded){'Green'}else{'Red'})
Write-Host ("OUT-scope {0}: {1} ({2})"    -f $OutOfScopeMailbox, $(if($outRes.ReadSucceeded){'READ OK'}else{'DENIED'}), $outRes.Detail) -ForegroundColor $(if($outRes.ReadSucceeded){'Red'}else{'Green'})

$pass = ($inRes.ReadSucceeded -eq $true) -and ($outRes.ReadSucceeded -eq $false)
if ($pass) {
    Write-Host "`nOVERALL: PASS — in-scope readable, out-of-scope denied. The one-mailbox boundary holds." -ForegroundColor Green
} elseif ($outRes.ReadSucceeded) {
    Write-Host "`nOVERALL: FAIL — the OUT-of-scope mailbox was READABLE. The mailbox scope is NOT in place (identity still has tenant-wide read). Apply the scope (Implementation Step 3 / scoping sibling product)." -ForegroundColor Red
} else {
    Write-Host "`nOVERALL: FAIL — the in-scope read did not succeed. Check the app-role grant/consent and the scope membership." -ForegroundColor Red
}
