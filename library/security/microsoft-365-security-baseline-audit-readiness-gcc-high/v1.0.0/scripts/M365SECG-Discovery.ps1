<#
.SYNOPSIS
    M365SECG-Discovery.ps1 — read-only inventory of a GCC High tenant's security baseline posture.
.DESCRIPTION
    PURPOSE
        Captures a starting-state snapshot of a Microsoft 365 GCC High tenant: current Microsoft
        Secure Score, licensing, admin role assignments, Conditional Access policies, and MFA
        registration posture. Read-only. Connects to Microsoft Graph US Gov. Set your own values for
        placeholders such as your-tenant-id and your-output-folder when prompted or via parameters.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\M365SECG-Discovery.ps1
        (Graph scopes: SecurityEvents.Read.All, Directory.Read.All, Policy.Read.All,
         RoleManagement.Read.Directory; connects with -Environment USGov)
    EXPECTED RESULTS
        Console summary plus a timestamped report file. If the tenant is reachable and scopes are
        consented, PASS: a baseline snapshot is written. If Graph connects to the wrong cloud, the
        script aborts before reading anything (FAIL with guidance to reconnect as USGov).
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [string]$OutputFolder = ".\M365SECG-output",
    [string]$Environment  = "USGov"   # GCC High = USGov (Graph root https://graph.microsoft.us)
)

$ErrorActionPreference = "Stop"

function Connect-USGovGraph {
    param([string[]]$Scopes, [string]$Env)
    $ctx = $null
    try { $ctx = Get-MgContext } catch { $ctx = $null }
    if (-not $ctx -or $ctx.Environment -ne $Env) {
        Write-Host "Connecting to Microsoft Graph ($Env / GCC High = https://graph.microsoft.us)..." -ForegroundColor Cyan
        Connect-MgGraph -Environment $Env -Scopes $Scopes | Out-Null
        $ctx = Get-MgContext
    }
    if ($ctx.Environment -ne $Env) {
        throw "Connected environment is '$($ctx.Environment)', expected '$Env'. Run Disconnect-MgGraph and reconnect with -Environment $Env. GCC High must NOT use the Commercial cloud."
    }
    Write-Host "Connected. Environment = $($ctx.Environment); Tenant = $($ctx.TenantId)" -ForegroundColor Green
    return $ctx
}

# --- Preconditions -----------------------------------------------------------
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    throw "Microsoft Graph PowerShell SDK not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
}
if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder | Out-Null }
$stamp  = Get-Date -Format "yyyyMMdd-HHmmss"
$report = Join-Path $OutputFolder "M365SECG-Discovery-$stamp.txt"

$scopes = @(
    "SecurityEvents.Read.All",
    "Directory.Read.All",
    "Policy.Read.All",
    "RoleManagement.Read.Directory"
)

$ctx = Connect-USGovGraph -Scopes $scopes -Env $Environment

$lines = New-Object System.Collections.Generic.List[string]
function Add-Line([string]$t){ $lines.Add($t); Write-Host $t }

Add-Line "==================================================================="
Add-Line " M365SECG Discovery (GCC High / US Gov)  -  $stamp"
Add-Line " Environment : $($ctx.Environment)   Tenant: $($ctx.TenantId)"
Add-Line " Graph root  : https://graph.microsoft.us"
Add-Line "==================================================================="

# --- Secure Score ------------------------------------------------------------
Add-Line "`n[1] Microsoft Secure Score (security.microsoft.us)"
try {
    $score = Get-MgSecuritySecureScore -Top 1 -ErrorAction Stop | Select-Object -First 1
    if ($score) {
        $pct = if ($score.MaxScore) { [math]::Round(($score.CurrentScore / $score.MaxScore) * 100, 1) } else { 0 }
        Add-Line ("    Current score : {0} / {1}  ({2}%)" -f $score.CurrentScore, $score.MaxScore, $pct)
        Add-Line ("    Active users  : {0}" -f $score.ActiveUserCount)
        Add-Line ("    Captured (UTC): {0}" -f $score.CreatedDateTime)
    } else {
        Add-Line "    No Secure Score record returned. Verify a Gov Defender SKU and Security Reader role."
    }
} catch {
    Add-Line "    Could not read Secure Score: $($_.Exception.Message)"
    Add-Line "    NOTE: In GCC High, some Secure Score recommendations are not available (see gcc-high-parity-notes)."
}

# --- Secure Score control profiles (available recommendations) ---------------
Add-Line "`n[2] Secure Score control profiles present in THIS tenant"
try {
    $profiles = Get-MgSecuritySecureScoreControlProfile -All -ErrorAction Stop
    Add-Line ("    Control profiles available in this GCC High tenant: {0}" -f ($profiles | Measure-Object).Count)
    Add-Line "    (This count differs from Commercial — GCC High omits some recommendations by design.)"
} catch {
    Add-Line "    Could not enumerate control profiles: $($_.Exception.Message)"
}

# --- Licensing ---------------------------------------------------------------
Add-Line "`n[3] Licensing (Gov SKUs)"
try {
    $skus = Get-MgSubscribedSku -All -ErrorAction Stop
    foreach ($s in $skus) {
        Add-Line ("    {0}  (enabled: {1}, consumed: {2})" -f $s.SkuPartNumber, $s.PrepaidUnits.Enabled, $s.ConsumedUnits)
    }
    Add-Line "    Confirm SKUs are Gov variants (names contain 'GCCHIGH'/'GOV'). CMMC L1-5 needs G5 Gov."
} catch {
    Add-Line "    Could not read SKUs: $($_.Exception.Message)"
}

# --- Admin role assignments --------------------------------------------------
Add-Line "`n[4] Directory role assignments (least-privilege review)"
try {
    $roles = Get-MgDirectoryRole -All -ErrorAction Stop
    foreach ($r in $roles) {
        $members = Get-MgDirectoryRoleMember -DirectoryRoleId $r.Id -All -ErrorAction SilentlyContinue
        $count = ($members | Measure-Object).Count
        Add-Line ("    {0} : {1} member(s)" -f $r.DisplayName, $count)
    }
    Add-Line "    Reserve Global Administrator for tenant-wide changes only."
} catch {
    Add-Line "    Could not read directory roles: $($_.Exception.Message)"
}

# --- Conditional Access ------------------------------------------------------
Add-Line "`n[5] Conditional Access policies (entra.microsoft.us)"
try {
    $ca = Get-MgIdentityConditionalAccessPolicy -All -ErrorAction Stop
    if (($ca | Measure-Object).Count -eq 0) {
        Add-Line "    No Conditional Access policies found."
    } else {
        foreach ($p in $ca) { Add-Line ("    [{0}] {1}" -f $p.State, $p.DisplayName) }
    }
} catch {
    Add-Line "    Could not read Conditional Access policies: $($_.Exception.Message)"
}

# --- MFA / auth methods posture (registration summary) -----------------------
Add-Line "`n[6] Authentication methods / registration posture"
try {
    $reg = Get-MgReportAuthenticationMethodUserRegistrationDetail -All -ErrorAction Stop
    $total = ($reg | Measure-Object).Count
    $mfaCap = ($reg | Where-Object { $_.IsMfaCapable }).Count
    Add-Line ("    Users evaluated     : {0}" -f $total)
    Add-Line ("    MFA-capable users   : {0}" -f $mfaCap)
} catch {
    Add-Line "    Could not read registration details (report scope may be required): $($_.Exception.Message)"
}

Add-Line "`n[✓] Discovery complete. Baseline saved for evidence."
$lines | Out-File -FilePath $report -Encoding UTF8
Write-Host "`nReport written to: $report" -ForegroundColor Green
Write-Host "This run was READ-ONLY. No tenant changes were made." -ForegroundColor Green
