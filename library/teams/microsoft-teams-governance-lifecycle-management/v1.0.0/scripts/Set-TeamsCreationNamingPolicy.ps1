<#
.SYNOPSIS
  Configure M365 Groups creation control + naming policy (and optionally enable container labels) via the
  Group.Unified directory setting. DRY-RUN by default (-WhatIf); writes only with -Commit.
.DESCRIPTION
  Restricts group/team creation to a named security group (EnableGroupCreation=false +
  GroupCreationAllowedGroupId), applies a prefix/suffix naming requirement and blocked-words list, and can
  turn on sensitivity-label support (EnableMIPLabels). -Rollback restores open creation and clears naming.
  Naming/labels require Entra ID P1 for members (verify in your tenant).
.EXAMPLE
  .\Set-TeamsCreationNamingPolicy.ps1 -CreatorsGroupName "Group Creators - Governed - Pilot" -Prefix "GRP-" -BlockedWords "CEO,Payroll,HR" -WhatIf
  .\Set-TeamsCreationNamingPolicy.ps1 -CreatorsGroupName "Group Creators - Governed - Pilot" -Prefix "GRP-" -BlockedWords "CEO,Payroll,HR" -Commit
  (PowerShell 5.1+/7+, Microsoft.Graph + Microsoft.Graph.Beta; connect with Connect-MgGraph)
.NOTES
  Expected results: dry-run prints the exact Group.Unified values that would change; -Commit applies them
  and re-reads to confirm. -Commit -Rollback sets EnableGroupCreation=true and clears the naming policy.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$CreatorsGroupName,
    [string]$Prefix = "",
    [string]$Suffix = "",
    [string]$BlockedWords = "",
    [switch]$EnableLabels,
    [switch]$Commit,
    [switch]$Rollback,
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
$templateName = 'Group.Unified'

if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes "Directory.ReadWrite.All","Group.Read.All" | Out-Null
}

# --- Resolve creators group GUID (unless rolling back) ---
$creatorsGroupId = $null
if (-not $Rollback) {
    if (-not $CreatorsGroupName) { throw "Provide -CreatorsGroupName (or use -Rollback)." }
    $grp = Get-MgGroup -Filter "displayName eq '$CreatorsGroupName'" -All
    if (-not $grp)            { throw "Creators security group '$CreatorsGroupName' not found." }
    if ($grp.Count -gt 1)     { throw "Multiple groups named '$CreatorsGroupName' — use a unique name." }
    $creatorsGroupId = $grp.Id
    Write-Host "Creators group '$CreatorsGroupName' resolved to $creatorsGroupId" -ForegroundColor Cyan
}

# --- Get or create the Group.Unified directory setting ---
$setting = Get-MgBetaDirectorySetting -All | Where-Object DisplayName -eq $templateName
if (-not $setting) {
    $template = Get-MgBetaDirectorySettingTemplate -All | Where-Object DisplayName -eq $templateName
    if (-not $template) { throw "Group.Unified template not found in this tenant." }
    Write-Host "Group.Unified setting does not exist yet; it will be created from template." -ForegroundColor Yellow
    $isNew = $true
    $values = @($template.Values | ForEach-Object { @{ Name = $_.Name; Value = $_.DefaultValue } })
} else {
    $isNew = $false
    $values = @($setting.Values | ForEach-Object { @{ Name = $_.Name; Value = $_.Value } })
}

function Set-Val([array]$vals, [string]$name, [string]$value) {
    $hit = $vals | Where-Object { $_.Name -eq $name }
    if ($hit) { $hit.Value = $value } else { $vals += @{ Name = $name; Value = $value } }
    return $vals
}

# --- Compute desired values ---
if ($Rollback) {
    $values = Set-Val $values 'EnableGroupCreation' 'true'
    $values = Set-Val $values 'GroupCreationAllowedGroupId' ''
    $values = Set-Val $values 'PrefixSuffixNamingRequirement' ''
    $values = Set-Val $values 'CustomBlockedWordsList' ''
    Write-Host "ROLLBACK: restoring open creation and clearing naming policy." -ForegroundColor Yellow
} else {
    $namingReq = ""
    if ($Prefix -or $Suffix) { $namingReq = "$Prefix[GroupName]$Suffix" }
    $values = Set-Val $values 'EnableGroupCreation' 'false'
    $values = Set-Val $values 'GroupCreationAllowedGroupId' $creatorsGroupId
    if ($namingReq)   { $values = Set-Val $values 'PrefixSuffixNamingRequirement' $namingReq }
    if ($BlockedWords){ $values = Set-Val $values 'CustomBlockedWordsList' $BlockedWords }
    if ($EnableLabels){ $values = Set-Val $values 'EnableMIPLabels' 'true' }
}

# --- Show the plan ---
Write-Host "`n=== Planned Group.Unified values ===" -ForegroundColor Yellow
$values | Where-Object { $_.Name -in 'EnableGroupCreation','GroupCreationAllowedGroupId','PrefixSuffixNamingRequirement','CustomBlockedWordsList','EnableMIPLabels' } |
    ForEach-Object { Write-Host ("  {0,-30} = {1}" -f $_.Name, ($_.Value ? $_.Value : '<empty>')) }

if ($WhatIf -or -not $Commit) {
    Write-Host "`nDRY-RUN only (no -Commit). Re-run with -Commit to apply." -ForegroundColor Cyan
    return
}

# --- Commit ---
$body = @{ Values = $values }
if ($PSCmdlet.ShouldProcess("Group.Unified directory setting", "Apply creation/naming policy")) {
    if ($isNew) {
        $template = Get-MgBetaDirectorySettingTemplate -All | Where-Object DisplayName -eq $templateName
        New-MgBetaDirectorySetting -TemplateId $template.Id -Values $values | Out-Null
    } else {
        Update-MgBetaDirectorySetting -DirectorySettingId $setting.Id -BodyParameter $body
    }
    Write-Host "`nApplied. Re-reading to confirm..." -ForegroundColor Green
    $after = Get-MgBetaDirectorySetting -All | Where-Object DisplayName -eq $templateName
    ($after.Values | Where-Object Name -in 'EnableGroupCreation','GroupCreationAllowedGroupId','PrefixSuffixNamingRequirement','CustomBlockedWordsList','EnableMIPLabels') |
        ForEach-Object { Write-Host ("  {0,-30} = {1}" -f $_.Name, $_.Value) }
    Write-Host "`nNote: directory changes can take time to propagate to all users." -ForegroundColor Cyan
}
