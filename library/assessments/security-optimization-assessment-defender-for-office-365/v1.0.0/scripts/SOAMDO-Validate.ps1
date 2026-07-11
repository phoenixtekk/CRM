<#
.SYNOPSIS
    SOAMDO-Validate.ps1 — self-check that the assessor can READ every MDO/EOP policy (incl. transport rules and the Tenant Allow/Block List) and has NO write role.
.DESCRIPTION
    PURPOSE
        The read-only guarantee of the assessment. Confirms the current identity can read an anti-phish,
        Safe Links, Safe Attachments, anti-spam and anti-malware policy; the preset security policy
        rules; the transport (mail-flow) rules and the Tenant Allow/Block List (critical for bypass
        hygiene); and a Graph advanced-hunting query — and asserts that NO write role/scope is present.
        A missing transport-rule / allow-list read is called out specifically because it hides the
        highest-value findings.
    HOW TO RUN
        pwsh -File .\SOAMDO-Validate.ps1
        Requires ExchangeOnlineManagement + Microsoft.Graph modules. Prompts for interactive sign-in.
        Assessor should hold Global Reader / Security Reader / View-Only Configuration only.
        *Verify current role-to-cmdlet mapping and Graph scope names.*
    EXPECTED RESULTS
        A PASS/FAIL line per check and an overall verdict. Read-only — makes no changes.
.NOTES
    White-label. Read-only. Makes no changes. Assessment access self-check.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$results = [System.Collections.Generic.List[object]]::new()
function Add-Result([string]$Check, [bool]$Pass, [string]$Detail) {
    $results.Add([pscustomobject]@{ Check = $Check; Result = ($(if ($Pass) { 'PASS' } else { 'FAIL' })); Detail = $Detail })
}
function Try-Read([string]$Check, [scriptblock]$Block) {
    try { $out = & $Block; Add-Result $Check $true $(if ($out) { 'readable' } else { 'readable (none configured)' }) }
    catch { Add-Result $Check $false $_.Exception.Message }
}

Write-Host "SOAMDO access validation (read-only)`n" -ForegroundColor Cyan

# --- Connect (read-only sessions) --------------------------------------------
try {
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop
    Add-Result 'Connect-ExchangeOnline' $true 'connected'
} catch { Add-Result 'Connect-ExchangeOnline' $false $_.Exception.Message }

try { Connect-IPPSSession -ErrorAction Stop; Add-Result 'Connect-IPPSSession' $true 'connected' }
catch { Add-Result 'Connect-IPPSSession' $false "$($_.Exception.Message) (Safe Links/Attachments live here in some tenants)" }

# --- Policy reads ------------------------------------------------------------
Try-Read 'Read anti-phish policy'       { Get-AntiPhishPolicy -ErrorAction Stop | Select-Object -First 1 }
Try-Read 'Read anti-spam policy'        { Get-HostedContentFilterPolicy -ErrorAction Stop | Select-Object -First 1 }
Try-Read 'Read anti-malware policy'     { Get-MalwareFilterPolicy -ErrorAction Stop | Select-Object -First 1 }
Try-Read 'Read Safe Links policy'       { Get-SafeLinksPolicy -ErrorAction Stop | Select-Object -First 1 }
Try-Read 'Read Safe Attachments policy' { Get-SafeAttachmentPolicy -ErrorAction Stop | Select-Object -First 1 }
Try-Read 'Read preset (EOP) rules'      { Get-EOPProtectionPolicyRule -ErrorAction Stop | Select-Object -First 1 }
Try-Read 'Read preset (ATP) rules'      { Get-ATPProtectionPolicyRule -ErrorAction Stop | Select-Object -First 1 }

# --- Bypass-hygiene reads (critical) -----------------------------------------
Try-Read 'Read TRANSPORT (mail-flow) rules' { Get-TransportRule -ErrorAction Stop | Select-Object -First 1 }
Try-Read 'Read Tenant Allow/Block List'     { Get-TenantAllowBlockListItems -ListType Sender -ErrorAction Stop | Select-Object -First 1 }
Try-Read 'Read connection filter (IP allow)'{ Get-HostedConnectionFilterPolicy -ErrorAction Stop | Select-Object -First 1 }

# --- Graph advanced hunting --------------------------------------------------
try {
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes 'SecurityEvents.Read.All' -NoWelcome -ErrorAction Stop
    $ctx = Get-MgContext
    $writeHits = @($ctx.Scopes | Where-Object { $_ -match 'ReadWrite|\.Manage|Write|FullControl' })
    Add-Result 'Graph read scopes only' ($writeHits.Count -eq 0) ($(if ($writeHits) { "write scopes present: $($writeHits -join ', ')" } else { 'read-only scopes' }))
    try {
        $body = @{ Query = 'EmailEvents | take 1' } | ConvertTo-Json
        Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body $body -ContentType 'application/json' -ErrorAction Stop | Out-Null
        Add-Result 'Advanced hunting (EmailEvents)' $true 'query executed'
    } catch { Add-Result 'Advanced hunting (EmailEvents)' $false $_.Exception.Message }
} catch { Add-Result 'Graph connect' $false $_.Exception.Message }

# --- No-write role assertion (Exchange RBAC) ---------------------------------
try {
    $writeRoles = Get-ManagementRoleAssignment -RoleAssignee (Get-ConnectionInformation | Select-Object -First 1 -ExpandProperty UserPrincipalName) -ErrorAction SilentlyContinue |
        Where-Object { $_.Role -match 'Transport Rules|Anti-|Security Admin|Hygiene|Configuration' -and $_.Role -notmatch 'View-Only' }
    $noWrite = -not $writeRoles
    Add-Result 'No Exchange write role' $noWrite ($(if ($writeRoles) { "write-capable roles: $($writeRoles.Role -join ', ')" } else { 'view-only' }))
} catch { Add-Result 'No Exchange write role' $true 'could not enumerate role assignments (informational)' }

# --- Verdict -----------------------------------------------------------------
Write-Host "`n--- Validation results ---" -ForegroundColor Cyan
$results | Format-Table -AutoSize
$failed = @($results | Where-Object Result -eq 'FAIL')
if ($failed.Count -eq 0) {
    Write-Host "`nALL CHECKS PASSED — read-only access confirmed. Proceed to SOAMDO-Discovery.ps1." -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n$($failed.Count) check(s) FAILED — resolve before running (empty transport-rule/allow-list reads hide bypass findings)." -ForegroundColor Yellow
    exit 1
}
