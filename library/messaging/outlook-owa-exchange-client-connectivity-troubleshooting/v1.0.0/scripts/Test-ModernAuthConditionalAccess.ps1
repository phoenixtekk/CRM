<#
.SYNOPSIS
  Read-only summary of the Authentication layer for a user: org modern-auth (OAuth), per-user
  auth policy, and - via Microsoft Graph - Conditional Access policies and recent mail-client
  sign-in results.
.DESCRIPTION
  Reports Get-OrganizationConfig OAuth2ClientProfileEnabled and the user's authentication policy
  from Get-CASMailbox (EXO). If Microsoft Graph is available and connected, it lists enabled
  Conditional Access policies and the user's recent sign-ins (client app + CA status) to spot the
  grant a client cannot satisfy. Purely read-only. Populates node D3 and Gate 3.
.EXAMPLE
  .\Test-ModernAuthConditionalAccess.ps1 -UserPrincipalName user@contoso.com
  # Org OAuth + per-user auth policy (EXO only).
.EXAMPLE
  .\Test-ModernAuthConditionalAccess.ps1 -UserPrincipalName user@contoso.com -IncludeGraph
  (EXO V3 module; Microsoft.Graph module for -IncludeGraph. Connect-MgGraph scopes:
   Policy.Read.All, AuditLog.Read.All, Directory.Read.All)
.NOTES
  Expected results: OAuth2ClientProfileEnabled=True and no blocking per-user auth policy; sign-in
  rows showing CA 'success'/'notApplied' for the mail client = PASS. A CA 'failure' row for the
  client app is the root cause for an auth loop (D3.2).
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$UserPrincipalName,

    [Parameter()]
    [switch]$IncludeGraph,

    [Parameter()]
    [int]$SignInLookbackDays = 7
)

function Ensure-ExoConnected {
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        throw "ExchangeOnlineManagement (EXO V3) module not found. Install-Module ExchangeOnlineManagement."
    }
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    try { Get-ConnectionInformation -ErrorAction Stop | Out-Null }
    catch {
        Write-Host "Connecting to Exchange Online (modern auth)..." -ForegroundColor Cyan
        Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop
    }
}

Ensure-ExoConnected

# --- Org modern auth ---
$org = Get-OrganizationConfig -ErrorAction Stop
Write-Host "=== Organization modern auth ===" -ForegroundColor Cyan
Write-Host "OAuth2ClientProfileEnabled : $($org.OAuth2ClientProfileEnabled)"
if (-not $org.OAuth2ClientProfileEnabled) {
    Write-Warning "Modern auth (OAuth) is NOT enabled org-wide - this alone can break Outlook connectivity."
}

# --- Per-user auth policy ---
$cas = Get-CASMailbox -Identity $UserPrincipalName -ErrorAction Stop
Write-Host "=== Per-user auth policy ($UserPrincipalName) ===" -ForegroundColor Cyan
$cas | Select-Object Name,
    @{n='AuthenticationPolicy';e={$_.AuthenticationPolicy}},
    MapiEnabled, EwsEnabled, OWAEnabled, ActiveSyncEnabled | Format-List

# --- Graph: Conditional Access + sign-ins ---
if ($IncludeGraph) {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
        Write-Warning "Microsoft.Graph module not found - skipping CA/sign-in checks. Install-Module Microsoft.Graph."
    }
    else {
        Import-Module Microsoft.Graph.Identity.SignIns -ErrorAction SilentlyContinue
        Import-Module Microsoft.Graph.Reports -ErrorAction SilentlyContinue
        $ctx = $null; try { $ctx = Get-MgContext } catch {}
        if (-not $ctx) {
            Write-Host "Connecting to Microsoft Graph (read-only scopes)..." -ForegroundColor Cyan
            Connect-MgGraph -Scopes 'Policy.Read.All','AuditLog.Read.All','Directory.Read.All' -NoWelcome -ErrorAction Stop
        }

        Write-Host "=== Enabled Conditional Access policies ===" -ForegroundColor Cyan
        try {
            Get-MgIdentityConditionalAccessPolicy -All -ErrorAction Stop |
                Where-Object { $_.State -eq 'enabled' } |
                Select-Object DisplayName, State,
                    @{n='GrantControls';e={ ($_.GrantControls.BuiltInControls) -join ',' }} |
                Format-Table -AutoSize
        } catch { Write-Warning "Could not read CA policies: $($_.Exception.Message)" }

        Write-Host "=== Recent sign-ins ($SignInLookbackDays days) - mail client apps ===" -ForegroundColor Cyan
        $since = (Get-Date).AddDays(-$SignInLookbackDays).ToString('yyyy-MM-ddTHH:mm:ssZ')
        $filter = "userPrincipalName eq '$UserPrincipalName' and createdDateTime ge $since"
        try {
            Get-MgAuditLogSignIn -Filter $filter -Top 50 -ErrorAction Stop |
                Select-Object CreatedDateTime, AppDisplayName, ClientAppUsed,
                    @{n='Status';e={$_.Status.ErrorCode}},
                    @{n='CAResult';e={ ($_.AppliedConditionalAccessPolicies |
                        ForEach-Object { "$($_.DisplayName):$($_.Result)" }) -join '; ' }} |
                Format-Table -AutoSize
        } catch { Write-Warning "Could not read sign-in logs (needs Entra ID P1+ and AuditLog.Read.All): $($_.Exception.Message)" }
    }
}
else {
    Write-Host "Tip: re-run with -IncludeGraph to pull Conditional Access policies + sign-in results for the auth-loop diagnosis (D3.2)." -ForegroundColor DarkGray
}
