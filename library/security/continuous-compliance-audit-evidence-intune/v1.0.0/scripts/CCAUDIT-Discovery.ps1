<#
.SYNOPSIS
    CCAUDIT-Discovery.ps1 — inventory the control state of your CIS/STIG baseline on Intune + Entra (read-only).
.DESCRIPTION
    PURPOSE
        Discover and inventory the Intune and Entra objects that encode your deployed CIS/STIG
        baseline: device-configuration and Settings Catalog profiles, compliance policies, Security
        Baselines, and Entra Conditional Access and authentication-method policies. Optionally emits a
        baseline-reference template (CCAUDIT-Baseline.json) so you can record the expected value for
        each monitored control. Read-only — nothing is changed.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CCAUDIT-Discovery.ps1 -OutputPath C:\CCAUDIT\out

        Required Graph scopes (read): DeviceManagementConfiguration.Read.All,
        DeviceManagementManagedDevices.Read.All, Policy.Read.All, Directory.Read.All, Group.Read.All
    EXPECTED RESULTS
        Writes CCAUDIT-Discovery-<timestamp>.csv and .json listing discovered configuration objects
        and their current settings. With -EmitBaselineTemplate, also writes CCAUDIT-Baseline.template.json.
        PASS: the file lists your baseline profiles/policies with no permissions error.
        FAIL: a permissions error or empty output — check roles and consented read scopes.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph. CIS/STIG control content deferred to CIS/DISA.
#>

[CmdletBinding()]
param(
    [string]$OutputPath = ".",
    [switch]$EmitBaselineTemplate
)

$ErrorActionPreference = "Stop"
$scopes = @(
    "DeviceManagementConfiguration.Read.All",
    "DeviceManagementManagedDevices.Read.All",
    "Policy.Read.All",
    "Directory.Read.All",
    "Group.Read.All"
)

function Connect-CCAudit {
    param([string[]]$Scopes)
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
        throw "Microsoft.Graph module not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes $Scopes -NoWelcome | Out-Null
    $ctx = Get-MgContext
    if (-not $ctx) { throw "Failed to connect to Microsoft Graph." }
    return $ctx
}

function Invoke-CCGraphGet {
    param([string]$Uri)
    $items = @()
    $next = $Uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($resp.value) { $items += $resp.value } elseif ($resp) { $items += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $items
}

if (-not (Test-Path -LiteralPath $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"

Write-Host "Connecting to Microsoft Graph (read-only discovery)..." -ForegroundColor Cyan
$ctx = Connect-CCAudit -Scopes $scopes
Write-Host ("Connected to tenant {0} as {1}" -f $ctx.TenantId, $ctx.Account) -ForegroundColor Green

$records = New-Object System.Collections.Generic.List[object]

function Add-Record {
    param($Domain, $ObjectType, $Id, $Name, $Detail)
    $records.Add([pscustomobject]@{
        CollectedUtc = (Get-Date).ToUniversalTime().ToString("o")
        TenantId     = $ctx.TenantId
        Operator     = $ctx.Account
        Domain       = $Domain
        ObjectType   = $ObjectType
        ObjectId     = $Id
        ObjectName   = $Name
        Detail       = $Detail
    })
}

Write-Host "Discovering Intune configuration profiles (Settings Catalog / device configuration)..." -ForegroundColor Cyan
try {
    foreach ($p in (Invoke-CCGraphGet "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies")) {
        Add-Record "Intune" "SettingsCatalogPolicy" $p.id $p.name $p.description
    }
    foreach ($p in (Invoke-CCGraphGet "https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations")) {
        Add-Record "Intune" "DeviceConfiguration" $p.id $p.displayName $p.'@odata.type'
    }
} catch { Write-Warning "Configuration profile discovery: $($_.Exception.Message)" }

Write-Host "Discovering Intune compliance policies..." -ForegroundColor Cyan
try {
    foreach ($p in (Invoke-CCGraphGet "https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies")) {
        Add-Record "Intune" "CompliancePolicy" $p.id $p.displayName $p.'@odata.type'
    }
} catch { Write-Warning "Compliance policy discovery: $($_.Exception.Message)" }

Write-Host "Discovering Intune Security Baselines (intents)..." -ForegroundColor Cyan
try {
    foreach ($p in (Invoke-CCGraphGet "https://graph.microsoft.com/beta/deviceManagement/intents")) {
        Add-Record "Intune" "SecurityBaselineIntent" $p.id $p.displayName $p.templateId
    }
} catch { Write-Warning "Security Baseline discovery: $($_.Exception.Message)" }

Write-Host "Discovering Entra Conditional Access policies..." -ForegroundColor Cyan
try {
    foreach ($p in (Invoke-CCGraphGet "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies")) {
        Add-Record "Entra" "ConditionalAccessPolicy" $p.id $p.displayName $p.state
    }
} catch { Write-Warning "Conditional Access discovery: $($_.Exception.Message)" }

Write-Host "Discovering Entra authentication-method policy..." -ForegroundColor Cyan
try {
    $amp = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/policies/authenticationMethodsPolicy"
    if ($amp) { Add-Record "Entra" "AuthenticationMethodsPolicy" $amp.id $amp.displayName $amp.policyVersion }
} catch { Write-Warning "Authentication-methods policy discovery: $($_.Exception.Message)" }

$csv  = Join-Path $OutputPath "CCAUDIT-Discovery-$stamp.csv"
$json = Join-Path $OutputPath "CCAUDIT-Discovery-$stamp.json"
$records | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
$records | ConvertTo-Json -Depth 6 | Out-File -FilePath $json -Encoding UTF8
Write-Host ("Discovered {0} objects. Wrote:`n  {1}`n  {2}" -f $records.Count, $csv, $json) -ForegroundColor Green

if ($EmitBaselineTemplate) {
    $template = $records | ForEach-Object {
        [pscustomobject]@{
            ControlId     = "REPLACE-WITH-CIS-OR-STIG-CONTROL-ID"
            Domain        = $_.Domain
            TargetObject  = $_.ObjectName
            TargetObjectId= $_.ObjectId
            SettingName   = "REPLACE-WITH-SETTING-NAME"
            ExpectedValue = "REPLACE-WITH-EXPECTED-VALUE"
            Severity      = "REPLACE-High-Medium-Low"
        }
    }
    $tpath = Join-Path $OutputPath "CCAUDIT-Baseline.template.json"
    $template | ConvertTo-Json -Depth 6 | Out-File -FilePath $tpath -Encoding UTF8
    Write-Host ("Baseline template written: {0} (complete it, save as CCAUDIT-Baseline.json, approve under change control)" -f $tpath) -ForegroundColor Yellow
}

Disconnect-MgGraph | Out-Null
