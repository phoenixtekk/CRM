<#
.SYNOPSIS
    WS1DROID-Set-MigrationRingTargeting.ps1 — build and populate the Android migration ring groups.
.DESCRIPTION
    PURPOSE
        Creates the migration ring Entra security groups (if missing) and populates them from a
        device-to-ring mapping CSV, so app/config/compliance parity artifacts can be assigned per ring and
        cutover proceeds Pilot -> Wave 1 -> Wave 2. Use this to seed the pilot and stage each wave.
    HOW TO RUN
        Preview (default, no changes):
            powershell -ExecutionPolicy Bypass -File .\WS1DROID-Set-MigrationRingTargeting.ps1 -MappingCsv .\ring-mapping.csv
        Apply:
            powershell -ExecutionPolicy Bypass -File .\WS1DROID-Set-MigrationRingTargeting.ps1 -MappingCsv .\ring-mapping.csv -Execute
        The CSV has two columns: 'azureADDeviceId' and 'ring' (Pilot / Wave 1 / Wave 2).
        Group names built: 'Migration Ring – Pilot – Android', 'Migration Ring – Wave 1 – Android',
        'Migration Ring – Wave 2 – Android'.
        Requires the Microsoft Graph SDK and scopes (Group.ReadWrite.All, Device.Read.All).
    EXPECTED RESULTS
        In preview, prints which groups would be created and which devices would be added to which ring.
        With -Execute, creates missing groups and adds the device objects as members; reports per-device.
.NOTES
    Workplace Marketplace — Migrations. Defaults to preview; pass -Execute to make changes.
#>
[CmdletBinding(SupportsShouldProcess = $true)] param(
    [Parameter(Mandatory = $true)][string]$MappingCsv,
    [switch]$Execute
)

if (-not $Execute) { $WhatIfPreference = $true }

if (-not (Test-Path $MappingCsv)) { Write-Host "Mapping CSV not found: $MappingCsv" -ForegroundColor Red; return }
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','Device.Read.All' -NoWelcome

Write-Host "=== Build/populate Android migration ring groups ===" -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host "  PREVIEW MODE — no changes will be made (pass -Execute to apply)." -ForegroundColor Yellow }

$ringGroupName = @{
    'Pilot'  = 'Migration Ring – Pilot – Android'
    'Wave 1' = 'Migration Ring – Wave 1 – Android'
    'Wave 2' = 'Migration Ring – Wave 2 – Android'
}

function Get-OrCreateGroup([string]$name) {
    $g = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$name'").value | Select-Object -First 1
    if ($g) { return $g }
    if ($PSCmdlet.ShouldProcess($name, 'Create security group')) {
        $body = @{
            displayName     = $name
            mailEnabled     = $false
            mailNickname    = ($name -replace '[^a-zA-Z0-9]','')
            securityEnabled = $true
        }
        $g = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($body | ConvertTo-Json)
        Write-Host ("  Created group: {0}" -f $name) -ForegroundColor Green
        return $g
    }
    Write-Host ("  WOULD create group: {0}" -f $name) -ForegroundColor Yellow
    return $null
}

$rows = Import-Csv -Path $MappingCsv
$grouped = $rows | Group-Object ring

foreach ($rg in $grouped) {
    $name = $ringGroupName[$rg.Name]
    if (-not $name) { Write-Host ("  Unknown ring '{0}' — skipping (use Pilot / Wave 1 / Wave 2)." -f $rg.Name) -ForegroundColor Yellow; continue }
    Write-Host ("`n--- {0} ({1} devices) ---" -f $name, $rg.Count) -ForegroundColor Cyan
    $grp = Get-OrCreateGroup $name
    foreach ($row in $rg.Group) {
        $aadDeviceId = $row.azureADDeviceId
        if (-not $aadDeviceId) { continue }
        # Resolve the directory device object id from the Azure AD device id
        $devObj = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/devices?`$filter=deviceId eq '$aadDeviceId'").value | Select-Object -First 1
        if (-not $devObj) { Write-Host ("  {0}: device not found in directory — skipped." -f $aadDeviceId) -ForegroundColor Yellow; continue }
        if (-not $grp) { Write-Host ("  WOULD add {0} to {1}" -f $devObj.displayName, $name) -ForegroundColor Yellow; continue }
        if ($PSCmdlet.ShouldProcess($devObj.displayName, "Add to $name")) {
            try {
                $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$($devObj.id)" }
                Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$($grp.id)/members/`$ref" -Body ($ref | ConvertTo-Json) | Out-Null
                Write-Host ("  Added {0} to {1}" -f $devObj.displayName, $name) -ForegroundColor Green
            } catch { Write-Host ("  {0}: add FAILED — {1}" -f $devObj.displayName, $_.Exception.Message) -ForegroundColor Red }
        }
    }
}

Write-Host "`nAssign the parity/compliance artifacts to these ring groups, then validate with WS1DROID-Validation.ps1." -ForegroundColor Green
Disconnect-MgGraph | Out-Null
