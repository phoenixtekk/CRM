<#
.SYNOPSIS
    IACINTUNE-Discovery.ps1 — export existing Intune policies to code (baseline) via Microsoft Graph.
.DESCRIPTION
    PURPOSE
        Read-only baseline export for the "Intune-as-Code" solution. Reads existing device
        configuration profiles, compliance policies, and app-protection policies from Microsoft Graph
        and writes each to JSON under -OutputPath. This is your starting point before writing Terraform
        and doubles as your first backup. Makes NO changes to the tenant.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\IACINTUNE-Discovery.ps1 -OutputPath .\baseline
        Requires the Microsoft.Graph PowerShell module. Authenticates as the automation app
        (Connect-MgGraph with the app credential) or interactively with the required scopes.
        *Verify current Microsoft.Graph module versions and whether an endpoint is /beta.*
    EXPECTED RESULTS
        JSON files under .\baseline for configuration, compliance, and app-protection policies, plus a
        printed count per category. No tenant changes.
.NOTES
    White-label. Read-only export. Makes no changes to Intune.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = ".\baseline",
    [string]$TenantId,
    [string]$ClientId,
    [string]$ClientSecret
)

$ErrorActionPreference = 'Stop'
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Write-Warning "Microsoft.Graph module not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

# Connect: app-only if credentials supplied, otherwise interactive (least-privilege read scopes).
if ($ClientId -and $ClientSecret -and $TenantId) {
    $sec = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential($ClientId, $sec)
    Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $cred | Out-Null
} else {
    Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementApps.Read.All' | Out-Null
}

New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null

# Graph endpoints to export. NOTE: some app-protection paths live under /beta — *verify current version*.
$targets = @(
    @{ Name = 'device-configuration'; Uri = 'https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations' }
    @{ Name = 'compliance';           Uri = 'https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies' }
    @{ Name = 'config-policies';      Uri = 'https://graph.microsoft.com/beta/deviceManagement/configurationPolicies' }        # settings catalog — beta *verify*
    @{ Name = 'app-protection-ios';   Uri = 'https://graph.microsoft.com/beta/deviceAppManagement/iosManagedAppProtections' }  # *verify*
    @{ Name = 'app-protection-android'; Uri = 'https://graph.microsoft.com/beta/deviceAppManagement/androidManagedAppProtections' } # *verify*
)

foreach ($t in $targets) {
    try {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $t.Uri
        $items = $resp.value
        $file = Join-Path $OutputPath ("{0}.json" -f $t.Name)
        $items | ConvertTo-Json -Depth 20 | Out-File -FilePath $file -Encoding utf8
        Write-Host ("Exported {0,-22} : {1,4} item(s) -> {2}" -f $t.Name, @($items).Count, $file) -ForegroundColor Green
    } catch {
        Write-Warning ("Export failed for {0}: {1}" -f $t.Name, $_.Exception.Message)
    }
}

Write-Host "`nBaseline export complete. Review the JSON and pick a scoped starter set to codify in main.tf." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
