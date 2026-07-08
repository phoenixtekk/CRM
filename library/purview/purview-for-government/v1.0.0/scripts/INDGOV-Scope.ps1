<#
.SYNOPSIS
    INDGOV-Scope.ps1 — in-scope population + connection/role/endpoint-onboarding health helper (read-only).
.DESCRIPTION
    PURPOSE
        Enumerates the intended in-scope population and confirms toolchain health with no changes: members
        of the controlled-data group, the mailboxes/sites in scope, the compliance role groups it can see
        (for duty separation on who reads DLP matches / audit evidence), which endpoints (S&C PowerShell /
        Graph) are reachable in your cloud, and pointers for endpoint-DLP device onboarding readiness. Use
        before configuring so the pilot scope is grounded in real objects. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\INDGOV-Scope.ps1 -ControlledDataGroup "Gov Controlled Data Users"
        # Sovereign cloud — pass the cloud endpoints:
        .\INDGOV-Scope.ps1 -ControlledDataGroup "Gov Controlled Data Users" -ConnectionUri https://ps.compliance.protection.office365.us/powershell-liveid/ -GraphEnvironment USGov
        Requires ExchangeOnlineManagement (Connect-IPPSSession) and, for group membership, Microsoft.Graph
        with delegated Group.Read.All / User.Read.All. Interactive modern-auth / MFA admin; no secrets.
        VERIFY the exact -ConnectionUri / -GraphEnvironment for your cloud.
    EXPECTED RESULTS
        A scope summary: group member count, sample in-scope mailboxes, visible role groups, and endpoint
        reachability. PASS = the controlled-data group resolves and both cloud endpoints are reachable;
        FAIL = group not found or an endpoint unreachable (resolve before configuring). Endpoint-DLP
        onboarding state is a POINTER — confirm onboarded devices in the Purview portal / Devices.
.NOTES
    Purview category — Government industry bundle (CJIS/CMMC/ITAR). Read-only. In-scope population and data
    classification are compliance/security determinations; this only enumerates what you name. Confirm
    cmdlet/role/endpoint names against your tenant and cloud.
#>
[CmdletBinding()]
param(
    [string]$ControlledDataGroup,        # display name of the group of in-scope controlled-data users (optional)
    [string]$UserPrincipalName,
    [string]$ConnectionUri,              # sovereign-cloud S&C endpoint — VERIFY for your cloud
    [ValidateSet('Global','USGov','USGovDoD')]
    [string]$GraphEnvironment = 'Global',
    [switch]$SkipGraph
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Ok($m){ Write-Host $m -ForegroundColor Green }
function Warn($m){ Write-Host $m -ForegroundColor Yellow }

# --- Endpoint health: Security & Compliance PowerShell (cloud endpoint if supplied) ---
Write-Section "Endpoint health"
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Warn "ExchangeOnlineManagement not installed. Install-Module ExchangeOnlineManagement -Scope CurrentUser"; return
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
$connectParams = @{}
if ($UserPrincipalName) { $connectParams['UserPrincipalName'] = $UserPrincipalName }
if ($ConnectionUri)     { $connectParams['ConnectionUri']     = $ConnectionUri; Warn "Using sovereign-cloud S&C endpoint: $ConnectionUri (verify for your cloud)." }
$ippsOk = $false
try { Connect-IPPSSession @connectParams -ErrorAction Stop | Out-Null; $ippsOk = $true; Ok "Security & Compliance PowerShell (Connect-IPPSSession) : reachable" }
catch { Warn "Connect-IPPSSession failed: $($_.Exception.Message) — in GCC High/DoD you must pass the correct -ConnectionUri." }

# --- Visible role groups (duty separation for DLP-match / audit-evidence access) ---
if ($ippsOk) {
    Write-Section "Compliance role groups (duty separation)"
    try {
        $rg = Get-RoleGroup -ErrorAction Stop | Where-Object { $_.Name -match 'Compliance|Records|Retention|Audit|Information Protection|DLP|Insider|Data' }
        if ($rg) {
            $rg | Select-Object Name, @{n='Members';e={ @($_.Members).Count }} | Format-Table -AutoSize | Out-String | Write-Host
            Warn "DLP matches and audit evidence can contain CJI/CUI/ITAR — confirm who may READ them is SEPARATE from the configuring admin."
        } else { Warn "No matching compliance role groups visible (check permissions)." }
    } catch { Warn "Could not enumerate role groups (Get-RoleGroup): $($_.Exception.Message)" }
}

# --- Endpoint-DLP onboarding readiness (pointer) ---
Write-Section "Endpoint DLP device onboarding (pointer)"
Warn "Endpoint DLP only controls egress on ONBOARDED devices. Confirm onboarded devices in the Purview portal → Settings → Devices (Device onboarding), and that endpoint DLP is available in your cloud. This script cannot enumerate device onboarding state."

# --- In-scope population + mailboxes (Graph, cloud environment) ---
if (-not $SkipGraph) {
    Write-Section "In-scope population (Microsoft Graph)"
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Warn "Microsoft.Graph not installed — skipping population. Install-Module Microsoft.Graph -Scope CurrentUser (or -SkipGraph)."
    } elseif (-not $ControlledDataGroup) {
        Warn "No -ControlledDataGroup supplied — provide the in-scope controlled-data group display name to enumerate scope."
    } else {
        try {
            Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
            $mgParams = @{ Scopes = @('Group.Read.All','User.Read.All'); NoWelcome = $true }
            if ($GraphEnvironment -ne 'Global') { $mgParams['Environment'] = $GraphEnvironment; Warn "Using Graph environment '$GraphEnvironment' (verify for your cloud)." }
            Connect-MgGraph @mgParams
            $esc = $ControlledDataGroup.Replace("'","''")
            $grp = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter=displayName eq '{0}'&`$select=id,displayName" -f $esc)).value
            if (-not $grp) { Warn "Group '$ControlledDataGroup' not found — confirm the exact display name." }
            else {
                $gid = $grp[0].id
                $members = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups/{0}/members?`$select=userPrincipalName,displayName&`$top=999" -f $gid)).value
                Ok ("Controlled-data group '{0}' resolves — {1} member(s)." -f $ControlledDataGroup, @($members).Count)
                $members | Select-Object -First 10 | ForEach-Object { Write-Host ("   in-scope: {0}" -f $_.userPrincipalName) }
                if (@($members).Count -gt 10) { Write-Host ("   ... and {0} more" -f (@($members).Count - 10)) }
                Warn "This is the population your labels/DLP/retention/audit controls should target. Scope + classification are compliance/security's determination."
            }
        } catch { Warn "Graph population check failed: $($_.Exception.Message)" }
    }
}

Write-Section "Summary"
Write-Host "Use the resolved population + onboarded devices + duty separation to define 'Gov Pilot – Controlled Data – Stage1' before configuring anything." -ForegroundColor White
