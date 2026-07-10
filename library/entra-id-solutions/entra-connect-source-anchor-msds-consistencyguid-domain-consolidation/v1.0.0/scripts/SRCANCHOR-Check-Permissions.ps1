<#
.SYNOPSIS
    SRCANCHOR-Check-Permissions.ps1 — verify the connector account can write mS-DS-ConsistencyGuid.
.DESCRIPTION
    PURPOSE
        Read-only permission check. To switch the source anchor, Microsoft Entra Connect seeds each
        in-scope object's objectGUID into its mS-DS-ConsistencyGuid attribute (a write-back into AD), so
        the AD DS connector (sync) account must have Write permission to mS-DS-ConsistencyGuid on the
        in-scope OUs. This script reads each OU's ACL, resolves the mS-DS-ConsistencyGuid schema GUID,
        and reports per-OU PASS/FAIL for a WriteProperty grant to the supplied connector account (an
        explicit grant on the exact attribute, or on all properties). Makes no changes.
    HOW TO RUN
        On a host with the ActiveDirectory module (RSAT AD tools), elevated:
            powershell -ExecutionPolicy Bypass -File .\SRCANCHOR-Check-Permissions.ps1 ^
                -ConnectorAccount "CORP\svc_adsync" ^
                -IncludeOU "OU=Source Anchor - In-Scope OUs,DC=corp,DC=example,DC=com"
        Supply the AD DS connector (sync) account (DOMAIN\sam or UPN) and one or more in-scope OU DNs.
    EXPECTED RESULTS
        Per-OU PASS (the connector account has Write mS-DS-ConsistencyGuid) or FAIL (grant it — see the
        Implementation Guide). Note: grants inherited via group membership on the account may also apply
        and are reported when the ACL identity resolves to the account. No changes are made.
.NOTES
    White-label — the repeatable way. Read-only; the anchor change itself is done in the Microsoft Entra
    Connect wizard, never scripted. Vendor internals (Quest On Demand Migration) deferred to vendor docs.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ConnectorAccount,

    [Parameter(Mandatory = $true)]
    [string[]]$IncludeOU
)

if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Host "ActiveDirectory module required (RSAT AD tools)." -ForegroundColor Yellow
    return
}
Import-Module ActiveDirectory -ErrorAction Stop

Write-Host "`n=== Connector Write-Permission Check (mS-DS-ConsistencyGuid) ===" -ForegroundColor Cyan
Write-Host ("Connector account : {0}" -f $ConnectorAccount)

# Resolve the mS-DS-ConsistencyGuid schemaIDGUID
try {
    $schema = (Get-ADRootDSE).schemaNamingContext
    $attr = Get-ADObject -SearchBase $schema -LDAPFilter '(lDAPDisplayName=mS-DS-ConsistencyGuid)' -Properties schemaIDGUID -ErrorAction Stop
    $attrGuid = [guid]$attr.schemaIDGUID
    Write-Host ("Attribute GUID    : {0}" -f $attrGuid)
} catch {
    Write-Host "Could not resolve the mS-DS-ConsistencyGuid schema GUID: $($_.Exception.Message)" -ForegroundColor Yellow
    return
}
$emptyGuid = [guid]::Empty

# Resolve the connector account to an NTAccount string for comparison
try { $wantNt = (New-Object System.Security.Principal.NTAccount($ConnectorAccount)).Translate([System.Security.Principal.NTAccount]).Value }
catch { $wantNt = $ConnectorAccount }

$allPass = $true
foreach ($ou in $IncludeOU) {
    $pass = $false
    try {
        $acl = Get-Acl -Path ("AD:\{0}" -f $ou) -ErrorAction Stop
        foreach ($ace in $acl.Access) {
            if ($ace.AccessControlType -ne 'Allow') { continue }
            if (-not ($ace.ActiveDirectoryRights.ToString() -match 'WriteProperty|GenericWrite|GenericAll')) { continue }
            if ($ace.ObjectType -ne $attrGuid -and $ace.ObjectType -ne $emptyGuid) { continue }
            if ($ace.IdentityReference.Value -ieq $wantNt) { $pass = $true; break }
        }
        Write-Host ("  {0}`n    Write mS-DS-ConsistencyGuid: {1}" -f $ou, ($(if ($pass) { 'PASS' } else { 'FAIL' }))) -ForegroundColor ($(if ($pass) { 'Green' } else { 'Yellow' }))
    } catch {
        Write-Host ("  {0}`n    could not read ACL: {1}" -f $ou, $_.Exception.Message) -ForegroundColor Yellow
    }
    if (-not $pass) { $allPass = $false }
}

if ($allPass) {
    Write-Host "`nResult: PASS — the connector account can write mS-DS-ConsistencyGuid on every in-scope OU." -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nResult: FAIL — delegate Write mS-DS-ConsistencyGuid to the connector account on the failing OU(s) (Implementation Step 4)." -ForegroundColor Yellow
    exit 1
}
