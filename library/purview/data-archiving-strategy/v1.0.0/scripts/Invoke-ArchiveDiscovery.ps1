<#
.SYNOPSIS
    Discovers the current archiving posture across the tenant (READ-ONLY; captures a baseline).
.DESCRIPTION
    Reports mailbox archive status and sizes, the org-level auto-expanding archive setting, existing
    MRM retention tags/policies, and existing Purview Data Lifecycle Management retention policies.
    Writes CSV baselines. Makes no changes; enables nothing.
.EXAMPLE
    .\Invoke-ArchiveDiscovery.ps1 -OutputPath .\discovery
    .\Invoke-ArchiveDiscovery.ps1 -PilotGroup grp-archive-pilot -OutputPath .\discovery
    Runs on PowerShell 5.1+/7+. Connect first with Connect-ExchangeOnline and Connect-IPPSSession.
    Expected results: CSVs for mailbox archive status, MRM tags/policies, and DLM retention policies,
    plus a console summary of the org auto-expanding-archive setting.
.NOTES
    Expected results: a baseline you compare against after configuration (archive growth / primary
    reduction). No credentials or secrets are used. Read-only.
#>
[CmdletBinding()]
param(
    [string]$PilotGroup,
    [string]$OutputPath = '.\archive-discovery'
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

# Resolve target mailboxes: pilot group if supplied, otherwise all user mailboxes.
if ($PilotGroup) {
    $targets = Get-DistributionGroupMember -Identity $PilotGroup |
        Where-Object { $_.RecipientType -like '*Mailbox*' } |
        ForEach-Object { $_.PrimarySmtpAddress }
} else {
    $targets = Get-Mailbox -ResultSize Unlimited -RecipientTypeDetails UserMailbox |
        ForEach-Object { $_.PrimarySmtpAddress }
}
Write-Host "Discovering $($targets.Count) mailbox(es)..." -ForegroundColor Cyan

# 1. Org-level auto-expanding archive
$org = Get-OrganizationConfig
Write-Host "Org AutoExpandingArchive = $($org.AutoExpandingArchive)" -ForegroundColor Cyan

# 2. Per-mailbox archive status + sizes
$mbxRows = foreach ($t in $targets) {
    try {
        $m  = Get-Mailbox -Identity $t
        $ps = $null; $as = $null
        try { $ps = Get-MailboxStatistics -Identity $t } catch {}
        if ($m.ArchiveStatus -eq 'Active') {
            try { $as = Get-MailboxStatistics -Identity $t -Archive } catch {}
        }
        [pscustomobject]@{
            PrimarySmtpAddress      = $m.PrimarySmtpAddress
            ArchiveStatus           = $m.ArchiveStatus
            ArchiveGuid             = $m.ArchiveGuid
            AutoExpandingArchive    = $m.AutoExpandingArchiveEnabled
            RetentionPolicy         = $m.RetentionPolicy
            PrimarySize             = if ($ps) { $ps.TotalItemSize } else { '' }
            PrimaryItemCount        = if ($ps) { $ps.ItemCount } else { '' }
            ArchiveSize             = if ($as) { $as.TotalItemSize } else { '' }
            ArchiveItemCount        = if ($as) { $as.ItemCount } else { '' }
        }
    } catch {
        [pscustomobject]@{ PrimarySmtpAddress = $t; ArchiveStatus = "ERROR: $($_.Exception.Message)" }
    }
}
$mbxCsv = Join-Path $OutputPath "mailbox-archive-status-$stamp.csv"
$mbxRows | Export-Csv -Path $mbxCsv -NoTypeInformation -Encoding UTF8
Write-Host "  -> $mbxCsv" -ForegroundColor Green

# 3. MRM retention tags and policies
$tags = Get-RetentionPolicyTag | Select-Object Name, Type, RetentionAction, AgeLimitForRetention, RetentionEnabled
$tagCsv = Join-Path $OutputPath "mrm-tags-$stamp.csv"
$tags | Export-Csv -Path $tagCsv -NoTypeInformation -Encoding UTF8
Write-Host "  -> $tagCsv" -ForegroundColor Green

$pol = Get-RetentionPolicy | Select-Object Name, @{n='TagLinks';e={ ($_.RetentionPolicyTagLinks -join '; ') }}
$polCsv = Join-Path $OutputPath "mrm-policies-$stamp.csv"
$pol | Export-Csv -Path $polCsv -NoTypeInformation -Encoding UTF8
Write-Host "  -> $polCsv" -ForegroundColor Green

# 4. Purview DLM retention policies (Security & Compliance)
try {
    $dlm = Get-RetentionCompliancePolicy |
        Select-Object Name, Enabled, Mode, DistributionStatus,
            @{n='ExchangeLocation';e={ ($_.ExchangeLocation -join '; ') }}
    $dlmCsv = Join-Path $OutputPath "dlm-retention-policies-$stamp.csv"
    $dlm | Export-Csv -Path $dlmCsv -NoTypeInformation -Encoding UTF8
    Write-Host "  -> $dlmCsv" -ForegroundColor Green
} catch {
    Write-Warning "DLM retention policies not read (connect Security & Compliance PowerShell): $($_.Exception.Message)"
}

Write-Host ''
Write-Host 'Discovery complete. Use these CSVs as the pre-change baseline.' -ForegroundColor Green
