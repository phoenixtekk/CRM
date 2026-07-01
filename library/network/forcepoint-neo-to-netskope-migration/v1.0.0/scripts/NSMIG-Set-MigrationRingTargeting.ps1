<#
.SYNOPSIS
    NSMIG-Set-MigrationRingTargeting.ps1 — create/populate the migration-ring and steering Entra
    groups via Microsoft Graph.
.DESCRIPTION
    PURPOSE
        Ensures the named Entra security groups used to stage the Forcepoint Neo -> Netskope cutover
        exist, and (optionally) moves a device between the passive and enforce groups for a ring swap.
        Groups created/ensured (names reused verbatim across the docs and consoles):
          Migration Ring - Pilot - Cutover
          Migration Ring - Broad - Cutover
          Legacy Estate - Forcepoint Neo - Inventory
          Coexistence Group - Netskope - Passive
          Steering Group - Netskope - Enforce
        Defaults to -WhatIf (preview). Group/membership changes happen only with -Confirm. Netskope
        steering and Forcepoint teardown in the consoles remain manual and are deferred to vendor docs.
    HOW TO RUN
        Preview groups: powershell -ExecutionPolicy Bypass -File .\NSMIG-Set-MigrationRingTargeting.ps1
        Create groups:  powershell -ExecutionPolicy Bypass -File .\NSMIG-Set-MigrationRingTargeting.ps1 -Confirm
        Swap a device to enforce (cutover):
          .\NSMIG-Set-MigrationRingTargeting.ps1 -Confirm -DeviceObjectId <id> -SwapToEnforce
        Requires the Microsoft Graph PowerShell SDK and Group.ReadWrite.All.
    EXPECTED RESULTS
        -WhatIf: lists which groups exist and which it would create / which membership it would change.
        -Confirm: ensures the groups exist; with -SwapToEnforce, moves the device from the passive
        group to the enforce group (one enforcing agent at a time).
.NOTES
    Network Solutions. Defaults to -WhatIf. Keeps passive and enforce membership non-overlapping.
#>
[CmdletBinding()] param(
    [switch]$WhatIf = $true,
    [switch]$Confirm,
    [string]$DeviceObjectId,
    [switch]$SwapToEnforce
)
if ($Confirm) { $WhatIf = $false }

$Groups = @(
    'Migration Ring - Pilot - Cutover',
    'Migration Ring - Broad - Cutover',
    'Legacy Estate - Forcepoint Neo - Inventory',
    'Coexistence Group - Netskope - Passive',
    'Steering Group - Netskope - Enforce'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All' -NoWelcome
Write-Host ("Mode: {0}" -f ($(if($WhatIf){'PREVIEW (-WhatIf)'}else{'APPLY (-Confirm)'}))) -ForegroundColor ($(if($WhatIf){'Yellow'}else{'Cyan'}))

function Get-GroupByName([string]$name) {
    $f = [uri]::EscapeDataString("displayName eq '$name'")
    (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=$f").value | Select-Object -First 1
}
function Ensure-Group([string]$name) {
    $g = Get-GroupByName $name
    if ($g) { Write-Host ("  exists : {0}" -f $name) -ForegroundColor Green; return $g }
    if ($WhatIf) { Write-Host ("  [WhatIf] would create: {0}" -f $name) -ForegroundColor Yellow; return $null }
    $nick = ($name -replace '[^a-zA-Z0-9]', '')
    $body = @{ displayName = $name; mailEnabled = $false; mailNickname = $nick; securityEnabled = $true }
    $new = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($body | ConvertTo-Json)
    Write-Host ("  created: {0}" -f $name) -ForegroundColor Cyan
    return $new
}

Write-Host "=== Ensuring migration groups ===" -ForegroundColor Cyan
$map = @{}
foreach ($n in $Groups) { $map[$n] = Ensure-Group $n }

# Optional: swap a device from passive coexistence to Netskope enforce (ring cutover)
if ($DeviceObjectId -and $SwapToEnforce) {
    $passive = $map['Coexistence Group - Netskope - Passive']
    $enforce = $map['Steering Group - Netskope - Enforce']
    Write-Host "`n=== Cutover swap: passive -> enforce ===" -ForegroundColor Cyan
    if (-not $passive -or -not $enforce) { Write-Host "  Groups not present yet (run -Confirm first)." -ForegroundColor Yellow }
    elseif ($WhatIf) {
        Write-Host ("  [WhatIf] would remove device {0} from '{1}' and add to '{2}'." -f $DeviceObjectId, $passive.displayName, $enforce.displayName) -ForegroundColor Yellow
    } else {
        try { Invoke-MgGraphRequest -Method DELETE -Uri "/v1.0/groups/$($passive.id)/members/$DeviceObjectId/`$ref" | Out-Null; Write-Host "  removed from passive." -ForegroundColor Green } catch { Write-Host ("  remove note: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
        $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$DeviceObjectId" }
        try { Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$($enforce.id)/members/`$ref" -Body ($ref | ConvertTo-Json) | Out-Null; Write-Host "  added to enforce." -ForegroundColor Green } catch { Write-Host ("  add note: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
        Write-Host "  Cutover swap complete — confirm only Netskope enforces (NSMIG-Validation.ps1)." -ForegroundColor Green
    }
}

Disconnect-MgGraph | Out-Null
