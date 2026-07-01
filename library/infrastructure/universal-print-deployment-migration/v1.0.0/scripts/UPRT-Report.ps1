<#
.SYNOPSIS
    UPRT-Report.ps1 - printer and Universal Print deployment inventory.
.DESCRIPTION
    PURPOSE
        Produces a consolidated inventory across two surfaces: (1) local/legacy print queues via the
        PrintManagement module, and (2) Universal Print registered printers, shares, and printer-share
        deployments via Microsoft Graph. Use it to track migration coverage - which printers are
        registered/shared and which are deployed to groups - before retiring print servers.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\UPRT-Report.ps1
        Requires the Microsoft Graph PowerShell SDK and consent for Printer.Read.All and
        PrinterShare.Read.All (delegated). Sign in when prompted.
    EXPECTED RESULTS
        A table of legacy queues, then a table of Universal Print printers/shares with their
        deployment targets (group IDs), so coverage gaps are obvious.
.NOTES
    Infrastructure solution - the repeatable way. Read-only (GET only against Graph).
#>
[CmdletBinding()]
param()

# ---- Legacy / local print queues ----
Import-Module PrintManagement -ErrorAction SilentlyContinue
Write-Host "`n=== Legacy print queues ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan
try {
    Get-Printer -ErrorAction Stop |
        Select-Object Name, DriverName, PortName, Shared, ShareName |
        Format-Table -AutoSize
} catch {
    Write-Host "  No local print queues (or PrintManagement unavailable)." -ForegroundColor DarkGray
}

# ---- Universal Print via Microsoft Graph ----
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

# Universal Print endpoints live under /print in Microsoft Graph.
Connect-MgGraph -Scopes 'Printer.Read.All', 'PrinterShare.Read.All' -NoWelcome

Write-Host "=== Universal Print - registered printers ===" -ForegroundColor Cyan
try {
    $printers = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/print/printers').value
    foreach ($p in $printers) {
        Write-Host ("  {0,-36} id={1}" -f $p.displayName, $p.id)
    }
    if (-not $printers) { Write-Host "  (none)" -ForegroundColor Yellow }
} catch {
    Write-Host "  Could not read /print/printers: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "=== Universal Print - shares and deployment targets ===" -ForegroundColor Cyan
try {
    $shares = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/print/shares').value
    foreach ($s in $shares) {
        # 'allowedGroups' on a printer share approximates the deployment targeting groups.
        $groups = @()
        try {
            $groups = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/print/shares/$($s.id)/allowedGroups").value |
                      ForEach-Object { $_.id }
        } catch { }
        Write-Host ("  {0,-36} groups=[{1}]" -f $s.displayName, ($groups -join ', '))
    }
    if (-not $shares) { Write-Host "  (none)" -ForegroundColor Yellow }
} catch {
    Write-Host "  Could not read /print/shares: $($_.Exception.Message)" -ForegroundColor Yellow
}

Disconnect-MgGraph | Out-Null
Write-Host "`nInventory complete. Printers with no share/group are not yet deployed." -ForegroundColor Green
