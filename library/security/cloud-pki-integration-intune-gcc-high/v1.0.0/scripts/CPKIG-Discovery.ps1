<#
.SYNOPSIS
    CPKIG-Discovery.ps1 — inventory certificate connectors and cert profiles on a GCC High tenant (read-only).
.DESCRIPTION
    PURPOSE
        Connects to the US Gov Microsoft Graph endpoint for a GCC High tenant and inventories the
        certificate-management posture: Intune Certificate Connectors, trusted-certificate profiles,
        and SCEP/PKCS certificate profiles. It also confirms Cloud PKI is not being assumed — Cloud
        PKI is not available in GCC High (planned) and not planned for DoD, so this solution uses the
        connector-backed SCEP/PKCS path. Read-only — it changes nothing. Replace the sample group
        name your-pilot-group-name if you use a different pilot group.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CPKIG-Discovery.ps1

        Required Graph scopes (delegated): DeviceManagementConfiguration.Read.All,
        DeviceManagementServiceConfig.Read.All, Directory.Read.All.
        GCC High: this script connects with Connect-MgGraph -Environment USGov (graph.microsoft.us).
        For DoD tenants change USGov to USGovDoD.
    EXPECTED RESULTS
        A connection summary showing Environment = USGov, followed by lists of discovered certificate
        connectors and certificate profiles (trusted-root, SCEP, PKCS). PASS = the environment is
        USGov and discovery completes without error. FAIL = environment is not USGov (wrong cloud) or
        the connection/permission fails.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [string] $PilotGroupName = 'SG-CPKI-Pilot',
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
    $scopes = @('DeviceManagementConfiguration.Read.All','DeviceManagementServiceConfig.Read.All','Directory.Read.All')
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

Write-Section 'Cloud PKI parity reminder'
Write-Host 'Microsoft Cloud PKI is NOT available in GCC High (planned) and NOT planned for DoD.'
Write-Host 'This solution uses the supported path: SCEP/PKCS certificate profiles delivered by the'
Write-Host 'Intune Certificate Connector, anchored to your AD CS CA. See gcc-high-parity-notes.md section 2.'

Write-Section 'Certificate connectors'
try {
    $connectors = Invoke-MgGraphRequest -Method GET -Uri '/v1.0/deviceManagement/certificateConnectorDetails' -ErrorAction Stop
    $items = @($connectors.value)
    if ($items.Count -gt 0) {
        foreach ($c in $items) {
            Write-Host ("- {0} | status: {1} | version: {2} | lastCheckin: {3}" -f `
                $c.displayName, $c.status, $c.connectorVersion, $c.lastConnectionDateTime)
        }
        Write-Host ("Total certificate connectors: {0}" -f $items.Count)
    } else {
        Write-Warning 'No certificate connectors found. SCEP/PKCS issuance requires the Certificate Connector for Microsoft Intune (install from intune.microsoft.us).'
    }
}
catch {
    Write-Warning ("Could not read certificate connectors via Graph: {0}" -f $_.Exception.Message)
    Write-Host 'Review connectors in intune.microsoft.us -> Tenant administration -> Connectors and tokens -> Certificate connectors.'
}

Write-Section 'Certificate profiles (trusted-root / SCEP / PKCS)'
try {
    $configs = Invoke-MgGraphRequest -Method GET -Uri '/v1.0/deviceManagement/deviceConfigurations?$select=id,displayName,@odata.type' -ErrorAction Stop
    $certTypes = @(
        'trustedRootCertificate','scepCertificate','pkcsCertificate',
        'windows81TrustedRootCertificate','windows81SCEPCertificate',
        'androidTrustedRootCertificate','androidScepCertificate',
        'iosTrustedRootCertificate','iosScepCertificate','iosPkcsCertificate',
        'macOSTrustedRootCertificate','macOSScepCertificate','macOSPkcsCertificate',
        'androidWorkProfileTrustedRootCertificate','androidWorkProfileScepCertificate'
    )
    $certProfiles = @($configs.value | Where-Object {
        $t = ($_.'@odata.type' -replace '#microsoft.graph.','')
        $certTypes -contains $t -or $t -match 'TrustedRoot|Scep|Pkcs|SCEP|PKCS'
    })
    if ($certProfiles.Count -gt 0) {
        foreach ($p in $certProfiles) {
            $t = ($p.'@odata.type' -replace '#microsoft.graph.','')
            Write-Host ("- {0}  [{1}]" -f $p.displayName, $t)
        }
        Write-Host ("Total certificate profiles: {0}" -f $certProfiles.Count)
    } else {
        Write-Warning 'No trusted-root/SCEP/PKCS certificate profiles found. Create them per 03-implementation.md.'
    }
}
catch {
    Write-Warning ("Could not read device configuration profiles via Graph: {0}" -f $_.Exception.Message)
    Write-Host 'Review profiles in intune.microsoft.us -> Devices -> Configuration.'
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

Write-Section 'Discovery complete'
Write-Host 'Read-only discovery finished. Compare discovered names against the designed object names'
Write-Host '(SG-CPKI-Pilot; Trust-Root-CA; SCEP-Device-ClientAuth; PKCS-User-ClientAuth).'
