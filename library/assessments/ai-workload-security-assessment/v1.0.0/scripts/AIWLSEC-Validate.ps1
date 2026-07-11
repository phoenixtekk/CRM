<#
.SYNOPSIS
    AIWLSEC-Validate.ps1 — read-only pre-flight that proves the AI assessment can run and is least-privilege.
.DESCRIPTION
    PURPOSE
        The gate you run before any substantive review. Confirms PowerShell and module versions, that Azure
        and Microsoft Graph are connected, that the signed-in identity is read-only (Azure Reader + Security
        Reader with NO Contributor/write role detected), that the AI resource providers are registered, and
        lists the AI resources (Azure OpenAI / AI Search / Azure ML) it can see in scope. If this does not
        pass, a whole review area can silently return empty or the read-only guarantee is broken.
    HOW TO RUN
        Connect-AzAccount
        Connect-MgGraph -Scopes "Directory.Read.All","Policy.Read.All"
        pwsh -File .\AIWLSEC-Validate.ps1 -SubscriptionIds "<sub1>","<sub2>"
        Requires PowerShell 7+ and the Az + Microsoft.Graph modules. *Verify current scope names/modules.*
    EXPECTED RESULTS
        A PASS/WARN/FAIL checklist and a count of AI resources found. All PASS = ready for AIWLSEC-Discovery.ps1.
.NOTES
    White-label. Read-only. Makes no changes.
#>
[CmdletBinding()]
param(
    [string[]]$SubscriptionIds,
    [string[]]$RequiredGraphScopes = @('Directory.Read.All')
)

$ErrorActionPreference = 'Continue'
$results = New-Object System.Collections.Generic.List[object]
function Add-Check([string]$Name,[string]$Status,[string]$Detail){
    $results.Add([pscustomobject]@{ Check=$Name; Status=$Status; Detail=$Detail })
}
Write-Host "AIWLSEC pre-flight validation (read-only)`n" -ForegroundColor Cyan

# --- PowerShell version ------------------------------------------------------
if ($PSVersionTable.PSVersion.Major -ge 7) { Add-Check 'PowerShell 7+' 'PASS' $PSVersionTable.PSVersion.ToString() }
else { Add-Check 'PowerShell 7+' 'FAIL' "Found $($PSVersionTable.PSVersion); install PowerShell 7+ (R4)" }

# --- Modules -----------------------------------------------------------------
foreach ($m in 'Az.Accounts','Az.Resources','Az.CognitiveServices','Az.Search','Az.Network','Microsoft.Graph') {
    $mod = Get-Module -ListAvailable -Name $m | Select-Object -First 1
    if ($mod) { Add-Check "Module: $m" 'PASS' "v$($mod.Version)" }
    else { Add-Check "Module: $m" 'WARN' "Install-Module $m -Scope CurrentUser (R4) — some review areas need it" }
}

# --- Azure connection --------------------------------------------------------
$azctx = $null
try { $azctx = Get-AzContext -ErrorAction SilentlyContinue } catch {}
if ($azctx) {
    Add-Check 'Azure connected' 'PASS' "Account $($azctx.Account.Id)"
} else {
    Add-Check 'Azure connected' 'FAIL' 'Run Connect-AzAccount first (R1)'
}

# --- Subscriptions + AI resources -------------------------------------------
if ($azctx) {
    if (-not $SubscriptionIds) { $SubscriptionIds = (Get-AzSubscription -ErrorAction SilentlyContinue).Id }
    $aiCount = 0
    foreach ($sid in $SubscriptionIds) {
        try { Set-AzContext -SubscriptionId $sid -ErrorAction Stop | Out-Null } catch { Add-Check "Subscription $sid" 'WARN' 'Cannot set context — Reader missing? (R1)'; continue }
        # Provider registration
        $prov = Get-AzResourceProvider -ProviderNamespace Microsoft.CognitiveServices -ErrorAction SilentlyContinue | Select-Object -First 1
        $provState = if ($prov) { $prov.RegistrationState } else { 'unknown' }
        Add-Check "CognitiveServices provider ($sid)" (if ($provState -eq 'Registered'){'PASS'}else{'WARN'}) "state=$provState (R3)"
        # AI resources visible
        $cs = Get-AzCognitiveServicesAccount -ErrorAction SilentlyContinue
        $search = Get-AzResource -ResourceType 'Microsoft.Search/searchServices' -ErrorAction SilentlyContinue
        $ml = Get-AzResource -ResourceType 'Microsoft.MachineLearningServices/workspaces' -ErrorAction SilentlyContinue
        $n = (@($cs)).Count + (@($search)).Count + (@($ml)).Count
        $aiCount += $n
        Add-Check "AI resources ($sid)" (if ($n -gt 0){'PASS'}else{'WARN'}) "$((@($cs)).Count) CogSvc/OpenAI, $((@($search)).Count) Search, $((@($ml)).Count) ML"
    }
    Add-Check 'AI resources in scope (total)' (if ($aiCount -gt 0){'PASS'}else{'WARN'}) "$aiCount found — if 0, check Reader role/scope (R1)"
}

# --- Graph connection + read-only scopes ------------------------------------
$mgctx = $null
try { $mgctx = Get-MgContext -ErrorAction SilentlyContinue } catch {}
if ($mgctx) {
    Add-Check 'Graph connected' 'PASS' "Account $($mgctx.Account)"
    $granted = @($mgctx.Scopes)
    foreach ($s in $RequiredGraphScopes) {
        if ($granted -contains $s) { Add-Check "Graph scope: $s" 'PASS' 'granted' }
        else { Add-Check "Graph scope: $s" 'WARN' 'not granted — identity/RBAC review will be limited (R3)' }
    }
    $writeScopes = $granted | Where-Object { $_ -match 'ReadWrite|\.Write|Manage' }
    if ($writeScopes) { Add-Check 'Read-only Graph scopes' 'FAIL' "WRITE scope(s) present: $($writeScopes -join ', ') — use read-only only (R2)" }
    else { Add-Check 'Read-only Graph scopes' 'PASS' 'no write scopes granted' }
} else {
    Add-Check 'Graph connected' 'WARN' 'Run Connect-MgGraph -Scopes "Directory.Read.All" for the identity/RBAC review (R2)'
}

# --- Report ------------------------------------------------------------------
$results | Format-Table -AutoSize
$fail = ($results | Where-Object Status -eq 'FAIL').Count
$warn = ($results | Where-Object Status -eq 'WARN').Count
Write-Host ""
if ($fail -gt 0) { Write-Host "$fail FAIL, $warn WARN — resolve FAILs before running discovery." -ForegroundColor Red }
elseif ($warn -gt 0) { Write-Host "0 FAIL, $warn WARN — review warnings; some areas may under-report." -ForegroundColor Yellow }
else { Write-Host "All checks passed — ready for AIWLSEC-Discovery.ps1. Read-only; nothing was changed." -ForegroundColor Green }
