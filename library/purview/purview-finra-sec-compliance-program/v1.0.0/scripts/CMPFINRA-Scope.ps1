<#
.SYNOPSIS
    CMPFINRA-Scope.ps1 — covered-persons scope + connection/role health helper (read-only).
.DESCRIPTION
    PURPOSE
        Enumerates the intended in-scope population and confirms toolchain health with no changes:
        members of the covered-persons group, the mailboxes/sites in scope, the compliance role groups
        it can see (for reviewer-separation review), and which endpoints (S&C PowerShell / Graph) are
        reachable. Use before configuring so the pilot scope is grounded in real objects. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CMPFINRA-Scope.ps1 -CoveredPersonsGroup "Registered Persons"
        Requires ExchangeOnlineManagement (Connect-IPPSSession) and, for group membership, Microsoft.Graph
        with delegated Group.Read.All / User.Read.All. Interactive modern-auth / MFA admin; no secrets.
    EXPECTED RESULTS
        A scope summary: group member count, sample in-scope mailboxes, visible role groups, and endpoint
        reachability. PASS = the covered-persons group resolves and both endpoints are reachable;
        FAIL = group not found or an endpoint unreachable (resolve before configuring).
.NOTES
    Purview category — FINRA/SEC Compliance Program. Read-only. In-scope population is a compliance
    determination; this only enumerates what you name. Confirm cmdlet/role names against your tenant.
#>
[CmdletBinding()]
param(
    [string]$CoveredPersonsGroup,        # display name of the group of covered/registered persons (optional)
    [string]$UserPrincipalName,
    [switch]$SkipGraph
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Ok($m){ Write-Host $m -ForegroundColor Green }
function Warn($m){ Write-Host $m -ForegroundColor Yellow }

# --- Endpoint health: Security & Compliance PowerShell ---
Write-Section "Endpoint health"
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Warn "ExchangeOnlineManagement not installed. Install-Module ExchangeOnlineManagement -Scope CurrentUser"; return
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
$connectParams = @{}
if ($UserPrincipalName) { $connectParams['UserPrincipalName'] = $UserPrincipalName }
$ippsOk = $false
try { Connect-IPPSSession @connectParams -ErrorAction Stop | Out-Null; $ippsOk = $true; Ok "Security & Compliance PowerShell (Connect-IPPSSession) : reachable" }
catch { Warn "Connect-IPPSSession failed: $($_.Exception.Message)" }

# --- Visible role groups (for reviewer-separation review) ---
if ($ippsOk) {
    Write-Section "Compliance role groups (reviewer separation)"
    try {
        $rg = Get-RoleGroup -ErrorAction Stop | Where-Object { $_.Name -match 'Compliance|Records|Retention|Audit|Communication|Insider|Supervisory|Reviewer' }
        if ($rg) {
            $rg | Select-Object Name, @{n='Members';e={ @($_.Members).Count }} | Format-Table -AutoSize | Out-String | Write-Host
            Warn "Confirm Communication Compliance reviewers are SEPARATE from the configuring admin (privacy/role separation)."
        } else { Warn "No matching compliance role groups visible (check permissions)." }
    } catch { Warn "Could not enumerate role groups (Get-RoleGroup): $($_.Exception.Message)" }
}

# --- Covered-persons population + in-scope mailboxes (Graph) ---
if (-not $SkipGraph) {
    Write-Section "Covered-persons population (Microsoft Graph)"
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Warn "Microsoft.Graph not installed — skipping population. Install-Module Microsoft.Graph -Scope CurrentUser (or -SkipGraph)."
    } elseif (-not $CoveredPersonsGroup) {
        Warn "No -CoveredPersonsGroup supplied — provide the covered/registered-persons group display name to enumerate scope."
    } else {
        try {
            Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
            Connect-MgGraph -Scopes 'Group.Read.All','User.Read.All' -NoWelcome
            $esc = $CoveredPersonsGroup.Replace("'","''")
            $grp = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter=displayName eq '{0}'&`$select=id,displayName" -f $esc)).value
            if (-not $grp) { Warn "Group '$CoveredPersonsGroup' not found — confirm the exact display name." }
            else {
                $gid = $grp[0].id
                $members = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups/{0}/members?`$select=userPrincipalName,displayName&`$top=999" -f $gid)).value
                Ok ("Covered-persons group '{0}' resolves — {1} member(s)." -f $CoveredPersonsGroup, @($members).Count)
                $members | Select-Object -First 10 | ForEach-Object { Write-Host ("   in-scope: {0}" -f $_.userPrincipalName) }
                if (@($members).Count -gt 10) { Write-Host ("   ... and {0} more" -f (@($members).Count - 10)) }
                Warn "This is the population your labels/supervision/audit-evidence controls should target. Scope is compliance's determination."
            }
        } catch { Warn "Graph population check failed: $($_.Exception.Message)" }
    }
}

Write-Section "Summary"
Write-Host "Use the resolved population + role separation to define 'FINRA/SEC Pilot – Registered Persons – Stage1' before configuring anything." -ForegroundColor White
