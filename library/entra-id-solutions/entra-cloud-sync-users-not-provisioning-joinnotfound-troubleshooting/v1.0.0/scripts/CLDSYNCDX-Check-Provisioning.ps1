<#
.SYNOPSIS
    CLDSYNCDX-Check-Provisioning.ps1 — cloud sync job / service-principal / org health check (read-only).
.DESCRIPTION
    PURPOSE
        Read-only Microsoft Graph check of the tenant-side state behind "nothing is provisioning".
        Reports: the cloud sync SYNCHRONIZATION JOB and whether it is Active / Enabled / QUARANTINED
        (with the quarantine reason and escrow/series count); whether the "Microsoft Entra AD
        Synchronization Service" service principal EXISTS; and the org's onPremisesSyncEnabled flag. It
        flags the AzureDirectoryServiceAuthorizationFailed symptom (missing sync SP) and the
        object-deletion-threshold symptom. Makes NO changes (never restarts or clears quarantine).
    HOW TO RUN
        powershell -File .\CLDSYNCDX-Check-Provisioning.ps1
        powershell -File .\CLDSYNCDX-Check-Provisioning.ps1 -ServicePrincipalId <cloud-sync-sp-object-id>
        Required Microsoft Graph scopes (delegated, read-only):
            Synchronization.Read.All
            Directory.Read.All
    EXPECTED RESULTS
        The job status (Active/Paused/Quarantine), quarantine reason if any, the sync-service SP
        present/absent verdict, and onPremisesSyncEnabled. Quarantine / missing SP / disabled sync point
        you at the matching remedy in 03-implementation.md (Phase 3) and 06-troubleshooting.md.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph. Cloud sync service internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [string] $ServicePrincipalId,
    [string] $SyncServiceSpName = 'Microsoft Entra AD Synchronization Service'
)

$ErrorActionPreference = 'Stop'

function Connect-Graph {
    if (-not (Get-Module Microsoft.Graph.Authentication -ListAvailable)) {
        throw "Microsoft Graph PowerShell SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $scopes = @('Synchronization.Read.All', 'Directory.Read.All')
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

function Try-Graph { param([string] $Uri) try { return @(Invoke-Graph $Uri) } catch { return @() } }

Connect-Graph
$base = 'https://graph.microsoft.com/v1.0'

# --- 1. Locate the cloud sync synchronization job -----------------------------
Write-Host "`n=== Cloud Sync — Job / SP / Org Health ===" -ForegroundColor Cyan
Write-Host "`n-- Synchronization job --" -ForegroundColor Cyan

$jobs = @()
if ($ServicePrincipalId) {
    $spList = @([pscustomobject]@{ id = $ServicePrincipalId; displayName = "(supplied SP $ServicePrincipalId)" })
} else {
    # Cloud sync configurations are represented by service principals that host a synchronization job.
    # Probing every SP is expensive, so we narrow to likely provisioning apps by display name, then probe.
    Write-Host "No -ServicePrincipalId supplied; searching likely cloud sync service principals (pass -ServicePrincipalId to target directly)..."
    $allSps = Try-Graph "$base/servicePrincipals?`$select=id,displayName,appId&`$top=999"
    $spList = @($allSps | Where-Object {
        $_.displayName -match 'provision|cloud sync|Active Directory to Microsoft Entra|AD to (Azure|Entra)|AAD Connect'
    })
    if (-not $spList.Count) { $spList = $allSps }  # fall back to probing all if none matched
}

$found = $false
foreach ($sp in $spList) {
    $spJobs = Try-Graph "$base/servicePrincipals/$($sp.id)/synchronization/jobs"
    foreach ($j in $spJobs) {
        # Cloud sync (AD to Entra) jobs carry an AD2AAD-style template id.
        if ($ServicePrincipalId -or ($j.templateId -match 'AD2AAD|ADToAAD|Provision')) {
            $found = $true
            $jobs += [pscustomobject]@{ Sp = $sp.displayName; SpId = $sp.id; Job = $j }
        }
    }
    if ($found -and -not $ServicePrincipalId -and $jobs.Count -ge 1) { break }
}

if (-not $jobs.Count) {
    Write-Host "No cloud sync synchronization job located." -ForegroundColor Yellow
    Write-Host "  - Confirm a cloud sync configuration exists under Entra Connect > Cloud sync, and Synchronization.Read.All is consented." -ForegroundColor Yellow
    Write-Host "  - Pass -ServicePrincipalId <object-id of the cloud sync app service principal> to target it directly." -ForegroundColor Yellow
} else {
    foreach ($row in $jobs) {
        $j = $row.Job
        $code = "$($j.status.code)"
        $codeColor = switch ($code) { 'Active' { 'Green' } 'Paused' { 'Yellow' } 'Quarantine' { 'Red' } default { 'Gray' } }
        Write-Host ("`n  Service principal : {0}  [{1}]" -f $row.Sp, $row.SpId)
        Write-Host ("  Job id            : {0}" -f $j.id)
        Write-Host ("  Template          : {0}" -f $j.templateId)
        Write-Host ("  Schedule state    : {0}" -f $j.schedule.state)
        Write-Host ("  Status code       : {0}" -f $code) -ForegroundColor $codeColor
        if ($j.status.quarantine) {
            $q = $j.status.quarantine
            Write-Host ("  QUARANTINED       : reason = {0}; since = {1}; seriesCount = {2}" -f $q.reason, $q.currentBegan, $q.seriesCount) -ForegroundColor Red
            Write-Host "    -> Fix the underlying auth failure, then Clear quarantine / Restart the job (see 03-implementation.md Phase 3)." -ForegroundColor Yellow
        }
        # Escrow / error signal from the last execution.
        $le = $j.status.lastExecution
        if ($le) {
            Write-Host ("  Last execution    : state = {0}; error = {1}" -f $le.state, $le.error.code)
            if ("$($le.error.code)" -match 'AzureDirectoryServiceAuthorizationFailed') {
                Write-Host "    -> AzureDirectoryServiceAuthorizationFailed: the sync-service SP is likely missing (see below)." -ForegroundColor Red
            }
            if ("$($le.error.code)" -match 'Delet|Threshold') {
                Write-Host "    -> Possible object-deletion threshold block (Connect + cloud sync coexistence) — see 06-troubleshooting.md." -ForegroundColor Yellow
            }
        }
    }
}

# --- 2. "Microsoft Entra AD Synchronization Service" service principal ---------
Write-Host "`n-- Sync-service service principal --" -ForegroundColor Cyan
$sn = $SyncServiceSpName.Replace("'", "''")
$syncSp = Try-Graph "$base/servicePrincipals?`$filter=displayName eq '$sn'&`$select=id,displayName,appId,accountEnabled"
if (-not $syncSp.Count) {
    # older tenants may name it "Azure AD Synchronization Service"
    $syncSp = Try-Graph "$base/servicePrincipals?`$filter=displayName eq 'Azure AD Synchronization Service'&`$select=id,displayName,appId,accountEnabled"
}
if ($syncSp.Count) {
    Write-Host ("  PRESENT: {0} (appId {1}; enabled {2})" -f $syncSp[0].displayName, $syncSp[0].appId, $syncSp[0].accountEnabled) -ForegroundColor Green
} else {
    Write-Host ("  MISSING: no '{0}' service principal found." -f $SyncServiceSpName) -ForegroundColor Red
    Write-Host "    -> AzureDirectoryServiceAuthorizationFailed symptom. Re-enable sync to recreate it:" -ForegroundColor Yellow
    Write-Host "       PATCH /organization/<tenantId> { onPremisesSyncEnabled: true }  (see 03-implementation.md Phase 3)." -ForegroundColor Yellow
}

# --- 3. Org onPremisesSyncEnabled ---------------------------------------------
Write-Host "`n-- Directory sync flag --" -ForegroundColor Cyan
$org = Try-Graph "$base/organization?`$select=id,displayName,onPremisesSyncEnabled"
if ($org.Count) {
    $val = $org[0].onPremisesSyncEnabled
    $c = $(if ($val -eq $true) { 'Green' } else { 'Yellow' })
    Write-Host ("  Tenant           : {0}" -f $org[0].displayName)
    Write-Host ("  onPremisesSyncEnabled : {0}" -f $val) -ForegroundColor $c
    if ($val -ne $true) {
        Write-Host "    -> Directory sync is not enabled at the org level; enabling it recreates the sync-service SP." -ForegroundColor Yellow
    }
} else {
    Write-Host "  Could not read organization (need Directory.Read.All)." -ForegroundColor Yellow
}

Write-Host "`nRead-only: no changes were made (the job was not restarted and quarantine was not cleared)." -ForegroundColor Green
