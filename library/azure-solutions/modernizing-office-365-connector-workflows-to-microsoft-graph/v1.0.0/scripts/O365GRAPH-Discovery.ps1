<#
.SYNOPSIS
    O365GRAPH-Discovery.ps1 — inventory Azure Logic Apps that use Office 365 connectors and record
    how each authenticates; flag where Power Automate flow data must be supplied.
.DESCRIPTION
    PURPOSE
        Read-only discovery for the "Modernizing Office 365 Connector Workflows to Microsoft Graph"
        migration program. Enumerates Logic Apps across the in-scope Azure subscriptions, inspects
        each workflow definition + its API connections, flags those using an Office 365 connector
        (Office 365 Outlook / Office 365 Users / Excel Online), and records the auth model of each
        (interactive user, shared service account, stored secret, or an existing managed identity).
        Writes the "Connector-Flow-Inventory - Estate - Program.csv" register. Makes NO changes.

        Power Automate flows are NOT Azure resources and are enumerated through a Power Platform
        admin method, separate from this Az-based Logic Apps discovery. This script emits a clearly
        marked placeholder row set for the Power Automate side so the merged register is complete.
        The exact Power Platform enumeration method is a "verify against current Microsoft
        documentation" item and is intentionally not hard-coded here.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\O365GRAPH-Discovery.ps1
        powershell -ExecutionPolicy Bypass -File .\O365GRAPH-Discovery.ps1 -SubscriptionId '<sub id>'
        powershell -ExecutionPolicy Bypass -File .\O365GRAPH-Discovery.ps1 -OutputCsv '.\Connector-Flow-Inventory - Estate - Program.csv'
    SCOPES / ROLES
        Azure: Reader across the subscriptions/resource groups holding Logic Apps
        (Az.Accounts, Az.LogicApp, Az.Resources). Run Connect-AzAccount first, or the script prompts.
        Power Automate: Power Platform administrator (or read) to enumerate flows (method: verify).
    EXPECTED RESULTS
        A CSV register, one row per flow: FlowName, Platform (LogicApp/PowerAutomate), Connector(s),
        AuthModel, Owner, MailboxesOrResources, ResourceId. A single readiness picture of the whole
        connector estate and its authentication before you classify and migrate.
.NOTES
    Azure Solutions — read-only. Reports on configuration/identifiers only; makes no changes.
    White-label sample values use contoso.com. Verify volatile Microsoft specifics against current docs.
#>
[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [string]$OutputCsv = ".\Connector-Flow-Inventory - Estate - Program.csv"
)

# Office 365 connector managed-API identifiers to flag (verify current names against Microsoft docs).
$o365Connectors = @('office365','office365users','excelonlinebusiness','excelonline')

foreach ($m in 'Az.Accounts','Az.LogicApp','Az.Resources') {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Install-Module Az -Scope CurrentUser -Force -AllowClobber
        break
    }
}
Import-Module Az.Accounts  -ErrorAction Stop
Import-Module Az.LogicApp  -ErrorAction Stop
Import-Module Az.Resources -ErrorAction Stop

if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId | Out-Null }

$rows = New-Object System.Collections.Generic.List[object]

Write-Host "`n=== O365 Connector Workflows -> Graph — discovery ===" -ForegroundColor Cyan

# --- Logic Apps side (Azure) ---
Write-Host "`n-- Logic Apps using Office 365 connectors --" -ForegroundColor Cyan
try {
    $logicApps = Get-AzLogicApp -ErrorAction Stop
} catch {
    Write-Warning "Could not enumerate Logic Apps: $($_.Exception.Message)"
    $logicApps = @()
}

foreach ($la in $logicApps) {
    # Serialize the workflow definition + parameters to inspect connector references and auth.
    $defJson = ($la.Definition | ConvertTo-Json -Depth 40 -ErrorAction SilentlyContinue)
    $paramJson = ($la.Parameters | ConvertTo-Json -Depth 40 -ErrorAction SilentlyContinue)
    $blob = "$defJson`n$paramJson"

    $matched = @()
    foreach ($c in $o365Connectors) { if ($blob -match [regex]::Escape($c)) { $matched += $c } }
    if (-not $matched) { continue }   # only report connector-based flows

    # Infer the auth model from the connection reference shape (heuristic; confirm per connection).
    $authModel = 'Unknown (inspect connection)'
    if     ($blob -match '"identity"')                 { $authModel = 'Managed identity (already)' }
    elseif ($blob -match 'connectionKey|serviceAccount'){ $authModel = 'Service account / secret (standing cred)' }
    elseif ($blob -match 'oauthSettings|tokenProvider'){ $authModel = 'Interactive user (delegated token)' }

    $rows.Add([pscustomobject]@{
        FlowName             = $la.Name
        Platform             = 'LogicApp'
        Connectors           = ($matched -join ';')
        AuthModel            = $authModel
        Owner                = ''                 # populate from tags/ownership as available
        MailboxesOrResources = ''                 # populate from the flow's target mailbox(es)
        ResourceId           = $la.Id
    })
    Write-Host ("  [O365] {0}  auth={1}  connectors={2}" -f $la.Name, $authModel, ($matched -join ';'))
}

# --- Power Automate side (Power Platform) — enumeration method is a VERIFY item ---
Write-Host "`n-- Power Automate flows (Power Platform) --" -ForegroundColor Yellow
Write-Host "  NOTE: Power Automate flows are enumerated via a Power Platform admin method (verify" -ForegroundColor Yellow
Write-Host "  against current Microsoft documentation). Supply the exported flow list and merge it" -ForegroundColor Yellow
Write-Host "  into the register with the same columns (Platform=PowerAutomate, AuthModel per" -ForegroundColor Yellow
Write-Host "  connection reference). A placeholder row is emitted so the register is visibly complete." -ForegroundColor Yellow
$rows.Add([pscustomobject]@{
    FlowName             = '<supply Power Automate flows here>'
    Platform             = 'PowerAutomate'
    Connectors           = 'office365 (verify)'
    AuthModel            = 'Connection reference — user/service account (verify; typically NOT an Azure managed identity)'
    Owner                = ''
    MailboxesOrResources = ''
    ResourceId           = ''
})

$rows | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
Write-Host ("`nWrote {0} flow row(s) to {1}" -f $rows.Count, $OutputCsv) -ForegroundColor Green
Write-Host "Next: O365GRAPH-Classify.ps1 to score risk + Graph-migratability." -ForegroundColor Cyan
