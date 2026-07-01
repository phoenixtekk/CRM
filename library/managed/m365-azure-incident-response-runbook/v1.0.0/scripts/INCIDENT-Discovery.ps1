<#
.SYNOPSIS
    INCIDENT-Discovery.ps1 - Read-only live incident snapshot across Microsoft 365 + Azure.

    PURPOSE:
        Seeds the Diagnose phase of an incident by pulling, in one pass:
          - Current Microsoft 365 Service Health issues (admin center) and Azure Service Health events.
          - Recent high-severity / failed sign-ins and (if Entra ID P2) risk detections from Entra.
          - An Azure Resource Health snapshot for in-scope subscriptions.
        Output is a single CSV the Incident Lead can attach to the Incident Record and, if escalating,
        to a Microsoft support case. No changes are made to any tenant - strictly read-only.

    HOW TO RUN:
        1. Install modules (run once):
             Install-Module Microsoft.Graph, Az -Scope CurrentUser
        2. Run during (or to baseline before) an incident:
             .\INCIDENT-Discovery.ps1 -OutputCsv ".\Incident Snapshot - Estate - Detect.csv" `
                                      -SignInLookbackHours 6
        3. Sign in interactively when prompted (a Global Reader / Security Reader / Monitoring Reader
           account is sufficient).

    EXPECTED RESULTS:
        A CSV "Incident Snapshot - Estate - Detect.csv" with one row per finding
        (Source, Category, Severity, Name/Identity, Status, Detail, Observed) plus a console summary.
        Read-only: performs no changes.

.NOTES
    Managed - read-only.
#>

[CmdletBinding()]
param(
    [string]$OutputCsv = ".\Incident Snapshot - Estate - Detect.csv",
    [int]$SignInLookbackHours = 6,
    [switch]$SkipM365,
    [switch]$SkipAzure
)

$ErrorActionPreference = 'Stop'
$findings = New-Object System.Collections.Generic.List[object]

function Add-Finding {
    param($Source, $Category, $Severity = '', $Name = '', $Status = '', $Detail = '')
    $findings.Add([pscustomobject]@{
        Source   = $Source
        Category = $Category
        Severity = $Severity
        Name     = $Name
        Status   = $Status
        Detail   = $Detail
        Observed = (Get-Date).ToString('s')
    })
}

if (-not $SkipM365) {
    Write-Host "=== Microsoft 365 Service Health + Entra sign-in/risk ===" -ForegroundColor Cyan
    try {
        Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
        Connect-MgGraph -Scopes "ServiceHealth.Read.All","AuditLog.Read.All","IdentityRiskEvent.Read.All" -NoWelcome

        # --- M365 Service Health: active service issues ---
        Write-Host "Reading Microsoft 365 Service health..."
        try {
            $issues = Invoke-MgGraphRequest -Method GET `
                -Uri "https://graph.microsoft.com/v1.0/admin/serviceAnnouncement/issues?`$filter=isResolved eq false"
            foreach ($i in $issues.value) {
                Add-Finding 'M365 Service Health' 'ServiceIssue' $i.classification `
                            $i.title $i.status ("Service={0}; Id={1}" -f $i.service, $i.id)
            }
        } catch { Add-Finding 'M365 Service Health' 'ServiceIssue' 'error' '' 'error' $_.Exception.Message }

        # --- Entra: recent failed / high-risk sign-ins ---
        Write-Host "Reading recent failed sign-ins (last $SignInLookbackHours h)..."
        $since = (Get-Date).ToUniversalTime().AddHours(-$SignInLookbackHours).ToString('o')
        try {
            $uri = "https://graph.microsoft.com/v1.0/auditLogs/signIns?`$filter=createdDateTime ge $since and status/errorCode ne 0&`$top=200"
            $signins = Invoke-MgGraphRequest -Method GET -Uri $uri
            foreach ($s in $signins.value) {
                Add-Finding 'Entra Sign-in' 'FailedSignIn' $s.riskLevelDuringSignIn `
                            $s.userPrincipalName ("err {0}" -f $s.status.errorCode) `
                            ("App={0}; CA={1}; Reason={2}" -f $s.appDisplayName, $s.conditionalAccessStatus, $s.status.failureReason)
            }
        } catch { Add-Finding 'Entra Sign-in' 'FailedSignIn' 'error' '' 'error' $_.Exception.Message }

        # --- Entra: risk detections (requires Entra ID P2) ---
        Write-Host "Reading recent risk detections (Entra ID P2)..."
        try {
            $uri = "https://graph.microsoft.com/v1.0/identityProtection/riskDetections?`$filter=detectedDateTime ge $since&`$top=200"
            $risks = Invoke-MgGraphRequest -Method GET -Uri $uri
            foreach ($r in $risks.value) {
                Add-Finding 'Entra Identity Protection' 'RiskDetection' $r.riskLevel `
                            $r.userPrincipalName $r.riskState `
                            ("Type={0}; Activity={1}" -f $r.riskEventType, $r.activity)
            }
        } catch {
            Add-Finding 'Entra Identity Protection' 'RiskDetection' 'n/a' '' 'unavailable' `
                        'Risk detections need Entra ID P2 / sufficient role.'
        }
    }
    catch { Add-Finding 'Microsoft Graph' 'Connection' 'error' '' 'error' $_.Exception.Message }
    finally { try { Disconnect-MgGraph | Out-Null } catch {} }
}

if (-not $SkipAzure) {
    Write-Host "=== Azure Service Health + Resource Health ===" -ForegroundColor Cyan
    try {
        Import-Module Az.Accounts, Az.ResourceGraph -ErrorAction Stop
        Connect-AzAccount | Out-Null

        foreach ($sub in Get-AzSubscription) {
            Set-AzContext -SubscriptionId $sub.Id | Out-Null

            # --- Azure Service Health: active service issues ---
            Write-Host ("Reading Service Health events for '{0}'..." -f $sub.Name)
            try {
                $events = Get-AzResource -ResourceType 'Microsoft.ResourceHealth/events' -ApiVersion '2022-10-01' -ErrorAction SilentlyContinue
                foreach ($e in $events) {
                    Add-Finding 'Azure Service Health' 'ServiceIssue' $e.Properties.eventLevel `
                                $e.Properties.title $e.Properties.status ("Sub={0}" -f $sub.Name)
                }
            } catch { Add-Finding 'Azure Service Health' 'ServiceIssue' 'info' '' 'note' 'No active events or insufficient access.' }

            # --- Resource Health: non-Available resources (via Resource Graph) ---
            Write-Host ("Reading Resource Health snapshot for '{0}'..." -f $sub.Name)
            try {
                $q = "healthresources | where type =~ 'microsoft.resourcehealth/availabilitystatuses' " +
                     "| extend rid = tostring(properties.targetResourceId), avail = tostring(properties.availabilityState) " +
                     "| where avail != 'Available' | project rid, avail"
                $rh = Search-AzGraph -Query $q -Subscription $sub.Id -ErrorAction SilentlyContinue
                foreach ($row in $rh) {
                    Add-Finding 'Azure Resource Health' 'ResourceHealth' 'high' $row.rid $row.avail ("Sub={0}" -f $sub.Name)
                }
            } catch { Add-Finding 'Azure Resource Health' 'ResourceHealth' 'info' '' 'note' $_.Exception.Message }
        }
    }
    catch { Add-Finding 'Azure' 'Connection' 'error' '' 'error' $_.Exception.Message }
}

# --- Export + summary ---
$findings | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
Write-Host ("`nExported {0} findings to {1}" -f $findings.Count, $OutputCsv) -ForegroundColor Green
Write-Host "`n=== Summary by source ===" -ForegroundColor Cyan
$findings | Group-Object Source | ForEach-Object {
    Write-Host ("  {0,-28} Count={1}" -f $_.Name, $_.Count)
}
