<#
.SYNOPSIS
    PURVEDM-Schema.ps1 — EDM schema helper: validate/emit a schema XML and create it (-WhatIf by default).
.DESCRIPTION
    PURPOSE
        Helps you author and register an EDM schema (the data-store field definition). It can EMIT a
        starter schema XML template (-EmitTemplate), VALIDATE an existing schema XML (well-formedness,
        exactly-one-or-more searchable field, field names present), and — only with -Commit — create or
        update the schema via New-DlpEdmSchema / Set-DlpEdmSchema. Safe by default: without -Commit it
        validates and prints the intended call but changes nothing. Reads no sensitive record data.
    HOW TO RUN
        # 1) Emit a starter schema XML you can edit:
        powershell -File .\PURVEDM-Schema.ps1 -EmitTemplate -SchemaFile .\CustomerRecords-schema.xml
        # 2) Validate your edited schema (no changes):
        powershell -File .\PURVEDM-Schema.ps1 -SchemaFile .\CustomerRecords-schema.xml -WhatIf
        # 3) Create/update the schema in the tenant:
        powershell -File .\PURVEDM-Schema.ps1 -SchemaFile .\CustomerRecords-schema.xml -Commit
        Requires Security & Compliance PowerShell (Connect-IPPSSession) for validate/commit against the tenant.
    EXPECTED RESULTS
        -EmitTemplate: writes a starter XML. -WhatIf: prints PASS/ISSUES for the XML and the
        New-/Set-DlpEdmSchema call it WOULD run. -Commit: creates/updates the schema and re-reads it
        (schema listed by Get-DlpEdmSchema = PASS). Verify with PURVEDM-Discovery.ps1.
.NOTES
    Purview — Exact Data Match. Writes gated behind -Commit. No credentials, salts, or record data in code.
    Field-count / searchable-field limits evolve — verify current limits on Microsoft Learn.
#>
[CmdletBinding()]
param(
    [string]$SchemaFile,
    [switch]$EmitTemplate,
    [string]$UserPrincipalName,
    [switch]$Commit
)

# --- Emit a starter schema template (offline, no connection needed) ---
if ($EmitTemplate) {
    if (-not $SchemaFile) { $SchemaFile = '.\CustomerRecords-schema.xml' }
    if (Test-Path $SchemaFile) { Write-Host ("Refusing to overwrite existing file: {0}" -f $SchemaFile) -ForegroundColor Red; return }
    $template = @'
<?xml version="1.0" encoding="utf-8"?>
<EdmSchema xmlns="http://schemas.microsoft.com/office/2018/edm">
  <DataStore name="CustomerRecords" description="Customer account records" version="1">
    <!-- Mark high-cardinality, stable-format fields as searchable (primary). At least one required. -->
    <Field name="AccountNumber" searchable="true" caseInsensitive="false" ignoredDelimiters="-, " />
    <Field name="LastName"      searchable="false" caseInsensitive="true" />
    <Field name="SSN"           searchable="false" caseInsensitive="false" ignoredDelimiters="-, " />
    <Field name="Email"         searchable="false" caseInsensitive="true" />
  </DataStore>
</EdmSchema>
'@
    Set-Content -Path $SchemaFile -Value $template -Encoding UTF8
    Write-Host ("Wrote starter schema template to {0}. Edit field names/attributes to match your data, then re-run with -WhatIf." -f $SchemaFile) -ForegroundColor Green
    Write-Host 'NOTE: attribute names/format are illustrative — confirm the current EDM schema XML format on Microsoft Learn.' -ForegroundColor DarkGray
    return
}

if (-not $SchemaFile) { Write-Host 'Provide -SchemaFile <path> (or -EmitTemplate to create a starter).' -ForegroundColor Red; return }
if (-not (Test-Path $SchemaFile)) { Write-Host ("Schema file not found: {0}" -f $SchemaFile) -ForegroundColor Red; return }

# --- Validate the schema XML (offline structural checks) ---
Write-Host ("=== Validating schema XML: {0} ===" -f $SchemaFile) -ForegroundColor Cyan
$issues = @()
[xml]$xml = $null
try { [xml]$xml = Get-Content -Path $SchemaFile -Raw } catch { Write-Host ("XML is not well-formed: {0}" -f $_.Exception.Message) -ForegroundColor Red; return }

$fields = @($xml.SelectNodes('//*[local-name()="Field"]'))
if ($fields.Count -eq 0) { $issues += 'No <Field> elements found.' }
$names = @($fields | ForEach-Object { $_.name })
if ($names | Where-Object { [string]::IsNullOrWhiteSpace($_) }) { $issues += 'One or more fields have no name.' }
$dups = $names | Group-Object | Where-Object { $_.Count -gt 1 }
if ($dups) { $issues += ("Duplicate field name(s): {0}" -f (($dups | ForEach-Object { $_.Name }) -join ', ')) }
$searchable = @($fields | Where-Object { "$($_.searchable)" -match 'true' })
if ($searchable.Count -lt 1) { $issues += 'No searchable (primary) field — at least one field must have searchable="true".' }

Write-Host ("Fields: {0} ({1})" -f $fields.Count, ($names -join ', '))
Write-Host ("Searchable/primary: {0} ({1})" -f $searchable.Count, (($searchable | ForEach-Object { $_.name }) -join ', '))
if ($issues.Count -gt 0) {
    Write-Host 'ISSUES:' -ForegroundColor Yellow
    $issues | ForEach-Object { Write-Host ("  - {0}" -f $_) -ForegroundColor Yellow }
} else {
    Write-Host 'PASS: schema XML looks structurally valid.' -ForegroundColor Green
}
Write-Host 'Reminder: confirm current field-count / searchable-field limits on Microsoft Learn.' -ForegroundColor DarkGray

if (-not $Commit) {
    Write-Host '-- WhatIf: no tenant changes made. Would run (create if new, else update): --' -ForegroundColor Yellow
    Write-Host '   New-DlpEdmSchema -FileData ([IO.File]::ReadAllBytes(<SchemaFile>))   # or Set-DlpEdmSchema for an update'
    Write-Host 'Re-run with -Commit to apply.' -ForegroundColor Yellow
    return
}
if ($issues.Count -gt 0) { Write-Host 'Not committing: resolve the ISSUES above first.' -ForegroundColor Red; return }

# --- Commit path ---
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) { Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber }
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpEdmSchema -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

$storeName = $xml.SelectSingleNode('//*[local-name()="DataStore"]').name
$bytes = [System.IO.File]::ReadAllBytes((Resolve-Path $SchemaFile))
$existing = $null
try { $existing = Get-DlpEdmSchema -Identity $storeName -ErrorAction SilentlyContinue } catch {}
if ($existing) {
    Set-DlpEdmSchema -Identity $storeName -FileData $bytes -Confirm:$false -ErrorAction Stop
    Write-Host ("Updated EDM schema '{0}'." -f $storeName) -ForegroundColor Green
} else {
    New-DlpEdmSchema -FileData $bytes -Confirm:$false -ErrorAction Stop | Out-Null
    Write-Host ("Created EDM schema '{0}'." -f $storeName) -ForegroundColor Green
}
if (Get-DlpEdmSchema -Identity $storeName -ErrorAction SilentlyContinue) {
    Write-Host ("PASS: schema '{0}' is registered. Next: create the EDM SIT, then hash+upload with EdmUploadAgent.exe." -f $storeName) -ForegroundColor Green
} else {
    Write-Host 'WARNING: schema not found after commit — verify in the portal.' -ForegroundColor Yellow
}
