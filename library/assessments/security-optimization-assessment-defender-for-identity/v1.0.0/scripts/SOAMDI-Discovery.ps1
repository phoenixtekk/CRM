<#
.SYNOPSIS
    SOAMDI-Discovery.ps1 — read-only collection of the AD identity inventory and Defender for Identity configuration signals into a dated run folder.
.DESCRIPTION
    PURPOSE
        Builds the raw evidence base the coverage and scoring passes consume. Collects, read-only: the
        AD inventory (all domain controllers, and AD FS / AD CS role holders) as the coverage
        denominator; the MDI sensor list & health where programmatically available; the directory-service
        account (DSA) and honeytoken/tagged-entity signals (flagged 'verify' for portal confirmation
        where no public read API exists); ISPM recommendations (MDI posture assessments + identity Secure
        Score); and identity detection activity via advanced hunting. Nothing is changed.
    HOW TO RUN
        pwsh -File .\SOAMDI-Discovery.ps1 -ScopeFile ".\SOAMDI-Scope - Forest - Assess.json" -OutputDir ".\SOAMDI-Run - 2026-07-11 - Assess"
        Run SOAMDI-Validate.ps1 first, from a domain-joined host with the ActiveDirectory module.
        *Verify current MDI read-API availability and Graph scope names.*
    EXPECTED RESULTS
        A populated run folder with one file per area plus discovery-manifest.json; items with no API are
        flagged 'verify' for portal confirmation. Read-only — no changes.
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
$scope = if (Test-Path $ScopeFile) { Get-Content $ScopeFile -Raw | ConvertFrom-Json } else { @{ description = 'unspecified'; baseline = 'MDI guidance + identity Secure Score (verify)' } }
Write-Host "SOAMDI discovery (read-only) -> $OutputDir`n" -ForegroundColor Cyan

function Save-Area([string]$Name, [scriptblock]$Block) {
    try { $data = & $Block } catch { $data = @{ error = $_.Exception.Message }; Write-Host "  (read failed: $Name : $($_.Exception.Message))" -ForegroundColor Yellow }
    ($data | ConvertTo-Json -Depth 12) | Set-Content -Path (Join-Path $OutputDir "$Name.json") -Encoding UTF8
    $count = if ($data -is [System.Array]) { $data.Count } elseif ($null -ne $data) { 1 } else { 0 }
    Write-Host ("  {0,-28} {1,5} record(s)" -f $Name, $count)
    return $count
}

$manifest = [ordered]@{ tool = 'SOAMDI-Discovery'; runDate = (Get-Date).ToString('s'); scope = $scope; areas = @{}; verifyItems = @() }

# --- 1. AD inventory: domain controllers (the denominator) -------------------
Import-Module ActiveDirectory -ErrorAction SilentlyContinue
$manifest.areas['domain-controllers'] = Save-Area 'domain-controllers' {
    Get-ADDomainController -Filter * | Select-Object Name, HostName, Domain, Site, IsGlobalCatalog, IsReadOnly, OperatingSystem, IPv4Address
}

# --- 2. AD FS / AD CS role holders (best-effort discovery) -------------------
# AD FS servers register a service connection point; AD CS enrollment services live under the config NC.
$manifest.areas['adfs-servers'] = Save-Area 'adfs-servers' {
    try {
        $cfgNc = (Get-ADRootDSE).configurationNamingContext
        Get-ADObject -SearchBase $cfgNc -Filter "objectClass -eq 'serviceConnectionPoint' -and name -eq 'ADFS'" -ErrorAction SilentlyContinue | Select-Object Name, DistinguishedName
    } catch { @{ note = 'AD FS SCP query failed — confirm AD FS server list manually'; verify = $true } }
}
$manifest.areas['adcs-servers'] = Save-Area 'adcs-servers' {
    try {
        $cfgNc = (Get-ADRootDSE).configurationNamingContext
        Get-ADObject -SearchBase "CN=Enrollment Services,CN=Public Key Services,CN=Services,$cfgNc" -Filter * -ErrorAction SilentlyContinue | Select-Object Name, DistinguishedName, dNSHostName
    } catch { @{ note = 'AD CS enrollment-services query failed — confirm AD CS server list manually'; verify = $true } }
}

# --- 3. MDI sensor list & health (Graph where available; else portal verify) -
Import-Module Microsoft.Graph.Authentication -ErrorAction SilentlyContinue
try { Connect-MgGraph -Scopes 'SecurityEvents.Read.All' -NoWelcome -ErrorAction Stop } catch { Write-Host "  (Graph connect: $($_.Exception.Message))" -ForegroundColor Yellow }

$manifest.areas['mdi-sensors'] = Save-Area 'mdi-sensors' {
    try {
        # NOTE: MDI sensor health has limited/evolving public API surface. *Verify current endpoint.*
        $r = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/security/identities/sensors' -ErrorAction Stop
        if ($r.value) { $r.value } else { @{ note = 'No sensor API data returned — confirm sensor list & health in Settings > Identities > Sensors'; verify = $true } }
    } catch { @{ note = "MDI sensor read not available via API ($($_.Exception.Message)) — confirm in Settings > Identities > Sensors"; verify = $true } }
}
$manifest.verifyItems += 'mdi-sensors (confirm sensor presence & health in portal)'

# --- 4. DSA + honeytoken signals (portal verify where no API) ----------------
$manifest.areas['dsa-signal'] = Save-Area 'dsa-signal' {
    @{ note = 'Confirm Directory Service Account in Settings > Identities > Directory service accounts. Best practice = gMSA, least privilege.'; verify = $true }
}
$manifest.verifyItems += 'dsa-signal (confirm DSA present & is a gMSA)'

# Honeytoken: tagged entities appear in IdentityInfo/portal entity tags. Best-effort via hunting.
$manifest.areas['honeytoken-signal'] = Save-Area 'honeytoken-signal' {
    try {
        $kql = 'IdentityInfo | where Tags has "Honeytoken" | project AccountName, AccountDomain, Tags | take 50'
        $r = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body (@{ Query = $kql } | ConvertTo-Json) -ContentType 'application/json' -ErrorAction Stop
        if ($r.results.Count -gt 0) { $r.results } else { @{ note = 'No honeytoken-tagged identities found via hunting — confirm entity tags in Settings > Identities > Entity tags'; verify = $true } }
    } catch { @{ note = "Honeytoken hunting failed ($($_.Exception.Message)) — confirm entity tags in portal"; verify = $true } }
}
$manifest.verifyItems += 'honeytoken-signal (confirm honeytoken accounts exist & are tagged)'

# --- 5. ISPM: identity Secure Score recommendations --------------------------
$manifest.areas['secure-score'] = Save-Area 'secure-score' {
    try { (Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/security/secureScores?$top=1').value } catch { @{ error = $_.Exception.Message } }
}
$manifest.areas['secure-score-controls'] = Save-Area 'secure-score-controls' {
    try { (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/security/secureScoreControlProfiles?`$top=200").value | Where-Object { $_.controlCategory -match 'Identity' } } catch { @{ error = $_.Exception.Message } }
}

# --- 6. Identity detection activity (30d) ------------------------------------
$manifest.areas['identity-directory-events-30d'] = Save-Area 'identity-directory-events-30d' {
    try {
        $kql = @'
IdentityDirectoryEvents
| where Timestamp > ago(30d)
| summarize Events = count() by ActionType
| top 25 by Events
'@
        (Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body (@{ Query = $kql } | ConvertTo-Json) -ContentType 'application/json' -ErrorAction Stop).results
    } catch { @{ error = $_.Exception.Message } }
}

$manifest | ConvertTo-Json -Depth 8 | Set-Content -Path (Join-Path $OutputDir 'discovery-manifest.json') -Encoding UTF8
Write-Host "`nDiscovery complete — raw evidence in '$OutputDir'. Items flagged 'verify' need portal confirmation." -ForegroundColor Green
Write-Host "Read-only; no changes made. Next: SOAMDI-Coverage.ps1 then SOAMDI-Assess.ps1." -ForegroundColor Green
