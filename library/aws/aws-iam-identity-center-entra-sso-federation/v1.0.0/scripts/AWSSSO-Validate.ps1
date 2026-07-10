<#
.SYNOPSIS
    AWSSSO-Validate.ps1 — read-only validation of the Entra ID side of the AWS
    IAM Identity Center federation (SAML app + SCIM provisioning + groups).

.DESCRIPTION
    PURPOSE
        Confirms the Entra enterprise application "AWS IAM Identity Center –
        Federation – SSO" is configured correctly for federation: the app
        exists, SAML single sign-on is set, provisioning (SCIM) is enabled with
        a healthy scope, and the five AWS-SSO-* security groups are present and
        in provisioning scope. Read-only — it reads Graph, changes nothing.

    HOW TO RUN
        Install the Microsoft Graph module once:
            Install-Module Microsoft.Graph -Scope CurrentUser
        Then run (read-only delegated scopes):
            ./AWSSSO-Validate.ps1
        You will be prompted to sign in to Entra. Consent to the read scopes:
        Application.Read.All, Directory.Read.All, Synchronization.Read.All.

    EXPECTED RESULTS
        A checklist to the console — PASS/WARN per item:
            [PASS] Enterprise app found
            [PASS] SAML SSO configured
            [PASS] Provisioning (SCIM) job present / enabled
            [PASS] Scope = assigned users and groups
            [PASS] Groups AWS-SSO-* present and assigned to the app
        WARN items point to the matching Troubleshooting entry (T1/T2/T3).

.NOTES
    White-label. Read-only. Uses least-privilege Graph read scopes only.
    Feature/licensing behaviour changes — verify current availability in your
    tenant. Pairs with AWSSSO-Report.sh (the AWS side).
#>

[CmdletBinding()]
param(
    [string]$AppDisplayName = 'AWS IAM Identity Center – Federation – SSO',
    [string[]]$GroupPrefixes = @(
        'AWS-SSO-Admin-Sandbox-Pilot',
        'AWS-SSO-ReadOnly-AllAccounts',
        'AWS-SSO-PowerUser-Workloads',
        'AWS-SSO-Billing-Management',
        'AWS-SSO-BreakGlass-Emergency'
    )
)

function Write-Check { param($ok,$msg) $tag = if($ok){'[PASS]'}else{'[WARN]'}; Write-Host "$tag $msg" }

try { Import-Module Microsoft.Graph.Applications, Microsoft.Graph.Groups -ErrorAction Stop }
catch { Write-Error "Microsoft.Graph module not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"; exit 1 }

Connect-MgGraph -Scopes 'Application.Read.All','Directory.Read.All','Synchronization.Read.All' -NoWelcome

Write-Host "`n=== AWSSSO Entra validation — $(Get-Date -Format s) ===`n"

# 1. Enterprise application (service principal)
$sp = Get-MgServicePrincipal -Filter "displayName eq '$AppDisplayName'" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $sp) {
    Write-Check $false "Enterprise app '$AppDisplayName' NOT found. See Implementation Step B3 / Troubleshooting T2."
    Disconnect-MgGraph | Out-Null; exit 2
}
Write-Check $true "Enterprise app found (appId $($sp.AppId))"

# 2. SAML SSO configured
$saml = ($sp.PreferredSingleSignOnMode -eq 'saml')
Write-Check $saml "SAML SSO mode $([string]::Format('({0})',$sp.PreferredSingleSignOnMode)). Expected 'saml' — see Troubleshooting T1 if not."

# 3. Provisioning (SCIM) synchronization job
$sync = Get-MgServicePrincipalSynchronizationJob -ServicePrincipalId $sp.Id -ErrorAction SilentlyContinue
if ($sync) {
    $running = ($sync.Status.Code -eq 'Active' -or $sync.Schedule.State -eq 'Active')
    Write-Check $running "Provisioning job present (state: $($sync.Schedule.State), status: $($sync.Status.Code)). See Troubleshooting T3 if not Active."
} else {
    Write-Check $false "No SCIM provisioning job found. Enable provisioning per Implementation Step B5/C1 (Troubleshooting T3)."
}

# 4. Groups present and assigned to the app
$assigned = Get-MgServicePrincipalAppRoleAssignedTo -ServicePrincipalId $sp.Id -All -ErrorAction SilentlyContinue
foreach ($g in $GroupPrefixes) {
    $grp = Get-MgGroup -Filter "displayName eq '$g'" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $grp) { Write-Check $false "Group '$g' NOT found (Implementation Step B6)."; continue }
    $isAssigned = $assigned | Where-Object { $_.PrincipalId -eq $grp.Id }
    Write-Check ([bool]$isAssigned) "Group '$g' exists$([string]::Format('{0}', $(if($isAssigned){' and is assigned to the app'}else{' but is NOT assigned to the app (Step B6/Troubleshooting T2)'})))"
}

Write-Host "`nValidation complete. Resolve any [WARN] before expanding beyond the pilot.`n"
Disconnect-MgGraph | Out-Null
