<#
.SYNOPSIS
    GWCONSOL-Discovery.ps1 — Read-only collaboration + AI estate/redundancy inventory for consolidation.
.DESCRIPTION
    PURPOSE
        Produces the consolidation baseline for a Collaboration & AI Platform Consolidation Strategy
        engagement. Uses Microsoft Graph to inventory the discoverable legacy Microsoft estate the
        strategy must retire or map: the tenant, the wave-scope targeting groups (named "Consolidation
        Wave Scope - ..."), the subscribed SKUs / licence footprint (mail, Teams, SharePoint/OneDrive,
        Copilot/AI), and managed devices. It also records placeholders for the non-discoverable context
        (third-party collaboration/AI apps, contracts) the analyst captures manually. The output CSV is
        the read-only baseline that drives the current-vs-target estate map and the roadmap sequencing.
        Google Workspace / Gemini target-side details are captured in the Google Admin console per
        Google documentation; Gemini preview capabilities are verified in your tenant, not assumed.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWCONSOL-Discovery.ps1
        Required Graph scopes (read-only): Organization.Read.All, Group.Read.All, Directory.Read.All,
        Device.Read.All, DeviceManagementManagedDevices.Read.All. A global-reader / read-only admin is
        sufficient. Install once: Install-Module Microsoft.Graph -Scope CurrentUser
    EXPECTED RESULTS
        A CSV (default ".\Consolidation Current State - Platform - Discovery.csv") with one row per
        discovered object (Area, ObjectType, Name, Detail) plus manual-capture rows for third-party
        apps and contracts, and a console summary by area. No changes are made to any tenant — this
        script is strictly read-only (PASS = it completes and writes the baseline CSV).
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>

[CmdletBinding()]
param(
    [string]$OutputCsv = ".\Consolidation Current State - Platform - Discovery.csv",
    [string]$GroupNamePrefix = "Consolidation Wave Scope"
)

$ErrorActionPreference = 'Stop'
$results = New-Object System.Collections.Generic.List[object]

function Add-Item {
    param($Area, $Type, $Name, $Detail = '')
    $results.Add([pscustomobject]@{
        Area       = $Area
        ObjectType = $Type
        Name       = $Name
        Detail     = $Detail
    })
}

# Substrings that flag a SKU as a consolidation-relevant (legacy) collaboration/AI capability.
$legacyHints = 'EXCHANGE','TEAMS','SHAREPOINT','ONEDRIVE','COPILOT','OFFICE','VIVA','M365','O365'

Write-Host "=== Collaboration & AI estate discovery (read-only, Microsoft Graph) ===" -ForegroundColor Cyan

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
# Read-only scopes only.
Connect-MgGraph -Scopes @(
    "Organization.Read.All",
    "Group.Read.All",
    "Directory.Read.All",
    "Device.Read.All",
    "DeviceManagementManagedDevices.Read.All"
) -NoWelcome

# --- Tenant / identity control plane ---
try {
    $org = Get-MgOrganization -ErrorAction Stop | Select-Object -First 1
    Add-Item -Area 'Identity' -Type 'Tenant' -Name $org.DisplayName `
             -Detail ("TenantId={0}" -f $org.Id)
} catch {
    Write-Warning "Could not read organization: $($_.Exception.Message)"
}

# --- Wave-scope targeting groups (the named Consolidation groups) ---
Write-Host "Enumerating wave-scope targeting groups..."
try {
    $groups = Get-MgGroup -Filter "startswith(displayName,'$GroupNamePrefix')" -All -ErrorAction Stop
    if (-not $groups) {
        Add-Item -Area 'Identity' -Type 'WaveScopeGroup' -Name '(none found)' `
                 -Detail "No groups starting with '$GroupNamePrefix' - build with GWCONSOL-Set-ScopeTargeting.ps1"
    }
    foreach ($g in $groups) {
        $count = (Get-MgGroupMember -GroupId $g.Id -All -ErrorAction SilentlyContinue).Count
        Add-Item -Area 'Identity' -Type 'WaveScopeGroup' -Name $g.DisplayName `
                 -Detail ("Members={0}; Id={1}" -f $count, $g.Id)
    }
} catch {
    Write-Warning "Group enumeration failed: $($_.Exception.Message)"
}

# --- Licence / SKU footprint (the legacy collaboration + AI estate to consolidate) ---
Write-Host "Summarizing subscribed SKUs (licence footprint)..."
try {
    $skus = Get-MgSubscribedSku -All -ErrorAction Stop
    foreach ($s in $skus) {
        $partNo   = $s.SkuPartNumber
        $consumed = $s.ConsumedUnits
        $enabled  = $s.PrepaidUnits.Enabled
        $isLegacy = $false
        foreach ($h in $legacyHints) { if ($partNo -match $h) { $isLegacy = $true; break } }
        $area = if ($isLegacy) { 'Legacy estate (candidate)' } else { 'Licensing' }
        Add-Item -Area $area -Type 'SubscribedSku' -Name $partNo `
                 -Detail ("Assigned={0}; Enabled={1}; ConsolidationCandidate={2}" -f $consumed, $enabled, $isLegacy)
    }
} catch {
    Write-Warning "SKU read failed (Directory.Read.All?): $($_.Exception.Message)"
    Add-Item -Area 'Licensing' -Type 'SubscribedSku' -Name '(unavailable)' `
             -Detail "Could not read subscribed SKUs - confirm Directory.Read.All (R4)"
}

# --- Managed devices (management-surface footprint) ---
Write-Host "Summarizing managed devices..."
try {
    $devices = Get-MgDeviceManagementManagedDevice -All -ErrorAction Stop
    $total     = $devices.Count
    $compliant = ($devices | Where-Object { $_.ComplianceState -eq 'compliant' }).Count
    Add-Item -Area 'Endpoints' -Type 'ManagedDeviceSummary' -Name 'All managed devices' `
             -Detail ("Total={0}; Compliant={1}" -f $total, $compliant)
} catch {
    Write-Warning "Managed device read failed (Intune licensing/scope?): $($_.Exception.Message)"
    Add-Item -Area 'Endpoints' -Type 'ManagedDeviceSummary' -Name '(unavailable)' `
             -Detail "Could not read managed devices - confirm Intune + scope"
}

Disconnect-MgGraph | Out-Null

# --- Manual-capture placeholders (not discoverable via Graph) ---
Add-Item -Area 'Estate (manual)' -Type 'ThirdPartyCollabApp' -Name '(capture manually)' -Detail 'Record any third-party collaboration app to be unified/retired'
Add-Item -Area 'Estate (manual)' -Type 'ThirdPartyAIApp'     -Name '(capture manually)' -Detail 'Record any third-party AI/assistant app in use vs the Gemini target'
Add-Item -Area 'Estate (manual)' -Type 'ContractRenewal'     -Name '(capture manually)' -Detail 'Record M365/Copilot contract renewal/true-up dates for savings timing'
Add-Item -Area 'Estate (manual)' -Type 'RetainedException'   -Name '(capture manually)' -Detail 'Record any system kept as a justified retained exception + review date'

# --- Export + summary ---
$results | Sort-Object Area, ObjectType, Name | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
Write-Host ("`nExported {0} rows to {1}" -f $results.Count, $OutputCsv) -ForegroundColor Green
Write-Host "`n=== Summary by area ===" -ForegroundColor Cyan
$results | Group-Object Area | ForEach-Object {
    Write-Host ("  {0,-26} Rows={1}" -f $_.Name, $_.Count)
}
Write-Host "`nNote: Google Workspace/Gemini target state is captured in the Google Admin console per Google docs; capture the 'Estate (manual)' rows by hand." -ForegroundColor Yellow
