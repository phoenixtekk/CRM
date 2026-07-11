<#
.SYNOPSIS
    SOAMDO-Discovery.ps1 — read-only collection of every Defender for Office 365 / EOP policy, rule, and bypass into a dated run folder.
.DESCRIPTION
    PURPOSE
        Builds the raw evidence base the coverage and scoring passes consume. Collects, read-only: anti-spam
        (hosted content filter) + outbound spam, anti-malware, anti-phish, Safe Links, Safe Attachments
        policies and their rules; the preset (EOP + ATP) protection policy rules; the connection filter and
        DKIM config; and — for bypass hygiene — the transport (mail-flow) rules and the Tenant Allow/Block
        List. Also pulls Secure Score MDO recommendations and an EmailEvents volume signal via Graph
        advanced hunting. Nothing is changed.
    HOW TO RUN
        pwsh -File .\SOAMDO-Discovery.ps1 -ScopeFile ".\SOAMDO-Scope - Tenant - Assess.json" -OutputDir ".\SOAMDO-Run - 2026-07-11 - Assess"
        Run SOAMDO-Validate.ps1 first. Requires read-only Exchange Online + Graph access.
        *Verify current cmdlet/API coverage and role mapping.*
    EXPECTED RESULTS
        A populated run folder with one file per area plus discovery-manifest.json. Read-only — no changes.
.NOTES
    White-label. Read-only. Makes no changes.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string]$ScopeFile,
    [Parameter(Mandatory = $true)] [string]$OutputDir
)

$ErrorActionPreference = 'Continue'
if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir | Out-Null }
$scope = if (Test-Path $ScopeFile) { Get-Content $ScopeFile -Raw | ConvertFrom-Json } else { @{ description = 'unspecified'; expectedMailboxCount = 0; baseline = 'Preset Strict + Secure Score (verify)' } }
Write-Host "SOAMDO discovery (read-only) -> $OutputDir`n" -ForegroundColor Cyan

Import-Module ExchangeOnlineManagement -ErrorAction Stop
try { Get-ConnectionInformation | Out-Null } catch {}
try { Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop } catch { Write-Host "  (Connect-ExchangeOnline: $($_.Exception.Message))" -ForegroundColor Yellow }
try { Connect-IPPSSession -ErrorAction Stop } catch { Write-Host "  (Connect-IPPSSession: $($_.Exception.Message))" -ForegroundColor Yellow }

function Save-Area([string]$Name, [scriptblock]$Block) {
    try { $data = & $Block } catch { $data = @{ error = $_.Exception.Message }; Write-Host "  (read failed: $Name : $($_.Exception.Message))" -ForegroundColor Yellow }
    $path = Join-Path $OutputDir "$Name.json"
    $data | ConvertTo-Json -Depth 12 | Set-Content -Path $path -Encoding UTF8
    $count = if ($data -is [System.Array]) { $data.Count } elseif ($null -ne $data) { 1 } else { 0 }
    Write-Host ("  {0,-30} {1,5} record(s)" -f $Name, $count)
    return $count
}

$manifest = [ordered]@{ tool = 'SOAMDO-Discovery'; runDate = (Get-Date).ToString('s'); scope = $scope; areas = @{} }

# --- Protection policies + rules ---------------------------------------------
$manifest.areas['antispam-policies']    = Save-Area 'antispam-policies'    { Get-HostedContentFilterPolicy | Select-Object * }
$manifest.areas['antispam-rules']       = Save-Area 'antispam-rules'       { Get-HostedContentFilterRule  | Select-Object * }
$manifest.areas['outbound-spam']        = Save-Area 'outbound-spam'        { Get-HostedOutboundSpamFilterPolicy | Select-Object * }
$manifest.areas['antimalware-policies'] = Save-Area 'antimalware-policies' { Get-MalwareFilterPolicy | Select-Object * }
$manifest.areas['antiphish-policies']   = Save-Area 'antiphish-policies'   { Get-AntiPhishPolicy | Select-Object * }
$manifest.areas['antiphish-rules']      = Save-Area 'antiphish-rules'      { Get-AntiPhishRule | Select-Object * }
$manifest.areas['safelinks-policies']   = Save-Area 'safelinks-policies'   { Get-SafeLinksPolicy | Select-Object * }
$manifest.areas['safelinks-rules']      = Save-Area 'safelinks-rules'      { Get-SafeLinksRule | Select-Object * }
$manifest.areas['safeattach-policies']  = Save-Area 'safeattach-policies'  { Get-SafeAttachmentPolicy | Select-Object * }
$manifest.areas['safeattach-rules']     = Save-Area 'safeattach-rules'     { Get-SafeAttachmentRule | Select-Object * }

# --- Preset security policies -------------------------------------------------
$manifest.areas['preset-eop-rules']     = Save-Area 'preset-eop-rules'     { Get-EOPProtectionPolicyRule | Select-Object * }
$manifest.areas['preset-atp-rules']     = Save-Area 'preset-atp-rules'     { Get-ATPProtectionPolicyRule | Select-Object * }

# --- Connection filter, DKIM --------------------------------------------------
$manifest.areas['connection-filter']    = Save-Area 'connection-filter'    { Get-HostedConnectionFilterPolicy | Select-Object * }
$manifest.areas['dkim']                 = Save-Area 'dkim'                 { Get-DkimSigningConfig | Select-Object Domain, Enabled, Status }

# --- BYPASS HYGIENE: transport rules + Tenant Allow/Block List ---------------
$manifest.areas['transport-rules']      = Save-Area 'transport-rules'      { Get-TransportRule | Select-Object Name, State, Priority, SetSCL, Mode, Description, Comments }
$manifest.areas['tabl-senders']         = Save-Area 'tabl-senders'         { Get-TenantAllowBlockListItems -ListType Sender | Select-Object * }
$manifest.areas['tabl-urls']            = Save-Area 'tabl-urls'            { Get-TenantAllowBlockListItems -ListType Url | Select-Object * }
$manifest.areas['tabl-filehash']        = Save-Area 'tabl-filehash'        { Get-TenantAllowBlockListItems -ListType FileHash | Select-Object * }

# --- Mailbox count (denominator helper) --------------------------------------
$manifest.areas['mailbox-count']        = Save-Area 'mailbox-count'        { @{ count = (Get-EXOMailbox -ResultSize Unlimited -ErrorAction SilentlyContinue | Measure-Object).Count } }

# --- Graph: Secure Score + EmailEvents signal --------------------------------
try {
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes 'SecurityEvents.Read.All' -NoWelcome -ErrorAction Stop
    $manifest.areas['secure-score'] = Save-Area 'secure-score' { (Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/security/secureScores?$top=1').value }
    $kql = @'
EmailEvents
| where Timestamp > ago(7d)
| summarize Total = count() by DeliveryAction, ThreatTypes
'@
    $manifest.areas['emailevents-7d'] = Save-Area 'emailevents-7d' { (Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body (@{ Query = $kql } | ConvertTo-Json) -ContentType 'application/json').results }
} catch { Write-Host "  (Graph signals skipped: $($_.Exception.Message))" -ForegroundColor Yellow }

$manifest | ConvertTo-Json -Depth 8 | Set-Content -Path (Join-Path $OutputDir 'discovery-manifest.json') -Encoding UTF8
Write-Host "`nDiscovery complete — raw evidence in '$OutputDir'. Read-only; no changes made." -ForegroundColor Green
Write-Host "Next: SOAMDO-Coverage.ps1 then SOAMDO-Assess.ps1." -ForegroundColor Green
