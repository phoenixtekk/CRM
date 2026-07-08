<#
.SYNOPSIS
    CLSCUSTOM-Discovery.ps1 — read-only readiness check and custom sensitive-information-type inventory.
.DESCRIPTION
    PURPOSE
        Assesses whether the tenant is ready to build custom sensitive information types (SITs) and
        captures the inventory baseline. Confirms Connect-IPPSSession, the DlpSensitiveInformationType
        cmdlets, and Test-DataClassification are available; inventories existing CUSTOM SITs and rule
        packages (separated from the built-ins) so you do not duplicate one; and writes the
        "Custom SIT Inventory - Evidence" snapshot. Read-only — makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CLSCUSTOM-Discovery.ps1
        powershell -ExecutionPolicy Bypass -File .\CLSCUSTOM-Discovery.ps1 -CsvPath C:\Temp\CustomSIT-Inventory.csv
        Requires the ExchangeOnlineManagement module; connects with Connect-IPPSSession (Security &
        Compliance PowerShell). Sign in with an admin holding a role that can manage sensitive info
        types (e.g. Compliance Administrator / Compliance Data Administrator).
    EXPECTED RESULTS
        A console summary: toolchain OK, the count of built-in vs custom SITs, a list of custom SITs and
        rule packages (the "Custom SIT Inventory - Evidence" snapshot), and a Test-DataClassification
        smoke test. Optional CSV of the custom-SIT inventory.
.NOTES
    Purview — Custom Sensitive Information Types. Read-only. No credentials are stored. The capabilities
    that CONSUME SITs (advanced DLP, auto-labeling, Insider Risk, DSPM) are licensing-dependent and the
    portal/cmdlets evolve — verify availability against your own licensing and tenant.
#>
[CmdletBinding()]
param(
    [string]$CsvPath
)

# --- Connect (Security & Compliance PowerShell) ---
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host 'Installing ExchangeOnlineManagement module...' -ForegroundColor Yellow
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
try {
    Connect-IPPSSession -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
} catch {
    Write-Error "Connect-IPPSSession failed: $($_.Exception.Message). Confirm licensing and your admin role."
    return
}

Write-Host '=== Custom SIT Inventory - Evidence ===' -ForegroundColor Cyan

# --- Sensitive information types: built-in vs custom ---
try {
    $allSits = @(Get-DlpSensitiveInformationType -ErrorAction Stop)
} catch {
    Write-Error "Get-DlpSensitiveInformationType failed: $($_.Exception.Message). Confirm your role can manage sensitive info types."
    return
}

# Publisher 'Microsoft Corporation' identifies built-ins; anything else is custom/tenant-authored.
$builtIn = @($allSits | Where-Object { $_.Publisher -eq 'Microsoft Corporation' })
$custom  = @($allSits | Where-Object { $_.Publisher -ne 'Microsoft Corporation' })

Write-Host ("  Built-in SITs : {0}" -f $builtIn.Count) -ForegroundColor DarkGray
Write-Host ("  Custom  SITs  : {0}" -f $custom.Count) -ForegroundColor Cyan

if ($custom.Count -eq 0) {
    Write-Host '    (no custom SITs yet — clean slate)' -ForegroundColor DarkGray
} else {
    Write-Host '  --- Custom sensitive information types ---' -ForegroundColor Cyan
    foreach ($s in $custom | Sort-Object Name) {
        Write-Host ("    {0}   [publisher: {1}]" -f $s.Name, $s.Publisher)
    }
}

# --- Rule packages (custom SITs are imported as rule packages) ---
Write-Host ''
Write-Host '=== Custom SIT rule packages ===' -ForegroundColor Cyan
try {
    $pkgs = @(Get-DlpSensitiveInformationTypeRulePackage -ErrorAction Stop |
              Where-Object { $_.Name -ne 'Microsoft Rule Package' })
    if ($pkgs.Count -eq 0) {
        Write-Host '  (none — no custom rule packages imported)' -ForegroundColor DarkGray
    } else {
        foreach ($p in $pkgs) { Write-Host ("  - {0}" -f $p.Name) }
    }
} catch {
    Write-Host ("  Could not enumerate rule packages: {0}" -f $_.Exception.Message) -ForegroundColor DarkYellow
}

# --- Test-DataClassification smoke test (proves the validation cmdlet is available) ---
Write-Host ''
Write-Host '=== Toolchain: Test-DataClassification smoke test ===' -ForegroundColor Cyan
try {
    $smoke = Test-DataClassification -TestTextItem 'Sample text with a value 4111 1111 1111 1111' `
                -ClassificationNames 'Credit Card Number' -ErrorAction Stop
    Write-Host '  [OK] Test-DataClassification is available (used by CLSCUSTOM-Validation.ps1).' -ForegroundColor Green
} catch {
    Write-Host ("  [WARN] Test-DataClassification not available: {0}" -f $_.Exception.Message) -ForegroundColor DarkYellow
    Write-Host '         Update ExchangeOnlineManagement and confirm your role/tenant supports it.' -ForegroundColor DarkYellow
}

# --- Optional CSV of the custom-SIT inventory ---
if ($CsvPath) {
    try {
        $custom | Select-Object Name, Publisher, Id |
            Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
        Write-Host ("`nCustom-SIT inventory written to {0}" -f $CsvPath) -ForegroundColor Green
    } catch {
        Write-Warning "Could not write CSV: $($_.Exception.Message)"
    }
}

Write-Host ''
Write-Host 'Discovery complete (read-only). You have the current SIT inventory — design your new SIT (Implementation Step 2) so you do not duplicate an existing one.' -ForegroundColor Cyan
