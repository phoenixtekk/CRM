<#
  daily-learning-run.ps1 — Documentation Validation Learning Loop daily driver (CLAUDE.md §6).

  Runs the DETERMINISTIC detector daily: finds owner validation edits to published solution docs on
  Wiki.js and writes a report. If edits are found it (best-effort) launches a headless Claude run to
  LEARN + apply the safe corrections (source sync, lessons append, rebuild/republish); if the `claude`
  CLI isn't available it just leaves the report + a NOTICE for the next interactive session — so the
  daily detection is always reliable and nothing risky happens unattended without the CLI.

  Registered as a Windows Scheduled Task (see tools/register-learning-task is documented in §6).
  On-demand use (don't wait for the schedule):
    pwsh -File tools\daily-learning-run.ps1 -DetectOnly   # CHECK: capture edits + report, no changes
    pwsh -File tools\daily-learning-run.ps1               # APPLY: capture + re-render/learn now
#>
param([switch]$DetectOnly)
$ErrorActionPreference = 'Stop'
$repo = 'G:\VisualStudioCode\CRM'
Set-Location $repo

# Load WIKIJS_URL / WIKIJS_TOKEN from the repo env (falls back to ~/.claude/.wikijs.env via the tool)
$envFile = Join-Path $repo '.wikijs.env'
if (Test-Path $envFile) {
  Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([A-Za-z_]+)\s*=\s*(.*)$') {
      [Environment]::SetEnvironmentVariable($matches[1], $matches[2].Trim().Trim('"').Trim("'"))
    }
  }
}

$stamp   = Get-Date -Format 'yyyy-MM-dd'
$logDir  = Join-Path $repo 'library\_index'
$report  = Join-Path $logDir 'learning-report.json'
$log     = Join-Path $logDir 'learning-last-run.log'
$notice  = Join-Path $logDir 'learning-NOTICE.txt'

"[$([DateTime]::Now)] daily learning detector run" | Tee-Object -FilePath $log
python tools\wiki-learning-sync.py --registry library\_index\registry.json --json $report 2>&1 |
  Tee-Object -FilePath $log -Append

# How many solutions had owner edits?
$count = 0
try { $count = (@(Get-Content $report -Raw | ConvertFrom-Json)).Count } catch { $count = 0 }
"[$([DateTime]::Now)] solutions with owner edits: $count" | Tee-Object -FilePath $log -Append

if ($count -gt 0) {
  $slugs = (@(Get-Content $report -Raw | ConvertFrom-Json) | ForEach-Object { $_.slug }) -join ', '
  "Validation edits detected $stamp on: $slugs`nReport: $report`nRun the §6 learning loop to apply + learn." |
    Set-Content -Path $notice
  Copy-Item $report (Join-Path $logDir "learning-report-$stamp.json") -Force

  if ($DetectOnly) {
    "[$([DateTime]::Now)] DetectOnly: $count solution(s) edited — report captured at $report; apply skipped." |
      Tee-Object -FilePath $log -Append
    return
  }

  # Autonomous learning IF the Claude CLI is available; otherwise leave it for an interactive session.
  $claudeExe = if (Test-Path "$env:APPDATA\npm\claude.cmd") { "$env:APPDATA\npm\claude.cmd" }
               else { (Get-Command claude -ErrorAction SilentlyContinue).Source }
  if ($claudeExe) {
    $prompt = @'
Run the Documentation Validation Learning Loop (global CLAUDE.md §6) for the Workplace Marketplace.
The detector already wrote library/_index/learning-report.json. For each corrected solution:
- apply solution-specific fixes into source/<file>.md, rebuild deliverables, redeploy + republish the
  store listing on linuxg5 (loader --purge then reload, indexer:index, optimize:clear, verify download 404),
  and republish the wiki (tools/publish-wiki.py, which rewrites the baseline and closes the loop);
- append generalizable lessons to library/_index/AUTHORING_LESSONS.md;
- for high-impact/recurring lessons, PROPOSE a generate-solution SKILL change for human approval — do NOT
  edit the SKILL autonomously. Never publish secrets. Then re-run the detector to confirm 0 remain and
  write a brief learning report.
'@
    "[$([DateTime]::Now)] launching headless Claude to learn/apply" | Tee-Object -FilePath $log -Append
    # empty stdin (no TTY in a scheduled task). Permission grant for unattended runs: a non-console
    # process (Task Scheduler / Start-Process) REFUSES --dangerously-skip-permissions and bypass mode
    # (they need a TTY to arm), so we pre-authorize the exact tools the loop needs with --allowedTools
    # + acceptEdits — the documented headless/CI path, which works without a console. Bounded turns as a
    # runaway backstop. Uses the stored OAuth creds in ~/.claude.
    $allow = "Bash Edit Write Read Glob Grep"
    # Pass the routine via STDIN, NOT as the -p argument: `claude.cmd` is a batch shim that mangles
    # shell-special chars (> ( ) ` * |) in a command-line prompt, which silently drops the trailing
    # flags (--allowedTools) and leaves the run in ask-mode → all tool calls denied. Stdin is immune.
    $prompt | & $claudeExe -p --permission-mode acceptEdits --allowedTools $allow --max-turns 120 *>> $log
    "[$([DateTime]::Now)] headless Claude exit=$LASTEXITCODE" | Tee-Object -FilePath $log -Append
  } else {
    "[$([DateTime]::Now)] claude CLI not found — left NOTICE for interactive learning" |
      Tee-Object -FilePath $log -Append
  }
} else {
  if (Test-Path $notice) { Remove-Item $notice -Force }
  "[$([DateTime]::Now)] no owner edits — nothing to learn." | Tee-Object -FilePath $log -Append
}
