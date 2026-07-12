<#
.SYNOPSIS
    EKHYBID-Validate.ps1 — Read-only check that the enablement-lab prerequisites are met.
.DESCRIPTION
    PURPOSE
        Confirm the lab is ready before the guided labs: the Microsoft.Graph module is available, the
        operator can read directory/organization data (read role sufficient), the ActiveDirectory
        (RSAT) module is present for AD-side labs, and licensing (P1/P2/Governance hints) is detected.
        Prints PASS/FAIL per check.
    HOW TO RUN
        .\EKHYBID-Validate.ps1
        Sign in when prompted (read-only scopes). No changes are made.
    EXPECTED RESULTS
        A PASS/FAIL list. AD-module absence is a WARN (AD-side labs become concept-only), not a hard
        fail. Resolve any FAIL before starting the labs.
.NOTES
    White-label. Read-only.
#>
[CmdletBinding()] param()

$ErrorActionPreference = 'Stop'
$fail = 0
function Check($ok,$msg){ if($ok){Write-Host "  PASS  $msg" -ForegroundColor Green}else{Write-Host "  FAIL  $msg" -ForegroundColor Red; $script:fail++} }
function Warn($ok,$msg){ if($ok){Write-Host "  PASS  $msg" -ForegroundColor Green}else{Write-Host "  WARN  $msg" -ForegroundColor Yellow} }

Write-Host "`n=== Hybrid Identity — Lab Prerequisite Validation ===" -ForegroundColor Cyan

$mg = Get-Module Microsoft.Graph -ListAvailable | Select-Object -First 1
Check ($null -ne $mg) ("Microsoft.Graph module installed" + $(if($mg){" (v$($mg.Version))"}else{" — Install-Module Microsoft.Graph"}))

try { Connect-MgGraph -Scopes 'Directory.Read.All','Organization.Read.All','Domain.Read.All' -NoWelcome } catch { Write-Host "Connect-MgGraph failed: $($_.Exception.Message)" -ForegroundColor Red; return }

# Read role sufficient (can we read organization + domains?)
try { $null = Get-MgOrganization; $null = Get-MgDomain -Top 1; Check $true "Directory read access confirmed (Global Reader or higher)" }
catch { Check $false "Directory read access — assign Global Reader ($($_.Exception.Message))" }

# AD module (WARN only)
$ad = Get-Module ActiveDirectory -ListAvailable | Select-Object -First 1
Warn ($null -ne $ad) ("ActiveDirectory (RSAT) module present" + $(if($ad){""}else{" — AD-side labs become concept-only"}))

# Licensing hints
try {
    $plans = (Get-MgSubscribedSku -All).ServicePlans.ServicePlanName
    Warn ($plans -match 'AAD_PREMIUM')    "Entra ID P1 detected (hybrid Conditional Access)"
    Warn ($plans -match 'AAD_PREMIUM_P2') "Entra ID P2 detected (risk-based CA / PIM)"
} catch { Write-Host "  INFO  Could not read SKUs: $($_.Exception.Message)" -ForegroundColor Yellow }

Write-Host ""
if ($fail -eq 0) { Write-Host "All required checks passed — start Lab 1." -ForegroundColor Green }
else { Write-Host "$fail check(s) failed — resolve before starting (see 06-troubleshooting.md)." -ForegroundColor Red }
