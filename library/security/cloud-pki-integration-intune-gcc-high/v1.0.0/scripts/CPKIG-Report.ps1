<#
.SYNOPSIS
    CPKIG-Report.ps1 — produce a certificate coverage / connector-health report (read-only, GCC High).
.DESCRIPTION
    PURPOSE
        Generates a review-friendly report of the certificate-management posture on a GCC High
        tenant: the certificate connectors and their health/version, the trusted-root and SCEP/PKCS
        certificate profiles and their assignments, and pointers to the issued-certificate data an
        admin should review before expanding. Read-only — it collects and prints, it never changes
        configuration. Writes an optional CSV summary to the path you pass in OutputCsv.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CPKIG-Report.ps1
        powershell -ExecutionPolicy Bypass -File .\CPKIG-Report.ps1 -OutputCsv .\cpkig-report.csv

        Required Graph scopes (delegated): DeviceManagementConfiguration.Read.All,
        DeviceManagementServiceConfig.Read.All, Directory.Read.All.
        GCC High: connects with Connect-MgGraph -Environment USGov (graph.microsoft.us). Issued-certificate
        detail lives in intune.microsoft.us (Devices -> Monitor -> Certificates) and the connector
        Event logs; the report links you there for data Graph does not expose. For DoD change USGov
        to USGovDoD.
    EXPECTED RESULTS
        An on-screen report (and optional CSV) listing connectors, profiles, assignments, and review
        pointers. PASS = report generates and shows connectors plus profile presence. FAIL = wrong
        cloud or a connection/permission error (the report says which).
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [string] $OutputCsv        = '',
    [string] $TrustProfileName = 'Trust-Root-CA',
    [string] $ScepProfileName  = 'SCEP-Device-ClientAuth',
    [string] $PkcsProfileName  = 'PKCS-User-ClientAuth',
    [ValidateSet('USGov','USGovDoD')]
    [string] $GraphEnvironment = 'USGov'
)

$ErrorActionPreference = 'Stop'
$rows = New-Object System.Collections.Generic.List[object]

try {
    Connect-MgGraph -Environment $GraphEnvironment `
        -Scopes @('DeviceManagementConfiguration.Read.All','DeviceManagementServiceConfig.Read.All','Directory.Read.All') | Out-Null
    $ctx = Get-MgContext
    Write-Host ("Environment : {0}" -f $ctx.Environment)
    if ($ctx.Environment -notin @('USGov','USGovDoD')) {
        Write-Error 'Not connected to a US Gov cloud (GCC High). Reconnect with -Environment USGov.'
        return
    }
    Write-Host 'Cloud check PASS — US Gov endpoint.' -ForegroundColor Green
}
catch {
    Write-Error ("Graph connect (US Gov) failed: {0}" -f $_.Exception.Message)
    return
}

Write-Host ''
Write-Host '=== Cloud PKI status (context) ===' -ForegroundColor Cyan
Write-Host 'Cloud PKI is NOT available in GCC High (planned) and NOT planned for DoD. This report'
Write-Host 'covers the supported SCEP/PKCS-via-connector path. See gcc-high-parity-notes.md section 2.'

Write-Host ''
Write-Host '=== Certificate connectors ===' -ForegroundColor Cyan
try {
    $connectors = Invoke-MgGraphRequest -Method GET -Uri '/v1.0/deviceManagement/certificateConnectorDetails' -ErrorAction Stop
    foreach ($c in @($connectors.value)) {
        Write-Host ("- {0} | status: {1} | version: {2} | lastCheckin: {3}" -f $c.displayName, $c.status, $c.connectorVersion, $c.lastConnectionDateTime)
        $rows.Add([pscustomobject]@{ Category='Connector'; Name=$c.displayName; Detail=("status={0}; version={1}" -f $c.status, $c.connectorVersion) })
    }
    if (@($connectors.value).Count -eq 0) { Write-Warning 'No certificate connectors registered.' }
}
catch {
    Write-Warning ("Could not read connectors: {0}" -f $_.Exception.Message)
}

Write-Host ''
Write-Host '=== Certificate profiles & assignments ===' -ForegroundColor Cyan
try {
    $configs = Invoke-MgGraphRequest -Method GET -Uri '/v1.0/deviceManagement/deviceConfigurations?$select=id,displayName,@odata.type' -ErrorAction Stop
    $wanted = @($TrustProfileName, $ScepProfileName, $PkcsProfileName)
    foreach ($p in @($configs.value)) {
        $t = ($p.'@odata.type' -replace '#microsoft.graph.','')
        $isCert = ($t -match 'TrustedRoot|Scep|Pkcs|SCEP|PKCS')
        $named  = ($wanted | Where-Object { $p.displayName -like "$_*" })
        if (-not ($isCert -or $named)) { continue }

        $assignTxt = '(none)'
        try {
            $asg = Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/deviceManagement/deviceConfigurations/{0}/assignments" -f $p.id) -ErrorAction Stop
            $groupIds = @($asg.value | ForEach-Object { $_.target.groupId } | Where-Object { $_ })
            if ($groupIds.Count -gt 0) { $assignTxt = ($groupIds -join ', ') }
        } catch { $assignTxt = '(assignment read failed)' }

        Write-Host ("- {0}  [{1}]  assigned: {2}" -f $p.displayName, $t, $assignTxt)
        $rows.Add([pscustomobject]@{ Category='Profile'; Name=$p.displayName; Detail=("type={0}; assigned={1}" -f $t, $assignTxt) })
    }
}
catch {
    Write-Warning ("Could not read profiles/assignments: {0}" -f $_.Exception.Message)
}

Write-Host ''
Write-Host '=== Review pointers (data not in Graph) ===' -ForegroundColor Cyan
Write-Host '- Issued certificates: intune.microsoft.us -> Devices -> Monitor -> Certificates.'
Write-Host '- Connector issuance/revocation events: server Event Viewer -> Applications and Services'
Write-Host '  Logs -> Microsoft -> Intune -> Certificate Connectors (SCEP 4xxx, PKCS 1xxx, Revoke 3xxx).'

if ($OutputCsv) {
    try { $rows | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8; Write-Host ("`nCSV written: {0}" -f $OutputCsv) -ForegroundColor Green }
    catch { Write-Warning ("Could not write CSV: {0}" -f $_.Exception.Message) }
}

Write-Host ''
Write-Host 'Report complete (read-only).' -ForegroundColor Green
