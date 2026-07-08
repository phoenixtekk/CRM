<#
.SYNOPSIS
    PURVEDM-Discovery.ps1 — EDM readiness/discovery assessment (READ-ONLY).
.DESCRIPTION
    PURPOSE
        Reports the tenant's Exact Data Match (EDM) readiness: existing EDM schemas (data stores) and
        EDM-based sensitive information types, and — via Microsoft Graph — whether the required
        'EDM_DataUploaders' security group exists and who is in it (the accounts authorized to run the
        EDM Upload Agent). Read-only: it changes nothing and reads no sensitive record data.
    HOW TO RUN
        # Full readiness check (S&C PowerShell + Graph):
        powershell -File .\PURVEDM-Discovery.ps1
        # Skip the Graph/group check (S&C PowerShell only):
        powershell -File .\PURVEDM-Discovery.ps1 -SkipGraph
        Requires Security & Compliance PowerShell (Connect-IPPSSession) and, for the group check,
        Microsoft Graph (Connect-MgGraph with Group.Read.All / GroupMember.Read.All).
    EXPECTED RESULTS
        Prints the EDM schemas and EDM SITs found, and PASS/ATTENTION for the EDM_DataUploaders group
        (exists + has members = PASS). No schemas/SITs yet is expected on a fresh tenant.
.NOTES
    Purview — Exact Data Match. Read-only. No credentials, salts, or record data in code.
#>
[CmdletBinding()]
param(
    [string]$UploaderGroupName = 'EDM_DataUploaders',
    [string]$UserPrincipalName,
    [switch]$SkipGraph
)

function Write-Head($t) { Write-Host ("`n=== {0} ===" -f $t) -ForegroundColor Cyan }

# --- Connect to Security & Compliance PowerShell (read-only usage) ---
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host 'Installing ExchangeOnlineManagement module (CurrentUser)...' -ForegroundColor Yellow
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpEdmSchema -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

# --- EDM schemas (data stores) ---
Write-Head 'EDM schemas (data stores)'
$schemas = @()
try { $schemas = @(Get-DlpEdmSchema -ErrorAction Stop) } catch {
    Write-Host ("Could not read EDM schemas: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    Write-Host 'If this errors on licensing/permissions, verify E5/E5 Compliance and an EDM authoring role.' -ForegroundColor Yellow
}
if ($schemas.Count -eq 0) {
    Write-Host 'No EDM schemas found (expected on a fresh tenant — create one per the Implementation Guide).'
} else {
    $schemas | ForEach-Object {
        $fields = @()
        try { $fields = @($_.Field | ForEach-Object { $_.name }) } catch {}
        Write-Host ("- {0}  (fields: {1})" -f $_.Name, ($(if ($fields) { $fields -join ', ' } else { 'n/a' })))
    }
}

# --- EDM-based sensitive information types ---
Write-Head 'EDM sensitive information types'
$edmSits = @()
try {
    $edmSits = @(Get-DlpSensitiveInformationType -ErrorAction Stop |
        Where-Object { $_.Publisher -match 'EDM' -or $_.Name -match 'EDM' -or $_.RulePackType -match 'EDM' })
} catch {
    Write-Host ("Could not read sensitive information types: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}
if ($edmSits.Count -eq 0) {
    Write-Host 'No EDM SITs detected yet (create one that references your schema).'
} else {
    $edmSits | ForEach-Object { Write-Host ("- {0}" -f $_.Name) }
}

# --- EDM_DataUploaders group (Graph) ---
if (-not $SkipGraph) {
    Write-Head ("Upload authorization: '{0}' security group (Graph)" -f $UploaderGroupName)
    try {
        if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Groups)) {
            Write-Host 'Installing Microsoft.Graph.Groups module (CurrentUser)...' -ForegroundColor Yellow
            Install-Module Microsoft.Graph.Groups -Scope CurrentUser -Force -AllowClobber
        }
        Import-Module Microsoft.Graph.Groups -ErrorAction Stop
        if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'Group.Read.All','GroupMember.Read.All' | Out-Null }

        $grp = Get-MgGroup -Filter "displayName eq '$UploaderGroupName'" -ErrorAction Stop
        if (-not $grp) {
            Write-Host ("ATTENTION: group '{0}' not found — create it in Entra ID and add the upload account (R3)." -f $UploaderGroupName) -ForegroundColor Yellow
        } else {
            $members = @(Get-MgGroupMember -GroupId $grp.Id -All -ErrorAction Stop)
            if ($members.Count -eq 0) {
                Write-Host ("ATTENTION: '{0}' exists but has NO members — add the upload account (R3)." -f $UploaderGroupName) -ForegroundColor Yellow
            } else {
                Write-Host ("PASS: '{0}' exists with {1} member(s):" -f $UploaderGroupName, $members.Count) -ForegroundColor Green
                $members | ForEach-Object {
                    $d = $_.AdditionalProperties['userPrincipalName']; if (-not $d) { $d = $_.AdditionalProperties['displayName'] }
                    Write-Host ("   - {0}" -f $d)
                }
            }
        }
    } catch {
        Write-Host ("Graph check skipped/failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
        Write-Host 'Re-run with the Graph module + Group.Read.All / GroupMember.Read.All, or use -SkipGraph.' -ForegroundColor Yellow
    }
} else {
    Write-Host "`n(Graph group check skipped by -SkipGraph.)" -ForegroundColor DarkGray
}

Write-Head 'Summary'
Write-Host ("EDM schemas: {0} | EDM SITs: {1}" -f $schemas.Count, $edmSits.Count)
Write-Host 'Next: design/create the schema (PURVEDM-Schema.ps1), hash+upload with EdmUploadAgent.exe, then validate (PURVEDM-Validate.ps1).'
Write-Host 'Reminder: EDM is licensing-dependent (E5 / E5 Compliance) — verify capability/limits in your tenant.' -ForegroundColor DarkGray
