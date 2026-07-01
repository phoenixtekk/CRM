<#
.SYNOPSIS
    NSCASB-Validation.ps1 — CASB readiness and pilot-scoping validation (read-only).
.DESCRIPTION
    PURPOSE
        Confirms the local steering/inspection readiness signals on the device (the Netskope client
        is present and a decryption certificate is trusted) and confirms the CASB scope groups exist
        in Entra ID so policies can be scoped to the pilot before expansion. Validating the Netskope
        policy objects themselves is done via the Netskope REST API and is flagged/deferred.
    HOW TO RUN
        Local readiness signals (run on a steered endpoint, elevated):
            powershell -ExecutionPolicy Bypass -File .\NSCASB-Validation.ps1
        Add -CheckGroups to also confirm scope groups in Entra (needs Graph SDK, Group.Read.All).
    EXPECTED RESULTS
        Steering client present (yes/no), a Netskope decryption certificate trusted (yes/no), and —
        with -CheckGroups — the pilot/broad scope groups present. No changes are made (read-only).
.NOTES
    Network / CASB — read-only. Netskope console internals deferred to the official Netskope docs.
#>
[CmdletBinding()] param(
    [switch] $CheckGroups,
    [string[]] $ScopeGroup = @('CASB Pilot - Pilot users - Pilot','CASB Broad - All users - Expand')
)

Write-Host "`n=== NSCASB Validation — readiness ($($env:COMPUTERNAME)) (read-only) ===" -ForegroundColor Cyan

# --- Steering client presence (local signal) ---
Write-Host "`n[Steering client]" -ForegroundColor Cyan
$svc = Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'netskope|stagent' -or $_.DisplayName -match 'Netskope' }
if ($svc) {
    foreach ($s in $svc) { Write-Host ("  OK   service {0} = {1}" -f $s.Name, $s.Status) -ForegroundColor Green }
} else {
    Write-Host "  MISS no Netskope steering service detected — inline CASB cannot see this device's traffic." -ForegroundColor Yellow
}

# --- Decryption certificate trusted (local signal) ---
Write-Host "`n[SSL/TLS inspection certificate]" -ForegroundColor Cyan
$certs = Get-ChildItem Cert:\LocalMachine\Root -ErrorAction SilentlyContinue | Where-Object { $_.Subject -match 'Netskope' }
if ($certs) {
    foreach ($c in $certs) { Write-Host ("  OK   trusted root: {0} (expires {1:yyyy-MM-dd})" -f $c.Subject, $c.NotAfter) -ForegroundColor Green }
} else {
    Write-Host "  MISS no Netskope decryption certificate in Trusted Root — HTTPS activity cannot be inspected." -ForegroundColor Yellow
}

# --- Scope-group presence (optional, Graph) ---
if ($CheckGroups) {
    Write-Host "`n[CASB scope groups]" -ForegroundColor Cyan
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes 'Group.Read.All' -NoWelcome
    foreach ($g in $ScopeGroup) {
        $f = "displayName eq '$($g.Replace("'","''"))'"
        $found = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=$f").value
        if ($found) { Write-Host ("  OK   {0}" -f $g) -ForegroundColor Green }
        else        { Write-Host ("  MISS {0}" -f $g) -ForegroundColor Yellow }
    }
    Disconnect-MgGraph | Out-Null
}

# --- Netskope policy-object validation (FLAGGED / DEFERRED) ---
Write-Host "`n[Netskope policy validation — DEFERRED]" -ForegroundColor DarkYellow
Write-Host "  Confirming that the named CASB policies (Sanctioned apps policy, Unsanctioned apps" -ForegroundColor DarkYellow
Write-Host "  policy, the inline activity controls profile, and API connections) are scoped to" -ForegroundColor DarkYellow
Write-Host "  'CASB Pilot - Pilot users - Pilot' is done via the Netskope REST API / console and is" -ForegroundColor DarkYellow
Write-Host "  deferred to the official Netskope documentation (tenant-specific endpoints)." -ForegroundColor DarkYellow

Write-Host "`nReadiness check complete." -ForegroundColor Green
