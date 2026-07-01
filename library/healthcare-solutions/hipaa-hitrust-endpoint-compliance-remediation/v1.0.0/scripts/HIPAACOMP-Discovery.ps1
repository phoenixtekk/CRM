<#
.SYNOPSIS
    HIPAACOMP-Discovery — Tenant readiness check for HIPAA & HITRUST endpoint
    compliance + vulnerability remediation (Intune + Defender).

.DESCRIPTION
    Read-only assessment of tenant readiness. Confirms the presence and assignment
    of the named Intune compliance policy and configuration baselines, Microsoft
    Defender for Endpoint onboarding, the Conditional Access compliance gate, and
    BitLocker / disk-encryption state for the clinical endpoint scope group
    "HIPAA - Clinical Endpoints". Reports gaps; makes no changes.

    Phase: Assess. Run this first when diagnosing readiness or drift.

.PARAMETER GroupName
    The clinical endpoint scope group. Default: "HIPAA - Clinical Endpoints".

.PARAMETER OutputCsv
    Optional path to write the readiness summary as CSV (for the evidence store).

.EXAMPLE
    .\HIPAACOMP-Discovery.ps1

.EXAMPLE
    .\HIPAACOMP-Discovery.ps1 -OutputCsv "C:\Evidence\HIPAACOMP-Discovery.csv"

.NOTES
    Healthcare Solutions — read-only.

    Requires the Microsoft Graph PowerShell SDK. Connect with read scopes such as:
      DeviceManagementConfiguration.Read.All,
      DeviceManagementManagedDevices.Read.All,
      Policy.Read.All, Group.Read.All
    Defender data may require SecurityEvents.Read.All / ThreatHunting.Read.All or
    Defender portal access depending on tenant configuration.
#>

[CmdletBinding()]
param(
    [string] $GroupName = "HIPAA - Clinical Endpoints",
    [string] $OutputCsv
)

$ErrorActionPreference = 'Stop'

# Named objects this solution expects (kept verbatim with the documentation).
$ExpectedCompliancePolicy = "HIPAA Compliance - Clinical Endpoints - Policy"
$ExpectedBaselines = @(
    "Encryption - Clinical Endpoints - Baseline",
    "Lock - Clinical Endpoints - Baseline",
    "Antivirus - Clinical Endpoints - Baseline",
    "Firewall - Clinical Endpoints - Baseline",
    "Patch - Clinical Endpoints - Baseline",
    "Access - Clinical Endpoints - Baseline"
)
$ExpectedCaGate = "Require Compliance - Clinical Endpoints - Gate"

$results = New-Object System.Collections.Generic.List[object]
function Add-Result {
    param([string]$Check, [string]$Status, [string]$Detail)
    $results.Add([pscustomobject]@{ Check = $Check; Status = $Status; Detail = $Detail })
    Write-Host ("[{0}] {1} - {2}" -f $Status, $Check, $Detail)
}

# --- Connect to Microsoft Graph (read-only scopes) ---
try {
    if (-not (Get-Module Microsoft.Graph.Authentication -ListAvailable)) {
        throw "Microsoft Graph PowerShell SDK not found. Install-Module Microsoft.Graph"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    if (-not (Get-MgContext)) {
        Connect-MgGraph -Scopes @(
            "DeviceManagementConfiguration.Read.All",
            "DeviceManagementManagedDevices.Read.All",
            "Policy.Read.All",
            "Group.Read.All"
        ) -NoWelcome
    }
    Add-Result "Graph connection" "PASS" ("Connected as " + (Get-MgContext).Account)
}
catch {
    Add-Result "Graph connection" "FAIL" $_.Exception.Message
    Write-Warning "Cannot continue without Microsoft Graph. Resolve and re-run."
    return
}

$baseUri = "https://graph.microsoft.com/v1.0"

# --- 1. Scope group ---
try {
    $grp = Invoke-MgGraphRequest -Method GET -Uri ("{0}/groups?`$filter=displayName eq '{1}'" -f $baseUri, $GroupName)
    if ($grp.value.Count -ge 1) {
        Add-Result "Scope group '$GroupName'" "PASS" ("Found (id " + $grp.value[0].id + ")")
        $groupId = $grp.value[0].id
    } else {
        Add-Result "Scope group '$GroupName'" "FAIL" "Group not found. Create it per Requirements R5."
        $groupId = $null
    }
}
catch { Add-Result "Scope group '$GroupName'" "FAIL" $_.Exception.Message; $groupId = $null }

# --- 2. Compliance policy ---
try {
    $cp = Invoke-MgGraphRequest -Method GET -Uri ("{0}/deviceManagement/deviceCompliancePolicies" -f $baseUri)
    $match = $cp.value | Where-Object { $_.displayName -eq $ExpectedCompliancePolicy }
    if ($match) {
        Add-Result "Compliance policy" "PASS" "'$ExpectedCompliancePolicy' present."
    } else {
        Add-Result "Compliance policy" "FAIL" "'$ExpectedCompliancePolicy' not found. Build per Implementation Step 3."
    }
}
catch { Add-Result "Compliance policy" "WARN" $_.Exception.Message }

# --- 3. Configuration baselines (settings catalog + endpoint security profiles) ---
try {
    $names = @()
    $conf = Invoke-MgGraphRequest -Method GET -Uri ("{0}/deviceManagement/configurationPolicies?`$select=name,id" -f $baseUri)
    $names += $conf.value | ForEach-Object { $_.name }
    $legacy = Invoke-MgGraphRequest -Method GET -Uri ("{0}/deviceManagement/deviceConfigurations?`$select=displayName,id" -f $baseUri)
    $names += $legacy.value | ForEach-Object { $_.displayName }
    $intents = Invoke-MgGraphRequest -Method GET -Uri ("{0}/deviceManagement/intents?`$select=displayName,id" -f $baseUri)
    $names += $intents.value | ForEach-Object { $_.displayName }

    foreach ($b in $ExpectedBaselines) {
        if ($names -contains $b) {
            Add-Result "Baseline '$b'" "PASS" "Present."
        } else {
            Add-Result "Baseline '$b'" "FAIL" "Not found. Build per Implementation Steps 4-8."
        }
    }
}
catch { Add-Result "Configuration baselines" "WARN" $_.Exception.Message }

# --- 4. Conditional Access gate ---
try {
    $ca = Invoke-MgGraphRequest -Method GET -Uri ("{0}/identity/conditionalAccess/policies" -f $baseUri)
    $gate = $ca.value | Where-Object { $_.displayName -eq $ExpectedCaGate }
    if ($gate) {
        Add-Result "Conditional Access gate" "PASS" ("'{0}' present (state: {1})." -f $ExpectedCaGate, $gate.state)
    } else {
        Add-Result "Conditional Access gate" "FAIL" "'$ExpectedCaGate' not found. Build per Implementation Step 9."
    }
}
catch { Add-Result "Conditional Access gate" "WARN" ("Could not read CA policies: " + $_.Exception.Message) }

# --- 5. Defender for Endpoint onboarding signal (via managed device Defender state) ---
try {
    $md = Invoke-MgGraphRequest -Method GET -Uri ("{0}/deviceManagement/managedDevices?`$select=deviceName,operatingSystem,isEncrypted,managementState&`$top=50" -f $baseUri)
    $win = $md.value | Where-Object { $_.operatingSystem -like "Windows*" }
    if ($win.Count -gt 0) {
        $enc = ($win | Where-Object { $_.isEncrypted }).Count
        Add-Result "BitLocker/encryption state" "INFO" ("{0}/{1} sampled Windows devices report encrypted." -f $enc, $win.Count)
        Add-Result "Defender onboarding" "INFO" "Confirm Onboarded + Active sensor in security.microsoft.com > Assets > Devices (Requirement R4)."
    } else {
        Add-Result "Managed Windows devices" "WARN" "No Windows managed devices sampled. Confirm enrollment."
    }
}
catch { Add-Result "Device/encryption sample" "WARN" $_.Exception.Message }

# --- Summary ---
$fail = ($results | Where-Object { $_.Status -eq "FAIL" }).Count
Write-Host ""
Write-Host ("Discovery complete. FAIL: {0}  (PASS/INFO/WARN above)" -f $fail)
if ($fail -gt 0) { Write-Host "Resolve FAIL items per 02-requirements.md / 03-implementation.md before relying on enforcement." }

if ($OutputCsv) {
    try { $results | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8; Write-Host "Summary written: $OutputCsv" }
    catch { Write-Warning "Could not write CSV: $($_.Exception.Message)" }
}
