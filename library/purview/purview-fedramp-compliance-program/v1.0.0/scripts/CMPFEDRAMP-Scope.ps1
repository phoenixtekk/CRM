<#
.SYNOPSIS
    CMPFEDRAMP-Scope.ps1 — controlled-data scope + connection/role health helper (read-only).
.DESCRIPTION
    PURPOSE
        Enumerates the intended in-scope population and confirms toolchain health with no changes:
        members of the controlled-data-owners group, the mailboxes/sites in scope, the compliance role
        groups it can see (for least-privilege review), and which endpoints (S&C PowerShell / Graph) are
        reachable. Use before configuring so the pilot scope is grounded in real objects. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CMPFEDRAMP-Scope.ps1 -ControlledDataGroup "Controlled Data Owners"
        Requires ExchangeOnlineManagement (Connect-IPPSSession) and, for group membership, Microsoft.Graph
        with delegated Group.Read.All / User.Read.All. Interactive modern-auth / MFA admin; no secrets.
    EXPECTED RESULTS
        A scope summary: group member count, sample in-scope mailboxes, visible role groups, and endpoint
        reachability. PASS = the controlled-data-owners group resolves and both endpoints are reachable;
        FAIL = group not found or an endpoint unreachable (resolve before configuring).
.NOTES
    Purview category — FedRAMP Compliance Program. Read-only. In-scope controlled data and baseline are
    security/compliance determinations; this only enumerates what you name. Confirm cmdlet/role names
    against your tenant.
#>
[CmdletBinding()]
param(
    [string]$ControlledDataGroup,        # display name of the group of controlled-data owners (optional)
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

# --- Visible role groups (least-privilege review) ---
if ($ippsOk) {
    Write-Section "Compliance role groups (least-privilege)"
    try {
        $rg = Get-RoleGroup -ErrorAction Stop | Where-Object { $_.Name -match 'Compliance|Records|Retention|Audit|Information Protection|DLP|Data Loss' }
        if ($rg) {
            $rg | Select-Object Name, @{n='Members';e={ @($_.Members).Count }} | Format-Table -AutoSize | Out-String | Write-Host
            Warn "Confirm Information Protection / DLP / Audit / Records roles are distinct and least-privilege (Global Admin reserved for one-time enablement)."
        } else { Warn "No matching compliance role groups visible (check permissions)." }
    } catch { Warn "Could not enumerate role groups (Get-RoleGroup): $($_.Exception.Message)" }
}

# --- Controlled-data population + in-scope mailboxes (Graph) ---
if (-not $SkipGraph) {
    Write-Section "Controlled-data population (Microsoft Graph)"
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Warn "Microsoft.Graph not installed — skipping population. Install-Module Microsoft.Graph -Scope CurrentUser (or -SkipGraph)."
    } elseif (-not $ControlledDataGroup) {
        Warn "No -ControlledDataGroup supplied — provide the controlled-data-owners group display name to enumerate scope."
    } else {
        try {
            Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
            Connect-MgGraph -Scopes 'Group.Read.All','User.Read.All' -NoWelcome
            $esc = $ControlledDataGroup.Replace("'","''")
            $grp = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter=displayName eq '{0}'&`$select=id,displayName" -f $esc)).value
            if (-not $grp) { Warn "Group '$ControlledDataGroup' not found — confirm the exact display name." }
            else {
                $gid = $grp[0].id
                $members = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups/{0}/members?`$select=userPrincipalName,displayName&`$top=999" -f $gid)).value
                Ok ("Controlled-data group '{0}' resolves — {1} member(s)." -f $ControlledDataGroup, @($members).Count)
                $members | Select-Object -First 10 | ForEach-Object { Write-Host ("   in-scope: {0}" -f $_.userPrincipalName) }
                if (@($members).Count -gt 10) { Write-Host ("   ... and {0} more" -f (@($members).Count - 10)) }
                Warn "This is the population your labels/DLP/retention/audit-evidence controls should target. Scope and baseline are security/compliance's determination."
            }
        } catch { Warn "Graph population check failed: $($_.Exception.Message)" }
    }
}

Write-Section "Summary"
Write-Host "Use the resolved population + role review to define 'FedRAMP Pilot – Controlled Data – Stage1' before configuring anything." -ForegroundColor White
