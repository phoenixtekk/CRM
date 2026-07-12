# 6. Troubleshooting Guide — Privileged Access Workstation (PAW) for Cloud Administration

Use `ENTPAW-Validate.ps1` / `ENTPAW-Discovery.ps1` for current configuration state,
`ENTPAW-Report.ps1` for privileged-access coverage, `ENTPAW-Set-CAState.ps1` (default `-WhatIf`, with
a break-glass guard) to flip the policy back to report-only fast, and `ENTPAW-DeviceTag.ps1` to fix
device markers.

## A. PAW not recognised by the device filter
| Symptom | Cause | Remediation |
|---|---|---|
| PAW admin "would block" even from the PAW | Device marker not set, or set on the wrong device object | Confirm `extensionAttribute1 = PAW` on the correct Entra device object; set with `ENTPAW-DeviceTag.ps1`; allow directory propagation |
| Device filter matches the wrong devices | Marker reused elsewhere, or filter rule typo | Reserve the marker for PAWs only; confirm the rule is exactly `device.extensionAttribute1 -eq "PAW"`; run `ENTPAW-Validate.ps1` |
| Filter change not taking effect | Token still cached from before the change | Sign out/in on the PAW to get a fresh evaluation; re-check `Sign-in logs -> Report-only` |

## B. Compliance / hardening problems
| Symptom | Cause | Remediation |
|---|---|---|
| PAW shows non-compliant | Baseline/BitLocker/Secure Boot/firewall requirement not met, or policy still applying | Open `Intune -> Devices -> (PAW) -> Device compliance`; remediate the failing setting; wait for the next check-in |
| Admin tooling blocked on the PAW | App Control allow-list too tight | Keep App Control in audit; add the required admin tools to the allow-list; only then move to enforced |
| Admin can still read email / browse freely | Isolation restrictions not assigned or not applied | Confirm `Restrictions – PAW Isolation – Pilot` is assigned to `PAW Devices – Admin Devices – Pilot` and applied; re-sync the device |

## C. Break-glass / lockout risk
- Confirm `CA Break-Glass Exclusion` (both cloud-only break-glass accounts) is on the Exclude tab of `CA – Require PAW for Privileged Roles – Pilot`; run `ENTPAW-Validate.ps1`. The `ENTPAW-Set-CAState.ps1` guard refuses to enable a policy that does not exclude break-glass.
- If the device filter locks out administrators, sign in with a break-glass account (from any device), set the policy to report-only, and investigate. Never remove the break-glass exclusion.

## D. Conditional Access enforcement issues
| Symptom | Cause | Remediation |
|---|---|---|
| Non-PAW privileged sign-in NOT blocked after enforce | Policy still report-only, or target resources too narrow | Confirm state is enabled (`ENTPAW-Validate.ps1`); confirm the admin surface (admin portals / management API) is targeted |
| Legitimate PAW admin blocked after enforce | Compliance flapping, or grant requires a method the admin lacks | Confirm compliance is stable; confirm required MFA/method is registered; revert to report-only if needed and re-read |
| Policy applies to non-admin sign-ins | User scope too broad | Scope Users to `PAW Admins – Cloud Admin – Pilot` and the correct admin resources only |

## E. PIM activation from the PAW
| Symptom | Cause | Remediation |
|---|---|---|
| Cannot activate a role from the PAW | Role not eligible, or activation blocked by policy | Confirm an eligible assignment exists in PIM; check the activation policy (MFA/approval); see the PIM solution |
| Activation succeeds but admin portal still blocked | Device filter evaluated the sign-in as non-PAW | Fix the device marker/compliance (Section A/B); the PAW must be recognised for the session |

## F. Licensing / feature not visible
- If PIM or device filters are not available, confirm Entra ID P2 (PIM) and Conditional Access (P1+) licensing; if App Control or a baseline is missing, confirm Intune licensing and enrolment. Run `ENTPAW-Discovery.ps1`. *Verify current availability in your tenant.*

## G. Diagnostics quick reference
```powershell
Connect-MgGraph -Scopes 'Policy.Read.All','Device.Read.All','DeviceManagementConfiguration.Read.All'
# Conditional Access device-filter policies and state
Get-MgIdentityConditionalAccessPolicy -All | Where-Object { $_.Conditions.Devices } | Select-Object DisplayName, State
# Device marker check
Invoke-MgGraphRequest -Method GET -Uri "/v1.0/devices?`$filter=extensionAttributes/extensionAttribute1 eq 'PAW'&`$select=displayName,deviceId"
# Intune compliance policies
Invoke-MgGraphRequest -Method GET -Uri '/v1.0/deviceManagement/deviceCompliancePolicies'
```

## H. When to escalate
If the PAW is compliant and correctly marked, break-glass is excluded, PIM eligibility is in place,
and privileged sign-ins still evaluate incorrectly after a clean report-only read, capture
`ENTPAW-Report.ps1` output and the affected sign-in's report-only detail and open a Microsoft support
case.
