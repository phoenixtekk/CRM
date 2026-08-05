<#
.SYNOPSIS
    AGBINV-Report-GovernanceRegister.ps1 — merge the inventory and sharing exports into the
    Agent Builder Governance Register (one row per agent, with review columns).
.DESCRIPTION
    PURPOSE
        Builds the review artifact. Joins the inventory CSV (one row per agent) with the sharing CSV
        (one row per agent x recipient) into a single register: one row per agent, sharing recipients
        collapsed to a readable list, sharing scope surfaced, and blank governance-review columns added
        (OwnerConfirmed / SharingApproved / Action / ReviewedBy / ReviewedOn). File-only; no Graph.
    HOW TO RUN
        Path B (with granular sharing):
          pwsh -File .\AGBINV-Report-GovernanceRegister.ps1 `
               -InventoryCsv C:\AgentGovernance\Exports\AgentBuilder-Inventory_<date>.csv `
               -SharingCsv   C:\AgentGovernance\Exports\AgentBuilder-Sharing_<date>.csv `
               -OutputPath   C:\AgentGovernance\Exports
        Path A (admin center export, no per-recipient sharing):
          pwsh -File .\AGBINV-Report-GovernanceRegister.ps1 `
               -InventoryCsv C:\AgentGovernance\Exports\admin-center-export.csv -OutputPath C:\AgentGovernance\Exports
    EXPECTED RESULTS
        AgentBuilder-Governance-Register_<yyyyMMdd-HHmm>.csv — the register. If -SharingCsv is omitted,
        the SharedWith column reads "admin-center export - recipients not enumerated (use Path B)".
.NOTES
    Copilot Solutions — the repeatable way. File-only; no Graph calls. Store the register in an
    access-controlled location — it names users and groups.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $InventoryCsv,
    [string] $SharingCsv,
    [string] $OutputPath = '.',
    [string] $Owner = ''      # optional register owner recorded in each row's ReviewedBy default
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $InventoryCsv)) { throw "Inventory CSV not found: $InventoryCsv" }

$inv = Import-Csv -Path $InventoryCsv
if (-not $inv) { Write-Host "Inventory CSV is empty." -ForegroundColor Yellow; return }

# Build a lookup of AgentId -> sharing rows (Path B only).
$shareByAgent = @{}
if ($SharingCsv -and (Test-Path $SharingCsv)) {
    foreach ($s in (Import-Csv -Path $SharingCsv)) {
        if (-not $shareByAgent.ContainsKey($s.AgentId)) { $shareByAgent[$s.AgentId] = New-Object System.Collections.Generic.List[object] }
        $shareByAgent[$s.AgentId].Add($s)
    }
}

# Tolerate both Graph-export headers (Id/DisplayName) and admin-center headers (Name/Owner).
function Field($obj, [string[]]$names) {
    foreach ($n in $names) { if ($obj.PSObject.Properties.Name -contains $n -and "$($obj.$n)" -ne '') { return $obj.$n } }
    return ''
}

$register = foreach ($a in $inv) {
    $id   = Field $a @('Id','AgentId','ObjectId')
    $name = Field $a @('DisplayName','Name')
    $scope = ''; $sharedWith = ''
    if ($shareByAgent.ContainsKey($id)) {
        $rows = $shareByAgent[$id]
        $scope = ($rows | Select-Object -First 1).SharingScope
        $named = $rows | Where-Object { $_.RecipientName -and $_.RecipientType -notin 'None' } |
                 ForEach-Object { "$($_.RecipientName) [$($_.RecipientType)]" }
        $sharedWith = ($named -join '; ')
        if (-not $sharedWith) { $sharedWith = ($rows | Select-Object -First 1).RecipientName }
    } elseif ($SharingCsv) {
        $scope = 'Unknown'; $sharedWith = '(no sharing rows for this agent)'
    } else {
        $scope = 'See admin center'; $sharedWith = 'admin-center export - recipients not enumerated (use Path B)'
    }

    [pscustomobject]@{
        AgentName       = $name
        AgentId         = $id
        Owner           = Field $a @('Owner')
        Status          = Field $a @('Status','IsBlocked')
        Platform        = Field $a @('Platform')
        Version         = Field $a @('Version')
        Created         = Field $a @('DateCreated','Created')
        LastModified    = Field $a @('LastModifiedDateTime','LastModified','Last Modified')
        SharingScope    = $scope
        SharedWith      = $sharedWith
        OwnerConfirmed  = ''
        SharingApproved = ''
        Action          = ''      # Keep / Restrict sharing / Reassign owner / Block / Delete
        ReviewedBy      = $Owner
        ReviewedOn      = ''
    }
}

if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }
$stamp = (Get-Date).ToString('yyyyMMdd-HHmm')
$csv = Join-Path $OutputPath "AgentBuilder-Governance-Register_$stamp.csv"
$register | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8

$orgWide = @($register | Where-Object { $_.SharingScope -eq 'OrgWide' }).Count
Write-Host ("Wrote {0}  ({1} agents; {2} org-wide shared — review those first)" -f $csv, @($register).Count, $orgWide) -ForegroundColor Green
Write-Host "Store this register in an access-controlled location — it names users and groups." -ForegroundColor DarkCyan
