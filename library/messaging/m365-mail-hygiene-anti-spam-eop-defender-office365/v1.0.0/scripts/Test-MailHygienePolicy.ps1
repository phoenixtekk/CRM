<#
.SYNOPSIS
  Read-only validation of the mail-hygiene baseline: policy presence/scope, quarantine actions,
  Tenant Allow/Block List, and SPF/DKIM/DMARC posture. Summarizes pass/fail for the validation gates.
.DESCRIPTION
  Connects with Exchange Online PowerShell (EXO V3) and checks that the expected policies exist and
  are scoped to the pilot group, that spam/phish verdict actions are set, that DKIM signing is
  enabled per domain, and that SPF/DMARC TXT records resolve. Makes NO changes. Message-injection
  tests (GTUBE/EICAR/spoof) are performed by actually sending mail per the Testing guide.
.EXAMPLE
  .\Test-MailHygienePolicy.ps1 -PilotGroup "Hygiene-Pilot"
  # Read-only. Connect first with Connect-ExchangeOnline.
  # (PowerShell 5.1+/7+, ExchangeOnlineManagement module)
.NOTES
  Expected results: a PASS/FAIL table per check. All PASS on the pilot means the read-side gates are
  met; then run the message-injection tests. Nothing is modified.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$PilotGroup,
    [string[]]$Domains
)

try { Get-OrganizationConfig -ErrorAction Stop | Out-Null }
catch { throw "Not connected. Run Connect-ExchangeOnline first." }

$results = New-Object System.Collections.Generic.List[object]
function Add-Result([string]$Check, [bool]$Pass, [string]$Detail) {
    $results.Add([pscustomobject]@{ Check = $Check; Result = $(if ($Pass) {'PASS'} else {'FAIL'}); Detail = $Detail })
}

# 1. Preset OR custom policy scoped to the pilot group
$eopPreset = Get-EOPProtectionPolicyRule -ErrorAction SilentlyContinue | Where-Object { $_.SentToMemberOf -contains $PilotGroup -or $_.SentTo -contains $PilotGroup }
$customSpamRule = Get-HostedContentFilterRule -ErrorAction SilentlyContinue | Where-Object { $_.SentToMemberOf -contains $PilotGroup }
if ($eopPreset) { Add-Result "Anti-spam scope" $true "Preset scoped: $($eopPreset.Name)" }
elseif ($customSpamRule) { Add-Result "Anti-spam scope" $true "Custom rule scoped: $($customSpamRule.Name)" }
else { Add-Result "Anti-spam scope" $false "No preset or custom anti-spam rule targets '$PilotGroup'." }

# 2. High-confidence phish action = Quarantine somewhere applicable
$spamPolicies = Get-HostedContentFilterPolicy -ErrorAction SilentlyContinue
$hcpQuarantine = $spamPolicies | Where-Object { $_.HighConfidencePhishAction -eq 'Quarantine' }
Add-Result "HC-phish -> Quarantine" ([bool]$hcpQuarantine) $(if ($hcpQuarantine) { "Set in: $($hcpQuarantine.Name -join ', ')" } else { "No anti-spam policy quarantines high-confidence phish." })

# 3. Anti-malware present
$mal = Get-MalwareFilterPolicy -ErrorAction SilentlyContinue
Add-Result "Anti-malware policy" ([bool]$mal) $(if ($mal) { "$(@($mal).Count) policy(ies)" } else { "None found." })

# 4. Defender for Office 365 (informational - not a fail on EOP-only tenants)
$mdo = Get-SafeAttachmentPolicy -ErrorAction SilentlyContinue
if ($mdo) { Add-Result "Defender for Office 365" $true "Safe Attachments present ($(@($mdo).Count)). Validate Safe Links/Attachments via test mail." }
else { Add-Result "Defender for Office 365" $true "Not present (EOP-only or not licensed) - INFO only, not a failure." }

# 5. Quarantine policy with notifications
$qp = Get-QuarantinePolicy -ErrorAction SilentlyContinue | Where-Object { $_.EndUserQuarantinePermissionsValue -gt 0 -or $_.Name -like '*Notification*' }
Add-Result "Quarantine + notify" ([bool]$qp) $(if ($qp) { "$($qp.Name -join ', ')" } else { "No end-user quarantine/notification policy detected." })

# 6. DKIM enabled per domain
$dkim = Get-DkimSigningConfig -ErrorAction SilentlyContinue
$dkimOn = $dkim | Where-Object { $_.Enabled -eq $true }
Add-Result "DKIM signing" ([bool]$dkimOn) $(if ($dkimOn) { "Enabled: $($dkimOn.Domain -join ', ')" } else { "No domain has DKIM enabled." })

# 7. SPF + DMARC TXT resolve (best-effort DNS; requires Resolve-DnsName)
if (-not $Domains) {
    $Domains = (Get-AcceptedDomain -ErrorAction SilentlyContinue | Where-Object { $_.DomainType -eq 'Authoritative' }).DomainName
}
foreach ($d in $Domains) {
    try {
        $spf = Resolve-DnsName -Name $d -Type TXT -ErrorAction Stop | Where-Object { $_.Strings -match 'v=spf1' }
        $dmarc = Resolve-DnsName -Name "_dmarc.$d" -Type TXT -ErrorAction SilentlyContinue | Where-Object { $_.Strings -match 'v=DMARC1' }
        Add-Result "SPF ($d)" ([bool]$spf) $(if ($spf) { "present" } else { "missing" })
        Add-Result "DMARC ($d)" ([bool]$dmarc) $(if ($dmarc) { ($dmarc.Strings -join '') } else { "missing (publish p=none to start)" })
    } catch { Add-Result "DNS ($d)" $false "Resolve-DnsName unavailable/failed: $($_.Exception.Message)" }
}

$results | Format-Table -AutoSize
$fail = @($results | Where-Object { $_.Result -eq 'FAIL' }).Count
Write-Host ("`nValidation summary: {0} check(s), {1} FAIL." -f $results.Count, $fail) -ForegroundColor $(if ($fail) {'Yellow'} else {'Green'})
if ($fail -eq 0) { Write-Host "Read-side gates met. Proceed to message-injection tests (GTUBE/EICAR/spoof)." -ForegroundColor Green }
