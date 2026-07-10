<#
.SYNOPSIS
    AWSSSO-Entra-Provisioning.ps1 — GATED helper to create the Entra enterprise
    app and the five AWS-SSO-* security groups for the federation. Previews by
    default; changes only when explicitly confirmed.

.DESCRIPTION
    PURPOSE
        Optional convenience for the Configure stage: creates the five Entra
        security groups (and, if requested, instantiates the AWS IAM Identity
        Center gallery application) so you do not click each one by hand. This
        is the ONLY script in the package that can write to Entra, so it is
        gated: it runs in preview (-WhatIf) mode unless you pass -Apply, and it
        never touches SAML certificates, SCIM tokens, or membership.

    HOW TO RUN
        Install Graph once:
            Install-Module Microsoft.Graph -Scope CurrentUser
        Preview (default — makes NO changes):
            ./AWSSSO-Entra-Provisioning.ps1
        Apply (creates the groups after your explicit confirmation):
            ./AWSSSO-Entra-Provisioning.ps1 -Apply
        Also create the enterprise app instance from the gallery:
            ./AWSSSO-Entra-Provisioning.ps1 -Apply -CreateApp

    EXPECTED RESULTS
        Preview: prints exactly what WOULD be created ([WhatIf]).
        Apply:   creates any missing AWS-SSO-* groups (idempotent — existing
                 groups are left untouched) and reports their object IDs.
        SAML trust, SCIM enablement, and group membership remain MANUAL steps
        (Implementation B4/B5/B6) — this helper does not automate them.

.NOTES
    White-label. Write-gated: preview by default, -Apply required to change.
    Requires Group.ReadWrite.All (and Application.ReadWrite.All with -CreateApp).
    Verify current Graph module and permission behaviour in your tenant.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [switch]$Apply,        # without this, the script only previews
    [switch]$CreateApp,    # also instantiate the gallery enterprise app
    [string]$AppDisplayName = 'AWS IAM Identity Center – Federation – SSO',
    [string[]]$Groups = @(
        'AWS-SSO-Admin-Sandbox-Pilot',
        'AWS-SSO-ReadOnly-AllAccounts',
        'AWS-SSO-PowerUser-Workloads',
        'AWS-SSO-Billing-Management',
        'AWS-SSO-BreakGlass-Emergency'
    )
)

# Default to preview unless -Apply is explicitly supplied.
if (-not $Apply) { $WhatIfPreference = $true; Write-Host "PREVIEW MODE (no -Apply) — nothing will be changed.`n" -ForegroundColor Yellow }

$scopes = @('Group.ReadWrite.All','Directory.Read.All')
if ($CreateApp) { $scopes += 'Application.ReadWrite.All' }

try { Import-Module Microsoft.Graph.Groups, Microsoft.Graph.Applications -ErrorAction Stop }
catch { Write-Error "Microsoft.Graph module not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"; exit 1 }

Connect-MgGraph -Scopes $scopes -NoWelcome

Write-Host "=== AWSSSO Entra provisioning helper — $(Get-Date -Format s) ===`n"

# --- Groups (idempotent) ----------------------------------------------------
foreach ($g in $Groups) {
    $existing = Get-MgGroup -Filter "displayName eq '$g'" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($existing) { Write-Host "[SKIP] Group '$g' already exists ($($existing.Id))."; continue }
    if ($PSCmdlet.ShouldProcess($g, "Create Entra security group")) {
        $mailNick = ($g -replace '[^A-Za-z0-9]','')
        $new = New-MgGroup -DisplayName $g -MailEnabled:$false -MailNickname $mailNick -SecurityEnabled:$true `
                           -Description "Maps to the matching IAM Identity Center permission set (AWS SSO federation)."
        Write-Host "[CREATED] Group '$g' -> $($new.Id)"
    }
}

# --- Optional: instantiate the gallery enterprise app -----------------------
if ($CreateApp) {
    $sp = Get-MgServicePrincipal -Filter "displayName eq '$AppDisplayName'" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($sp) {
        Write-Host "[SKIP] Enterprise app '$AppDisplayName' already exists ($($sp.Id))."
    } elseif ($PSCmdlet.ShouldProcess($AppDisplayName, "Instantiate AWS IAM Identity Center gallery app")) {
        # AWS IAM Identity Center gallery application template id (verify current id for your tenant).
        $templateId = '8b1025e4-1dd2-430b-a150-2ef79cd700f5'
        $inst = Invoke-MgInstantiateApplicationTemplate -ApplicationTemplateId $templateId -DisplayName $AppDisplayName
        Write-Host "[CREATED] Enterprise app '$AppDisplayName'. Now complete SAML (B4) and SCIM (B5) MANUALLY."
    }
}

Write-Host "`nDone. Remember: SAML trust, SCIM enablement, and group membership are MANUAL (Implementation B4/B5/B6)."
if ($WhatIfPreference) { Write-Host "This was a PREVIEW. Re-run with -Apply to create the groups." -ForegroundColor Yellow }
Disconnect-MgGraph | Out-Null
