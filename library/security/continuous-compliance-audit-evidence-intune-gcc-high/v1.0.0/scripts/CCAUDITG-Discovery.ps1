<#
.SYNOPSIS
    CCAUDITG-Discovery.ps1 — inventory the control state of your CIS/STIG baseline on Intune + Entra in GCC High (read-only).
.DESCRIPTION
    PURPOSE
        Discover and inventory the Intune and Entra objects that encode your deployed CIS/STIG baseline
        in a US Government (GCC High / DoD) tenant: device-configuration and Settings Catalog profiles,
        compliance policies, Security Baselines, and Entra Conditional Access and authentication-method
        policies. Optionally emits a baseline-reference template (CCAUDITG-Baseline.json). Read-only —
        nothing is changed. Runs against Microsoft Graph US Gov; use your-tenant-id / your-account as
        prompted at sign-in.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CCAUDITG-Discovery.ps1 -OutputPath C:\CCAUDITG\out
        (add -EmitBaselineTemplate to also write a baseline template; add -Environment USGovDoD on a DoD tenant)

        Graph scopes (read): DeviceManagementConfiguration.Read.All, DeviceManagementManagedDevices.Read.All,
        Policy.Read.All, Directory.Read.All, Group.Read.All. Connects with -Environment USGov (US Gov Graph).
    EXPECTED RESULTS
        Writes CCAUDITG-Discovery-<timestamp>.csv and .json listing discovered configuration objects and
        their current settings. With -EmitBaselineTemplate, also writes CCAUDITG-Baseline.template.json.
        PASS: the file lists your baseline profiles/policies with no permissions error, connected to a
        graph.microsoft.us host. FAIL: a permissions error, empty output, or a graph.microsoft.com host
        (wrong cloud) — check roles, consented read scopes, and -Environment.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [string]$OutputPath = ".",
    [ValidateSet("USGov", "USGovDoD")]
    [string]$Environment = "USGov",
    [switch]$EmitBaselineTemplate
)

$ErrorActionPreference = "Stop"

# US Gov Graph base host (GCC High = graph.microsoft.us; DoD/IL5 = dod-graph.microsoft.us).
$GraphBase = if ($Environment -eq "USGovDoD") { "https://dod-graph.microsoft.us" } else { "https://graph.microsoft.us" }

$scopes = @(
    "DeviceManagementConfiguration.Read.All",
    "DeviceManagementManagedDevices.Read.All",
    "Policy.Read.All",
    "Directory.Read.All",
    "Group.Read.All"
)

function Connect-CCAudit {
    param([string[]]$Scopes, [string]$Env)
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
        throw "Microsoft.Graph module not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    # -Environment targets the US Gov identity + Graph endpoints (sign-in at login.microsoftonline.us).
    Connect-MgGraph -Scopes $Scopes -Environment $Env -NoWelcome | Out-Null
    $ctx = Get-MgContext
    if (-not $ctx) { throw "Failed to connect to Microsoft Graph US Gov ($Env)." }
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

Write-Host ("Connecting to Microsoft Graph US Gov ({0}) — read-only discovery..." -f $Environment) -ForegroundColor Cyan
$ctx = Connect-CCAudit -Scopes $scopes -Env $Environment
Write-Host ("Connected to tenant {0} as {1}" -f $ctx.TenantId, $ctx.Account) -ForegroundColor Green
Write-Host ("Graph environment: {0}  (verify this is a *.microsoft.us host)" -f $ctx.Environment) -ForegroundColor Yellow

$records = New-Object System.Collections.Generic.List[object]

function Add-Record {
    param($Domain, $ObjectType, $Id, $Name, $Detail)
    $records.Add([pscustomobject]@{
        CollectedUtc = (Get-Date).ToUniversalTime().ToString("o")
        TenantId     = $ctx.TenantId
        Operator     = $ctx.Account
        Cloud        = $Environment
        Domain       = $Domain
        ObjectType   = $ObjectType
        ObjectId     = $Id
        ObjectName   = $Name
        Detail       = $Detail
    })
}

Write-Host "Discovering Intune configuration profiles (Settings Catalog / device configuration)..." -ForegroundColor Cyan
try {
    foreach ($p in (Invoke-CCGraphGet "$GraphBase/beta/deviceManagement/configurationPolicies")) {
        Add-Record "Intune" "SettingsCatalogPolicy" $p.id $p.name $p.description
    }
    foreach ($p in (Invoke-CCGraphGet "$GraphBase/v1.0/deviceManagement/deviceConfigurations")) {
        Add-Record "Intune" "DeviceConfiguration" $p.id $p.displayName $p.'@odata.type'
    }
} catch { Write-Warning "Configuration profile discovery: $($_.Exception.Message)" }

Write-Host "Discovering Intune compliance policies..." -ForegroundColor Cyan
try {
    foreach ($p in (Invoke-CCGraphGet "$GraphBase/v1.0/deviceManagement/deviceCompliancePolicies")) {
        Add-Record "Intune" "CompliancePolicy" $p.id $p.displayName $p.'@odata.type'
    }
} catch { Write-Warning "Compliance policy discovery: $($_.Exception.Message)" }

Write-Host "Discovering Intune Security Baselines (intents)..." -ForegroundColor Cyan
try {
    foreach ($p in (Invoke-CCGraphGet "$GraphBase/beta/deviceManagement/intents")) {
        Add-Record "Intune" "SecurityBaselineIntent" $p.id $p.displayName $p.templateId
    }
} catch { Write-Warning "Security Baseline discovery: $($_.Exception.Message)" }

Write-Host "Discovering Entra Conditional Access policies..." -ForegroundColor Cyan
try {
    foreach ($p in (Invoke-CCGraphGet "$GraphBase/v1.0/identity/conditionalAccess/policies")) {
        Add-Record "Entra" "ConditionalAccessPolicy" $p.id $p.displayName $p.state
    }
} catch { Write-Warning "Conditional Access discovery: $($_.Exception.Message)" }

Write-Host "Discovering Entra authentication-method policy..." -ForegroundColor Cyan
try {
    $amp = Invoke-MgGraphRequest -Method GET -Uri "$GraphBase/v1.0/policies/authenticationMethodsPolicy"
    if ($amp) { Add-Record "Entra" "AuthenticationMethodsPolicy" $amp.id $amp.displayName $amp.policyVersion }
} catch { Write-Warning "Authentication-methods policy discovery: $($_.Exception.Message)" }

$csv  = Join-Path $OutputPath "CCAUDITG-Discovery-$stamp.csv"
$json = Join-Path $OutputPath "CCAUDITG-Discovery-$stamp.json"
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
    $tpath = Join-Path $OutputPath "CCAUDITG-Baseline.template.json"
    $template | ConvertTo-Json -Depth 6 | Out-File -FilePath $tpath -Encoding UTF8
    Write-Host ("Baseline template written: {0} (complete it, save as CCAUDITG-Baseline.json, approve under change control). Do NOT include controls whose enforcement mechanism is unavailable in GCC High — e.g. BIOS/DFCI, update rings, Device Health Attestation." -f $tpath) -ForegroundColor Yellow
}

Disconnect-MgGraph | Out-Null
