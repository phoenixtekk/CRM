<#
.SYNOPSIS
  Read-only assessment of the Microsoft 365 mail hygiene posture (EOP + Defender for Office 365).
  Makes NO changes. Produces the rollback baseline before any tuning.
.DESCRIPTION
  Connects with Exchange Online PowerShell (EXO V3) and exports the current hygiene configuration:
  anti-spam (hosted content filter), anti-malware, anti-phish, Safe Links / Safe Attachments (if
  Defender for Office 365 is licensed), the connection filter, quarantine policies, preset security
  policy state, and the Tenant Allow/Block List. It also flags risky legacy mail-flow (transport)
  rules that bypass filtering (e.g. SCL -1). Output is written to CSV/JSON for archival as the
  rollback baseline.
.EXAMPLE
  .\Get-MailHygieneAssessment.ps1 -OutputFolder .\hygiene-baseline
  # Read-only. Connect first with Connect-ExchangeOnline (modern auth).
  # (PowerShell 5.1+/7+, ExchangeOnlineManagement module)
.NOTES
  Expected results: a set of export files plus a console summary. The "RISK" lines flag transport
  rules that bypass filtering (SCL -1) and any policy gaps vs the Standard baseline. Nothing is
  modified.
#>
[CmdletBinding()]
param(
    [string]$OutputFolder = ".\hygiene-baseline",
    [switch]$IncludeTenantAllowBlockList = $true
)

function Ensure-ExoConnected {
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        throw "ExchangeOnlineManagement (EXO V3) module not found. Install-Module ExchangeOnlineManagement"
    }
    try { Get-OrganizationConfig -ErrorAction Stop | Out-Null }
    catch { throw "Not connected. Run Connect-ExchangeOnline first (use -ExchangeEnvironmentName for Gov clouds)." }
}

Ensure-ExoConnected
if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null }
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
Write-Host "Mail hygiene assessment (READ-ONLY) -> $OutputFolder" -ForegroundColor Cyan

function Export-Safe([scriptblock]$Get, [string]$Name) {
    try {
        $data = & $Get
        if ($null -ne $data) {
            $path = Join-Path $OutputFolder "$Name-$stamp.json"
            $data | ConvertTo-Json -Depth 6 | Out-File -FilePath $path -Encoding UTF8
            Write-Host ("  exported {0,-32} ({1} object(s))" -f $Name, @($data).Count)
        } else { Write-Host "  (none) $Name" -ForegroundColor DarkGray }
    } catch { Write-Warning "  skipped $Name : $($_.Exception.Message)" }
}

# EOP
Export-Safe { Get-HostedContentFilterPolicy }      "antispam-policies"
Export-Safe { Get-HostedContentFilterRule }        "antispam-rules"
Export-Safe { Get-MalwareFilterPolicy }            "antimalware-policies"
Export-Safe { Get-MalwareFilterRule }              "antimalware-rules"
Export-Safe { Get-HostedConnectionFilterPolicy }   "connection-filter"
Export-Safe { Get-QuarantinePolicy }               "quarantine-policies"

# Defender for Office 365 (present only if licensed) - guarded
Export-Safe { Get-AntiPhishPolicy }                "antiphish-policies"
Export-Safe { Get-AntiPhishRule }                  "antiphish-rules"
Export-Safe { Get-SafeLinksPolicy }                "safelinks-policies"
Export-Safe { Get-SafeAttachmentPolicy }           "safeattach-policies"

# Preset security policies state
Export-Safe { Get-EOPProtectionPolicyRule }        "preset-eop-rules"
Export-Safe { Get-ATPProtectionPolicyRule }        "preset-mdo-rules"

# Tenant Allow/Block List
if ($IncludeTenantAllowBlockList) {
    Export-Safe { Get-TenantAllowBlockListItems -ListType Sender } "tabl-sender"
    Export-Safe { Get-TenantAllowBlockListItems -ListType Url }    "tabl-url"
    Export-Safe { Get-TenantAllowBlockListItems -ListType FileHash } "tabl-filehash"
}

# Transport rules + RISK flagging of filter-bypassing rules
try {
    $rules = Get-TransportRule -ErrorAction Stop
    Export-Safe { $rules } "transport-rules"
    $bypass = $rules | Where-Object { $_.SetSCL -eq '-1' -or ($_.SetHeaderName -eq 'X-MS-Exchange-Organization-BypassClutter') }
    if ($bypass) {
        Write-Host "`n  RISK: transport rules that bypass spam filtering (SCL -1 / bypass):" -ForegroundColor Yellow
        $bypass | ForEach-Object { Write-Host ("    - {0} (State={1})" -f $_.Name, $_.State) -ForegroundColor Yellow }
    } else { Write-Host "  OK: no SCL -1 filter-bypass transport rules found." -ForegroundColor Green }
} catch { Write-Warning "  transport rules unavailable: $($_.Exception.Message)" }

Write-Host "`nAssessment complete. Archive '$OutputFolder' as the rollback baseline." -ForegroundColor Cyan
