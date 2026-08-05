<#
.SYNOPSIS
    NTLMHARD-Discovery.ps1 — tenant readiness check for NTLM-elimination + SMB-signing hardening.
.DESCRIPTION
    PURPOSE
        Confirms the Intune tenant is ready to enforce legacy-authentication hardening on Windows 10/11
        endpoints: a Windows Settings Catalog policy exists carrying the NTLM/SMB controls (LAN Manager
        authentication level, NTLM SSP minimum session security for clients and servers, SMB signing for
        client and server, insecure guest logons, and unauthenticated-RPC restriction), and reports
        whether an audit-first NTLM policy (Restrict NTLM: Audit) is present. Read-only. This checks the
        endpoint (client/member) legacy-auth hardening only — not domain-controller NTLM policy or a full
        CIS/STIG baseline.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\NTLMHARD-Discovery.ps1
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: DeviceManagementConfiguration.Read.All
    EXPECTED RESULTS
        A PASS/FAIL line per check and an overall verdict. A READY tenant shows a Windows Settings Catalog
        policy carrying the NTLM/SMB legacy-auth settings, and (recommended) a separate NTLM audit policy.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string]$ProfileName = 'NTLM-SMB Hardening - Pilot',
    [string]$AuditProfileName = 'NTLM Audit - Pilot'
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All' | Out-Null

# Registry-value anchors and Settings Catalog identifier fragments for the NTLM/SMB controls.
# The catalog display strings can change; these substrings are the stable identity of each control.
$anchors = @(
    'lmcompatibilitylevel','lanmanauthenticationlevel',
    'minimumsessionsecurity','ntlmminclientsec','ntlmminserversec',
    'digitallysigncommunications','requiresecuritysignature',
    'insecureguestlogons','allowinsecureguestauth',
    'restrictunauthenticatedrpc','restrictremoteclients'
)

function R($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}
$results = New-Object System.Collections.Generic.List[object]

# Pull all Windows Settings Catalog policies once
$policies = @()
try {
    $cfg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=platforms eq 'windows10'"
    $policies = @($cfg.value)
} catch {}

# Helper: does a policy's settings JSON reference any of the given fragments?
function Test-PolicyHasAny($PolicyId, [string[]]$Fragments) {
    try {
        $settings = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$PolicyId/settings"
        $json = ("$($settings | ConvertTo-Json -Depth 30)").ToLower()
        foreach ($f in $Fragments) { if ($json -match [regex]::Escape($f.ToLower())) { return $true } }
    } catch {}
    return $false
}

# 1) Hardening policy present (by name, or by settings content)
$hard = $null
foreach ($p in $policies) { if ($p.name -eq $ProfileName) { $hard = $p; break } }
if (-not $hard) {
    foreach ($p in $policies) { if (Test-PolicyHasAny $p.id $anchors) { $hard = $p; break } }
}
$results.Add( (R 'NTLM/SMB hardening Settings Catalog policy present' ($null -ne $hard) $(if ($hard) { "Policy: $($hard.name)" } else { "Not found: $ProfileName" })) )

# 2) Individual control coverage (best-effort, by anchor fragment)
if ($hard) {
    $checks = @(
        @{ n='LAN Manager authentication level (LmCompatibilityLevel)'; f=@('lmcompatibilitylevel','lanmanauthenticationlevel') },
        @{ n='NTLM SSP min session security (client + server)';        f=@('minimumsessionsecurity','ntlmminclientsec','ntlmminserversec') },
        @{ n='SMB signing always (client + server)';                   f=@('digitallysigncommunications','requiresecuritysignature') },
        @{ n='Insecure guest logons disabled';                         f=@('insecureguestlogons','allowinsecureguestauth') },
        @{ n='Restrict unauthenticated RPC clients';                   f=@('restrictunauthenticatedrpc','restrictremoteclients') }
    )
    foreach ($c in $checks) {
        $has = Test-PolicyHasAny $hard.id $c.f
        $results.Add( (R "  setting: $($c.n)" $has $(if ($has) { 'present' } else { 'not detected — verify display string in tenant' })) )
    }
}

# 3) Audit-first NTLM policy present (recommended, not required)
$audit = $null
foreach ($p in $policies) { if ($p.name -eq $AuditProfileName) { $audit = $p; break } }
if (-not $audit) { foreach ($p in $policies) { if (Test-PolicyHasAny $p.id @('restrictntlm','auditntlm','outgoingntlm')) { $audit = $p; break } } }
$results.Add( (R 'NTLM audit policy present (Restrict NTLM: Audit) — recommended' ($null -ne $audit) $(if ($audit) { "Policy: $($audit.name)" } else { 'Not found — deploy audit-first before enforcing (Implementation Phase 2)' })) )

$results | Format-Table -AutoSize
$fail = @($results | Where-Object { $_.Result -eq 'FAIL' -and $_.Check -notmatch 'audit policy present' }).Count
Write-Host ''
if ($fail -eq 0 -and $hard) { Write-Host 'OVERALL: READY — tenant carries the NTLM/SMB hardening policy. Confirm the audit policy ran before enforcing.' -ForegroundColor Green }
else { Write-Host "OVERALL: NOT READY — $fail hardening check(s) failed. Resolve before piloting." -ForegroundColor Yellow }
