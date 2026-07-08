<#
.SYNOPSIS
    CLSSIT-Set-Scope.ps1 — narrow the SIT measurement policy to a pilot ring, -WhatIf by default (writes only with -Commit).
.DESCRIPTION
    PURPOSE
        Scopes the simulation measurement policy so the sample is limited to a pilot ring rather than the
        whole tenant. For Exchange it restricts the rule to senders who are members of a mail-enabled group
        (Set-DlpComplianceRule -FromMemberOf); for SharePoint/OneDrive it can include specific site URLs.
        Previews the exact cmdlet under -WhatIf and changes the policy ONLY with -Commit. It never enables
        enforcement — the policy stays in simulation. Refuses to touch a policy that is in enforce (Enable) mode.
    HOW TO RUN
        # Preview: limit the Exchange scope to a pilot group's senders
        powershell -ExecutionPolicy Bypass -File .\CLSSIT-Set-Scope.ps1 -PolicyName 'SIT Measure - Payment Card - Simulation' -IncludeGroup 'sit-pilot-ring@contoso.com' -WhatIf
        # Apply
        powershell -ExecutionPolicy Bypass -File .\CLSSIT-Set-Scope.ps1 -PolicyName 'SIT Measure - Payment Card - Simulation' -IncludeGroup 'sit-pilot-ring@contoso.com' -Commit
        # Optionally scope SharePoint/OneDrive to specific sites
        ... -IncludeSites 'https://contoso.sharepoint.com/sites/pilot' -Commit
        Requires Security & Compliance PowerShell (Connect-IPPSSession). PowerShell 5.1+ or 7+.
    EXPECTED RESULTS
        -WhatIf: prints the Set-DlpComplianceRule / Set-DlpCompliancePolicy it WOULD run. -Commit: applies the
        scope and re-reads to confirm the policy is still in a Test* (simulation) mode.
.NOTES
    Purview — Sensitive Information Types Implementation. Safe-by-default (-WhatIf); simulation-only (never
    Enable). -IncludeGroup must be a mail-enabled group. DLP location scoping differs per workload — verify.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PolicyName,
    [string]$IncludeGroup,                          # mail-enabled group for Exchange sender scoping
    [string[]]$IncludeSites,                         # SharePoint/OneDrive site URLs to include
    [string]$RuleName,                               # defaults to "<PolicyName> - Rule"
    [switch]$Commit,
    [string]$UserPrincipalName
)

$ErrorActionPreference = 'Stop'
function Info($m){ Write-Host "  $m" -ForegroundColor White }
function Ok($m){ Write-Host "  [OK]   $m" -ForegroundColor Green }
function Warn($m){ Write-Host "  [WARN] $m" -ForegroundColor Yellow }

if (-not $IncludeGroup -and -not $IncludeSites) { Warn "Provide -IncludeGroup (Exchange senders) and/or -IncludeSites (SharePoint/OneDrive)."; return }
if (-not $RuleName) { $RuleName = "$PolicyName - Rule" }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) { Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber }
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

Write-Host ("=== Scope '{0}' to pilot ring ({1}) ===" -f $PolicyName, $(if($Commit){'COMMIT'}else{'WhatIf — preview'})) -ForegroundColor Cyan

# Safety: never touch an enforcing policy.
$pol = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue
if (-not $pol) { Warn "Policy '$PolicyName' not found — create it first with CLSSIT-BuildSimPolicy.ps1."; return }
if ($pol.Mode -eq 'Enable') { Warn "SAFETY: '$PolicyName' is ENFORCING — this helper will not modify an enforcing policy. Scope it in the portal under change control."; return }
Info ("Current policy mode: {0} (simulation)." -f $pol.Mode)

# --- Exchange sender scoping via the rule ---
if ($IncludeGroup) {
    Info ("Would run: Set-DlpComplianceRule -Identity '{0}' -FromMemberOf '{1}'  (Exchange: only senders in this group)" -f $RuleName, $IncludeGroup)
    if ($Commit) {
        Set-DlpComplianceRule -Identity $RuleName -FromMemberOf $IncludeGroup -ErrorAction Stop
        Ok ("Exchange scope limited to members of '{0}'." -f $IncludeGroup)
    }
}

# --- SharePoint/OneDrive site inclusion ---
if ($IncludeSites) {
    foreach ($site in $IncludeSites) {
        Info ("Would run: Set-DlpCompliancePolicy -Identity '{0}' -AddSharePointLocation '{1}'" -f $PolicyName, $site)
        if ($Commit) {
            Set-DlpCompliancePolicy -Identity $PolicyName -AddSharePointLocation $site -ErrorAction Stop
            Ok ("Added SharePoint/OneDrive site '{0}' to scope." -f $site)
        }
    }
    Info "Note: to LIMIT to only these sites, also remove the broad 'All' location in the portal or set -SharePointLocation explicitly — verify the resulting scope."
}

if ($Commit) {
    $after = Get-DlpCompliancePolicy -Identity $PolicyName
    if ($after.Mode -like 'Test*') { Ok ("PASS: '{0}' still in SIMULATION (Mode={1}) after scoping." -f $PolicyName, $after.Mode) }
    else { Warn ("Unexpected Mode '{0}' — verify in the portal; the policy must remain in simulation." -f $after.Mode) }
} else {
    Info "Preview complete. Re-run with -Commit to apply. The policy remains in simulation throughout."
}
