<#
.SYNOPSIS
    OPSADOPT-Remediation.ps1 — change-controlled adoption ring helper: EXPANDS the adoption ring by the next wave (AddWave) or rolls a wave back (RemoveWave) via Microsoft Graph group membership. -WhatIf by DEFAULT; writes only with -Commit.
.DESCRIPTION
    PURPOSE
        The one write-capable tool, safe by default. Adds (AddWave) or removes (RemoveWave) the users listed
        in a wave CSV to/from the adoption ring group in Microsoft Graph — the concrete act of expanding the
        rollout after a ring has cleared its wave gate. With no -Commit it PREVIEWS the membership change and
        makes NONE. On -Commit it applies the change and appends a row to the change record CSV
        (who/when/action/ring/user). No credentials or secrets in code.
    HOW TO RUN
        Connect-MgGraph -Scopes 'Group.ReadWrite.All','User.Read.All'
        # Preview (default, no change):
        .\OPSADOPT-Remediation.ps1 -Action AddWave -RingGroup "Adoption Ring - Purview - Wave2" -MembersCsv .\Wave2.csv -WhatIf
        # Apply inside a change window, AFTER a CLEAR wave gate:
        .\OPSADOPT-Remediation.ps1 -Action AddWave -RingGroup "Adoption Ring - Purview - Wave2" -MembersCsv .\Wave2.csv -Commit
        .\OPSADOPT-Remediation.ps1 -Action RemoveWave -RingGroup "Adoption Ring - Purview - Wave2" -MembersCsv .\Wave2.csv -Commit
        MembersCsv column: Upn   |   PowerShell 5.1+/7+; requires Microsoft.Graph.
    EXPECTED RESULTS
        -WhatIf: lists the users it WOULD add/remove and confirms NO change was made.
        -Commit: membership changes as previewed AND a row per user is written to the change record CSV.
.NOTES
    Purview — Adoption Program. HIGH-IMPACT: expand a ring ONLY after its wave gate is CLEAR, in a change
    window, with approval. Introducing mandatory labeling / DLP enforcement is done on the (label/DLP) policy
    scope itself under its own change control and is intentionally NOT automated here — this tool only manages
    ring MEMBERSHIP. Verify group scope/licensing for your tenant.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)][ValidateSet('AddWave','RemoveWave')][string]$Action,
    [Parameter(Mandatory=$true)][string]$RingGroup,
    [Parameter(Mandatory=$true)][string]$MembersCsv,
    [switch]$Commit,
    [string]$ChangeRecordCsv = '.\Change-Record-Purview-Adoption.csv'
)

# Safe by default: unless -Commit is passed, force -WhatIf behavior (no writes).
if (-not $Commit) { $WhatIfPreference = $true }

if (-not (Get-Command Get-MgGroup -ErrorAction SilentlyContinue)) {
    Write-Error "Microsoft.Graph not available. Install-Module Microsoft.Graph and Connect-MgGraph -Scopes 'Group.ReadWrite.All','User.Read.All'."
    return
}
if (-not (Test-Path $MembersCsv)) { Write-Error "Members CSV not found at $MembersCsv (expected column: Upn)."; return }

$members = Import-Csv $MembersCsv
if (-not ($members | Get-Member -Name 'Upn' -MemberType NoteProperty)) { Write-Error "Members CSV must have a 'Upn' column."; return }

$grp = Get-MgGroup -Filter "displayName eq '$RingGroup'" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $grp) { Write-Error "Ring group '$RingGroup' not found. Create it first (Requirement 2.4)."; return }

$existing = @(Get-MgGroupMember -GroupId $grp.Id -All | ForEach-Object { $_.AdditionalProperties.userPrincipalName } | Where-Object { $_ })

Write-Host ("=== {0}: ring '{1}' ({2} users in CSV) ===" -f $Action, $RingGroup, @($members).Count) -ForegroundColor Cyan

$operator = try { (Get-MgContext).Account } catch { $env:USERNAME }
$applied = 0; $skipped = 0

foreach ($m in $members) {
    $upn = [string]$m.Upn
    if (-not $upn) { continue }

    $inGroup = $existing -contains $upn
    if ($Action -eq 'AddWave' -and $inGroup)     { Write-Host ("  skip (already in ring): {0}" -f $upn) -ForegroundColor DarkGray; $skipped++; continue }
    if ($Action -eq 'RemoveWave' -and -not $inGroup) { Write-Host ("  skip (not in ring): {0}" -f $upn) -ForegroundColor DarkGray; $skipped++; continue }

    $verb = if ($Action -eq 'AddWave') { 'add to' } else { 'remove from' }
    if ($PSCmdlet.ShouldProcess("$upn", "$verb ring '$RingGroup'")) {
        try {
            $user = Get-MgUser -UserId $upn -ErrorAction Stop
            if ($Action -eq 'AddWave') { New-MgGroupMember -GroupId $grp.Id -DirectoryObjectId $user.Id -ErrorAction Stop }
            else { Remove-MgGroupMember -GroupId $grp.Id -DirectoryObjectId $user.Id -ErrorAction Stop }
            Write-Host ("  APPLIED: {0} {1} ring." -f $upn, $(if($Action -eq 'AddWave'){'added to'}else{'removed from'})) -ForegroundColor Green
            $applied++
            [pscustomobject]@{
                TimestampUtc = (Get-Date).ToUniversalTime().ToString('s')
                Operator     = $operator
                Action       = $Action
                RingGroup    = $RingGroup
                Upn          = $upn
            } | Export-Csv -Path $ChangeRecordCsv -NoTypeInformation -Append
        } catch { Write-Error ("  FAILED for {0}: {1}" -f $upn, $_.Exception.Message) }
    }
}

if (-not $Commit) {
    Write-Host ("WHATIF (default): no change made. {0} user(s) would be affected. Re-run with -Commit inside a change window AFTER a CLEAR wave gate." -f (@($members).Count - $skipped)) -ForegroundColor Yellow
} else {
    Write-Host ("Done. Applied: {0}  Skipped: {1}. Changes recorded in {2}." -f $applied, $skipped, $ChangeRecordCsv) -ForegroundColor Green
}
