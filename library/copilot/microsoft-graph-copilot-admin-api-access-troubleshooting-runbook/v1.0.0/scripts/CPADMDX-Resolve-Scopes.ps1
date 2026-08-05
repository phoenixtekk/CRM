<#
.SYNOPSIS
    CPADMDX-Resolve-Scopes.ps1 - Report the scopes and admin role the caller HAS versus what the named
    Copilot admin endpoint NEEDS, isolating a scope gap (Branch C/D) from a role gap (Branch E).
    READ-ONLY.

.DESCRIPTION
    PURPOSE
      Answers the most common confusion: "I have the permission and still get 403." It prints a
      have-vs-need table for the endpoint family you name, using the verified scope requirements, and
      shows whether the signed-in user holds an admin role. It does not change anything.

    HOW TO RUN
      1. Connect first (or let this script connect) - see CPADMDX-Preflight.ps1.
      2. Name the endpoint family you are calling:
           .\CPADMDX-Resolve-Scopes.ps1 -Endpoint Packages
           .\CPADMDX-Resolve-Scopes.ps1 -Endpoint PolicySettings
           .\CPADMDX-Resolve-Scopes.ps1 -Endpoint UsageReports
           .\CPADMDX-Resolve-Scopes.ps1 -Endpoint PackagesWrite

    EXPECTED RESULTS
      A have-vs-need summary: SCOPE satisfied? (yes/no), ADMIN ROLE present? (yes/no), and a branch
      pointer. Writes CPADMDX-Diagnostics\CPADMDX-Scopes.json.

.NOTES
    Copilot category - read-only diagnostics for the Microsoft Graph Copilot admin (beta) API.
    Scope/role facts verified against Microsoft Learn on the build date; beta - subject to change.
#>
[CmdletBinding()]
param(
    [ValidateSet('Packages','PackagesWrite','PolicySettings','PolicySettingsWrite','UsageReports')]
    [string]$Endpoint = 'Packages',

    [ValidateSet('Global','USGov','USGovDoD')]
    [string]$Environment = 'Global',

    [string]$OutputFolder = '.\CPADMDX-Diagnostics'
)

$ErrorActionPreference = 'Stop'

function Get-GraphHost([string]$env) {
    switch ($env) {
        'USGov'    { 'https://graph.microsoft.us' }
        'USGovDoD' { 'https://dod-graph.microsoft.us' }
        default    { 'https://graph.microsoft.com' }
    }
}

# Verified scope/role requirements per endpoint family (build-date; beta subject to change).
$need = @{
    'Packages'            = @{ Scopes=@('CopilotPackages.Read.All');            Delegated=$true;  AdminRole=$true;  Note='App permission documented but not reliably enforced; treat as delegated-only.' }
    'PackagesWrite'       = @{ Scopes=@('CopilotPackages.ReadWrite.All');       Delegated=$true;  AdminRole=$true;  Note='block/unblock/reassign/update (preview).' }
    'PolicySettings'      = @{ Scopes=@('CopilotPolicySettings.Read');          Delegated=$true;  AdminRole=$true;  Note='Application permission NOT supported.' }
    'PolicySettingsWrite' = @{ Scopes=@('CopilotPolicySettings.ReadWrite');     Delegated=$true;  AdminRole=$true;  Note='Application permission NOT supported.' }
    'UsageReports'        = @{ Scopes=@('Reports.Read.All');                     Delegated=$true;  AdminRole=$false; Note='GA fallback; Reports.Read.All (app permission supported for unattended).' }
}

$adminRoleNames = @('AI Administrator','Global Administrator','Company Administrator')

if (-not (Get-MgContext)) {
    Connect-MgGraph -Environment $Environment -Scopes ($need[$Endpoint].Scopes) -NoWelcome | Out-Null
}
$ctx = Get-MgContext
$have = @($ctx.Scopes)
$req  = $need[$Endpoint]

# roles
$roles = @()
if ($ctx.Account) {
    try {
        $resp = Invoke-MgGraphRequest -Method GET `
            -Uri "$(Get-GraphHost $Environment)/v1.0/me/memberOf/microsoft.graph.directoryRole?`$select=displayName"
        $roles = @($resp.value | ForEach-Object { $_.displayName })
    } catch {}
}

$scopeSatisfied = $true
foreach ($s in $req.Scopes) { if ($have -notcontains $s) { $scopeSatisfied = $false } }
$roleSatisfied = -not $req.AdminRole -or (@($roles | Where-Object { $adminRoleNames -contains $_ }).Count -gt 0)

Write-Host "== CPADMDX Resolve-Scopes: $Endpoint ==" -ForegroundColor Cyan
Write-Host "Need scope(s): $($req.Scopes -join ', ')   ($($req.Note))"
Write-Host "Have scope(s): $(if($have){$have -join ', '}else{'(none)'})"
Write-Host ("SCOPE satisfied : {0}" -f $(if($scopeSatisfied){'YES'}else{'NO  -> Branch C (missing) / D (not consented)'})) -ForegroundColor $(if($scopeSatisfied){'Green'}else{'Yellow'})
if ($req.AdminRole) {
    Write-Host "Admin roles held: $(if($roles){$roles -join ', '}else{'(none)'})"
    Write-Host ("ROLE satisfied  : {0}" -f $(if($roleSatisfied){'YES'}else{'NO  -> Branch E (assign AI Administrator)'})) -ForegroundColor $(if($roleSatisfied){'Green'}else{'Yellow'})
}

$verdict =
    if (-not $scopeSatisfied) { 'Branch C/D - scope not present in token.' }
    elseif ($req.AdminRole -and -not $roleSatisfied) { 'Branch E - scope OK but no admin role.' }
    else { 'Scope + role satisfied. If still 403: Branch B (app-only), F (Gov cloud), or G (license).' }
Write-Host ""
Write-Host "Verdict -> $verdict" -ForegroundColor Cyan

$out = [pscustomobject]@{
    Timestamp       = (Get-Date).ToString('o')
    Endpoint        = $Endpoint
    NeedScopes      = $req.Scopes
    HaveScopes      = $have
    ScopeSatisfied  = $scopeSatisfied
    AdminRoleNeeded = [bool]$req.AdminRole
    RolesHeld       = $roles
    RoleSatisfied   = $roleSatisfied
    Verdict         = $verdict
    Note            = $req.Note
}
if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder | Out-Null }
$out | ConvertTo-Json -Depth 6 | Set-Content -Path (Join-Path $OutputFolder 'CPADMDX-Scopes.json') -Encoding UTF8
Write-Host "Saved: $(Join-Path $OutputFolder 'CPADMDX-Scopes.json')" -ForegroundColor Green
return $out
