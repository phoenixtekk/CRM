<#
.SYNOPSIS
    ENTAPPMIG-Provisioning.ps1 — report SCIM provisioning status and preview an on-demand provision (gated).
.DESCRIPTION
    PURPOSE
        Supports the SCIM track. Reports, for a provisioned enterprise app (e.g. ENTAPPMIG - App - ScimSaaS
        - Pilot): the synchronization job(s), schedule state, and recent provisioning outcomes so you can
        confirm create/update/deprovision is healthy. With -ProvisionUserId it can trigger an ON-DEMAND
        provision of a single user — but only as a -WhatIf preview unless -Commit is given, so you never
        push a real provisioning action by accident.
    HOW TO RUN
        Report:       .\ENTAPPMIG-Provisioning.ps1 -AppName 'ENTAPPMIG - App - ScimSaaS - Pilot'
        Preview run:  .\ENTAPPMIG-Provisioning.ps1 -AppName '...' -ProvisionUserId <guid> -WhatIf
        Apply run:    .\ENTAPPMIG-Provisioning.ps1 -AppName '...' -ProvisionUserId <guid> -Commit
    EXPECTED RESULTS
        Job status table + recent provisioning results. PASS = job Active, recent successes, and (if you
        provision on demand) the pilot user created/updated in the target app.
.NOTES
    White-label — Entra ID Solutions. Read-only by default; on-demand provision gated behind -Commit with a
    -WhatIf preview. No credentials stored — the SCIM secret lives only in the app's provisioning config.
.EXAMPLE
    .\ENTAPPMIG-Provisioning.ps1 -AppName 'ENTAPPMIG - App - ScimSaaS - Pilot'
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)][string]$AppName,
    [string]$ProvisionUserId,
    [switch]$Commit
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$scopes = @('Application.Read.All','Synchronization.Read.All','AuditLog.Read.All')
if ($Commit) { $scopes += 'Synchronization.ReadWrite.All' }
Connect-MgGraph -Scopes $scopes -NoWelcome

function Get-AllPages([string]$Uri) { $i=@(); do { $r=Invoke-MgGraphRequest -Method GET -Uri $Uri; $i+=$r.value; $Uri=$r.'@odata.nextLink' } while ($Uri); return $i }

$sp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/servicePrincipals?`$filter=displayName eq '$AppName'").value | Select-Object -First 1
if (-not $sp) { Write-Host "App '$AppName' not found." -ForegroundColor Red; Disconnect-MgGraph | Out-Null; return }

Write-Host "`n=== Provisioning jobs for '$AppName' ===" -ForegroundColor Cyan
$jobs = @(); try { $jobs = Get-AllPages "/v1.0/servicePrincipals/$($sp.id)/synchronization/jobs" } catch {}
if (-not $jobs) { Write-Host "  (no synchronization job — configure Provisioning -> Automatic per 03-implementation Step 5)" -ForegroundColor Yellow }
foreach ($j in $jobs) {
    [pscustomobject]@{
        JobId       = $j.id
        Template    = $j.templateId
        State       = $j.schedule.state
        LastRun     = $j.status.lastExecution.timeEnded
        LastResult  = $j.status.lastExecution.state
        Code        = $j.status.code
    } | Format-List
    if ($j.status.quarantine) { Write-Host "  [WARN] job is in QUARANTINE: $($j.status.quarantine.reason)" -ForegroundColor Yellow }
}

# --- Optional on-demand provision (gated) -------------------------------------
if ($ProvisionUserId -and $jobs) {
    $jobId = $jobs[0].id
    if (-not $Commit) {
        Write-Host "`n[WhatIf] Would provision-on-demand user $ProvisionUserId via job $jobId for '$AppName'. Add -Commit to apply." -ForegroundColor Magenta
    }
    elseif ($PSCmdlet.ShouldProcess("$AppName job $jobId -> user $ProvisionUserId", "Provision on demand")) {
        $body = @{ parameters = @(@{ subjects = @(@{ objectId = $ProvisionUserId; objectTypeName = 'User' }); ruleId = $null }) }
        try {
            Invoke-MgGraphRequest -Method POST -Uri "/v1.0/servicePrincipals/$($sp.id)/synchronization/jobs/$jobId/provisionOnDemand" -Body $body | Out-Null
            Write-Host "  triggered on-demand provision of $ProvisionUserId" -ForegroundColor Green
        } catch { Write-Host "  provisionOnDemand failed: $($_.Exception.Message)" -ForegroundColor Yellow }
    }
}
Write-Host "`nProvisioning report complete." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
