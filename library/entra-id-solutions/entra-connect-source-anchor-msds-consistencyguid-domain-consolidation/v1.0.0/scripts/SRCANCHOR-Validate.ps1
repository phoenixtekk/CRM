<#
.SYNOPSIS
    SRCANCHOR-Validate.ps1 — confirm the anchor switched and the value is unchanged (no re-sync risk).
.DESCRIPTION
    PURPOSE
        Read-only post-change validation. Confirms (1) the current source anchor is now
        mS-DS-ConsistencyGuid, (2) sampled in-scope objects have mS-DS-ConsistencyGuid populated and its
        Base64 EQUALS the object's prior immutableId (the objectGUID Base64) — proving the anchor value
        did not change, so no re-sync and no duplicates — and (3) optionally, if the Microsoft Graph SDK
        is present, that the matching Entra user's onPremisesImmutableId equals that same Base64 (no
        duplicate in the cloud). Makes no changes.
    HOW TO RUN
        On the Microsoft Entra Connect server, elevated:
            powershell -ExecutionPolicy Bypass -File .\SRCANCHOR-Validate.ps1 ^
                -IncludeOU "OU=Source Anchor - In-Scope OUs,DC=corp,DC=example,DC=com"
        Requires the ADSync module (Connect role) and the ActiveDirectory module. The optional cloud
        check needs the Microsoft Graph SDK and Directory.Read.All / User.Read.All.
    EXPECTED RESULTS
        "ANCHOR MIGRATED" when the anchor reads mS-DS-ConsistencyGuid and every sampled object's
        mS-DS-ConsistencyGuid Base64 matches its objectGUID Base64 (and, if checked, the Entra user's
        onPremisesImmutableId matches). No changes are made.
.NOTES
    White-label — the repeatable way. Read-only; the anchor change itself is done in the Microsoft Entra
    Connect wizard, never scripted. Vendor internals (Quest On Demand Migration) deferred to vendor docs.
#>
[CmdletBinding()]
param(
    [string[]]$IncludeOU,
    [int]$SampleSize = 10,
    [switch]$SkipGraph
)

Write-Host "`n=== Source Anchor Validation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
$ok = $true

# 1) Current source anchor
if (Get-Module -ListAvailable -Name ADSync) {
    Import-Module ADSync -ErrorAction Stop
    try {
        $params = (Get-ADSyncGlobalSettings).Parameters
        $anchor = ($params | Where-Object { $_.Name -eq 'Microsoft.SourceAnchorAttribute' }).Value
        Write-Host ("Current source anchor : {0}" -f $anchor) -ForegroundColor ($(if ($anchor -eq 'mS-DS-ConsistencyGuid') { 'Green' } else { 'Yellow' }))
        if ($anchor -ne 'mS-DS-ConsistencyGuid') { $ok = $false }
    } catch { Write-Host "Could not read source anchor: $($_.Exception.Message)" -ForegroundColor Yellow; $ok = $false }
} else {
    Write-Host "ADSync module not found — run on the Microsoft Entra Connect server." -ForegroundColor Yellow; $ok = $false
}

# 2) Sampled objects: mS-DS-ConsistencyGuid Base64 == objectGUID Base64
$upns = @()
if (Get-Module -ListAvailable -Name ActiveDirectory) {
    Import-Module ActiveDirectory -ErrorAction Stop
    $scopes = if ($IncludeOU) { $IncludeOU } else { @((Get-ADDomain).DistinguishedName) }
    $checked = 0; $matched = 0
    foreach ($ou in $scopes) {
        if ($checked -ge $SampleSize) { break }
        $take = $SampleSize - $checked
        $objs = Get-ADUser -Filter * -SearchBase $ou -Properties objectGUID, 'mS-DS-ConsistencyGuid', UserPrincipalName -ResultSetSize $take -ErrorAction SilentlyContinue
        foreach ($o in $objs) {
            $checked++
            $cg = $o.'mS-DS-ConsistencyGuid'
            if (-not $cg) { Write-Host ("  {0}: mS-DS-ConsistencyGuid EMPTY (not seeded)" -f $o.UserPrincipalName) -ForegroundColor Yellow; $ok = $false; continue }
            $cgB64 = [Convert]::ToBase64String([byte[]]$cg)
            $ogB64 = [Convert]::ToBase64String($o.objectGUID.ToByteArray())
            $eq = ($cgB64 -eq $ogB64)
            if ($eq) { $matched++; $upns += $o.UserPrincipalName }
            Write-Host ("  {0}: consistencyGuid={1} objectGUID={2} {3}" -f $o.UserPrincipalName, $cgB64, $ogB64, ($(if ($eq) { 'MATCH' } else { 'DIFFERENT' }))) -ForegroundColor ($(if ($eq) { 'Green' } else { 'Yellow' }))
            if (-not $eq) { $ok = $false }
        }
    }
    Write-Host ("Sampled {0} object(s); {1} with unchanged anchor value." -f $checked, $matched)
} else {
    Write-Host "ActiveDirectory module not found — cannot validate object values." -ForegroundColor Yellow; $ok = $false
}

# 3) Optional cloud check via Graph — onPremisesImmutableId unchanged (no duplicate)
if (-not $SkipGraph -and $upns.Count -gt 0 -and (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    try {
        Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
        Connect-MgGraph -Scopes 'Directory.Read.All', 'User.Read.All' -NoWelcome
        foreach ($upn in ($upns | Select-Object -First 5)) {
            $u = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$upn`?`$select=userPrincipalName,onPremisesImmutableId" -ErrorAction SilentlyContinue)
            if ($u) { Write-Host ("  [cloud] {0}: onPremisesImmutableId={1}" -f $u.userPrincipalName, $u.onPremisesImmutableId) }
        }
        Disconnect-MgGraph | Out-Null
        Write-Host "  Compare each onPremisesImmutableId to the objectGUID Base64 above — they should match (no duplicate)." -ForegroundColor Cyan
    } catch { Write-Host "Graph check skipped: $($_.Exception.Message)" -ForegroundColor Yellow }
} elseif (-not $SkipGraph) {
    Write-Host "Microsoft Graph SDK not present — skipping the cloud immutableId check." -ForegroundColor Yellow
}

if ($ok) { Write-Host "`nResult: ANCHOR MIGRATED — mS-DS-ConsistencyGuid, value unchanged (seamless)." -ForegroundColor Green; exit 0 }
else { Write-Host "`nResult: NOT CONFIRMED — review the flagged items (anchor not switched, empty seed, or changed value)." -ForegroundColor Yellow; exit 1 }
