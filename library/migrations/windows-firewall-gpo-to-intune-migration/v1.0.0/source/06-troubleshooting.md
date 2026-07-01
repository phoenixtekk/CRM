# 6. Troubleshooting Guide — Windows Firewall GPO to Intune Migration

Use `FWMIG-Discovery.ps1` and `FWMIG-Validation.ps1` for per-device state, `FWMIG-Report.ps1` for
fleet coverage/conflicts, and `FWMIG-Remediation.ps1` (default `-WhatIf`) for safe fixes.

## A. Conflict — GPO and Intune disagree on a setting
| Symptom | Cause | Remediation |
|---|---|---|
| Effective default inbound/outbound action differs from the Intune policy | The device is still in GPO firewall scope while the Intune policy is assigned (two authorities) | Run `FWMIG-Report.ps1` (flags double-managed); remove the device from GPO firewall scope so only Intune enforces; re-sync |
| Intune policy shows Succeeded but the device behaves differently | GPO refresh re-asserts the old value after Intune applies | Confirm the coexistence control moved the device out of GPO scope at ring entry; `FWMIG-Remediation.ps1` to confirm/fix authority |

## B. Merge condition — unexpected rules still enforced
| Symptom | Cause | Remediation |
|---|---|---|
| A rule you "removed" is still active | Local/GPO rules are merging into the effective set | Set the rule-merge controls in `Firewall Policy – Migrated Rules – *` to disallow uncontrolled local/GPO merging; re-validate with `FWMIG-Validation.ps1` |
| Effective rule set is a superset of the Intune rules | Multiple rule sources merged | Identify the extra rules' source with `FWMIG-Validation.ps1` (reports rule origin); remove the stray source |

## C. Merge loop — oscillating / intermittent compliance
| Symptom | Cause | Remediation |
|---|---|---|
| Compliance flips between check-ins; effective firewall state changes each cycle | GPO re-asserts on its refresh while Intune re-asserts on check-in — the two are fighting | This is the classic loop: ensure exactly one authority per device. Use `FWMIG-Report.ps1` to find double-managed devices, remove them from GPO firewall scope, then `FWMIG-Validation.ps1` over two check-ins / a `gpupdate /force` to confirm the state is now stable |
| `FWMIG-Validation.ps1` returns different results on consecutive runs | Same as above | Do not advance the ring until the state is stable; fix coexistence first |

## D. Parity failure — Intune rule set != GPO inventory
| Symptom | Cause | Remediation |
|---|---|---|
| A migrated rule is missing | Rule not transcribed into the `Firewall Rules` profile | Add the missing rule from the `FWMIG-Report.ps1` inventory; re-validate |
| A rule's behavior differs | Field mistranslated (protocol/ports/program/address scope) | Compare the `FWMIG-Validation.ps1` diff to the inventory; correct the rule field |

## E. Connectivity broken after cutover
- A required inbound service (RDP/Remote Help, LOB listener) or outbound path stopped working →
  the corresponding allow rule was not translated or was mistranslated. Find it in the
  `FWMIG-Report.ps1` inventory, add/fix the rule in the `Firewall Rules` profile, re-validate. If it
  is blocking management, use the ring rollback (re-scope to GPO firewall / unassign Intune) and fix
  before re-attempting.

## F. Policy not applying at all
- Device not enrolled / not in the ring group → confirm enrollment (Intune → `Devices`) and
  membership of `Migration Ring – Pilot` (or current ring); sync.
- Unsupported build → `FWMIG-Discovery.ps1` reports the OS build; patch/upgrade.

## G. Diagnostics quick reference
```powershell
Get-NetFirewallProfile | Select Name, Enabled, DefaultInboundAction, DefaultOutboundAction
Get-NetFirewallRule -PolicyStore ActiveStore | Select DisplayName, Direction, Action, Enabled
Get-NetFirewallRule -PolicyStore ActiveStore | Get-NetFirewallRule  # inspect effective (merged) store
gpresult /h gpo-firewall.html   # confirm whether the firewall GPO still applies to the device
gpupdate /force                 # force a GPO refresh to test for oscillation
```
Effective rules live in the `ActiveStore`; GPO-sourced rules in the `RSOP`/GPO store — comparing the
two shows whether GPO is still contributing.

## H. When to escalate
If exactly one authority enforces the firewall (no double management), rule parity passes, and the
device is synced, but connectivity still fails or compliance still oscillates, capture
`FWMIG-Validation.ps1` output plus `gpresult /h` and open a Microsoft support case.
