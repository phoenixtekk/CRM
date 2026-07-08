<#
.SYNOPSIS
    PURVIEWG-Remediation.ps1 — safely remediate detected Purview gaps on a GCC High tenant (defaults to -WhatIf).
.DESCRIPTION
    PURPOSE
        Remediates the specific, safe gaps this solution can fix on a GCC High tenant: creating the
        pilot group if it is missing, and confirming/normalizing the pilot-scope targeting of the
        label policy. It DEFAULTS TO -WhatIf (preview only) and makes no change until you re-run with
        -WhatIf:$false. It never enables DLP enforcement, never publishes labels tenant-wide, and
        never deletes anything — those are change-controlled human actions. Replace the default names
        only if your objects are named differently.
    HOW TO RUN
        Preview (default, no changes):
          powershell -ExecutionPolicy Bypass -File .\PURVIEWG-Remediation.ps1
        Apply (after review + change approval):
          powershell -ExecutionPolicy Bypass -File .\PURVIEWG-Remediation.ps1 -WhatIf:$false

        Required Graph scopes (delegated): Group.ReadWrite.All, Directory.Read.All.
        GCC High: connects with Connect-MgGraph -Environment USGov (graph.microsoft.us). Label/DLP/
        retention object changes are performed via Security & Compliance PowerShell (GCC High URI) and
        are intentionally left as guided manual steps here. For DoD change USGov to USGovDoD.
    EXPECTED RESULTS
        In preview (default): a list of the actions that WOULD be taken, with no change made. With
        -WhatIf:$false: the pilot group is created if missing and the summary reports what changed.
        PASS = actions preview/apply without error. FAIL = wrong cloud or a permission error.
.NOTES
    White-label — the repeatable way. Change tool — defaults to -WhatIf. US Gov Graph endpoints for GCC High.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]   $PilotGroupName   = 'SG-Purview-Pilot',
    [string]   $LabelPolicyName  = 'LP-Purview-Pilot',
    [ValidateSet('USGov','USGovDoD')]
    [string]   $GraphEnvironment = 'USGov'
)

# Default to preview unless the caller explicitly turns -WhatIf off.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

$ErrorActionPreference = 'Stop'

try {
    Connect-MgGraph -Environment $GraphEnvironment -Scopes @('Group.ReadWrite.All','Directory.Read.All') | Out-Null
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
            -SecurityEnabled:$true -Description 'Purview pilot scope (the repeatable way)' | Out-Null
        Write-Host ("Created security group '{0}'." -f $PilotGroupName) -ForegroundColor Green
    }
    else {
        Write-Host ("WOULD create security group '{0}'." -f $PilotGroupName) -ForegroundColor Yellow
    }
}

# --- Remediation 2: pilot-scope targeting of the label policy (guided) ---
Write-Host ''
Write-Host ("=== Label policy '{0}' scope ===" -f $LabelPolicyName) -ForegroundColor Cyan
Write-Host 'Sensitivity label policy scoping is managed via Security & Compliance PowerShell / the'
Write-Host 'portal in GCC High, not Graph. This tool does not silently retarget a live label policy.'
if ($PSCmdlet.ShouldProcess($LabelPolicyName, "Confirm scope = $PilotGroupName (manual)")) {
    Write-Host ("APPROVED step: in compliance.microsoft.us, confirm '{0}' targets only '{1}'." -f $LabelPolicyName, $PilotGroupName)
} else {
    Write-Host ("WOULD prompt you to confirm '{0}' targets only '{1}' (pilot)." -f $LabelPolicyName, $PilotGroupName) -ForegroundColor Yellow
}
Write-Host 'If retargeting is needed, use: Set-LabelPolicy -Identity "the-label-policy-name" (Security & Compliance PowerShell, GCC High URI).'

# --- Guardrails (never auto-done) ---
Write-Host ''
Write-Host '=== Not automated (change-controlled human actions) ===' -ForegroundColor Cyan
Write-Host '  - Enabling DLP Block/Restrict (enforcement) on DLP-CUI-Baseline'
Write-Host '  - Publishing labels tenant-wide beyond the pilot group'
Write-Host '  - Turning on auto-labeling AL-CUI-ServiceSide outside simulation'
Write-Host '  - Any delete/disposition action'
Write-Host 'These stay manual per change control (see global-requirements-security.md G8).'

Write-Host ''
if ($WhatIfPreference) { Write-Host 'PREVIEW complete — re-run with -WhatIf:$false to apply.' -ForegroundColor Yellow }
else                   { Write-Host 'Remediation complete.' -ForegroundColor Green }
