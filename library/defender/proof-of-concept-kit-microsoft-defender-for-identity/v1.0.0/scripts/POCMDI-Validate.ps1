<#
.SYNOPSIS
    POCMDI-Validate.ps1 — demo/validate that the benign identity test signal produced real MDI detections. Read-only.
.DESCRIPTION
    PURPOSE
        Read-only validation and live-demo helper for the MDI proof of concept. Using the
        Microsoft 365 Defender advanced-hunting API (via Microsoft Graph Security), it confirms
        the benign test signal surfaced as:
          - AlertInfo               — a reconnaissance / honeytoken alert reached the portal
          - IdentityQueryEvents     — the enumeration was observed
          - IdentityDirectoryEvents — directory activity on the identity timeline
          - IdentityLogonEvents     — logon/authentication context
        It also points to the identity timeline / UEBA views for the demo. Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\POCMDI-Validate.ps1
        Requires Microsoft.Graph.Authentication and ThreatHunting.Read.All consent.
    EXPECTED RESULTS
        A pass/fail line per capability, plus portal paths for the identity timeline / UEBA demo.
.NOTES
    White-label. Read-only. Advanced-hunting queries only read telemetry; they change nothing.
#>
[CmdletBinding()]
param(
    [int]$LookbackHours = 6
)

foreach ($m in 'Microsoft.Graph.Authentication') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'ThreatHunting.Read.All' -NoWelcome | Out-Null }

function Invoke-Hunt([string]$Query) {
    $body = @{ Query = $Query } | ConvertTo-Json
    return Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body $body -ContentType 'application/json'
}
function Cnt($resp) { if ($resp.results -and $resp.results.Count -gt 0) { return [int]$resp.results[0].Cnt } return 0 }

Write-Host "`n=== POCMDI validation — benign-signal detections (read-only) ===" -ForegroundColor Cyan

$checks = @(
    @{ Name = 'Recon/honeytoken alert (AlertInfo)'; Kql = @"
AlertInfo
| where Timestamp > ago(${LookbackHours}h)
| where ServiceSource has 'Identity' or Category has_any('Reconnaissance','InitialAccess','CredentialAccess') or Title has_any('reconnaissance','honeytoken','enumeration')
| summarize Cnt = count()
"@ },
    @{ Name = 'Enumeration observed (IdentityQueryEvents)'; Kql = @"
IdentityQueryEvents
| where Timestamp > ago(${LookbackHours}h)
| summarize Cnt = count()
"@ },
    @{ Name = 'Directory activity (IdentityDirectoryEvents)'; Kql = @"
IdentityDirectoryEvents
| where Timestamp > ago(${LookbackHours}h)
| summarize Cnt = count()
"@ },
    @{ Name = 'Logon context (IdentityLogonEvents)'; Kql = @"
IdentityLogonEvents
| where Timestamp > ago(${LookbackHours}h)
| summarize Cnt = count()
"@ }
)

$pass = 0
foreach ($c in $checks) {
    try {
        $n = Cnt (Invoke-Hunt $c.Kql)
        if ($n -gt 0) { Write-Host ("  PASS — {0} ({1} row[s])" -f $c.Name, $n) -ForegroundColor Green; $pass++ }
        else { Write-Host ("  FAIL — {0}: no rows yet (allow warm-up, confirm sensor health)." -f $c.Name) -ForegroundColor Yellow }
    } catch {
        Write-Host ("  ERROR — {0}: {1}" -f $c.Name, $_.Exception.Message) -ForegroundColor Yellow
    }
}

Write-Host "`n[Demo the headline capabilities in the portal]" -ForegroundColor Cyan
Write-Host "  Incident story  : security.microsoft.com -> Incidents & alerts -> the recon/honeytoken incident." -ForegroundColor Gray
Write-Host "  Identity timeline: Assets -> Identities -> the tested identity -> Timeline." -ForegroundColor Gray
Write-Host "  UEBA / priority : the identity page -> investigation priority / UEBA insights." -ForegroundColor Gray

Write-Host ("`nSummary: {0}/{1} capability checks passing." -f $pass, $checks.Count) -ForegroundColor Cyan
Write-Host "Next: POCMDI-Scorecard.ps1" -ForegroundColor Cyan
