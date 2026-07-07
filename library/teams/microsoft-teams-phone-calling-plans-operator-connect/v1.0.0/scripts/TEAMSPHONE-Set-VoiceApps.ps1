<#
.SYNOPSIS
    TEAMSPHONE-Set-VoiceApps.ps1 — create/associate resource accounts, a call queue, and an auto attendant. Defaults to -WhatIf.
.DESCRIPTION
    PURPOSE
        Builds the voice-app layer: resource accounts ("Resource Account - AA-MainLine" /
        "Resource Account - CQ-Support"), a call queue ("Call Queue - Support - Prod") backed by the
        CQ resource account, and an auto attendant ("Auto Attendant - MainLine - Prod") with a
        business-hours schedule and a menu option routing callers to the call queue. SAFE BY DEFAULT —
        runs in -WhatIf (prints intended actions, changes nothing) unless -Execute is supplied.
        NOTE: resource accounts must be licensed (Teams Phone Resource Account) and assigned a service
        number (Set-CsPhoneNumberAssignment) — do that before -Execute or the association will fail.
    HOW TO RUN
        Dry-run (default, NO changes):
          .\TEAMSPHONE-Set-VoiceApps.ps1 -AaUpn aa-mainline@contoso.com -CqUpn cq-support@contoso.com -AgentUpns "a@contoso.com","b@contoso.com"
        Apply:
          .\TEAMSPHONE-Set-VoiceApps.ps1 -AaUpn aa-mainline@contoso.com -CqUpn cq-support@contoso.com -AgentUpns "a@contoso.com","b@contoso.com" -Execute
        (PowerShell 5.1+/7+, MicrosoftTeams module; connect with Connect-MicrosoftTeams — modern auth / MFA)
    EXPECTED RESULTS
        -WhatIf: prints each resource account, call queue, and auto attendant it WOULD create/associate.
        -Execute: creates the objects and associations; prints the resulting ObjectIds.
.NOTES
    Teams — Teams Phone Enablement (Calling Plans & Operator Connect). Default mode makes NO changes. No stored credentials.
    contoso.com is a documentation placeholder — substitute your tenant's routing domain.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$AaUpn,                 # auto attendant resource account UPN
    [Parameter(Mandatory)][string]$CqUpn,                 # call queue resource account UPN
    [string[]]$AgentUpns = @(),                            # call queue agents
    [string]$AaName = 'Auto Attendant - MainLine - Prod',
    [string]$CqName = 'Call Queue - Support - Prod',
    [switch]$Execute                                       # absent = -WhatIf (default, no changes)
)

$WhatIf = -not $Execute
$run = if ($WhatIf) { 'WHATIF (no changes)' } else { 'EXECUTE (applying changes)' }

if (-not (Get-Module -ListAvailable -Name MicrosoftTeams)) {
    Install-Module MicrosoftTeams -Scope CurrentUser -Force -AllowClobber
}
Import-Module MicrosoftTeams -ErrorAction Stop
try { $null = Get-CsTenant -ErrorAction Stop } catch { Connect-MicrosoftTeams | Out-Null }

Write-Host ("=== TEAMSPHONE Voice Apps [{0}] ===" -f $run) -ForegroundColor $(if ($WhatIf) { 'Yellow' } else { 'Red' })

function Ensure-ResourceAccount([string]$upn, [string]$display) {
    $ra = Get-CsOnlineApplicationInstance -Identity $upn -ErrorAction SilentlyContinue
    if ($ra) { Write-Host ("exists  resource account {0}" -f $upn) -ForegroundColor DarkGray; return $ra }
    if ($WhatIf) { Write-Host ("WOULD create resource account {0} ('{1}')" -f $upn, $display) -ForegroundColor Yellow; return $null }
    # ApplicationId GUIDs are fixed Microsoft values: AA = ce933385-9390-45d1-9512-c8d228074e07, CQ = 11cd3e2e-fccb-42ad-ad00-878b93575e07
    $appId = if ($display -match 'AA') { 'ce933385-9390-45d1-9512-c8d228074e07' } else { '11cd3e2e-fccb-42ad-ad00-878b93575e07' }
    $ra = New-CsOnlineApplicationInstance -UserPrincipalName $upn -DisplayName $display -ApplicationId $appId
    Write-Host ("OK    created resource account {0}" -f $upn) -ForegroundColor Green
    return $ra
}

# --- Resource accounts ---
$aaRa = Ensure-ResourceAccount -upn $AaUpn -display 'Resource Account - AA-MainLine'
$cqRa = Ensure-ResourceAccount -upn $CqUpn -display 'Resource Account - CQ-Support'

# --- Call queue ---
if ($WhatIf) {
    Write-Host ("WOULD create call queue '{0}' with {1} agent(s), routing=Attendant, backed by {2}" -f $CqName, $AgentUpns.Count, $CqUpn) -ForegroundColor Yellow
    Write-Host ("WOULD associate resource account {0} to call queue '{1}'" -f $CqUpn, $CqName) -ForegroundColor Yellow
} else {
    $agentIds = foreach ($a in $AgentUpns) { (Get-CsOnlineUser -Identity $a -ErrorAction SilentlyContinue).Identity }
    $cq = New-CsCallQueue -Name $CqName -RoutingMethod Attendant -Users @($agentIds | Where-Object { $_ }) -OverflowThreshold 10 -TimeoutThreshold 30
    if ($cqRa) {
        New-CsOnlineApplicationInstanceAssociation -Identities @($cqRa.ObjectId) -ConfigurationId $cq.Identity -ConfigurationType CallQueue | Out-Null
    }
    Write-Host ("OK    created call queue '{0}' (Id {1})" -f $CqName, $cq.Identity) -ForegroundColor Green
}

# --- Auto attendant (business-hours schedule + menu → call queue) ---
if ($WhatIf) {
    Write-Host ("WOULD create auto attendant '{0}' with a business-hours schedule and a menu routing to '{1}'" -f $AaName, $CqName) -ForegroundColor Yellow
    Write-Host ("WOULD associate resource account {0} to auto attendant '{1}'" -f $AaUpn, $AaName) -ForegroundColor Yellow
} else {
    $businessHours = New-CsOnlineTimeRange -Start 09:00 -End 17:00
    $schedule = New-CsOnlineSchedule -Name 'BusinessHours - HQ' -WeeklyRecurrentSchedule `
        -MondayHours   @($businessHours) -TuesdayHours @($businessHours) -WednesdayHours @($businessHours) `
        -ThursdayHours @($businessHours) -FridayHours   @($businessHours) -Complete

    $cqEntity = New-CsAutoAttendantCallableEntity -Identity $CqUpn -Type ApplicationEndpoint
    $menuOption = New-CsAutoAttendantMenuOption -Action TransferCallToTarget -DtmfResponse Tone1 -CallTarget $cqEntity
    $menu = New-CsAutoAttendantMenu -Name 'MainMenu - HQ' -MenuOptions @($menuOption)
    $callFlow = New-CsAutoAttendantCallFlow -Name 'BusinessHoursFlow - HQ' -Menu $menu

    $aa = New-CsAutoAttendant -Name $AaName -LanguageId 'en-US' -TimeZoneId 'Eastern Standard Time' -DefaultCallFlow $callFlow
    if ($aaRa) {
        New-CsOnlineApplicationInstanceAssociation -Identities @($aaRa.ObjectId) -ConfigurationId $aa.Identity -ConfigurationType AutoAttendant | Out-Null
    }
    Write-Host ("OK    created auto attendant '{0}' (Id {1})" -f $AaName, $aa.Identity) -ForegroundColor Green
}

Write-Host ("=== Voice Apps [{0}] complete ===" -f $run) -ForegroundColor Cyan
Disconnect-MicrosoftTeams -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
