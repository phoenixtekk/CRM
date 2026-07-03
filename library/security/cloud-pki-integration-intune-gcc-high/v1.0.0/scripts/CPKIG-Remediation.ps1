<#
.SYNOPSIS
    CPKIG-Remediation.ps1 — safely remediate detected certificate-solution gaps on a GCC High tenant (defaults to -WhatIf).
.DESCRIPTION
    PURPOSE
        Remediates the specific, safe gaps this solution can fix on a GCC High tenant: creating the
        pilot group if it is missing, and confirming the pilot-scope assignment of the certificate
        profiles. It DEFAULTS TO -WhatIf (preview only) and makes no change until you re-run with
        -WhatIf:$false. It never installs a connector, never issues or revokes certificates, never
        assigns a profile tenant-wide, and never deletes anything — those are change-controlled human
        actions. Replace the default names only if your objects are named differently.
    HOW TO RUN
        Preview (default, no changes):
          powershell -ExecutionPolicy Bypass -File .\CPKIG-Remediation.ps1
        Apply (after review + change approval):
          powershell -ExecutionPolicy Bypass -File .\CPKIG-Remediation.ps1 -WhatIf:$false

        Required Graph scopes (delegated): Group.ReadWrite.All, Directory.Read.All,
        DeviceManagementConfiguration.Read.All.
        GCC High: connects with Connect-MgGraph -Environment USGov (graph.microsoft.us). Certificate
        profile authoring and connector install remain guided manual steps in intune.microsoft.us.
        For DoD change USGov to USGovDoD.
    EXPECTED RESULTS
        In preview (default): a list of the actions that WOULD be taken, with no change made. With
        -WhatIf:$false: the pilot group is created if missing and the summary reports what changed.
        PASS = actions preview/apply without error. FAIL = wrong cloud or a permission error.
.NOTES
    White-label — the repeatable way. Change tool — defaults to -WhatIf. US Gov Graph endpoints for GCC High.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string] $PilotGroupName   = 'SG-CPKI-Pilot',
    [string] $TrustProfileName = 'Trust-Root-CA',
    [string] $ScepProfileName  = 'SCEP-Device-ClientAuth',
    [ValidateSet('USGov','USGovDoD')]
    [string] $GraphEnvironment = 'USGov'
)

# Default to preview unless the caller explicitly turns -WhatIf off.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

$ErrorActionPreference = 'Stop'

try {
    Connect-MgGraph -Environment $GraphEnvironment -Scopes @('Group.ReadWrite.All','Directory.Read.All','DeviceManagementConfiguration.Read.All') | Out-Null
    $ctx = Get-MgContext
    Write-Host ("Environment : {0}" -f $ctx.Environment)
    if ($ctx.Environment -notin @('USGov','USGovDoD')) {
        Write-Error 'Not connected to a US Gov cloud (GCC High). Aborting remediation. Reconnect with -Environment USGov.'
        return
    }
    if ($WhatIfPreference) { Write-Host 'MODE: PREVIEW (-WhatIf) — no changes will be made.' -ForegroundColor Yellow }
    else                   { Write-Host 'MODE: APPLY — changes WILL be made.' -ForegroundColor Red }
}
catch {
    Write-Error ("Graph connect (US Gov) failed: {0}" -f $_.Exception.Message)
    return
}

# --- Remediation 1: ensure pilot group exists ---
Write-Host ''
Write-Host ("=== Pilot group '{0}' ===" -f $PilotGroupName) -ForegroundColor Cyan
$grp = Get-MgGroup -Filter "displayName eq '$PilotGroupName'" -ConsistencyLevel eventual -CountVariable c -All -ErrorAction SilentlyContinue
if ($grp) {
    Write-Host ("Present (Id {0}) — no action." -f $grp[0].Id) -ForegroundColor Green
}
else {
    if ($PSCmdlet.ShouldProcess($PilotGroupName, 'Create security group')) {
        $mailNick = ($PilotGroupName -replace '[^a-zA-Z0-9]', '')
        New-MgGroup -DisplayName $PilotGroupName -MailEnabled:$false -MailNickname $mailNick `
            -SecurityEnabled:$true -Description 'Cloud PKI / certificate pilot scope (the repeatable way)' | Out-Null
        Write-Host ("Created security group '{0}'." -f $PilotGroupName) -ForegroundColor Green
    }
    else {
        Write-Host ("WOULD create security group '{0}'." -f $PilotGroupName) -ForegroundColor Yellow
    }
}

# --- Remediation 2: pilot-scope assignment of the certificate profiles (guided) ---
Write-Host ''
Write-Host '=== Certificate profile scope (guided) ===' -ForegroundColor Cyan
Write-Host 'This tool does not silently retarget live certificate profiles — an unintended assignment'
Write-Host 'can push certs to the wrong devices. Confirm scope in the portal or via Set-ScopeTargeting.'
foreach ($name in @($TrustProfileName, $ScepProfileName)) {
    if ($PSCmdlet.ShouldProcess($name, "Confirm assignment = $PilotGroupName (manual)")) {
        Write-Host ("APPROVED step: in intune.microsoft.us -> Devices -> Configuration, confirm '{0}' is assigned only to '{1}'." -f $name, $PilotGroupName)
    } else {
        Write-Host ("WOULD prompt you to confirm '{0}' is assigned only to '{1}' (pilot)." -f $name, $PilotGroupName) -ForegroundColor Yellow
    }
}

# --- Guardrails (never auto-done) ---
Write-Host ''
Write-Host '=== Not automated (change-controlled human actions) ===' -ForegroundColor Cyan
Write-Host '  - Installing/updating the Certificate Connector for Microsoft Intune'
Write-Host '  - Creating or editing trusted-root / SCEP / PKCS certificate profiles'
Write-Host '  - Assigning certificate / Wi-Fi / VPN profiles tenant-wide beyond the pilot group'
Write-Host '  - Issuing or revoking certificates'
Write-Host 'These stay manual per change control (see global-requirements-security.md G8).'

Write-Host ''
if ($WhatIfPreference) { Write-Host 'PREVIEW complete — re-run with -WhatIf:$false to apply.' -ForegroundColor Yellow }
else                   { Write-Host 'Remediation complete.' -ForegroundColor Green }
