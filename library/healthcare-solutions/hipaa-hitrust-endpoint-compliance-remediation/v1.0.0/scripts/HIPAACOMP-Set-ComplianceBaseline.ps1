<#
.SYNOPSIS
    HIPAACOMP-Set-ComplianceBaseline — Scaffold the HIPAA/HITRUST compliance policy
    and Conditional Access gate (Intune + Entra), with -WhatIf preview.

.DESCRIPTION
    Creates the foundational named objects for the solution:
      * Intune device compliance policy "HIPAA Compliance - Clinical Endpoints - Policy"
        (Windows) measuring BitLocker, encryption, firewall, antivirus + signature
        currency, real-time protection, and password/inactivity lock.
      * Conditional Access policy "Require Compliance - Clinical Endpoints - Gate"
        scaffold (created in reportOnly state) requiring device compliance.
    Both target the scope group "HIPAA - Clinical Endpoints". Configuration baselines
    (encryption/lock/AV/firewall/patch/access enforcement) are built per the
    documentation (Implementation Steps 4-8) and are out of scope for this scaffold.

    SAFETY: defaults to -WhatIf (preview, no changes). Pass -Apply to create the
    objects. The CA gate is always created in reportOnly state for safe rollout.

.PARAMETER GroupName
    Scope group. Default: "HIPAA - Clinical Endpoints".

.PARAMETER InactivityMinutes
    Max inactivity minutes before lock. Default: 15.

.PARAMETER Apply
    Switch. When present, creates the objects. Omitted = preview only.

.EXAMPLE
    .\HIPAACOMP-Set-ComplianceBaseline.ps1
    # Preview (read-only) - shows the objects that would be created.

.EXAMPLE
    .\HIPAACOMP-Set-ComplianceBaseline.ps1 -Apply
    # Creates the compliance policy + reportOnly CA gate scaffold.

.NOTES
    Healthcare Solutions — read-only.

    Defaults to -WhatIf; only -Apply creates objects, and the CA gate is created in
    reportOnly state (validate before enabling per Implementation Step 9). Requires
    the Microsoft Graph PowerShell SDK with scopes (only used when -Apply):
      DeviceManagementConfiguration.ReadWrite.All,
      Policy.ReadWrite.ConditionalAccess, Group.Read.All
    Always review the scaffolded objects in the portals and finish settings before
    assigning broadly. Roll out behind a pilot subset first.
#>

[CmdletBinding()]
param(
    [string] $GroupName = "HIPAA - Clinical Endpoints",
    [int]    $InactivityMinutes = 15,
    [switch] $Apply
)

$ErrorActionPreference = 'Stop'
$mode = if ($Apply) { "APPLY" } else { "WHATIF (preview, no changes)" }
Write-Host ("HIPAACOMP-Set-ComplianceBaseline - mode: {0}" -f $mode)

$CompliancePolicyName = "HIPAA Compliance - Clinical Endpoints - Policy"
$CaGateName           = "Require Compliance - Clinical Endpoints - Gate"

$scopes = @("Group.Read.All")
if ($Apply) { $scopes += @("DeviceManagementConfiguration.ReadWrite.All", "Policy.ReadWrite.ConditionalAccess") }

try {
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    if (-not (Get-MgContext)) { Connect-MgGraph -Scopes $scopes -NoWelcome }
}
catch { Write-Error "Microsoft Graph connection failed: $($_.Exception.Message)"; return }

$baseUri  = "https://graph.microsoft.com/v1.0"
$betaUri  = "https://graph.microsoft.com/beta"

# Resolve scope group id
$groupId = $null
try {
    $grp = Invoke-MgGraphRequest -Method GET -Uri ("{0}/groups?`$filter=displayName eq '{1}'&`$select=id,displayName" -f $baseUri, $GroupName)
    if ($grp.value.Count -ge 1) { $groupId = $grp.value[0].id; Write-Host ("Scope group found: {0} ({1})" -f $GroupName, $groupId) }
    else { Write-Warning "Scope group '$GroupName' not found. Create it (Requirement R5). Assignment will be skipped." }
}
catch { Write-Warning "Could not resolve scope group: $($_.Exception.Message)" }

# --- Build compliance policy body (Windows) ---
$compliancePolicy = @{
    "@odata.type"                                 = "#microsoft.graph.windows10CompliancePolicy"
    displayName                                   = $CompliancePolicyName
    description                                   = "Measures HIPAA/HITRUST endpoint safeguards: BitLocker, encryption, firewall, Defender AV + signatures, real-time protection, password/inactivity lock. Targets $GroupName."
    passwordRequired                              = $true
    passwordMinimumLength                         = 8
    passwordMinutesOfInactivityBeforeLock         = $InactivityMinutes
    passwordRequiredType                          = "alphanumeric"
    bitLockerEnabled                              = $true
    secureBootEnabled                             = $true
    codeIntegrityEnabled                          = $true
    storageRequireEncryption                      = $true
    activeFirewallRequired                        = $true
    defenderEnabled                               = $true
    rtpEnabled                                    = $true
    antivirusRequired                             = $true
    antiSpywareRequired                           = $true
    signatureOutOfDate                            = $true
    scheduledActionsForRule = @(
        @{
            ruleName = "PasswordRequired"
            scheduledActionConfigurations = @(
                @{ actionType = "block"; gracePeriodHours = 0 }
            )
        }
    )
}

if (-not $Apply) {
    Write-Host ""
    Write-Host "[WHATIF] Would create compliance policy:" -ForegroundColor Yellow
    Write-Host ("  Name: {0}" -f $CompliancePolicyName)
    Write-Host ("  Measures: BitLocker, SecureBoot, encryption, firewall, Defender AV + signatures, RTP, lock @ {0} min" -f $InactivityMinutes)
    Write-Host ("  Assign to: {0}" -f $GroupName)
} else {
    try {
        $created = Invoke-MgGraphRequest -Method POST -Uri ("{0}/deviceManagement/deviceCompliancePolicies" -f $baseUri) -Body ($compliancePolicy | ConvertTo-Json -Depth 8)
        Write-Host ("[APPLIED] Compliance policy created: {0} (id {1})" -f $CompliancePolicyName, $created.id) -ForegroundColor Green
        if ($groupId) {
            $assignBody = @{ assignments = @( @{ target = @{ "@odata.type" = "#microsoft.graph.groupAssignmentTarget"; groupId = $groupId } } ) } | ConvertTo-Json -Depth 6
            Invoke-MgGraphRequest -Method POST -Uri ("{0}/deviceManagement/deviceCompliancePolicies/{1}/assign" -f $baseUri, $created.id) -Body $assignBody | Out-Null
            Write-Host "[APPLIED] Compliance policy assigned to scope group."
        }
    }
    catch { Write-Warning "Failed to create/assign compliance policy: $($_.Exception.Message)" }
}

# --- Build Conditional Access gate (reportOnly) ---
$caPolicy = @{
    displayName = $CaGateName
    state       = "enabledForReportingButNotEnforced"   # report-only for safe rollout
    conditions  = @{
        applications = @{ includeApplications = @("All") }
        users        = @{ includeUsers = @("All") }
        platforms    = @{ includePlatforms = @("windows") }
        clientAppTypes = @("all")
    }
    grantControls = @{
        operator        = "OR"
        builtInControls = @("compliantDevice")
    }
}

if (-not $Apply) {
    Write-Host ""
    Write-Host "[WHATIF] Would create Conditional Access gate (reportOnly):" -ForegroundColor Yellow
    Write-Host ("  Name: {0}" -f $CaGateName)
    Write-Host "  Grant: Require device marked compliant; platform Windows; state reportOnly"
    Write-Host "  ACTION REQUIRED after create: exclude break-glass account, scope users/apps, validate, then set state=enabled (Implementation Step 9)."
} else {
    try {
        $caCreated = Invoke-MgGraphRequest -Method POST -Uri ("{0}/identity/conditionalAccess/policies" -f $betaUri) -Body ($caPolicy | ConvertTo-Json -Depth 8)
        Write-Host ("[APPLIED] CA gate created in reportOnly: {0} (id {1})" -f $CaGateName, $caCreated.id) -ForegroundColor Green
        Write-Warning "Exclude the break-glass account, scope users/apps, validate in report-only, THEN enable (Implementation Step 9)."
    }
    catch { Write-Warning "Failed to create CA gate: $($_.Exception.Message)" }
}

Write-Host ""
Write-Host "Next: build the configuration baselines (encryption/lock/AV/firewall/patch/access) per Implementation Steps 4-8,"
Write-Host "then validate with HIPAACOMP-Validation.ps1 and produce evidence with HIPAACOMP-Report.ps1."
if (-not $Apply) { Write-Host "No changes made (preview). Re-run with -Apply to create the objects." }
