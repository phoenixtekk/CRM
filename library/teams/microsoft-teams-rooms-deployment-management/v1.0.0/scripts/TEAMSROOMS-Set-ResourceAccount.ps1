<#
.SYNOPSIS
    TEAMSROOMS-Set-ResourceAccount — Create and configure a Microsoft Teams Rooms
    resource account: room mailbox, enable + usage location, non-expiring password,
    and Teams Rooms license. SAFE BY DEFAULT — dry-run unless -Commit is passed.

.DESCRIPTION
    Ensures a room resource account is provisioned to the Teams Rooms standard:
      1. a room mailbox (RecipientTypeDetails = RoomMailbox) exists in Exchange Online,
      2. the Entra account is enabled and has a UsageLocation,
      3. the password is set NOT to expire (a room signs in unattended),
      4. a Teams Rooms license (resolved from Get-MgSubscribedSku) is assigned.
    Without -Commit the script only REPORTS the actions it would take (-WhatIf style).
    No credentials are stored in this script; the room password is supplied at runtime
    as a SecureString and should come from your privileged secrets vault.

.PARAMETER Upn
    UPN / primary SMTP of the room account, e.g. room-boardroom-a@contoso.com.

.PARAMETER DisplayName
    Display name, e.g. "Room Account - Boardroom-A - Pilot".

.PARAMETER UsageLocation
    ISO country code for licensing, e.g. "US".

.PARAMETER SkuPartNumber
    The Teams Rooms SKU part number to assign (VERIFY in your tenant via
    Get-MgSubscribedSku), e.g. "Microsoft_Teams_Rooms_Pro".

.PARAMETER RoomPassword
    SecureString password of record for the room account (supply from your vault).
    Required only when creating a new mailbox with -Commit.

.PARAMETER Commit
    Actually perform the changes. Omit for a dry run (default).

.EXAMPLE
    .\TEAMSROOMS-Set-ResourceAccount.ps1 -Upn room-boardroom-a@contoso.com `
        -DisplayName "Room Account - Boardroom-A - Pilot" -UsageLocation US `
        -SkuPartNumber Microsoft_Teams_Rooms_Pro   # dry run — shows planned actions

.EXAMPLE
    $pw = Read-Host -AsSecureString "Room password of record"
    .\TEAMSROOMS-Set-ResourceAccount.ps1 -Upn room-boardroom-a@contoso.com `
        -DisplayName "Room Account - Boardroom-A - Pilot" -UsageLocation US `
        -SkuPartNumber Microsoft_Teams_Rooms_Pro -RoomPassword $pw -Commit
    (PowerShell 5.1+/7+; ExchangeOnlineManagement + Microsoft.Graph;
     Connect-ExchangeOnline, Connect-MgGraph -Scopes User.ReadWrite.All,Organization.Read.All)

.NOTES
    Expected results: dry-run prints each step as [WHATIF]; with -Commit each step
    prints [OK]. Verify with TEAMSROOMS-Validation.ps1 afterward. SKU is resolved at
    runtime — never hardcode a SkuId.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Upn,
    [Parameter(Mandatory)][string]$DisplayName,
    [Parameter(Mandatory)][string]$UsageLocation,
    [Parameter(Mandatory)][string]$SkuPartNumber,
    [Parameter(Mandatory = $false)][securestring]$RoomPassword,
    [Parameter(Mandatory = $false)][switch]$Commit
)

$ErrorActionPreference = 'Stop'
$tag = if ($Commit) { '[OK]     ' } else { '[WHATIF] ' }

function Assert-Module {
    param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][string]$Install)
    if (-not (Get-Module -ListAvailable -Name $Name)) { throw "$Name not installed. Run: $Install" }
    Import-Module $Name -ErrorAction Stop
}

Assert-Module -Name ExchangeOnlineManagement -Install "Install-Module ExchangeOnlineManagement -Scope CurrentUser"
Assert-Module -Name Microsoft.Graph          -Install "Install-Module Microsoft.Graph -Scope CurrentUser"
if (-not (Get-ConnectionInformation -ErrorAction SilentlyContinue)) { Connect-ExchangeOnline -ShowBanner:$false | Out-Null }
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes "User.ReadWrite.All","Organization.Read.All" | Out-Null }

if (-not $Commit) { Write-Host "DRY RUN — no changes will be made. Re-run with -Commit to apply.`n" -ForegroundColor Yellow }

# --- 1. Room mailbox ---
$existing = Get-Mailbox -Identity $Upn -ErrorAction SilentlyContinue
if ($existing) {
    if ($existing.RecipientTypeDetails -ne 'RoomMailbox') {
        Write-Warning "$Upn exists but is $($existing.RecipientTypeDetails), not RoomMailbox. Stopping."
        return
    }
    Write-Host "[SKIP]   Room mailbox already exists: $Upn" -ForegroundColor DarkGray
} else {
    Write-Host "$tag Create room mailbox '$DisplayName' ($Upn)" -ForegroundColor Cyan
    if ($Commit) {
        if (-not $RoomPassword) { throw "Creating a mailbox requires -RoomPassword (SecureString from your vault)." }
        New-Mailbox -Name $DisplayName -Alias ($Upn.Split('@')[0]) `
            -MicrosoftOnlineServicesID $Upn -Room -Password $RoomPassword | Out-Null
    }
}

# --- 2. Enable + usage location ---
$mgu = $null
if ($Commit -or $existing) { $mgu = Get-MgUser -UserId $Upn -Property Id,AccountEnabled,UsageLocation,PasswordPolicies -ErrorAction SilentlyContinue }
Write-Host "$tag Enable account and set UsageLocation=$UsageLocation" -ForegroundColor Cyan
if ($Commit -and $mgu) { Update-MgUser -UserId $mgu.Id -AccountEnabled -UsageLocation $UsageLocation }

# --- 3. Password never expires ---
Write-Host "$tag Set PasswordPolicies = DisablePasswordExpiration (unattended sign-in)" -ForegroundColor Cyan
if ($Commit -and $mgu) { Update-MgUser -UserId $mgu.Id -PasswordPolicies "DisablePasswordExpiration" }

# --- 4. License ---
$sku = Get-MgSubscribedSku -All | Where-Object { $_.SkuPartNumber -eq $SkuPartNumber }
if (-not $sku) {
    Write-Warning "SKU '$SkuPartNumber' not found in tenant. Run Get-MgSubscribedSku | Select SkuPartNumber to find the correct Teams Rooms SKU."
} else {
    $avail = $sku.PrepaidUnits.Enabled - $sku.ConsumedUnits
    Write-Host "$tag Assign license $SkuPartNumber (available seats: $avail)" -ForegroundColor Cyan
    if ($Commit -and $mgu) { Set-MgUserLicense -UserId $mgu.Id -AddLicenses @{ SkuId = $sku.SkuId } -RemoveLicenses @() | Out-Null }
}

$state = if ($Commit) { 'Changes applied' } else { 'Dry run only' }
Write-Host "`nDone. $state. Next: TEAMSROOMS-Set-RoomPolicy.ps1, then TEAMSROOMS-Validation.ps1." -ForegroundColor Green
