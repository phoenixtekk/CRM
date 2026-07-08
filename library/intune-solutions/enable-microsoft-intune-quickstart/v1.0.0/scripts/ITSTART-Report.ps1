<#
.SYNOPSIS
    ITSTART-Report.ps1 — lists enrolled devices with platform, ownership, management, and compliance.
.DESCRIPTION
    PURPOSE
        Read-only inventory of what has enrolled into Intune — proof the Quick-Start is functioning.
        Optionally exports a CSV.
    HOW TO RUN
        Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All"
        .\ITSTART-Report.ps1 -OutCsv .\quickstart-enrollment.csv
    EXPECTED RESULTS
        A table (and CSV) of enrolled devices. Nothing is changed.
.NOTES
    White-label — Intune Solutions. Read-only.
#>
[CmdletBinding()] param(
    [string]$OutCsv
)
if (-not (Get-MgContext)) { Write-Host 'Not connected. Run Connect-MgGraph first (see .SYNOPSIS).' -ForegroundColor Yellow; return }

$devs = @()
$uri = "v1.0/deviceManagement/managedDevices?`$select=deviceName,operatingSystem,osVersion,managedDeviceOwnerType,managementAgent,complianceState,enrolledDateTime,userPrincipalName,lastSyncDateTime"
do {
    $page = Invoke-MgGraphRequest -Method GET -Uri $uri
    $devs += $page.value
    $uri = $page.'@odata.nextLink'
} while ($uri)

if (-not $devs) { Write-Host 'No enrolled devices yet — enroll a Windows PC and an iPhone (see 05-testing).' -ForegroundColor Yellow; return }

$rows = $devs | ForEach-Object {
    [pscustomobject]@{
        Device     = $_.deviceName
        Platform   = $_.operatingSystem
        OSVersion  = $_.osVersion
        Ownership  = $_.managedDeviceOwnerType
        ManagedBy  = $_.managementAgent
        Compliance = $_.complianceState
        User       = $_.userPrincipalName
        Enrolled   = $_.enrolledDateTime
        LastSync   = $_.lastSyncDateTime
    }
}

Write-Host "`n=== Intune Enrolled Devices ($($rows.Count)) ===" -ForegroundColor Cyan
$rows | Sort-Object Platform, Device | Format-Table Device,Platform,Ownership,ManagedBy,Compliance,User -AutoSize

$byPlat = $rows | Group-Object Platform | ForEach-Object { "$($_.Name)=$($_.Count)" }
Write-Host ("By platform: {0}" -f ([string]::Join('  ', $byPlat))) -ForegroundColor Gray

if ($OutCsv) { $rows | Export-Csv -Path $OutCsv -NoTypeInformation -Encoding UTF8; Write-Host "Exported: $OutCsv" -ForegroundColor Green }
