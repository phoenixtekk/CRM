<#
.SYNOPSIS
    ENTAPPMIG-Discovery.ps1 — inventory AD FS relying parties + Entra apps for migration planning (read-only).
.DESCRIPTION
    PURPOSE
        Builds the migration map: (1) if run on / pointed at an AD FS server, the AD FS relying party trusts
        (identifier, endpoints); (2) the Entra 'AD FS application activity' insight where available;
        (3) existing Entra enterprise applications and their SSO mode; and (4) Application Proxy connector
        groups. Run before you migrate anything to see the starting estate and track progress.
    HOW TO RUN
        On the operator workstation (Entra side):
            powershell -ExecutionPolicy Bypass -File .\ENTAPPMIG-Discovery.ps1 -CsvFolder C:\Temp\entappmig
        Include the AD FS relying-party inventory (run where the ADFS module is available, e.g. an AD FS box):
            .\ENTAPPMIG-Discovery.ps1 -IncludeAdfs -CsvFolder C:\Temp\entappmig
        Requires the Microsoft Graph SDK and the read scopes below; -IncludeAdfs requires the ADFS module.
    EXPECTED RESULTS
        Console tables + optional CSVs for AD FS relying parties, Entra enterprise apps, and connector
        groups. Use them to prioritize the plan by usage and confirm the ENTAPPMIG - * objects as you build.
.NOTES
    White-label — Entra ID Solutions. Read-only. No credentials stored.
.EXAMPLE
    .\ENTAPPMIG-Discovery.ps1 -IncludeAdfs
#>
[CmdletBinding()]
param(
    [switch]$IncludeAdfs,
    [string]$CsvFolder
)

function Save-Csv($rows, $name) {
    if ($CsvFolder -and $rows) {
        if (-not (Test-Path $CsvFolder)) { New-Item -ItemType Directory -Path $CsvFolder | Out-Null }
        $p = Join-Path $CsvFolder "$name.csv"; $rows | Export-Csv -Path $p -NoTypeInformation
        Write-Host "  saved $p" -ForegroundColor Green
    }
}
function Get-AllPages([string]$Uri) { $i=@(); do { $r=Invoke-MgGraphRequest -Method GET -Uri $Uri; $i+=$r.value; $Uri=$r.'@odata.nextLink' } while ($Uri); return $i }

# --- AD FS relying parties (on-prem, optional) --------------------------------
if ($IncludeAdfs) {
    Write-Host "`n=== AD FS relying party trusts (local ADFS module) ===" -ForegroundColor Cyan
    if (Get-Command Get-AdfsRelyingPartyTrust -ErrorAction SilentlyContinue) {
        $rps = Get-AdfsRelyingPartyTrust
        $rpRows = $rps | ForEach-Object {
            [pscustomobject]@{
                Name       = $_.Name
                Identifier = ($_.Identifier -join ';')
                Enabled    = $_.Enabled
                SamlEndpoints = ($_.SamlEndpoints.Location -join ';')
                IssuanceRules = ([bool]$_.IssuanceTransformRules)
            }
        }
        $rpRows | Format-Table -AutoSize
        Save-Csv $rpRows 'adfs-relying-parties'
    } else {
        Write-Host "  ADFS module not found — run -IncludeAdfs on an AD FS server, or export trusts manually." -ForegroundColor Yellow
    }
}

# --- Entra side (Microsoft Graph) ---------------------------------------------
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Application.Read.All','Directory.Read.All','Policy.Read.All' -NoWelcome

Write-Host "`n=== Entra enterprise applications (SSO mode) ===" -ForegroundColor Cyan
$sps = Get-AllPages "/v1.0/servicePrincipals?`$filter=servicePrincipalType eq 'Application'&`$select=id,displayName,preferredSingleSignOnMode,tags,accountEnabled&`$top=999"
$appRows = $sps | ForEach-Object {
    [pscustomobject]@{
        App        = $_.displayName
        SsoMode    = $_.preferredSingleSignOnMode
        Enabled    = $_.accountEnabled
        AppProxy   = [bool](($_.tags -join ',') -match 'WindowsAzureActiveDirectoryOnPremApp|HideApp' )
    }
}
($appRows | Where-Object { $_.SsoMode -or $_.App -like 'ENTAPPMIG*' } | Sort-Object App) | Format-Table -AutoSize
Save-Csv $appRows 'entra-enterprise-apps'

Write-Host "`n=== Application Proxy connector groups ===" -ForegroundColor Cyan
try {
    $cgs = Get-AllPages "/beta/onPremisesPublishingProfiles/applicationProxy/connectorGroups"
    $cgRows = $cgs | ForEach-Object { [pscustomobject]@{ ConnectorGroup=$_.name; Region=$_.region; Connectors=$_.connectorCount } }
    if ($cgRows) { $cgRows | Format-Table -AutoSize } else { Write-Host "  (none)" -ForegroundColor Yellow }
    Save-Csv $cgRows 'appproxy-connector-groups'
} catch { Write-Host "  Could not read connector groups: $($_.Exception.Message)" -ForegroundColor Yellow }

Write-Host "`nTip: Entra portal -> Usage & insights -> AD FS application activity ranks relying parties by usage/readiness." -ForegroundColor DarkGray
Write-Host "Discovery complete." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
