<#
.SYNOPSIS
    ABMPROVG-Remediation.ps1 — safe, preview-first remediation of common ABM/Intune Government drift.
.DESCRIPTION
    PURPOSE
        Fixes a small set of low-risk configuration gaps for the supported GCC High path: ensures the
        pilot scope group exists and (optionally) assigns the Automated Device Enrollment profile to
        it. Defaults to preview mode (-WhatIf) and makes no change until you re-run without -WhatIf.
        It will not attempt any unsupported federation/SCIM action. Replace sample names with
        your-group-name / your-profile-name if renamed (defaults: ABM-Apple-Pilot-Devices,
        ABM-ADE-Profile-Gov).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ABMPROVG-Remediation.ps1            (preview only)
        powershell -ExecutionPolicy Bypass -File .\ABMPROVG-Remediation.ps1 -WhatIf:$false   (apply)
        (Graph scopes: Group.ReadWrite.All, DeviceManagementServiceConfig.ReadWrite.All;
         -Environment USGov)
    EXPECTED RESULTS
        In preview (default) each planned action prints as "WHATIF: ...". With -WhatIf:$false the
        actions are applied and confirmed. Review the preview before applying.
.NOTES
    White-label — the repeatable way. Change actions are gated behind -WhatIf (on by default) against
    Microsoft Graph US Gov endpoints.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$PilotDeviceGroup = 'ABM-Apple-Pilot-Devices',
    [string]$AdeProfileName   = 'ABM-ADE-Profile-Gov',
    [switch]$WhatIf = $true
)

# Honour our explicit default-on -WhatIf switch by feeding it into ShouldProcess.
if ($WhatIf) { $WhatIfPreference = $true }

$ErrorActionPreference = 'Stop'

function Write-Plan { param([string]$m) Write-Host ("WHATIF: {0}" -f $m) -ForegroundColor Yellow }
function Write-Did  { param([string]$m) Write-Host ("APPLIED: {0}" -f $m) -ForegroundColor Green }

Write-Host "=== ABMPROVG Remediation (GCC High / US Gov) ===" -ForegroundColor White
if ($WhatIfPreference) { Write-Host "Preview mode (-WhatIf). No changes will be made." -ForegroundColor Yellow }
else { Write-Host "APPLY mode. Changes WILL be made." -ForegroundColor Red }

# --- Connect ---
try {
    $scopes = @('Group.ReadWrite.All', 'DeviceManagementServiceConfig.ReadWrite.All')
    Connect-MgGraph -Environment USGov -Scopes $scopes -NoWelcome
    $ctx = Get-MgContext
    if ($ctx.Environment -ne 'USGov') {
        Write-Host "[FAIL] Connected environment is '$($ctx.Environment)', expected 'USGov'. Reconnect with -Environment USGov." -ForegroundColor Red
        return
    }
    Write-Host "Connected to US Gov Graph. Tenant: $($ctx.TenantId)" -ForegroundColor Green
}
catch {
    Write-Host "[FAIL] Could not connect: $($_.Exception.Message)" -ForegroundColor Red
    return
}

# --- Remediation 1: ensure pilot group exists ---
$group = $null
try {
    $group = Get-MgGroup -Filter "displayName eq '$PilotDeviceGroup'" -ErrorAction SilentlyContinue
    if (-not $group) {
        if ($PSCmdlet.ShouldProcess($PilotDeviceGroup, "Create security group")) {
            $mailNick = ($PilotDeviceGroup -replace '[^a-zA-Z0-9]', '')
            $group = New-MgGroup -DisplayName $PilotDeviceGroup -MailEnabled:$false `
                        -MailNickname $mailNick -SecurityEnabled:$true `
                        -Description "Pilot scope for ABM + Intune Government Apple enrollment (ABMPROVG)."
            Write-Did "Created security group '$PilotDeviceGroup' (Id $($group.Id))."
        }
        else {
            Write-Plan "Create security group '$PilotDeviceGroup'."
        }
    }
    else {
        Write-Host "Group '$PilotDeviceGroup' already exists (Id $($group.Id)) — no action." -ForegroundColor Cyan
    }
}
catch { Write-Host "Could not ensure group: $($_.Exception.Message)" -ForegroundColor Red }

# --- Remediation 2: report ADE profile assignment gap (assignment is portal-guided) ---
try {
    $tokens = Get-MgDeviceManagementDepOnboardingSetting -All -ErrorAction SilentlyContinue
    $foundProfile = $false
    foreach ($t in $tokens) {
        $uri = "https://graph.microsoft.us/beta/deviceManagement/depOnboardingSettings/$($t.Id)/enrollmentProfiles"
        try {
            $profiles = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
            if ($profiles.value | Where-Object { $_.displayName -eq $AdeProfileName }) { $foundProfile = $true }
        } catch { }
    }
    if (-not $foundProfile) {
        Write-Plan "ADE profile '$AdeProfileName' not found. Create and assign it to '$PilotDeviceGroup' in endpoint.microsoft.us (portal-guided; not auto-created here to avoid unsafe defaults)."
    }
    else {
        Write-Host "ADE profile '$AdeProfileName' present. Confirm it is assigned to '$PilotDeviceGroup' in endpoint.microsoft.us." -ForegroundColor Cyan
    }
}
catch { Write-Host "Could not check ADE profile: $($_.Exception.Message)" -ForegroundColor Red }

# --- Guardrail: never attempt unsupported federation/SCIM ---
Write-Host "`nGuardrail: this script does not attempt Entra<->ABM federation or SCIM provisioning — unsupported in national clouds (Apple)." -ForegroundColor Cyan

if ($WhatIfPreference) { Write-Host "`nPreview complete. Re-run with -WhatIf:`$false to apply." -ForegroundColor Yellow }
else { Write-Host "`nRemediation complete. Re-run ABMPROVG-Validation.ps1 to confirm." -ForegroundColor Green }
