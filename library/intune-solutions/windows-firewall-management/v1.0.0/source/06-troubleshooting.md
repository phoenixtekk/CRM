# 6. Troubleshooting Guide — Windows Firewall Management

Use **`WFM-Validation.ps1`** / **`WFM-Discovery.ps1`** for firewall state and
**`WFM-RuleReport.ps1`** / **`WFM-ConflictCheck.ps1`** to inspect rules and conflicts,
**`WFM-Remediation.ps1`** for safe fixes.

## A. Firewall not enabled / profiles off
| Symptom | Cause | Remediation |
|---|---|---|
| A profile shows Disabled | Policy not applied / synced, or a conflicting policy disabled it | Run `WFM-Remediation.ps1` (re-enables + syncs); resolve conflicts (`WFM-ConflictCheck.ps1`) |
| Policy "Error" | Device not synced/enrolled | Sync; confirm device in `Firewall-Pilot` |

## B. Legitimate inbound blocked
| Symptom | Cause | Remediation |
|---|---|---|
| Remote Help / remote mgmt / LOB app can't connect inbound | Default-deny inbound with no allow rule | Add an explicit **allow inbound** rule (rules policy) for the required port/program; re-test |
| App worked before, now blocked | Default inbound flipped to Block | Expected — create the allow rule for it; this is the point of default-deny |

## C. Conflicts
- A legacy **GPO firewall** or the **security baseline** also sets firewall state → they fight Intune. Make Intune the single authority; disable/scope the GPO and remove firewall settings from the baseline. Use `WFM-ConflictCheck.ps1`.
- "Merge" behavior: local rules may still apply unless you disable local rule merge — decide whether local admins can add rules.

## D. Rules not taking effect
- Rule present but not working → check direction/protocol/port/scope; confirm the profile the rule applies to matches the active network profile.
- Use `WFM-RuleReport.ps1` to see effective rules and their enabled state.

## E. Diagnostics quick reference
```powershell
Get-NetFirewallProfile | Select Name, Enabled, DefaultInboundAction, DefaultOutboundAction
Get-NetFirewallRule -Enabled True | Select DisplayName, Direction, Action | Sort Direction
netsh advfirewall show allprofiles
```
Firewall log (if enabled): `%systemroot%\system32\LogFiles\Firewall\pfirewall.log`.

## F. When to escalate
If profiles are enabled, the policy shows Succeeded, no conflicts are reported, and a required
service is still blocked with an allow rule in place, capture `Get-NetFirewallRule` output and the
firewall log and open a Microsoft support case.
