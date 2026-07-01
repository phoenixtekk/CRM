<#
.SYNOPSIS
    FWMIG-Discovery.ps1 - Inventory GPO + applied Windows Defender Firewall configuration (READ-ONLY).

.DESCRIPTION
    PURPOSE
        Captures the source-of-truth firewall inventory for a GPO-to-Intune migration: the
        Domain/Private/Public profile defaults and every applied firewall rule on an in-scope,
        domain-joined device. This export is what later parity validation is compared against.
        This script is READ-ONLY - it makes no changes.

    HOW TO RUN
        Run on a domain-joined, in-scope device in an elevated PowerShell session:
            .\FWMIG-Discovery.ps1
            .\FWMIG-Discovery.ps1 -OutputPath C:\Temp\fwmig
        Uses the built-in NetSecurity module (no install). Requires local admin to read the
        effective firewall policy stores.

    EXPECTED RESULTS
        - Console summary of the three profile defaults and the rule count.
        - Two files in the output folder:
            FWMIG-Inventory-<host>-<date>.json  (full structured inventory)
            FWMIG-Inventory-<host>-<date>.csv   (one row per rule)
        These files are the parity baseline used by FWMIG-Validation.ps1 / FWMIG-Report.ps1.
#>

[CmdletBinding()]
param(
    [string] $OutputPath = (Join-Path $env:TEMP 'FWMIG')
)

if (-not (Get-Module -ListAvailable -Name NetSecurity)) {
    Write-Error 'NetSecurity module not available. Run on Windows 10/11 with the firewall feature present.'
    return
}
Import-Module NetSecurity -ErrorAction Stop

if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }

$stamp    = Get-Date -Format 'yyyyMMdd-HHmmss'
$hostName = $env:COMPUTERNAME
$os       = Get-CimInstance Win32_OperatingSystem

Write-Host "FWMIG Discovery on $hostName  (OS build $($os.BuildNumber))" -ForegroundColor Cyan

# --- Profile defaults (effective / ActiveStore) ---
$profiles = Get-NetFirewallProfile -PolicyStore ActiveStore | ForEach-Object {
    [pscustomobject]@{
        Profile               = $_.Name
        Enabled               = [bool]$_.Enabled
        DefaultInboundAction  = "$($_.DefaultInboundAction)"
        DefaultOutboundAction = "$($_.DefaultOutboundAction)"
        AllowInboundRules     = "$($_.AllowInboundRules)"
        AllowLocalFirewallRules        = "$($_.AllowLocalFirewallRules)"
        AllowLocalIPsecRules           = "$($_.AllowLocalIPsecRules)"
        LogFileName           = $_.LogFileName
        LogBlocked            = "$($_.LogBlocked)"
        LogAllowed            = "$($_.LogAllowed)"
    }
}

# --- Applied rules (effective ActiveStore = local + GPO + MDM merged) ---
$activeRules = Get-NetFirewallRule -PolicyStore ActiveStore -ErrorAction SilentlyContinue
# --- GPO-sourced rules specifically (RSOP store) ---
$gpoRules = Get-NetFirewallRule -PolicyStore RSOP -ErrorAction SilentlyContinue

function Convert-Rule {
    param($rule, [string]$source)
    $port = $rule | Get-NetFirewallPortFilter -ErrorAction SilentlyContinue
    $app  = $rule | Get-NetFirewallApplicationFilter -ErrorAction SilentlyContinue
    $addr = $rule | Get-NetFirewallAddressFilter -ErrorAction SilentlyContinue
    [pscustomobject]@{
        Source        = $source
        DisplayName   = $rule.DisplayName
        Name          = $rule.Name
        Direction     = "$($rule.Direction)"
        Action        = "$($rule.Action)"
        Enabled       = "$($rule.Enabled)"
        Profile       = "$($rule.Profile)"
        Protocol      = "$($port.Protocol)"
        LocalPort     = ($port.LocalPort  -join ',')
        RemotePort    = ($port.RemotePort -join ',')
        Program       = $app.Program
        LocalAddress  = ($addr.LocalAddress  -join ',')
        RemoteAddress = ($addr.RemoteAddress -join ',')
    }
}

$ruleRows = @()
$ruleRows += $activeRules | ForEach-Object { Convert-Rule -rule $_ -source 'ActiveStore' }
$ruleRows += $gpoRules    | ForEach-Object { Convert-Rule -rule $_ -source 'GPO' }

$inventory = [pscustomobject]@{
    GeneratedUtc = (Get-Date).ToUniversalTime().ToString('o')
    Computer     = $hostName
    OsBuild      = $os.BuildNumber
    Profiles     = $profiles
    RuleCount    = @($activeRules).Count
    GpoRuleCount = @($gpoRules).Count
    Rules        = $ruleRows
}

$jsonPath = Join-Path $OutputPath "FWMIG-Inventory-$hostName-$stamp.json"
$csvPath  = Join-Path $OutputPath "FWMIG-Inventory-$hostName-$stamp.csv"
$inventory | ConvertTo-Json -Depth 6 | Set-Content -Path $jsonPath -Encoding UTF8
$ruleRows  | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

$profiles | Format-Table -AutoSize
Write-Host "Applied (effective) rules: $(@($activeRules).Count)   GPO-sourced rules: $(@($gpoRules).Count)"
Write-Host "Inventory written:" -ForegroundColor Green
Write-Host "  $jsonPath"
Write-Host "  $csvPath"
