<#
.SYNOPSIS
    ENTIGA-Lifecycle.ps1 — lifecycle-workflow run history, trigger-attribute readiness, on-demand run preview.
.DESCRIPTION
    PURPOSE
        Supports the joiner/mover/leaver workflows. Reports (1) each ENTIGA workflow's recent run
        history and task outcomes, and (2) which in-scope users have the scheduling attributes
        employeeHireDate / employeeLeaveDateTime populated (without them only on-demand runs work).
        With -RunUserId it will trigger an ON-DEMAND run of a named workflow for a test user — but only
        as a -WhatIf preview unless -Commit is given, so you never fire a real onboarding/offboarding by
        accident.
    HOW TO RUN
        Report:        .\ENTIGA-Lifecycle.ps1
        Attr check:    .\ENTIGA-Lifecycle.ps1 -CsvPath C:\Temp\lifecycle-attrs.csv
        Preview run:   .\ENTIGA-Lifecycle.ps1 -WorkflowName 'ENTIGA - Joiner - Onboarding' -RunUserId <guid> -WhatIf
        Apply run:     .\ENTIGA-Lifecycle.ps1 -WorkflowName 'ENTIGA - Joiner - Onboarding' -RunUserId <guid> -Commit
    EXPECTED RESULTS
        Workflow run table + attribute-readiness summary. PASS = workflows run clean and target users
        have the trigger attributes (or you run on-demand deliberately).
.NOTES
    White-label — Entra ID Solutions. Read-only by default; on-demand runs gated behind -Commit with a
    -WhatIf preview. No credentials stored.
.EXAMPLE
    .\ENTIGA-Lifecycle.ps1
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [string]$WorkflowName,
    [string]$RunUserId,
    [string]$CsvPath,
    [switch]$Commit
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$scopes = @('LifecycleWorkflows.Read.All','User.Read.All')
if ($Commit) { $scopes += 'LifecycleWorkflows.ReadWrite.All' }
Connect-MgGraph -Scopes $scopes -NoWelcome

function Get-AllPages([string]$Uri) {
    $items=@(); do { $r=Invoke-MgGraphRequest -Method GET -Uri $Uri; $items+=$r.value; $Uri=$r.'@odata.nextLink' } while ($Uri); return $items
}

# --- Workflow run history ------------------------------------------------------
Write-Host "`n=== ENTIGA lifecycle workflow run history ===" -ForegroundColor Cyan
$wfs = Get-AllPages "/v1.0/identityGovernance/lifecycleWorkflows/workflows"
$entWf = $wfs | Where-Object displayName -like 'ENTIGA*'
if (-not $entWf) { Write-Host "  (no ENTIGA workflows found — create them per 03-implementation Step 7)" -ForegroundColor Yellow }
foreach ($w in $entWf) {
    Write-Host ("`n  {0}  [enabled={1}, category={2}]" -f $w.displayName, $w.isEnabled, $w.category) -ForegroundColor White
    $runs = Get-AllPages "/v1.0/identityGovernance/lifecycleWorkflows/workflows/$($w.id)/runs?`$top=5&`$orderby=startedDateTime desc"
    if ($runs) {
        $runs | ForEach-Object { [pscustomobject]@{ Started=$_.startedDateTime; Status=$_.processingStatus; Users=$_.totalUsersCount; Failed=$_.failedUsersCount } } | Format-Table -AutoSize
    } else { Write-Host "    no runs yet" -ForegroundColor Yellow }
}

# --- Trigger-attribute readiness ----------------------------------------------
Write-Host "`n=== Trigger-attribute readiness (employeeHireDate / employeeLeaveDateTime) ===" -ForegroundColor Cyan
$users = Get-AllPages "/v1.0/users?`$select=userPrincipalName,employeeHireDate,employeeLeaveDateTime,accountEnabled&`$filter=userType eq 'Member'&`$top=200"
$attrRows = $users | ForEach-Object {
    [pscustomobject]@{
        User      = $_.userPrincipalName
        HireDate  = $_.employeeHireDate
        LeaveDate = $_.employeeLeaveDateTime
        Ready     = [bool]($_.employeeHireDate -or $_.employeeLeaveDateTime)
    }
}
$ready = ($attrRows | Where-Object Ready).Count
Write-Host ("  {0} of {1} sampled members have a hire/leave date set (schedulable)" -f $ready, $attrRows.Count) -ForegroundColor Yellow
if ($CsvPath) { $attrRows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "  saved $CsvPath" -ForegroundColor Green }

# --- Optional on-demand run (gated) -------------------------------------------
if ($WorkflowName -and $RunUserId) {
    $target = $entWf | Where-Object displayName -eq $WorkflowName | Select-Object -First 1
    if (-not $target) { Write-Host "`nWorkflow '$WorkflowName' not found." -ForegroundColor Red }
    elseif (-not $Commit) {
        Write-Host "`n[WhatIf] Would trigger ON-DEMAND run of '$WorkflowName' for user $RunUserId. Add -Commit to apply." -ForegroundColor Magenta
    }
    elseif ($PSCmdlet.ShouldProcess("$WorkflowName -> user $RunUserId", "Trigger on-demand lifecycle workflow run")) {
        $body = @{ subjects = @(@{ id = $RunUserId }) }
        Invoke-MgGraphRequest -Method POST -Uri "/v1.0/identityGovernance/lifecycleWorkflows/workflows/$($target.id)/activate" -Body $body | Out-Null
        Write-Host "  triggered on-demand run of '$WorkflowName' for $RunUserId" -ForegroundColor Green
    }
}
Disconnect-MgGraph | Out-Null
