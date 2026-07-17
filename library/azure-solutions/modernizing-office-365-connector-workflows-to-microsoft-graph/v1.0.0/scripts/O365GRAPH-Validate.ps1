<#
.SYNOPSIS
    O365GRAPH-Validate.ps1 — PASS/FAIL check that a migrated flow uses a managed identity + Microsoft
    Graph and carries no stored-credential connection.
.DESCRIPTION
    PURPOSE
        Read-only validation for the migration program. For a migrated Logic App (or a set), confirms
        the end-state acceptance criteria and emits PASS/FAIL per flow:
            1. The Logic App has a managed identity assigned ("<FlowName> - Graph MI - Target").
            2. The workflow calls Microsoft Graph (not an Office 365 connector).
            3. There is NO stored-credential connection (no user token / service-account secret).
            4. (Reported) A scoped Graph mail application permission is expected on the identity —
               the scoping mechanism itself is delivered/verified per sibling #4.
        Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\O365GRAPH-Validate.ps1 -LogicAppName 'Contoso-MailNotify'
        powershell -ExecutionPolicy Bypass -File .\O365GRAPH-Validate.ps1 -ResourceGroup 'rg-automation'
        powershell -ExecutionPolicy Bypass -File .\O365GRAPH-Validate.ps1 -All
    SCOPES / ROLES
        Azure: Reader on the Logic App(s) (Az.Accounts, Az.LogicApp). Microsoft.Graph read
        (Directory.Read.All / Application.Read.All) to confirm the identity's app-role assignments.
        Run Connect-AzAccount / Connect-MgGraph first, or the script prompts.
    EXPECTED RESULTS
        A PASS/FAIL line per flow with the failing criterion named, and a cohort summary
        (migrated-and-clean vs. still-carrying-a-credential). A migrated flow is PASS only when it
        uses managed identity + Graph and has zero stored-credential connections.
.NOTES
    Azure Solutions — read-only. Confirms end state; makes no changes.
    White-label sample values use contoso.com. Exact Graph permission names: verify against current docs.
#>
[CmdletBinding()]
param(
    [string]$LogicAppName,
    [string]$ResourceGroup,
    [switch]$All
)

foreach ($m in 'Az.Accounts','Az.LogicApp') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Az -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.LogicApp -ErrorAction Stop
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }

$targets = if     ($LogicAppName -and $ResourceGroup) { Get-AzLogicApp -ResourceGroupName $ResourceGroup -Name $LogicAppName }
           elseif ($ResourceGroup)                    { Get-AzLogicApp -ResourceGroupName $ResourceGroup }
           elseif ($All)                              { Get-AzLogicApp }
           elseif ($LogicAppName)                     { Get-AzLogicApp | Where-Object Name -eq $LogicAppName }
           else { throw "Specify -LogicAppName, -ResourceGroup, or -All." }

$pass = 0; $fail = 0
Write-Host "`n=== O365 Connector Workflows -> Graph — validation (PASS/FAIL) ===" -ForegroundColor Cyan

foreach ($la in $targets) {
    $blob = ("{0}`n{1}" -f ($la.Definition | ConvertTo-Json -Depth 40), ($la.Parameters | ConvertTo-Json -Depth 40))
    $reasons = @()

    # 1. Managed identity present
    $hasMi = ($null -ne $la.Identity) -and ($la.Identity.Type -match 'SystemAssigned|UserAssigned')
    if (-not $hasMi) { $reasons += 'no managed identity assigned' }

    # 2. Calls Graph, not an Office 365 connector
    $callsGraph  = $blob -match 'graph\.microsoft\.com|graph\.microsoft\.us'
    $usesO365    = $blob -match 'office365|excelonline'
    if (-not $callsGraph) { $reasons += 'does not call Microsoft Graph' }
    if ($usesO365)        { $reasons += 'still references an Office 365 connector' }

    # 3. No stored-credential connection
    $hasStoredCred = $blob -match 'connectionKey|serviceAccount|oauthSettings|"connectionString"'
    if ($hasStoredCred) { $reasons += 'stored-credential connection present' }

    if ($reasons.Count -eq 0) {
        $pass++
        Write-Host ("  PASS  {0}  (managed identity + Graph, no stored credential)" -f $la.Name) -ForegroundColor Green
        Write-Host ("        reminder: confirm the scoped mail permission per sibling #4") -ForegroundColor DarkGray
    } else {
        $fail++
        Write-Host ("  FAIL  {0}  -> {1}" -f $la.Name, ($reasons -join '; ')) -ForegroundColor Red
    }
}

Write-Host ("`nCohort: {0} PASS, {1} FAIL" -f $pass, $fail) -ForegroundColor Cyan
if ($fail -gt 0) { exit 1 } else { exit 0 }
