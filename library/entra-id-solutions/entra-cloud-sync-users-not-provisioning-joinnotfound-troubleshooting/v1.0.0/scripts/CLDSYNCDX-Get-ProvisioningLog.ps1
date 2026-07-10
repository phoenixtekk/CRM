<#
.SYNOPSIS
    CLDSYNCDX-Get-ProvisioningLog.ps1 — read the authoritative cloud sync provisioning-log reason for one object.
.DESCRIPTION
    PURPOSE
        Read-only Microsoft Graph query of the cloud sync PROVISIONING LOGS (auditLogs/provisioning)
        for a single object, given its Active Directory ObjectGuid (preferred — the reliable key) or its
        UPN. Prints the latest entries with the provisioningAction (create/update/delete/other), the
        status (success/skipped/failure), the skipReason (e.g. JoinNotFound), and the per-step detail
        (Import / Determine if in scope / Match user / Determine object action) so the operator sees the
        authoritative reason the object was skipped or created. Makes NO changes.
    HOW TO RUN
        powershell -File .\CLDSYNCDX-Get-ProvisioningLog.ps1 -ObjectGuid 11111111-2222-3333-4444-555555555555
        powershell -File .\CLDSYNCDX-Get-ProvisioningLog.ps1 -UserPrincipalName user@contoso.com
        Required Microsoft Graph scopes (delegated, read-only):
            AuditLog.Read.All
            Directory.Read.All
    EXPECTED RESULTS
        For the object: the most recent provisioning entries with action, status, and skipReason, plus
        each pipeline step's name/status/details. "skipped / JoinNotFound" points you at 06-troubleshooting.md
        (the core symptom); "Create/Update" confirms a fix (see 05-testing.md T8).
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph. Cloud sync service internals deferred to vendor docs.
#>

[CmdletBinding(DefaultParameterSetName = 'ByGuid')]
param(
    [Parameter(ParameterSetName = 'ByGuid', Mandatory = $true)]
    [string] $ObjectGuid,

    [Parameter(ParameterSetName = 'ByUpn', Mandatory = $true)]
    [string] $UserPrincipalName,

    [int] $Top = 10
)

$ErrorActionPreference = 'Stop'

function Connect-Graph {
    if (-not (Get-Module Microsoft.Graph.Authentication -ListAvailable)) {
        throw "Microsoft Graph PowerShell SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $scopes = @('AuditLog.Read.All', 'Directory.Read.All')
    if (-not (Get-MgContext)) { Connect-MgGraph -Scopes $scopes | Out-Null }
    Write-Host "Connected to Microsoft Graph as $((Get-MgContext).Account)" -ForegroundColor Green
}

function Invoke-Graph {
    param([string] $Uri)
    $results = @()
    do {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $Uri
        if ($resp.value) { $results += $resp.value } elseif ($resp) { $results += $resp }
        $Uri = $resp.'@odata.nextLink'
    } while ($Uri)
    return $results
}

Connect-Graph
$base = 'https://graph.microsoft.com/v1.0'

Write-Host "`n=== Cloud Sync — Provisioning Log ===" -ForegroundColor Cyan

# --- Build the query ----------------------------------------------------------
# The provisioning log is searchable by the AD source object id (ObjectGuid). Filtering by UPN is not
# reliably supported server-side, so for -UserPrincipalName we pull recent entries and match locally.
if ($PSCmdlet.ParameterSetName -eq 'ByGuid') {
    $guid = $ObjectGuid.Trim('{','}',' ')
    Write-Host ("Searching provisioning logs for source ObjectGuid: {0}" -f $guid)
    $uri = "$base/auditLogs/provisioning?`$filter=sourceIdentity/id eq '$guid'&`$top=$Top"
    $entries = @(Invoke-Graph $uri)
} else {
    Write-Host ("Searching recent provisioning logs for UPN: {0} (client-side match)" -f $UserPrincipalName)
    $uri = "$base/auditLogs/provisioning?`$top=200"
    $all = @(Invoke-Graph $uri)
    $entries = @($all | Where-Object {
        ($_.sourceIdentity.displayName -like "*$UserPrincipalName*") -or
        ($_.targetIdentity.displayName -like "*$UserPrincipalName*") -or
        ($_.sourceIdentity.id -eq $UserPrincipalName)
    } | Select-Object -First $Top)
}

if (-not $entries -or $entries.Count -eq 0) {
    Write-Host "`nNo provisioning-log entries found for that object." -ForegroundColor Yellow
    Write-Host "  - Confirm the ObjectGuid/UPN is correct and the scopes (AuditLog.Read.All) are consented." -ForegroundColor Yellow
    Write-Host "  - No entry usually means the object was never evaluated (likely OUT OF SCOPE for the scheduled cycle)." -ForegroundColor Yellow
    Write-Host "    Run PROVISION ON DEMAND for the object to force an evaluation, then re-run this tool. See 06-troubleshooting.md." -ForegroundColor Yellow
    return
}

# --- Print each entry ---------------------------------------------------------
$i = 0
foreach ($e in $entries) {
    $i++
    $status  = $e.provisioningStatusInfo.status
    $action  = $e.provisioningAction
    $when    = $e.activityDateTime
    $srcName = $e.sourceIdentity.displayName
    $srcId   = $e.sourceIdentity.id
    $tgtName = $e.targetIdentity.displayName

    Write-Host ("`n--- Entry {0} of {1} ---" -f $i, $entries.Count) -ForegroundColor Cyan
    Write-Host ("  Time         : {0}" -f $when)
    Write-Host ("  Source (AD)  : {0}  [{1}]" -f $srcName, $srcId)
    Write-Host ("  Target       : {0}" -f $(if ($tgtName) { $tgtName } else { '(none created)' }))
    $statusColor = switch ("$status") { 'success' { 'Green' } 'skipped' { 'Yellow' } 'failure' { 'Red' } default { 'Gray' } }
    Write-Host ("  Action       : {0}" -f $action)
    Write-Host ("  Status       : {0}" -f $status) -ForegroundColor $statusColor

    # skipReason / error surface in statusInfo (and inside the steps' details)
    if ($e.provisioningStatusInfo.errorInformation) {
        $err = $e.provisioningStatusInfo.errorInformation
        if ($err.reason)    { Write-Host ("  Reason       : {0}" -f $err.reason) -ForegroundColor Yellow }
        if ($err.errorCode) { Write-Host ("  Error code   : {0}" -f $err.errorCode) -ForegroundColor Yellow }
    }

    # Pipeline steps: Import / Determine if in scope / Match user / Determine object action
    if ($e.steps) {
        Write-Host "  Steps:"
        foreach ($s in $e.steps) {
            Write-Host ("    - {0,-32} [{1}] {2}" -f $s.name, $s.status, $s.provisioningStepType)
            if ($s.details) {
                foreach ($k in $s.details.Keys) {
                    $v = $s.details[$k]
                    if ($v) { Write-Host ("        {0}: {1}" -f $k, $v) -ForegroundColor DarkGray }
                }
            }
        }
    }
}

# --- Summary hint -------------------------------------------------------------
$latest = $entries | Select-Object -First 1
$lStatus = "$($latest.provisioningStatusInfo.status)"
$lReason = "$($latest.provisioningStatusInfo.errorInformation.reason)"
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
if ($lStatus -eq 'skipped') {
    Write-Host ("Latest entry: SKIPPED. Reason text: {0}" -f $(if ($lReason) { $lReason } else { '(see steps above; e.g. JoinNotFound)' })) -ForegroundColor Yellow
    Write-Host "Work the cause in 06-troubleshooting.md (already-exists / out-of-scope / critical object / quarantine)." -ForegroundColor Yellow
} elseif ($lStatus -eq 'success') {
    Write-Host ("Latest entry: SUCCESS (action = {0}). If this followed a fix, confirm the object in Entra ID (05-testing.md T8)." -f $latest.provisioningAction) -ForegroundColor Green
} else {
    Write-Host ("Latest entry status: {0}. Match the reason/error above to 06-troubleshooting.md." -f $lStatus) -ForegroundColor Yellow
}
Write-Host "Read-only: no changes were made." -ForegroundColor Green
