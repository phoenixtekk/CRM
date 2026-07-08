<#
.SYNOPSIS
    IPPBI-Check-Prereqs.ps1 — Prerequisite/health helper for analytics labeling: modules, connections,
    roles, licensing signals, and label publication (read-only; PASS/GAP per signal).
.DESCRIPTION
    PURPOSE
        Confirms the environment is ready to enable Power BI/Fabric sensitivity labeling: the required
        PowerShell modules and connections, the least-privilege roles (informational), the sensitivity-label
        and Power BI Pro/PPU signals, and whether the sensitivity labels are already published. Read-only.
    HOW TO RUN
        .\IPPBI-Check-Prereqs.ps1
        PowerShell 5.1+/7+. Connect first with Connect-IPPSSession and (optionally)
        Connect-PowerBIServiceAccount. No secret is stored in the script.
    EXPECTED RESULTS
        A PASS/GAP line per signal. GAPs are recorded against the Requirements checklist and remediated
        before configuring. Makes no change.
.NOTES
    Purview — Sensitivity Labeling for Power BI & Fabric. Read-only. Verify your licensing/tenant: AIP
    entitlement + Power BI Pro/PPU (or capacity) are required; confirm in the M365 admin center.
#>
[CmdletBinding()]
param()

function Test-Command([string]$Name) { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }
function Signal([string]$Name, [bool]$Ok, [string]$Detail) {
    if ($Ok) { Write-Host ("PASS  {0} — {1}" -f $Name, $Detail) -ForegroundColor Green }
    else     { Write-Host ("GAP   {0} — {1}" -f $Name, $Detail) -ForegroundColor Yellow }
}

Write-Host "`n=== Power BI/Fabric labeling — prerequisite/health check (read-only) ===" -ForegroundColor Cyan

# Modules
foreach ($m in 'ExchangeOnlineManagement','MicrosoftPowerBIMgmt') {
    $have = [bool](Get-Module -ListAvailable -Name $m)
    Signal ("Module: {0}" -f $m) $have $(if($have){'installed'}else{"install: Install-Module $m -Scope CurrentUser"})
}

# Connections
Signal 'S&C PowerShell connected' (Test-Command 'Get-Label') $(if(Test-Command 'Get-Label'){'Get-Label available'}else{'run Connect-IPPSSession'})
Signal 'Power BI connected'       (Test-Command 'Get-PowerBIWorkspace') $(if(Test-Command 'Get-PowerBIWorkspace'){'Get-PowerBIWorkspace available'}else{'run Connect-PowerBIServiceAccount (optional, for inventory)'})

# Labels published?
if (Test-Command 'Get-Label') {
    $labels = @(Get-Label -ErrorAction SilentlyContinue)
    Signal 'Sensitivity labels exist' ($labels.Count -gt 0) ("{0} label(s) found" -f $labels.Count)
    $policies = @(Get-LabelPolicy -ErrorAction SilentlyContinue)
    Signal 'Label policy published'   ($policies.Count -gt 0) ("{0} label policy(ies) found — confirm one targets BI creators" -f $policies.Count)
} else {
    Signal 'Sensitivity labels exist' $false 'cannot check — connect S&C PowerShell'
}

Write-Host "`nVerify manually (not readable here):" -ForegroundColor Cyan
Write-Host "  [ ] AIP / sensitivity-label entitlement (E5 / E5 Compliance) assigned to in-scope users" -ForegroundColor DarkGray
Write-Host "  [ ] Power BI Pro / PPU (or Premium/Fabric capacity) for in-scope creators/consumers" -ForegroundColor DarkGray
Write-Host "  [ ] Information Protection Admin (Purview) + Power BI/Fabric Administrator roles assigned" -ForegroundColor DarkGray
Write-Host "  [ ] Information-protection tenant settings available in the Power BI/Fabric admin portal" -ForegroundColor DarkGray
Write-Host "`nRecord every GAP against the Requirements checklist before configuring." -ForegroundColor DarkGray
