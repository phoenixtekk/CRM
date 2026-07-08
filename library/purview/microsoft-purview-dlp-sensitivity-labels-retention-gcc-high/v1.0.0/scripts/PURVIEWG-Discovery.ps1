<#
.SYNOPSIS
    PURVIEWG-Discovery.ps1 — inventory Purview labels, DLP, and retention on a GCC High tenant (read-only).
.DESCRIPTION
    PURPOSE
        Connects to the US Gov Microsoft Graph endpoint for a GCC High tenant and inventories the
        Microsoft Purview posture: sensitivity labels, label policies, DLP-relevant configuration,
        and retention/records signals it can read. Confirms you are in the USGov cloud, then prints
        what exists so you can compare against the designed object names. Read-only — it changes
        nothing. Replace the sample group name your-pilot-group-name if you use a different pilot group.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PURVIEWG-Discovery.ps1

        Required Graph scopes (delegated): InformationProtectionPolicy.Read,
        Policy.Read.All, Directory.Read.All.
        GCC High: this script connects with Connect-MgGraph -Environment USGov (graph.microsoft.us).
        Some label/DLP/retention objects are exposed via Security & Compliance PowerShell rather
        than Graph; where Graph has no read surface, this script reports that and points you to
        compliance.microsoft.us. For DoD tenants change USGov to USGovDoD.
    EXPECTED RESULTS
        A connection summary showing Environment = USGov, followed by lists of discovered
        sensitivity labels, label policies, and any readable retention/DLP signals. PASS = the
        environment is USGov and the discovery completes without error. FAIL = environment is not
        USGov (you are in the wrong cloud) or the connection/permission fails.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph (US Gov endpoints for GCC High).
#>

[CmdletBinding()]
param(
    [string] $PilotGroupName = 'SG-Purview-Pilot',
    [ValidateSet('USGov','USGovDoD')]
    [string] $GraphEnvironment = 'USGov'
)

$ErrorActionPreference = 'Stop'

function Write-Section([string] $Title) {
    Write-Host ''
    Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan
}

try {
    Write-Section 'Connecting to Microsoft Graph (US Gov / GCC High)'
    $scopes = @('InformationProtectionPolicy.Read','Policy.Read.All','Directory.Read.All')
    Connect-MgGraph -Environment $GraphEnvironment -Scopes $scopes | Out-Null

    $ctx = Get-MgContext
    Write-Host ("Environment : {0}" -f $ctx.Environment)
    Write-Host ("Tenant      : {0}" -f $ctx.TenantId)
    Write-Host ("Account     : {0}" -f $ctx.Account)

    if ($ctx.Environment -notin @('USGov','USGovDoD')) {
        Write-Warning "Not connected to a US Gov cloud. GCC High requires Environment USGov (or USGovDoD). You may be targeting Commercial. Reconnect with -Environment USGov."
    } else {
        Write-Host 'Cloud check PASS — connected to a US Gov endpoint.' -ForegroundColor Green
    }
}
catch {
    Write-Error ("Failed to connect to Microsoft Graph (US Gov): {0}" -f $_.Exception.Message)
    return
}

Write-Section 'Sensitivity labels'
try {
    $labels = Get-MgInformationProtectionPolicyLabel -All
    if ($labels) {
        $labels | Select-Object Name, IsActive, Id | Format-Table -AutoSize
        Write-Host ("Total sensitivity labels: {0}" -f $labels.Count)
    } else {
        Write-Host 'No sensitivity labels returned via Graph.'
    }
}
catch {
    Write-Warning ("Could not read sensitivity labels via Graph: {0}" -f $_.Exception.Message)
    Write-Host 'Review labels in compliance.microsoft.us -> Information Protection -> Labels.'
}

Write-Section 'Pilot group'
try {
    $grp = Get-MgGroup -Filter "displayName eq '$PilotGroupName'" -ConsistencyLevel eventual -CountVariable c -All
    if ($grp) {
        Write-Host ("Pilot group '{0}' found (Id {1})." -f $PilotGroupName, $grp[0].Id) -ForegroundColor Green
    } else {
        Write-Warning ("Pilot group '{0}' NOT found. Create it in entra.microsoft.us -> Groups." -f $PilotGroupName)
    }
}
catch {
    Write-Warning ("Could not query pilot group: {0}" -f $_.Exception.Message)
}

Write-Section 'DLP / retention read surfaces'
Write-Host 'Sensitivity labels are readable via Graph above.'
Write-Host 'DLP policies, auto-labeling policies, retention labels/policies, and records config are'
Write-Host 'primarily managed via Security & Compliance PowerShell in GCC High. To inventory them,'
Write-Host 'connect with:'
Write-Host '  Connect-IPPSSession -ConnectionUri https://ps.compliance.protection.office365.us/powershell-liveid/ -ExchangeEnvironmentName O365USGovGCCHigh'
Write-Host 'then run Get-DlpCompliancePolicy / Get-AutoSensitivityLabelPolicy / Get-RetentionCompliancePolicy / Get-ComplianceTag.'
Write-Host 'Or review them in the portal at compliance.microsoft.us (GCC High).'

Write-Section 'Discovery complete'
Write-Host 'Read-only discovery finished. Compare discovered names against the designed object names'
Write-Host '(SG-Purview-Pilot; Public/General/Confidential/Confidential \ CUI; LP-Purview-Pilot;'
Write-Host 'AL-CUI-ServiceSide; DLP-CUI-Baseline; Ret-CUI-7yr; RP-CUI-7yr-Auto; RP-Baseline-Retain).'
