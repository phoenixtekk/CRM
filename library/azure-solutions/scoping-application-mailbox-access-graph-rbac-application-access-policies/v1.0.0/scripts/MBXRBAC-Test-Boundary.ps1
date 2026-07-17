<#
.SYNOPSIS
    MBXRBAC-Test-Boundary.ps1 — the boundary proof: authenticate AS THE APPLICATION and confirm the
    in-scope mailbox read SUCCEEDS while the out-of-scope mailbox read is DENIED.
.DESCRIPTION
    PURPOSE
        Read-only proof for the "Scoping Application-Permission Mailbox Access" solution. Using the
        application's OWN credential (client credentials for the scoped app registration / managed
        identity), it attempts a Microsoft Graph mail read against the in-scope mailbox and against
        the out-of-scope mailbox, and reports PASS/FAIL:
          in-scope read  -> must SUCCEED (HTTP 200)
          out-of-scope   -> must be DENIED (HTTP 403 / ErrorAccessDenied)
        This is the evidence that the scope actually constrains the app. Reads only; sends/writes no
        mail and changes no configuration.
    HOW TO RUN
        # App-registration (client secret) example:
        powershell -ExecutionPolicy Bypass -File .\MBXRBAC-Test-Boundary.ps1 `
          -TenantId  "<tenant-guid>" `
          -AppId     "11111111-1111-1111-1111-111111111111" `
          -ClientSecret (Read-Host -AsSecureString "App client secret") `
          -InScopeMailbox "reports@contoso.com" -OutOfScopeMailbox "ceo@contoso.com"
        # Managed identity (Logic App / Function / VM) — omit -ClientSecret and use -UseManagedIdentity.
        Requires Microsoft.Graph.Authentication. Prefer a certificate or managed identity over a
        client secret in production.
    REQUIRED SCOPES / ROLES
        The APPLICATION being tested must hold the mail application permission being proven
        (e.g. Mail.Read) — that is the point. The operator running the script needs nothing beyond
        the app's own credential. VERIFY exact Graph permission names and endpoints against current
        Microsoft documentation (and use the correct national-cloud endpoint for GCC/GCC High/DoD).
    EXPECTED RESULTS
        PASS when the in-scope read returns 200 AND the out-of-scope read returns 403/denied. FAIL if
        the out-of-scope read succeeds (scope not in effect — wrong model, mis-scope, or propagation
        not complete) or the in-scope read is denied (scope too tight). Read-only.
.NOTES
    Azure Solutions — read-only (mailbox reads only). White-label sample values use contoso.com.
    All permission names/endpoints: verify against current Microsoft documentation.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$TenantId,
    [Parameter(Mandatory)] [string]$AppId,
    [System.Security.SecureString]$ClientSecret,
    [switch]$UseManagedIdentity,
    [string]$InScopeMailbox    = "reports@contoso.com",
    [string]$OutOfScopeMailbox = "ceo@contoso.com"
)

Import-Module Microsoft.Graph.Authentication -ErrorAction SilentlyContinue

# Connect AS THE APPLICATION (client credentials or managed identity), not as a user.
try {
    if ($UseManagedIdentity) {
        Connect-MgGraph -Identity -ErrorAction Stop | Out-Null
    } elseif ($ClientSecret) {
        $cred = New-Object System.Management.Automation.PSCredential($AppId, $ClientSecret)
        Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $cred -ErrorAction Stop | Out-Null
    } else {
        Write-Host "Provide -ClientSecret (or a certificate) or -UseManagedIdentity to authenticate as the app." -ForegroundColor Red
        exit 2
    }
} catch { Write-Host "App authentication failed: $($_.Exception.Message)" -ForegroundColor Red; exit 2 }

function Test-MailRead([string]$mailbox) {
    # VERIFY the endpoint/path and use the correct national-cloud host for GCC/GCC High/DoD.
    $uri = "https://graph.microsoft.com/v1.0/users/$mailbox/messages?`$top=1&`$select=subject"
    try {
        Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop | Out-Null
        return [pscustomobject]@{ Mailbox = $mailbox; Status = 200; Allowed = $true }
    } catch {
        $code = $_.Exception.Response.StatusCode.value__ 2>$null
        if (-not $code) { $code = 'error' }
        return [pscustomobject]@{ Mailbox = $mailbox; Status = $code; Allowed = $false }
    }
}

Write-Host "`n=== Boundary proof for app $AppId ===" -ForegroundColor Cyan
$inR  = Test-MailRead $InScopeMailbox
$outR = Test-MailRead $OutOfScopeMailbox

# In-scope: must succeed.
if ($inR.Allowed) { Write-Host ("   [PASS] in-scope read  '{0}' -> {1} (succeeded)" -f $inR.Mailbox, $inR.Status) -ForegroundColor Green }
else              { Write-Host ("   [FAIL] in-scope read  '{0}' -> {1} (denied — scope too tight?)" -f $inR.Mailbox, $inR.Status) -ForegroundColor Red }

# Out-of-scope: must be denied.
if (-not $outR.Allowed) { Write-Host ("   [PASS] out-of-scope   '{0}' -> {1} (denied — boundary holds)" -f $outR.Mailbox, $outR.Status) -ForegroundColor Green }
else                    { Write-Host ("   [FAIL] out-of-scope   '{0}' -> {1} (SUCCEEDED — scope NOT in effect!)" -f $outR.Mailbox, $outR.Status) -ForegroundColor Red }

Write-Host ""
if ($inR.Allowed -and (-not $outR.Allowed)) {
    Write-Host "RESULT: PASS — in-scope read succeeds and out-of-scope read is denied. Boundary proven." -ForegroundColor Green
    exit 0
} else {
    Write-Host "RESULT: FAIL — boundary not proven. If out-of-scope succeeded, check the model/mis-scope and allow propagation time (see Troubleshooting)." -ForegroundColor Red
    exit 1
}
