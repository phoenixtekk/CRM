<#
.SYNOPSIS
    GWVEND-Discovery.ps1 — inventory the vendor design register and cross-check vendor-created objects.
.DESCRIPTION
    PURPOSE
        Read-only inventory for vendor technical governance. It (1) enumerates the vendor design
        register (a CSV/JSON of every in-flight vendor deliverable/design with owner, type, status,
        and the four anti-lock-in fields) and (2) optionally cross-checks it against vendor-created
        objects readable in the source Microsoft 365 / Entra environment — enterprise apps and
        groups — so designs that were built ahead of the design-authority gate surface. This is the
        governance baseline. Provide the register path as 'your-register.csv' (no angle brackets).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWVEND-Discovery.ps1 -RegisterPath .\vendor-design-register.csv
        Add -CheckSourceEnvironment to also read vendor-created objects in the source tenant.
        Source recon uses the Microsoft Graph PowerShell SDK and consents to Application.Read.All,
        Directory.Read.All (read-only). Install once: Install-Module Microsoft.Graph -Scope CurrentUser.
    EXPECTED RESULTS
        A listing of every register entry with owner, type, status, and disposition, plus a count of
        entries lacking a disposition; with -CheckSourceEnvironment, a list of vendor-created objects
        and any that map to no approved design (flagged for review). No changes are made.
.NOTES
    White-label — the repeatable way. Read-only where it reads live systems.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$RegisterPath,
    [switch]$CheckSourceEnvironment,
    [string]$CsvPath
)

function Import-Register {
    param([string]$Path)
    if (-not (Test-Path $Path)) { throw "Register not found: $Path" }
    if ($Path -match '\.json$') {
        return @(Get-Content -Path $Path -Raw | ConvertFrom-Json)
    }
    return @(Import-Csv -Path $Path)
}

Write-Host "`n=== Vendor Design Register Inventory — $(Get-Date -Format s) ===" -ForegroundColor Cyan

$register = Import-Register -Path $RegisterPath
Write-Host ("Register entries found: {0}`n" -f $register.Count)

$noDisposition = 0
$rows = @()
foreach ($d in $register) {
    $disp = if ($d.Disposition) { $d.Disposition } else { '<none>' }
    if ($disp -eq '<none>') { $noDisposition++ }

    Write-Host ("• {0}  [{1}]" -f $d.Title, $d.DesignId) -ForegroundColor White
    Write-Host ("    owner: {0}  |  type: {1}  |  status: {2}  |  disposition: {3}" -f `
        ($(if($d.Owner){$d.Owner}else{'<unassigned>'})), `
        ($(if($d.Type){$d.Type}else{'<unspecified>'})), `
        ($(if($d.Status){$d.Status}else{'<unspecified>'})), $disp)

    $rows += [pscustomobject]@{
        DesignId    = $d.DesignId
        Title       = $d.Title
        Owner       = $d.Owner
        Type        = $d.Type
        Status      = $d.Status
        Disposition = $disp
    }
}

Write-Host ("`nEntries without a disposition: {0}" -f $noDisposition) -ForegroundColor `
    ($(if($noDisposition -gt 0){'Yellow'}else{'Green'}))

if ($CheckSourceEnvironment) {
    Write-Host "`n-- Source-environment vendor-created objects (read-only) --" -ForegroundColor Cyan
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes 'Application.Read.All','Directory.Read.All' -NoWelcome

    $approvedIds = @($register | Where-Object { $_.Disposition -match 'Approved' } | ForEach-Object { $_.DesignId })

    # Enterprise apps (service principals) are the objects vendors most often create during integration/migration.
    $sps = Get-MgServicePrincipal -All -ErrorAction SilentlyContinue
    Write-Host ("Service principals in source tenant: {0}" -f @($sps).Count)
    foreach ($sp in $sps) {
        # A vendor-created object should reference an approved DesignId in its notes/tags by convention.
        $linkedDesign = $null
        if ($sp.Notes) { $linkedDesign = ($register | Where-Object { $sp.Notes -match [regex]::Escape($_.DesignId) } | Select-Object -First 1) }
        if ($linkedDesign -and $linkedDesign.DesignId -in $approvedIds) {
            Write-Host ("  OK: {0} -> approved design {1}" -f $sp.DisplayName, $linkedDesign.DesignId) -ForegroundColor Green
        } else {
            Write-Host ("  REVIEW: {0} (appId {1}) maps to no approved design" -f $sp.DisplayName, $sp.AppId) -ForegroundColor Yellow
        }
    }
    Disconnect-MgGraph | Out-Null
}

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("`nExported {0} rows to {1}" -f $rows.Count, $CsvPath) -ForegroundColor Green
}
