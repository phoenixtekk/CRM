<#
.SYNOPSIS
    IPPBI-Discover.ps1 — Inventory sensitivity labels, publishing policies, Power BI workspaces, and the
    information-protection tenant-setting checklist (read-only).
.DESCRIPTION
    PURPOSE
        Reports the current state for analytics labeling: every sensitivity label and the label policies
        that publish them, the in-scope Power BI/Fabric workspaces, and a printed checklist of the
        information-protection tenant settings to confirm in the Power BI/Fabric admin portal (those
        settings are not fully readable from PowerShell). Read-only — makes no change.
    HOW TO RUN
        .\IPPBI-Discover.ps1
        PowerShell 5.1+/7+. Connect first with Connect-IPPSSession and (optionally)
        Connect-PowerBIServiceAccount for the workspace inventory. No secret is stored in the script.
    EXPECTED RESULTS
        A label/policy inventory, a workspace list, and the tenant-setting checklist — captured into
        'Analytics Scope - Map'. Makes no configuration change.
.NOTES
    Purview — Sensitivity Labeling for Power BI & Fabric. Read-only discovery. Verify your licensing/tenant:
    the information-protection tenant-setting names evolve; confirm them in the admin portal.
#>
[CmdletBinding()]
param()

function Test-Command([string]$Name) { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }

Write-Host "`n=== Sensitivity Labeling for Power BI & Fabric — discovery (read-only) ===" -ForegroundColor Cyan

# --- Labels + policies (Security & Compliance PowerShell) ---
if (Test-Command 'Get-Label') {
    $labels = @(Get-Label -ErrorAction SilentlyContinue)
    Write-Host ("`nSensitivity labels ({0}):" -f $labels.Count) -ForegroundColor Green
    $labels | Select-Object DisplayName, Name, ContentType | Format-Table -AutoSize

    $policies = @(Get-LabelPolicy -ErrorAction SilentlyContinue)
    Write-Host ("Label policies ({0}):" -f $policies.Count) -ForegroundColor Green
    $policies | Select-Object Name, Mode | Format-Table -AutoSize
} else {
    Write-Host "Get-Label not available — run Connect-IPPSSession to include the label inventory." -ForegroundColor Yellow
}

# --- Power BI / Fabric workspaces (read-only) ---
if (Test-Command 'Get-PowerBIWorkspace') {
    try {
        $ws = @(Get-PowerBIWorkspace -Scope Organization -First 5000 -ErrorAction Stop)
        Write-Host ("`nPower BI/Fabric workspaces ({0}):" -f $ws.Count) -ForegroundColor Green
        $ws | Select-Object Name, Id, IsOnDedicatedCapacity | Sort-Object Name | Format-Table -AutoSize
    } catch {
        Write-Host ("Could not read workspaces (need Power BI admin + Connect-PowerBIServiceAccount): {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    }
} else {
    Write-Host "`nGet-PowerBIWorkspace not available — Connect-PowerBIServiceAccount (MicrosoftPowerBIMgmt) to include workspaces." -ForegroundColor DarkGray
}

# --- Tenant-setting checklist (must be confirmed in the admin portal) ---
Write-Host "`nConfirm these in Power BI/Fabric admin portal -> Tenant settings -> Information protection:" -ForegroundColor Cyan
@(
    'Allow users to apply sensitivity labels for content  (scope: BI Labeling - Enabled Users)',
    'Apply sensitivity labels from data sources to their data in Power BI  (source inheritance)',
    'Restrict content with protected labels from unsupported apps / export protections  (export inheritance)',
    'Automatically apply sensitivity labels to downstream content  (where in scope)',
    'Mandatory label policy for Power BI  (leave OFF during pilot)'
) | ForEach-Object { Write-Host ("  [ ] {0}" -f $_) }

Write-Host "`nRecord the label/policy inventory, workspaces, and tenant-setting states in 'Analytics Scope - Map'." -ForegroundColor DarkGray
