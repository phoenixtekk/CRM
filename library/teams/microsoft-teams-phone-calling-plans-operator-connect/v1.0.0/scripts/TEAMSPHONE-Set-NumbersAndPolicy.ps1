<#
.SYNOPSIS
    TEAMSPHONE-Set-NumbersAndPolicy.ps1 — assign phone numbers + grant voice policies for Teams Phone users. Defaults to -WhatIf.
.DESCRIPTION
    PURPOSE
        Enables Teams Phone for a set of users from a mapping CSV: assigns each number with the correct
        PhoneNumberType (CallingPlan / OperatorConnect), attaches the emergency LocationId, and grants
        the named tenant dial plan, calling policy, and emergency calling policy. SAFE BY DEFAULT —
        runs in -WhatIf mode (prints intended changes, changes nothing) unless -Execute is supplied.
        -Rollback previews/applies the reversal (unassign number, reset policies to global).
    HOW TO RUN
        Dry-run (default, NO changes):
          .\TEAMSPHONE-Set-NumbersAndPolicy.ps1 -MappingCsv .\pilot-numbers.csv
        Apply:
          .\TEAMSPHONE-Set-NumbersAndPolicy.ps1 -MappingCsv .\pilot-numbers.csv -Execute
        Roll back (preview then apply):
          .\TEAMSPHONE-Set-NumbersAndPolicy.ps1 -MappingCsv .\pilot-numbers.csv -Rollback
          .\TEAMSPHONE-Set-NumbersAndPolicy.ps1 -MappingCsv .\pilot-numbers.csv -Rollback -Execute
        (PowerShell 5.1+/7+, MicrosoftTeams module; connect with Connect-MicrosoftTeams — modern auth / MFA)
        MappingCsv columns: UserPrincipalName, PhoneNumber (+E164), PhoneNumberType (CallingPlan|OperatorConnect),
                            LocationId (optional), DialPlan, CallingPolicy, EmergencyCallingPolicy
    EXPECTED RESULTS
        -WhatIf: one line per user describing the exact assignment + grants that WOULD be made; nothing changes.
        -Execute: numbers assigned and policies granted for the listed users only; a per-user result is printed.
.NOTES
    Teams — Teams Phone Enablement (Calling Plans & Operator Connect). Default mode makes NO changes. No stored credentials.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$MappingCsv,
    [switch]$Execute,     # absent = -WhatIf (default, no changes)
    [switch]$Rollback,    # reverse: unassign number, reset policies to Global
    [string]$ResultCsv
)

$WhatIf = -not $Execute
$mode = if ($Rollback) { 'ROLLBACK' } else { 'ENABLE' }
$run  = if ($WhatIf)   { 'WHATIF (no changes)' } else { 'EXECUTE (applying changes)' }

if (-not (Test-Path $MappingCsv)) { throw "Mapping CSV not found: $MappingCsv" }
if (-not (Get-Module -ListAvailable -Name MicrosoftTeams)) {
    Install-Module MicrosoftTeams -Scope CurrentUser -Force -AllowClobber
}
Import-Module MicrosoftTeams -ErrorAction Stop
try { $null = Get-CsTenant -ErrorAction Stop } catch { Connect-MicrosoftTeams | Out-Null }

Write-Host ("=== TEAMSPHONE {0} [{1}] from {2} ===" -f $mode, $run, $MappingCsv) -ForegroundColor $(if ($WhatIf) { 'Yellow' } else { 'Red' })

$map = Import-Csv -Path $MappingCsv
$results = @()

foreach ($m in $map) {
    $upn = $m.UserPrincipalName
    if (-not $upn) { continue }

    if ($Rollback) {
        if ($WhatIf) {
            $line = "WOULD unassign {0} ({1}) from {2}; reset dial plan / calling / emergency policies to Global" -f $m.PhoneNumber, $m.PhoneNumberType, $upn
            Write-Host $line -ForegroundColor Yellow
            $results += [pscustomobject]@{ User=$upn; Action='WOULD-ROLLBACK'; Detail=$line }
        } else {
            try {
                Remove-CsPhoneNumberAssignment -Identity $upn -PhoneNumber $m.PhoneNumber -PhoneNumberType $m.PhoneNumberType -ErrorAction Stop
                Grant-CsTenantDialPlan            -Identity $upn -PolicyName $null -ErrorAction SilentlyContinue
                Grant-CsTeamsCallingPolicy        -Identity $upn -PolicyName $null -ErrorAction SilentlyContinue
                Grant-CsTeamsEmergencyCallingPolicy -Identity $upn -PolicyName $null -ErrorAction SilentlyContinue
                Write-Host ("OK    rolled back {0}" -f $upn) -ForegroundColor Green
                $results += [pscustomobject]@{ User=$upn; Action='ROLLED-BACK'; Detail="Number unassigned; policies reset to Global" }
            } catch {
                Write-Host ("ERROR {0}: {1}" -f $upn, $_.Exception.Message) -ForegroundColor Red
                $results += [pscustomobject]@{ User=$upn; Action='ERROR'; Detail=$_.Exception.Message }
            }
        }
        continue
    }

    # --- ENABLE path ---
    $desc = "assign {0} ({1}) to {2}" -f $m.PhoneNumber, $m.PhoneNumberType, $upn
    if ($m.LocationId)             { $desc += "; location {0}" -f $m.LocationId }
    if ($m.DialPlan)               { $desc += "; dial plan '{0}'" -f $m.DialPlan }
    if ($m.CallingPolicy)          { $desc += "; calling policy '{0}'" -f $m.CallingPolicy }
    if ($m.EmergencyCallingPolicy) { $desc += "; emergency policy '{0}'" -f $m.EmergencyCallingPolicy }

    if ($WhatIf) {
        Write-Host ("WOULD {0}" -f $desc) -ForegroundColor Yellow
        $results += [pscustomobject]@{ User=$upn; Action='WOULD'; Detail=$desc }
        continue
    }

    try {
        $assignArgs = @{ Identity = $upn; PhoneNumber = $m.PhoneNumber; PhoneNumberType = $m.PhoneNumberType; ErrorAction = 'Stop' }
        if ($m.LocationId) { $assignArgs['LocationId'] = $m.LocationId }
        Set-CsPhoneNumberAssignment @assignArgs   # also enables enterprise voice

        if ($m.DialPlan)               { Grant-CsTenantDialPlan             -Identity $upn -PolicyName $m.DialPlan -ErrorAction Stop }
        if ($m.CallingPolicy)          { Grant-CsTeamsCallingPolicy         -Identity $upn -PolicyName $m.CallingPolicy -ErrorAction Stop }
        if ($m.EmergencyCallingPolicy) { Grant-CsTeamsEmergencyCallingPolicy -Identity $upn -PolicyName $m.EmergencyCallingPolicy -ErrorAction Stop }

        Write-Host ("OK    {0}" -f $desc) -ForegroundColor Green
        $results += [pscustomobject]@{ User=$upn; Action='DONE'; Detail=$desc }
    } catch {
        Write-Host ("ERROR {0}: {1}" -f $upn, $_.Exception.Message) -ForegroundColor Red
        $results += [pscustomobject]@{ User=$upn; Action='ERROR'; Detail=$_.Exception.Message }
    }
}

Write-Host ("=== {0} [{1}]: {2} users processed ===" -f $mode, $run, $results.Count) -ForegroundColor Cyan
if ($ResultCsv) { $results | Export-Csv -Path $ResultCsv -NoTypeInformation; Write-Host ("Saved results to {0}" -f $ResultCsv) -ForegroundColor Green }

Disconnect-MicrosoftTeams -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
