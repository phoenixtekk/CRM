<#
.SYNOPSIS
    M365LIC-Remediation.ps1 — SAFE reclamation of Microsoft 365 licenses (remove unused/duplicate, right-size over-tier). Defaults to -WhatIf.
.DESCRIPTION
    PURPOSE
        Acts on the validated candidate list for a target group: removes unused (leaver) and duplicate
        licenses and right-sizes over-tier users to a lower SKU. SAFE BY DEFAULT — runs in -WhatIf
        mode unless -Execute is supplied, re-checks the protected exclusion group at run time, and
        reclaims group-assigned seats by removing the user from the licensing group rather than
        stripping the user license.
    HOW TO RUN
        Dry-run (default, NO changes):
          powershell -ExecutionPolicy Bypass -File .\M365LIC-Remediation.ps1 -TargetGroup "Reclaim Targets - Pilot - Stage1" -CandidateCsv C:\Temp\M365LIC-Candidates.csv
        Apply changes:
          powershell -ExecutionPolicy Bypass -File .\M365LIC-Remediation.ps1 -TargetGroup "Reclaim Targets - Pilot - Stage1" -CandidateCsv C:\Temp\M365LIC-Candidates.csv -Execute
        Requires the Microsoft Graph PowerShell SDK and scopes:
        User.ReadWrite.All, Organization.Read.All, Directory.Read.All, GroupMember.ReadWrite.All.
    EXPECTED RESULTS
        -WhatIf: one line per user describing the exact change that WOULD be made; nothing changes.
        -Execute: the listed licenses are removed / right-sized for members of the target group only;
        a per-user result is printed and a result CSV optionally written.
.NOTES
    Asset Mgt — Microsoft 365 License Optimization & Reharvesting. Default mode makes NO changes.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$TargetGroup,
    [Parameter(Mandatory)][string]$CandidateCsv,
    [string]$ExclusionGroup = 'Reclaim Exclusions - Shared+Service - AllStages',
    [switch]$Execute,                  # absent = -WhatIf (default, no changes)
    [string]$ResultCsv
)

$WhatIf = -not $Execute
$mode = if ($WhatIf) { 'WHATIF (no changes)' } else { 'EXECUTE (applying changes)' }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$scopes = if ($WhatIf) { @('User.Read.All','Organization.Read.All','Directory.Read.All') } else { @('User.ReadWrite.All','Organization.Read.All','Directory.Read.All','GroupMember.ReadWrite.All') }
Connect-MgGraph -Scopes $scopes -NoWelcome

Write-Host ("=== M365LIC Remediation [{0}] target: {1} ===" -f $mode, $TargetGroup) -ForegroundColor $(if ($WhatIf) { 'Yellow' } else { 'Red' })

# --- SKU id <-> part-number maps ---
$skuById = @{}; $skuByName = @{}
(Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value | ForEach-Object { $skuById[$_.skuId] = $_.skuPartNumber; $skuByName[$_.skuPartNumber] = $_.skuId }

function Get-GroupMemberUpns([string]$name) {
    $set = New-Object System.Collections.Generic.HashSet[string]
    $g = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter=displayName eq '{0}'&`$select=id" -f ($name -replace "'","''"))).value | Select-Object -First 1
    if (-not $g) { return $set }
    $u = ("/v1.0/groups/{0}/members?`$select=userPrincipalName&`$top=999" -f $g.id)
    do { $r = Invoke-MgGraphRequest -Method GET -Uri $u; $r.value | ForEach-Object { if ($_.userPrincipalName) { [void]$set.Add($_.userPrincipalName.ToLower()) } }; $u = $r.'@odata.nextLink' } while ($u)
    return $set
}

$targets   = Get-GroupMemberUpns $TargetGroup
$protected = Get-GroupMemberUpns $ExclusionGroup
if ($targets.Count -eq 0) { Write-Warning ("Target group '{0}' has no members — nothing to do." -f $TargetGroup); Disconnect-MgGraph | Out-Null; return }

$candidates = Import-Csv -Path $CandidateCsv
$results = @()

foreach ($c in $candidates) {
    $upn = $c.UserPrincipalName
    if (-not $upn) { continue }
    if (-not $targets.Contains($upn.ToLower())) { continue }              # only act on the target group
    if ($protected.Contains($upn.ToLower())) {                            # safety re-check
        $results += [pscustomobject]@{ User=$upn; Action='SKIP'; Detail='In exclusion group (protected)' }
        Write-Host ("SKIP  {0} — protected" -f $upn) -ForegroundColor DarkYellow
        continue
    }

    # Determine the SKU(s) to remove for this classification.
    $remove = @()
    switch ($c.Classification) {
        'Unused'    { $remove = @($c.Skus -split ';' | Where-Object { $_ }) }
        'Duplicate' { if ($c.SuggestedAction -match 'Remove (\S+)') { $remove = @($Matches[1]) } }
        'OverTier'  { if ($c.SuggestedAction -match 'downgrade (\S+) -> (\S+)') { $remove = @($Matches[1]); $addSku = $Matches[2] } }
        default     { continue }
    }

    foreach ($skuName in $remove) {
        $skuId = $skuByName[$skuName]
        if (-not $skuId) { $results += [pscustomobject]@{ User=$upn; Action='ERROR'; Detail="Unknown SKU $skuName" }; continue }

        # Is this seat group-assigned? If so reclaim via group membership, not user-license removal.
        $detail = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/users/{0}/licenseDetails" -f $upn)).value | Where-Object { $_.skuId -eq $skuId } | Select-Object -First 1
        $byGroup = $detail -and ($detail.PSObject.Properties.Name -contains 'assignedByGroup') -and $detail.assignedByGroup

        if ($byGroup) {
            $line = "REMOVE-FROM-LICENSING-GROUP {0} ({1}) — seat is group-assigned; remove user from the assigning group manually or via M365LIC-Set-ScopeTargeting.ps1" -f $upn, $skuName
            $results += [pscustomobject]@{ User=$upn; Action=$(if($WhatIf){'WOULD'}else{'MANUAL'}); Detail=$line }
            Write-Host $line -ForegroundColor Magenta
            continue
        }

        if ($WhatIf) {
            $what = if ($c.Classification -eq 'OverTier') { "WOULD right-size {0}: remove {1}, add {2}" -f $upn, $skuName, $addSku } else { "WOULD remove {0} from {1}" -f $skuName, $upn }
            Write-Host $what -ForegroundColor Yellow
            $results += [pscustomobject]@{ User=$upn; Action='WOULD'; Detail=$what }
        } else {
            $body = @{ addLicenses = @(); removeLicenses = @($skuId) }
            if ($c.Classification -eq 'OverTier' -and $addSku -and $skuByName[$addSku]) { $body.addLicenses = @(@{ skuId = $skuByName[$addSku]; disabledPlans = @() }) }
            try {
                Invoke-MgGraphRequest -Method POST -Uri ("/v1.0/users/{0}/assignLicense" -f $upn) -Body ($body | ConvertTo-Json -Depth 5) -ContentType 'application/json' | Out-Null
                $done = if ($c.Classification -eq 'OverTier') { "right-sized {0}: -{1} +{2}" -f $upn, $skuName, $addSku } else { "removed {0} from {1}" -f $skuName, $upn }
                Write-Host ("OK    {0}" -f $done) -ForegroundColor Green
                $results += [pscustomobject]@{ User=$upn; Action='DONE'; Detail=$done }
            } catch {
                Write-Host ("ERROR {0}: {1}" -f $upn, $_.Exception.Message) -ForegroundColor Red
                $results += [pscustomobject]@{ User=$upn; Action='ERROR'; Detail=$_.Exception.Message }
            }
        }
    }
}

Write-Host ("=== {0}: {1} actions ({2}) ===" -f $mode, $results.Count, $(if($WhatIf){'no changes made'}else{'applied'})) -ForegroundColor Cyan
if ($ResultCsv) { $results | Export-Csv -Path $ResultCsv -NoTypeInformation; Write-Host ("Saved results to {0}" -f $ResultCsv) -ForegroundColor Green }

Disconnect-MgGraph | Out-Null
