<#
.SYNOPSIS
  Read-only scope/health helper: resolves which hygiene policy applies to a user (policy precedence),
  lists preset scope and custom policy priorities, and reports connection-filter / Enhanced-Filtering
  state. Answers "why did this user get this verdict?".
.DESCRIPTION
  Connects with Exchange Online PowerShell (EXO V3). Given a user, walks the enabled anti-spam,
  anti-malware, anti-phish (and Safe Links/Attachments if licensed) RULES in priority order and
  reports the FIRST matching policy of each type (which is the one that applies), plus the preset
  security policy scope. Also reports the connection filter policy and Enhanced Filtering for
  Connectors (skip listing). Makes NO changes.
.EXAMPLE
  .\Get-MailHygieneScopeHealth.ps1 -User user@contoso.com
  # Read-only. Connect first with Connect-ExchangeOnline.
  # (PowerShell 5.1+/7+, ExchangeOnlineManagement module)
.NOTES
  Expected results: the effective policy per filter type for the user, preset scope, priorities, and
  connector-filtering state. Nothing is modified.
#>
[CmdletBinding()]
param(
    [string]$User
)

try { Get-OrganizationConfig -ErrorAction Stop | Out-Null }
catch { throw "Not connected. Run Connect-ExchangeOnline first." }

# Resolve the user's group memberships (for -SentToMemberOf matching), best-effort.
$userGroups = @()
if ($User) {
    try {
        $rcpt = Get-Recipient -Identity $User -ErrorAction Stop
        # Group membership resolution is best-effort; report distribution groups the user belongs to.
        $userGroups = (Get-Recipient -Filter "Members -eq '$($rcpt.DistinguishedName)'" -ErrorAction SilentlyContinue).PrimarySmtpAddress
    } catch { Write-Warning "Could not fully resolve '$User' group membership: $($_.Exception.Message)" }
}

function Resolve-Effective([string]$Type, [scriptblock]$GetRules) {
    Write-Host "`n== $Type ==" -ForegroundColor Cyan
    $rules = & $GetRules | Where-Object { $_.State -eq 'Enabled' } | Sort-Object Priority
    if (-not $rules) { Write-Host "  (no enabled custom rules; default policy applies)" -ForegroundColor DarkGray; return }
    foreach ($r in $rules) {
        Write-Host ("  [prio {0}] {1}" -f $r.Priority, $r.Name)
    }
    if ($User) {
        $match = $rules | Where-Object {
            ($_.SentTo -contains $User) -or
            ($_.RecipientDomainIs | Where-Object { $User -like "*@$_" }) -or
            ($_.SentToMemberOf | Where-Object { $userGroups -contains $_ })
        } | Select-Object -First 1
        if ($match) { Write-Host ("  -> EFFECTIVE for {0}: {1}" -f $User, $match.Name) -ForegroundColor Green }
        else { Write-Host ("  -> No custom rule matches {0}; DEFAULT policy applies." -f $User) -ForegroundColor Yellow }
    }
}

Resolve-Effective "Anti-spam"    { Get-HostedContentFilterRule -ErrorAction SilentlyContinue }
Resolve-Effective "Anti-malware" { Get-MalwareFilterRule -ErrorAction SilentlyContinue }
Resolve-Effective "Anti-phish"   { Get-AntiPhishRule -ErrorAction SilentlyContinue }
Resolve-Effective "Safe Links"       { Get-SafeLinksRule -ErrorAction SilentlyContinue }
Resolve-Effective "Safe Attachments" { Get-SafeAttachmentRule -ErrorAction SilentlyContinue }

# Preset scope
Write-Host "`n== Preset security policies ==" -ForegroundColor Cyan
Get-EOPProtectionPolicyRule -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host ("  EOP preset '{0}' [{1}] scope: users={2} groups={3} domains={4}" -f `
        $_.Name, $_.State, ($_.SentTo -join ';'), ($_.SentToMemberOf -join ';'), ($_.RecipientDomainIs -join ';'))
}
Get-ATPProtectionPolicyRule -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host ("  MDO preset '{0}' [{1}] scope: users={2} groups={3} domains={4}" -f `
        $_.Name, $_.State, ($_.SentTo -join ';'), ($_.SentToMemberOf -join ';'), ($_.RecipientDomainIs -join ';'))
}

# Connection filter + Enhanced Filtering for Connectors
Write-Host "`n== Connection filter (Default) ==" -ForegroundColor Cyan
$cf = Get-HostedConnectionFilterPolicy -Identity Default -ErrorAction SilentlyContinue
if ($cf) {
    Write-Host ("  IPAllow: {0}" -f ($cf.IPAllowList -join ', '))
    Write-Host ("  IPBlock: {0}" -f ($cf.IPBlockList -join ', '))
    Write-Host ("  EnableSafeList: {0}" -f $cf.EnableSafeList)
}
Write-Host "`n== Enhanced Filtering for Connectors (skip listing) ==" -ForegroundColor Cyan
try {
    $ef = Get-InboundConnector -ErrorAction Stop | Where-Object { $_.EFSkipIPs -or $_.EFSkipLastIP }
    if ($ef) { $ef | ForEach-Object { Write-Host ("  Connector '{0}': EFSkipLastIP={1} EFSkipIPs={2}" -f $_.Name, $_.EFSkipLastIP, ($_.EFSkipIPs -join ',')) } }
    else { Write-Host "  No connector has Enhanced Filtering configured (expected if no third-party gateway in front)." -ForegroundColor DarkGray }
} catch { Write-Warning "  Inbound connectors unavailable: $($_.Exception.Message)" }

Write-Host "`nScope/health report complete (read-only)." -ForegroundColor Cyan
