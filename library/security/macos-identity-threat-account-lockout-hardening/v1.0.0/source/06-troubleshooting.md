# 6. Troubleshooting Guide — macOS Identity-Threat & Account-Lockout Hardening

Use `MACLOCK-Discovery.ps1` / `MACLOCK-Validation.ps1` for sign-in-failure state and Smart Lockout /
MFA posture, `MACLOCK-Report.ps1` for the before/after exposure report, and `MACLOCK-Remediation.ps1`
(default `-WhatIf`) for safe fixes.

## A. Failures keep coming from a Mac after the password change
| Symptom | Cause | Remediation |
|---|---|---|
| Same user's Mac still logs failed sign-ins | Keychain / mail / Wi-Fi still holds the old password and auto-retries | Clear the stale keychain items for that account, re-enter the current password in Mail / Outlook / Wi-Fi; re-run `MACLOCK-Discovery.ps1` and confirm the failures stop |
| Failures come from a specific app (e.g. Exchange) | That app's saved credential wasn't updated | Update the credential in the app profile; keychain re-sync is per-item |

## B. Account keeps locking out
| Symptom | Cause | Remediation |
|---|---|---|
| Legitimate user locked repeatedly | Smart Lockout threshold too low for the burst of Mac retries, or the Mac source not yet remediated | Remediate the Mac source first (A); then confirm the Smart Lockout threshold/duration in `MACLOCK Lockout & Spray Register - Mac Fleet - Baseline` is appropriate |
| Lockout behaves unexpectedly on a synced user | Hybrid account: on-prem AD lockout policy interacts with cloud Smart Lockout | Confirm the account is hybrid (Requirement 2.6); coordinate the cloud + on-prem lockout policy with the directory owner |

## C. Password-spray / risk detection still firing
| Symptom | Cause | Remediation |
|---|---|---|
| Spray detection persists for a user | The Mac source is still generating failures, or another (non-Mac) source exists | Confirm from the sign-in logs (OS = macOS) whether the failures are still Mac-originated; if not, the source is elsewhere and out of this solution's scope |
| No risk detections visible at all | Identity Protection risk detections need Entra ID P2 | Confirm licensing (Requirement 2.1); Smart Lockout + MFA still work without P2 |

## D. MFA policy problems
| Symptom | Cause | Remediation |
|---|---|---|
| Pilot user not prompted for MFA | Policy in report-only, wrong scope, or an exclusion applies | Confirm `MACLOCK CA - Require MFA - Mac Pilot` is On and assigned to `MACLOCK Scope - Pilot - Macs`; review the sign-in log's Conditional Access evaluation |
| MFA policy blocks a legitimate pilot user | Grant/condition too strict, or a needed app excluded | Narrow the policy, confirm the user has a registered MFA method, and re-test in report-only before turning On |

## E. SecureToken / local-account divergence
- If a user is prompted repeatedly on the Mac and keychain items keep becoming invalid after a reset,
  the local account password and its **SecureToken** have likely drifted from the current Entra
  password. Re-align the local password and SecureToken with the current Entra password (per your Mac
  admin runbook), then clear and re-populate the keychain items. Keep this gated by change control —
  it is authentication-impacting.

## F. Scope / targeting problems
- If a change reaches the wrong Macs, confirm membership of `MACLOCK Scope - Pilot - Macs` /
  `MACLOCK Scope - Broad - Macs`; run `MACLOCK-Set-ScopeTargeting.ps1` to confirm the groups exist and
  print their object IDs, and verify the Conditional Access / Intune assignments point at them.

## G. Graph / permissions problems
- If a script cannot read the sign-in logs, Smart Lockout policy, or Conditional Access, confirm the
  Microsoft Graph SDK is installed and consent was granted to the read scopes (`AuditLog.Read.All`,
  `Directory.Read.All`, `Policy.Read.All`, `IdentityRiskEvent.Read.All`); sign in with an account
  holding Security Reader / Security Administrator. Re-run `MACLOCK-Discovery.ps1`.

## H. When to escalate
If Mac-side remediation is complete and Smart Lockout / MFA validate correctly but a user still shows
Mac-originated failures or lockouts, export the discovery and report output and raise it — the source
may be a device you haven't remediated yet or a non-Mac source; open a Microsoft support case for a
sign-in-log / Identity Protection data question if the logs themselves look inconsistent.
