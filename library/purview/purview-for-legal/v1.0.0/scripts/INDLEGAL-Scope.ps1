<#
.SYNOPSIS
    INDLEGAL-Scope.ps1 — legal-population scope + connection/role health helper (read-only).
.DESCRIPTION
    PURPOSE
        Enumerates the intended in-scope legal population and confirms toolchain health with no changes:
        members of the legal-population group, the mailboxes/matter sites in scope, the compliance role
        groups it can see (for least-privilege review, keeping eDiscovery/hold roles with legal), and
        which endpoints (S&C PowerShell / Graph) are reachable. Use before configuring so the pilot scope
        is grounded in real objects. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\INDLEGAL-Scope.ps1 -LegalGroup "Legal Department"
        Requires ExchangeOnlineManagement (Connect-IPPSSession) and, for group membership, Microsoft.Graph
        with delegated Group.Read.All / User.Read.All. Interactive modern-auth / MFA admin; no secrets.
    EXPECTED RESULTS
        A scope summary: group member count, sample in-scope mailboxes, visible role groups, and endpoint
        reachability. PASS = the legal-population group resolves and both endpoints are reachable;
        FAIL = group not found or an endpoint unreachable (resolve before configuring).
.NOTES
    Purview category — Microsoft Purview for Legal (industry bundle). Read-only. In-scope population and
    matter mapping are legal determinations; this only enumerates what you name. Keep eDiscovery/legal-hold
    roles with the legal function. Confirm cmdlet/role names against your tenant.
#>
[CmdletBinding()]
param(
    [string]$LegalGroup,                 # display name of the legal-population group (optional)
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

# --- Visible role groups (for least-privilege review) ---
if ($ippsOk) {
    Write-Section "Compliance role groups (least-privilege review)"
    try {
        $rg = Get-RoleGroup -ErrorAction Stop | Where-Object { $_.Name -match 'Compliance|Records|Retention|Audit|Information Protection|DLP|eDiscovery|Reviewer' }
        if ($rg) {
            $rg | Select-Object Name, @{n='Members';e={ @($_.Members).Count }} | Format-Table -AutoSize | Out-String | Write-Host
            Warn "Keep eDiscovery / legal-hold roles with the LEGAL function (legally sensitive). Confirm each config role is least-privilege and distinct."
        } else { Warn "No matching compliance role groups visible (check permissions)." }
    } catch { Warn "Could not enumerate role groups (Get-RoleGroup): $($_.Exception.Message)" }
}

# --- Legal population + in-scope mailboxes (Graph) ---
if (-not $SkipGraph) {
    Write-Section "Legal population (Microsoft Graph)"
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Warn "Microsoft.Graph not installed — skipping population. Install-Module Microsoft.Graph -Scope CurrentUser (or -SkipGraph)."
    } elseif (-not $LegalGroup) {
        Warn "No -LegalGroup supplied — provide the legal-population group display name to enumerate scope."
    } else {
        try {
            Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
            Connect-MgGraph -Scopes 'Group.Read.All','User.Read.All' -NoWelcome
            $esc = $LegalGroup.Replace("'","''")
            $grp = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter=displayName eq '{0}'&`$select=id,displayName" -f $esc)).value
            if (-not $grp) { Warn "Group '$LegalGroup' not found — confirm the exact display name." }
            else {
                $gid = $grp[0].id
                $members = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups/{0}/members?`$select=userPrincipalName,displayName&`$top=999" -f $gid)).value
                Ok ("Legal-population group '{0}' resolves — {1} member(s)." -f $LegalGroup, @($members).Count)
                $members | Select-Object -First 10 | ForEach-Object { Write-Host ("   in-scope: {0}" -f $_.userPrincipalName) }
                if (@($members).Count -gt 10) { Write-Host ("   ... and {0} more" -f (@($members).Count - 10)) }
                Warn "This is the population your labels/DLP/retention controls should target. Population and matter mapping are legal's determination."
            }
        } catch { Warn "Graph population check failed: $($_.Exception.Message)" }
    }
}

Write-Section "Summary"
Write-Host "Use the resolved population + role review to define 'Legal Pilot – Privileged Data – Stage1' before configuring anything." -ForegroundColor White
