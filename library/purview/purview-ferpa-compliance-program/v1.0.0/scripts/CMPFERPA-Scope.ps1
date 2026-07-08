<#
.SYNOPSIS
    CMPFERPA-Scope.ps1 — education-record scope + connection/role health helper (read-only).
.DESCRIPTION
    PURPOSE
        Enumerates the intended in-scope education-record locations and confirms toolchain health with
        no changes: the in-scope mailboxes/sites where student records live, onboarded devices (for
        Endpoint DLP), the compliance role groups it can see (for least-privilege review), and which
        endpoints (S&C PowerShell / Graph) are reachable. Use before configuring so the pilot scope is
        grounded in real objects. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CMPFERPA-Scope.ps1 -RecordsSitesGroup "Registrar Sites"
        Requires ExchangeOnlineManagement (Connect-IPPSSession) and, for group membership, Microsoft.Graph
        with delegated Group.Read.All / User.Read.All. Interactive modern-auth / MFA admin; no secrets.
    EXPECTED RESULTS
        A scope summary: resolved in-scope population/locations, sample mailboxes, visible role groups,
        and endpoint reachability. PASS = the in-scope group/locations resolve and both endpoints are
        reachable; FAIL = group not found or an endpoint unreachable (resolve before configuring).
.NOTES
    Purview category — FERPA Compliance Program. Read-only. In-scope education-record data is a
    compliance/registrar determination; this only enumerates what you name. Confirm cmdlet/role names
    against your tenant.
#>
[CmdletBinding()]
param(
    [string]$RecordsSitesGroup,          # display name of a group of in-scope users / record owners (optional)
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
    Write-Section "Compliance role groups (least-privilege review)"
    try {
        $rg = Get-RoleGroup -ErrorAction Stop | Where-Object { $_.Name -match 'Compliance|Records|Retention|Audit|Information Protection|Data Loss|DLP' }
        if ($rg) {
            $rg | Select-Object Name, @{n='Members';e={ @($_.Members).Count }} | Format-Table -AutoSize | Out-String | Write-Host
            Warn "Confirm each control domain (labels / DLP / retention / audit) uses a distinct least-privilege role group; access to student-record controls is itself sensitive."
        } else { Warn "No matching compliance role groups visible (check permissions)." }
    } catch { Warn "Could not enumerate role groups (Get-RoleGroup): $($_.Exception.Message)" }

    # --- Endpoint DLP device onboarding (informational) ---
    Write-Section "Endpoint DLP device onboarding (informational)"
    Warn "If Endpoint DLP is in scope, confirm devices are onboarded to Purview (Settings → Device onboarding in the portal). Endpoint DLP requires E5/E5 Compliance and onboarded devices — verify for your tenant."
}

# --- In-scope population + mailboxes (Graph) ---
if (-not $SkipGraph) {
    Write-Section "In-scope population (Microsoft Graph)"
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Warn "Microsoft.Graph not installed — skipping population. Install-Module Microsoft.Graph -Scope CurrentUser (or -SkipGraph)."
    } elseif (-not $RecordsSitesGroup) {
        Warn "No -RecordsSitesGroup supplied — provide an in-scope group display name (e.g. registrar/record owners) to enumerate scope."
    } else {
        try {
            Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
            Connect-MgGraph -Scopes 'Group.Read.All','User.Read.All' -NoWelcome
            $esc = $RecordsSitesGroup.Replace("'","''")
            $grp = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter=displayName eq '{0}'&`$select=id,displayName" -f $esc)).value
            if (-not $grp) { Warn "Group '$RecordsSitesGroup' not found — confirm the exact display name." }
            else {
                $gid = $grp[0].id
                $members = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups/{0}/members?`$select=userPrincipalName,displayName&`$top=999" -f $gid)).value
                Ok ("In-scope group '{0}' resolves — {1} member(s)." -f $RecordsSitesGroup, @($members).Count)
                $members | Select-Object -First 10 | ForEach-Object { Write-Host ("   in-scope: {0}" -f $_.userPrincipalName) }
                if (@($members).Count -gt 10) { Write-Host ("   ... and {0} more" -f (@($members).Count - 10)) }
                Warn "This is the population your label/DLP/retention/audit controls should target. Education-record scope is compliance/registrar's determination."
            }
        } catch { Warn "Graph population check failed: $($_.Exception.Message)" }
    }
}

Write-Section "Summary"
Write-Host "Use the resolved population + locations + role separation to define 'FERPA Pilot – Education Records – Stage1' before configuring anything." -ForegroundColor White
