<#
.SYNOPSIS
    APPOPS-Export-ApprovalEvidence.ps1 — export the change-approval evidence trail for an app.
.DESCRIPTION
    PURPOSE
        Read-only. For a named application (or all applications), export the audit evidence
        an Application Review Board or an auditor needs to prove a change was authorised:
        the current governance Notes block, the applied scope tags, the assignment groups
        (i.e. which rings it reached), and the Intune audit events that recorded who created,
        assigned, or modified the app and when. This is the "evidence pack" the ARB attaches
        to each Decision Record.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\APPOPS-Export-ApprovalEvidence.ps1 -AppNameLike "Acrobat"
        powershell -ExecutionPolicy Bypass -File .\APPOPS-Export-ApprovalEvidence.ps1 -AppNameLike "Acrobat" -OutFolder .\Evidence -DaysBack 180
        Government tenant:  add  -GraphEnvironment USGov
        Required Graph scopes: DeviceManagementApps.Read.All, DeviceManagementConfiguration.Read.All
    EXPECTED RESULTS
        A per-application evidence file (CSV of audit events + a text summary of owner/scope/
        assignments) written to the output folder. Pass = a complete, dated trail of who
        changed the app. Fail = no audit events found (audit retention may be shorter than the
        requested window — verify Tenant administration > Audit logs retention).
.NOTES
    Intune Solutions — read-only. Uses the Microsoft Graph PowerShell SDK.
#>

[CmdletBinding()]
param(
    [string] $AppNameLike,
    [string] $OutFolder = '.\Evidence',
    [int]    $DaysBack = 90,
    [ValidateSet('Global','USGov')]
    [string] $GraphEnvironment = 'Global'
)

$ErrorActionPreference = 'Stop'

function Connect-Graph { param([string]$Environment)
    $scopes=@('DeviceManagementApps.Read.All','DeviceManagementConfiguration.Read.All')
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft Graph SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser" }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    if (-not (Get-MgContext)) {
        if ($Environment -eq 'USGov'){Connect-MgGraph -Scopes $scopes -Environment USGov|Out-Null}
        else {Connect-MgGraph -Scopes $scopes|Out-Null} } }
function Get-GraphBase { param([string]$Environment)
    if ($Environment -eq 'USGov'){'https://graph.microsoft.us/beta'}else{'https://graph.microsoft.com/beta'} }
function Invoke-GraphGet { param([Parameter(Mandatory)][string]$Uri)
    $items=@();$next=$Uri
    while($next){$r=Invoke-MgGraphRequest -Method GET -Uri $next
        if($r.value){$items+=$r.value}elseif($r){$items+=$r};$next=$r.'@odata.nextLink'}
    return $items }

Connect-Graph -Environment $GraphEnvironment
$base = Get-GraphBase -Environment $GraphEnvironment

if (-not (Test-Path $OutFolder)) { New-Item -ItemType Directory -Path $OutFolder | Out-Null }

Write-Host "Reading applications..." -ForegroundColor Cyan
$apps = Invoke-GraphGet -Uri "$base/deviceAppManagement/mobileApps?`$top=100"
if ($AppNameLike) { $apps = $apps | Where-Object { $_.displayName -like "*$AppNameLike*" } }
if (-not $apps) { Write-Host "No matching applications." -ForegroundColor Yellow; return }

$since = (Get-Date).AddDays(-$DaysBack).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')

foreach ($app in $apps) {
    $safe = ($app.displayName -replace '[\\/:*?"<>|]','_')
    Write-Host ("Building evidence pack for: {0}" -f $app.displayName) -ForegroundColor Cyan

    # Owner / scope / notes summary
    $notes = [string]$app.notes
    $summaryPath = Join-Path $OutFolder ("{0} - summary.txt" -f $safe)
    $assignmentsText = @()
    try {
        $as = Invoke-GraphGet -Uri "$base/deviceAppManagement/mobileApps/$($app.id)/assignments"
        $assignmentsText = $as | ForEach-Object {
            $tt=($_.target.'@odata.type' -replace '#microsoft.graph.','')
            $grp=$_.target.groupId
            "  intent=$($_.intent)  target=$tt$(if($grp){" group=$grp"})" }
    } catch { $assignmentsText = @('  (unable to read assignments)') }

    @(
        "Application evidence summary"
        "============================"
        "Application : $($app.displayName)"
        "Intune AppId: $($app.id)"
        "Type        : $(($app.'@odata.type' -replace '#microsoft.graph.',''))"
        "Scope tags  : $((@($app.roleScopeTagIds)) -join ', ')"
        "Publisher   : $($app.publisher)"
        ""
        "Governance Notes block:"
        "-----------------------"
        $(if([string]::IsNullOrWhiteSpace($notes)){"  (no governance block stamped — run APPOPS-Remediation.ps1)"}else{$notes})
        ""
        "Assignments (rings reached):"
        "----------------------------"
        $assignmentsText
        ""
        "Generated: $((Get-Date).ToString('u'))"
    ) | Set-Content -Path $summaryPath -Encoding UTF8

    # Audit events for this app object
    $auditPath = Join-Path $OutFolder ("{0} - audit-events.csv" -f $safe)
    try {
        $events = Invoke-GraphGet -Uri "$base/deviceManagement/auditEvents?`$filter=activityDateTime ge $since"
        $matched = $events | Where-Object {
            ($_.resources | Where-Object { $_.resourceId -eq $app.id }) -or
            ($_.displayName -like "*$($app.displayName)*")
        } | Select-Object activityDateTime, activityType, activityOperationType, activityResult,
            @{n='Actor';e={$_.actor.userPrincipalName}}, displayName
        if ($matched) {
            $matched | Sort-Object activityDateTime | Export-Csv -Path $auditPath -NoTypeInformation -Encoding UTF8
            Write-Host ("  {0} audit event(s) exported" -f @($matched).Count) -ForegroundColor Green
        } else {
            Write-Host "  No audit events in the requested window (check audit retention)." -ForegroundColor Yellow
        }
    } catch {
        Write-Host ("  Audit query failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    }
}

Write-Host ("Evidence packs written to {0}" -f (Resolve-Path $OutFolder)) -ForegroundColor Green
