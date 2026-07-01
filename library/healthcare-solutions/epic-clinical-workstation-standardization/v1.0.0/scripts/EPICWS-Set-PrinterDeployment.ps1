<#
.SYNOPSIS
    EPICWS-Set-PrinterDeployment.ps1 — Generates the per-unit printer deployment (scripted-install or Universal Print plan) and per-unit default.

.DESCRIPTION
    PURPOSE
        Produces the per-unit printer-deployment artifact this solution uses, named to the convention
        "EPIC - Clinical Workstations - Printers - <UNIT>":
          - Mode Script  -> emits a signed-ready PowerShell install script that adds the unit's
                            wristband/script/document printers (from print-server shares or direct IP),
                            in order, and sets <UNIT_DEFAULT_PRINTER> as default. Upload this as an
                            Intune platform script (Implementation Step 9).
          - Mode UniversalPrint -> emits a checklist/plan of the Universal Print shares to select for
                            the unit's printer-deployment policy (Implementation Step 8), including
                            which one to mark default.
        Also (optionally, via Graph) ensures the per-unit Entra device group
        "EPIC - Clinical Workstations - <UNIT>" exists. Supports -WhatIf so you can preview every
        create/emit before it happens. Generates artifacts only; it does not push policy to devices.

    HOW TO RUN
        Preview (no changes/files):
            powershell -ExecutionPolicy Bypass -File .\EPICWS-Set-PrinterDeployment.ps1 -Unit ED -Mode Script -WhatIf
        Emit a scripted-install script for the ED unit:
            .\EPICWS-Set-PrinterDeployment.ps1 -Unit ED -Mode Script `
                -Wristband '\\PRINTSRV\Wristband-ED' -Script '\\PRINTSRV\Script-ED' -Document '\\PRINTSRV\Doc-ED' `
                -DefaultPrinter '\\PRINTSRV\Doc-ED' -OutDir .\out
        Emit a Universal Print selection plan + ensure the unit group:
            .\EPICWS-Set-PrinterDeployment.ps1 -Unit ED -Mode UniversalPrint `
                -Wristband 'UP-Wristband-ED' -Script 'UP-Script-ED' -Document 'UP-Doc-ED' `
                -DefaultPrinter 'UP-Doc-ED' -EnsureGroup

    EXPECTED RESULTS
        Mode Script: a file .\out\EPICWS-InstallPrinters-<UNIT>.ps1 ready to upload as an Intune
        platform script. Mode UniversalPrint: a printed plan of which shares to add (and which is
        default) to the unit's Universal Print printer-deployment policy. With -EnsureGroup the unit
        device group exists. Then complete Implementation Step 8/9/10 and validate.

.NOTES
    Healthcare Solutions. Generates deployment artifacts (and optionally an Entra group via Graph);
    honors -WhatIf. Does NOT install printers on devices or push Intune policy directly. Never captures
    patient data. Printer share paths / IPs / Universal Print share names and the unit default come
    from your print team and Epic mapping (R5/R7) — substitute real values, do not invent them.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory)][string]$Unit,
    [ValidateSet('Script','UniversalPrint')][string]$Mode = 'Script',
    [string]$Wristband,
    [string]$Script,
    [string]$Document,
    [string]$DefaultPrinter,
    [string]$OutDir = '.\out',
    [switch]$EnsureGroup
)

$unitGroup = "EPIC - Clinical Workstations - $Unit"
$policyName = "EPIC - Clinical Workstations - Printers - $Unit"
Write-Host "`n=== EPIC Printer Deployment — Unit: $Unit / Mode: $Mode ===" -ForegroundColor Cyan
Write-Host "Policy/object name: $policyName" -ForegroundColor Cyan

# Optionally ensure the per-unit Entra device group exists.
if ($EnsureGroup) {
    try {
        Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
        Import-Module Microsoft.Graph.Groups -ErrorAction SilentlyContinue
        if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'Group.ReadWrite.All' -NoWelcome }
        $existing = Get-MgGroup -Filter "displayName eq '$unitGroup'" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($existing) { Write-Host "Unit group exists: $unitGroup ($($existing.Id))" -ForegroundColor Green }
        elseif ($PSCmdlet.ShouldProcess($unitGroup, 'Create Entra device group')) {
            $nick = ($unitGroup -replace '[^a-zA-Z0-9]','').ToLower()
            $g = New-MgGroup -DisplayName $unitGroup -Description "Per-unit clinical workstations for printer/default-printer deployment. Standard deployment model." `
                    -MailEnabled:$false -MailNickname $nick -SecurityEnabled:$true
            Write-Host "Created unit group: $unitGroup ($($g.Id))" -ForegroundColor Green
        } else { Write-Host "(WhatIf) Would create unit group: $unitGroup" -ForegroundColor Yellow }
    } catch { Write-Host "Group step skipped/failed (Graph SDK + rights needed): $($_.Exception.Message)" -ForegroundColor Yellow }
}

$ordered = [ordered]@{ Wristband = $Wristband; Script = $Script; Document = $Document }

if ($Mode -eq 'UniversalPrint') {
    Write-Host "`n-- Universal Print selection plan (Implementation Step 8) --" -ForegroundColor Cyan
    Write-Host "In the '$policyName' Universal Print printer-deployment policy, add these shares in order, assigned to '$unitGroup':"
    foreach ($k in $ordered.Keys) {
        $val = $ordered[$k]
        $isDef = ($val -and $val -eq $DefaultPrinter)
        Write-Host ("  [{0,-9}] {1}{2}" -f $k, ($(if ($val) { $val } else { '<not provided — get the Universal Print share name>' })), ($(if ($isDef) { '   <-- mark DEFAULT' } else { '' })))
    }
    if (-not $DefaultPrinter) { Write-Host "  Set <UNIT_DEFAULT_PRINTER> as default for this unit (R7)." -ForegroundColor Yellow }
    return
}

# Mode Script — emit an install script.
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# $policyName")
$lines.Add("# Generated by EPICWS-Set-PrinterDeployment.ps1 for unit '$Unit'. Upload as an Intune platform script (run as system, 64-bit).")
$lines.Add("# Adds the unit's printers in order (wristband -> script -> document) and sets the unit default.")
$lines.Add("`$ErrorActionPreference = 'Stop'")
foreach ($k in $ordered.Keys) {
    $val = $ordered[$k]
    if (-not $val) { $lines.Add("# WARNING: $k printer not provided — add the share/IP from your print team (R5)."); continue }
    if ($val -like '\\*') {
        $lines.Add("Add-Printer -ConnectionName '$val'   # $k")
    } else {
        $portName = "IP_$($val -replace '[^0-9A-Za-z]','_')"
        $lines.Add("if (-not (Get-PrinterPort -Name '$portName' -ErrorAction SilentlyContinue)) { Add-PrinterPort -Name '$portName' -PrinterHostAddress '$val' }   # $k")
        $lines.Add("# Add-Printer -Name '<$k-$Unit>' -DriverName '<SIGNED_DRIVER_NAME>' -PortName '$portName'   # supply driver name (R5)")
    }
}
if ($DefaultPrinter) {
    $lines.Add("(New-Object -ComObject WScript.Network).SetDefaultPrinter('$DefaultPrinter')   # <UNIT_DEFAULT_PRINTER>")
} else {
    $lines.Add("# Set the unit default: (New-Object -ComObject WScript.Network).SetDefaultPrinter('<UNIT_DEFAULT_PRINTER>')   # R7")
}

$outFile = Join-Path $OutDir ("EPICWS-InstallPrinters-$Unit.ps1")
if ($PSCmdlet.ShouldProcess($outFile, 'Write per-unit printer install script')) {
    if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }
    $lines | Set-Content -Path $outFile -Encoding UTF8
    Write-Host "`nWrote install script: $outFile" -ForegroundColor Green
    Write-Host "Upload it at Intune > Devices > Windows > Scripts and remediations > Platform scripts, named '$policyName', assigned to '$unitGroup' (Implementation Step 9)." -ForegroundColor Yellow
} else {
    Write-Host "`n(WhatIf) Would write install script to: $outFile" -ForegroundColor Yellow
    Write-Host "--- preview ---" -ForegroundColor DarkGray
    $lines | ForEach-Object { Write-Host $_ }
}
