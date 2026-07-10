<#
.SYNOPSIS
    Install-DatadogAgent.ps1 — install/uninstall the Datadog Agent on Windows (white-label).
.DESCRIPTION
    PURPOSE
        Installs the Datadog Agent on a Windows host as part of an as-code rollout. The API key is read
        from the ENVIRONMENT (populated from your SECRET STORE) — it is NEVER hard-coded or printed. Sets
        the Datadog site and base tags (env/service/team), and optionally enables logs/APM. Supports an
        -Uninstall path for rollback.
    HOW TO RUN  (key comes from your secret store, not the command line history)
        $env:DD_API_KEY = (Read-From-Secret-Store)      # e.g. Get-AzKeyVaultSecret ... -AsPlainText
        powershell -ExecutionPolicy Bypass -File .\Install-DatadogAgent.ps1 `
            -Site datadoghq.com -Env pilot -Service demo -Team platform -EnableLogs -EnableApm
        Uninstall:  .\Install-DatadogAgent.ps1 -Uninstall
    EXPECTED RESULTS
        The agent MSI is installed and the service started; `& "$env:ProgramFiles\Datadog\Datadog Agent\bin\agent.exe" status`
        shows API key OK and the host reports to Datadog with the given tags.
    NOTES
        White-label. NO SECRETS IN CODE: DD_API_KEY is taken from the environment/secret store and never
        printed. Requires an elevated (Administrator) session. Verify the current agent version / MSI URL
        for Windows in Datadog's docs.
.EXAMPLE
    .\Install-DatadogAgent.ps1 -Env pilot -Service demo -Team platform -EnableLogs
#>
[CmdletBinding()] param(
    [string]$Site = 'datadoghq.com',        # verify your org's site
    [string]$Env = 'pilot',
    [string]$Service = 'demo',
    [string]$Team = 'platform',
    [switch]$EnableLogs,
    [switch]$EnableApm,
    [switch]$Uninstall
)

function Assert-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    if (-not $p.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
        throw 'Run this script from an elevated (Administrator) PowerShell session.'
    }
}
Assert-Admin

if ($Uninstall) {
    Write-Host 'Uninstalling Datadog Agent...' -ForegroundColor Yellow
    $app = Get-CimInstance Win32_Product -Filter "Name like 'Datadog Agent%'" -ErrorAction SilentlyContinue
    if ($app) { $app | ForEach-Object { $_.Uninstall() | Out-Null }; Write-Host 'Uninstalled.' -ForegroundColor Green }
    else { Write-Host 'Datadog Agent not found.' -ForegroundColor Yellow }
    return
}

if (-not $env:DD_API_KEY) {
    throw 'DD_API_KEY is not set. Populate it from your SECRET STORE (never hard-code) before running.'
}

Write-Host "Installing Datadog Agent (site=$Site, env=$Env, service=$Service, team=$Team)..." -ForegroundColor Cyan

# Download the official MSI over HTTPS. Verify the current MSI URL in Datadog's docs.
$msiUrl = 'https://s3.amazonaws.com/ddagent-windows-stable/datadog-agent-7-latest.amd64.msi'
$msi = Join-Path $env:TEMP 'datadog-agent.msi'
Invoke-WebRequest -Uri $msiUrl -OutFile $msi -UseBasicParsing

$tags = "env:$Env,service:$Service,team:$Team"
# APIKEY / SITE / TAGS passed as MSI properties; key value is not echoed to the console/logs.
$msiArgs = @(
    '/qn', '/i', "`"$msi`"",
    "APIKEY=$($env:DD_API_KEY)",
    "SITE=$Site",
    "TAGS=`"$tags`""
)
if ($EnableLogs) { $msiArgs += 'LOGS_ENABLED=true' }
if ($EnableApm)  { $msiArgs += 'APM_ENABLED=true' }

Start-Process msiexec.exe -ArgumentList $msiArgs -Wait -NoNewWindow
Remove-Item $msi -Force -ErrorAction SilentlyContinue

Start-Service datadogagent -ErrorAction SilentlyContinue
Write-Host 'Done. Verify with: & "$env:ProgramFiles\Datadog\Datadog Agent\bin\agent.exe" status' -ForegroundColor Green
