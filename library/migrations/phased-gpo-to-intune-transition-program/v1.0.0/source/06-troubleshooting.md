# 6. Troubleshooting Guide — Phased GPO-to-Intune Transition Program

Use `scripts\GPOPROG-Discovery.ps1` for transition readiness, `scripts\GPOPROG-Validation.ps1 -Phase
"<Phase>"` for per-phase coexistence/conflict state, `scripts\GPOPROG-Report.ps1` for phase status and
the conflict report, and `scripts\GPOPROG-Remediation.ps1` for safe precedence fixes.

## A. Settings flip between GPO and Intune (the loop signature)
| Symptom | Cause | Remediation |
|---|---|---|
| A setting alternates between a GPO value and an Intune value across policy cycles | No precedence set, or the legacy GPO for a migrated area is still linked | Run `GPOPROG-Remediation.ps1` (sets `MDMWinsOverGP`, requests sync); then **scope the legacy GPO away** for that area — the durable fix is one authority per setting |
| `GPOPROG-Validation.ps1` reports `MDMWinsOverGP : not enabled` | `Coexistence Policy – MDM Wins Over GP – All Migrated` not assigned to the device | Assign the coexistence policy to the device's phase scope group; sync |

## B. Same-setting conflicts on a migrated area
- Confirm precedence is in effect (Test 1), then confirm the **legacy GPO for that area is unlinked**
  from migrated devices. A conflict that persists with `MDMWinsOverGP` enabled almost always means the
  Intune value and the GPO value differ *and* both still apply — remove the GPO authority for that area.

## C. Pressure to start security before stabilization passes
- This is a governance issue, not a technical one. **Hold the Phase-2 stabilization gate.** If
  `GPOPROG-Report.ps1` shows any open conflict/loop on the broad core-OS scope, security phases stay
  blocked. Surface the open count and the gate checklist to stakeholders; the gate, not the pressure,
  decides.

## D. Firewall phase: network lockout after migration
| Symptom | Cause | Remediation |
|---|---|---|
| Users lose required network access after the firewall policy applies | Firewall control migrated before core OS was stable, or a rule gap vs. the legacy GPO | **Roll the firewall phase back** (re-link the legacy firewall GPO, which is still present-but-unlinked; revert the Intune assignment); re-confirm Phase-2 stabilization; re-run the firewall pilot against parity |

## E. App-control phase: required apps blocked
| Symptom | Cause | Remediation |
|---|---|---|
| Required applications won't launch after app-control policy applies | App control enforced before audit/learn review, or a rule gap | Switch the control to **audit/learn** mode, review the block events, fill the rule gap, re-validate the pilot, then re-enforce; roll back via the present-but-unlinked legacy GPO if needed |

## F. A phase won't validate / gate stays red
- Confirm the phase scope group membership is correct and devices are Intune-managed
  (`GPOPROG-Discovery.ps1`). A device receiving GPO only (not enrolled) cannot honor precedence —
  enroll it or remove it from the phase scope.

## G. Diagnostics quick reference
```powershell
# Precedence (MDM wins over GP) on the device
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\ControlPolicyConflict' -EA SilentlyContinue
# What Intune is enforcing (applied MDM PolicyManager values)
Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device' -EA SilentlyContinue
# Resultant Group Policy (what GPO still applies) — review against migrated areas
gpresult /h .\rsop.html
# Trigger an MDM/Intune sync so policy re-evaluates
Start-Process "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList "/c /AutoEnrollMDM"
```

## H. When to escalate
If precedence is enabled, the legacy GPO for the area is unlinked, the device is enrolled and synced,
and a conflict/loop still persists after a policy cycle, capture `gpresult /h` output plus
`GPOPROG-Validation.ps1` results and open a Microsoft support case before advancing the affected phase.
