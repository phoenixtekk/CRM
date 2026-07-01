# 6. Troubleshooting Guide — Attack Surface Reduction (ASR) Rules

Use **`ASR-Validation.ps1`** / **`ASR-Discovery.ps1`** for rule state and **`ASR-AuditReport.ps1`**
for events, **`ASR-Remediation.ps1`** for safe fixes.

## A. Rules not taking effect
| Symptom | Cause | Remediation |
|---|---|---|
| No audit/block events | Defender AV not active, or real-time protection off | Run `ASR-Discovery.ps1`; ensure Defender AV active + RTP on (`ASR-Remediation.ps1`) |
| Rule shows "Not configured" on device | Policy not applied / not synced | `ASR-Remediation.ps1` (sync); confirm device in `ASR-Pilot` |
| Defender in passive mode | A third-party AV is primary | ASR needs Defender active; with MDE, enable EDR-in-block mode or make Defender active |

## B. Legitimate app blocked
| Symptom | Cause | Remediation |
|---|---|---|
| A business app stops working after Block | A rule blocks its (legitimate) behavior | Identify via `ASR-AuditReport.ps1` (event 1121); add a **per-rule exclusion** for the verified file/path; re-test |
| Same app trips multiple rules | Behavior matches several rules | Add the exclusion to each affected rule (or a global ASR exclusion) |

## C. Audit shows nothing during pilot
- Users didn't exercise the risky behaviors → ASR only logs when a matching behavior occurs. Run a benign rule test (e.g. controlled macro child-process), then re-check `ASR-AuditReport.ps1`.
- Wrong log → ASR events are in **Microsoft-Windows-Windows Defender/Operational** (IDs 1121 block, 1122 audit, 5007 config change).

## D. Conflicts with other policies/baseline
- ASR also appears in the security baseline → manage ASR in **one** place. If you use this dedicated solution, don't also set ASR in the baseline (and vice-versa). Check with the Baselines solution's `ESB-ConflictCheck.ps1`.

## E. Diagnostics quick reference
```powershell
(Get-MpPreference).AttackSurfaceReductionRules_Ids      # configured rule GUIDs
(Get-MpPreference).AttackSurfaceReductionRules_Actions  # matching actions (0=Off,1=Block,2=Audit,6=Warn)
Get-MpComputerStatus | Select AMRunning, RealTimeProtectionEnabled
# audit/block events:
Get-WinEvent -LogName 'Microsoft-Windows-Windows Defender/Operational' | Where-Object Id -in 1121,1122
```
Run `ASR-RuleReference.ps1` to map GUIDs to friendly rule names.

## F. When to escalate
If Defender is active, the policy shows Succeeded, rules are configured (`ASR-Validation.ps1`), and a
legitimate app is still blocked with an exclusion in place, capture the 1121 event detail and open a
Microsoft Defender support case.
