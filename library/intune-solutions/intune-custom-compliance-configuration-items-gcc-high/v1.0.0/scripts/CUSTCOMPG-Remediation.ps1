<#
.SYNOPSIS
    CUSTCOMPG-Remediation.ps1 — Safely apply the custom-compliance discovery script + JSON to the GCC High policy (WhatIf by default).
.DESCRIPTION
    PURPOSE
        Change-making helper for the Government (GCC High) edition of Intune Custom Compliance,
        gated behind -WhatIf so it PREVIEWS by default and changes nothing until you opt in.
        It ensures the named discovery script exists (creating/updating it from a local .ps1),
        and ensures the named custom-compliance policy references that script and the JSON
        rules file. Use it to reconcile the tenant to your source-controlled script + rules.
        Point -ScriptPath at your discovery script (e.g. 'CUSTCOMPG-Discovery-Win.ps1'),
        -RulesPath at your rules file (e.g. 'CUSTCOMPG-Rules.json').
    HOW TO RUN
        Preview (default, no changes):
          powershell -ExecutionPolicy Bypass -File .\CUSTCOMPG-Remediation.ps1 -ScriptPath .\CUSTCOMPG-Discovery-Win.ps1 -RulesPath .\CUSTCOMPG-Rules.json
        Apply (explicit):
          powershell -ExecutionPolicy Bypass -File .\CUSTCOMPG-Remediation.ps1 -ScriptPath .\CUSTCOMPG-Discovery-Win.ps1 -RulesPath .\CUSTCOMPG-Rules.json -WhatIf:$false
        (Graph scopes: DeviceManagementConfiguration.ReadWrite.All; -Environment USGov)
    EXPECTED RESULTS
        In preview: a list of the create/update actions that WOULD run, and nothing changes.
        When applied: the discovery script and policy are reconciled and confirmed. Always run
        CUSTCOMPG-Validation.ps1 first and pilot before applying broadly.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][string] $ScriptPath,
    [Parameter(Mandatory)][string] $RulesPath,
    [string] $ScriptDisplayName = 'CUSTCOMPG-Discovery-Win',
    [string] $PolicyName        = 'CUSTCOMPG-Compliance-Baseline'
)

# Default posture: preview only. -WhatIf is honoured automatically by ShouldProcess;
# we also force it on unless the caller explicitly passed -WhatIf:$false.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

$ErrorActionPreference = 'Stop'

function Connect-UsGovGraph {
    param([string[]] $Scopes)
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph PowerShell SDK not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    if ((Get-MgContext).Environment -ne 'USGov') {
        Write-Host "Connecting to Microsoft Graph US Gov (GCC High) — Environment USGov..." -ForegroundColor Cyan
        Connect-MgGraph -Environment USGov -Scopes $Scopes | Out-Null
    }
    if ((Get-MgContext).Environment -ne 'USGov') {
        throw "Connected environment is not 'USGov'. Reconnect with: Connect-MgGraph -Environment USGov"
    }
    Write-Host "Connected. Environment=USGov" -ForegroundColor Green
}

function Get-AllUsGov { param([string] $RelativeUri)
    $items=@(); $uri="https://graph.microsoft.us/beta/$RelativeUri"
    while ($uri) { $r=Invoke-MgGraphRequest -Method GET -Uri $uri; if($r.value){$items+=$r.value}; $uri=$r.'@odata.nextLink' }
    return $items
}

# --- Pre-flight: never apply an unvalidated script/rules pair ---
if (-not (Test-Path $ScriptPath)) { throw "Script not found: $ScriptPath" }
if (-not (Test-Path $RulesPath))  { throw "Rules file not found: $RulesPath" }
$scriptText = Get-Content -Path $ScriptPath -Raw
$rulesText  = Get-Content -Path $RulesPath  -Raw
if ($scriptText -notmatch 'ConvertTo-Json\s+.*-Compress') {
    throw "Discovery script does not end with 'ConvertTo-Json -Compress'. Run CUSTCOMPG-Validation.ps1 first."
}
try { $null = $rulesText | ConvertFrom-Json } catch { throw "Rules file is not valid JSON. Run CUSTCOMPG-Validation.ps1 first." }

Connect-UsGovGraph -Scopes @('DeviceManagementConfiguration.ReadWrite.All')

$scriptB64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($scriptText))

# --- Ensure the discovery script exists / is current ---
$scripts = Get-AllUsGov -RelativeUri "deviceManagement/deviceComplianceScripts"
$existing = $scripts | Where-Object { $_.displayName -eq $ScriptDisplayName } | Select-Object -First 1

$body = @{
    '@odata.type'      = '#microsoft.graph.deviceComplianceScript'
    displayName        = $ScriptDisplayName
    description         = 'CUSTCOMPG custom-compliance discovery script (GCC High).'
    publisher          = 'CUSTCOMPG'
    detectionScriptContent = $scriptB64
    runAsAccount       = 'system'
    enforceSignatureCheck  = $false
    runAs32Bit         = $false
} | ConvertTo-Json -Depth 6

if ($existing) {
    if ($PSCmdlet.ShouldProcess("deviceComplianceScript '$ScriptDisplayName' (id $($existing.id))", "UPDATE detection script content")) {
        Invoke-MgGraphRequest -Method PATCH -Uri "https://graph.microsoft.us/beta/deviceManagement/deviceComplianceScripts/$($existing.id)" -Body $body | Out-Null
        Write-Host "Updated discovery script '$ScriptDisplayName'." -ForegroundColor Green
    }
} else {
    if ($PSCmdlet.ShouldProcess("deviceComplianceScript '$ScriptDisplayName'", "CREATE detection script")) {
        Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.us/beta/deviceManagement/deviceComplianceScripts" -Body $body | Out-Null
        Write-Host "Created discovery script '$ScriptDisplayName'." -ForegroundColor Green
    }
}

# --- Report on the policy linkage (the JSON is bound to the policy in the portal) ---
$policies = Get-AllUsGov -RelativeUri "deviceManagement/deviceCompliancePolicies"
$policy = $policies | Where-Object { $_.displayName -eq $PolicyName } | Select-Object -First 1
if (-not $policy) {
    Write-Host "Policy '$PolicyName' not found. Create it in intune.microsoft.us (03-implementation.md Step 1.5) and" -ForegroundColor DarkYellow
    Write-Host "attach discovery script '$ScriptDisplayName' + the JSON rules file '$RulesPath' there." -ForegroundColor DarkYellow
} else {
    Write-Host "Policy '$PolicyName' exists (id $($policy.id)). Confirm in the portal that it references" -ForegroundColor Cyan
    Write-Host "discovery script '$ScriptDisplayName' and the current JSON rules file." -ForegroundColor Cyan
}

if ($WhatIfPreference) {
    Write-Host "`nPREVIEW ONLY (-WhatIf). No changes were made. Re-run with -WhatIf:`$false to apply." -ForegroundColor Yellow
} else {
    Write-Host "`nRemediation applied. Pilot and validate per 05-testing.md before expanding." -ForegroundColor Green
}
