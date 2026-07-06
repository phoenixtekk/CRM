# 6. Troubleshooting Guide — macOS Compliance & Conditional Access for Zero-Trust Access

Use **`MACCA-Report.ps1`** to see, per Mac, the compliance state and access decision;
**`MACCA-Validation.ps1`** before any enforcement change; and Entra → **Sign-in logs → (a sign-in) →
Report-only / Conditional Access** tabs to see exactly which policy applied and why.

## A. Lockout risk / users blocked unexpectedly
| Symptom | Cause | Remediation |
|---|---|---|
| Legitimate Mac user blocked | The Mac is **Not compliant** (a signal failed) | Run `MACCA-Report.ps1`; fix the failing signal (below); confirm Intune shows **Compliant** |
| Admin/service account blocked | Break-glass / exception not excluded from the CA policy | Sign in with a **break-glass** account; add the exclusion to `CA - macOS - Require Compliant Device`; re-verify with `MACCA-Validation.ps1` |
| Whole pilot blocked after enabling On | Policy enabled before Report-only was clean | Use break-glass to set `CA - macOS - Require Compliant Device` back to **Report-only**; resolve would-blocks, then re-enable |

## B. A specific compliance signal is failing
| Signal | Typical cause | Remediation |
|---|---|---|
| **Encryption / FileVault** | FileVault off, or key escrow not complete | Ensure the Intune **Disk encryption (FileVault)** policy targets the Mac; have the user enable FileVault; wait for re-evaluation |
| **Minimum OS version** | Mac below the floor you set | Lower the floor to what the fleet can reach *or* update the Mac (Software Update / update policy); confirm with `MACCA-Discovery.ps1` |
| **Firewall** | macOS firewall disabled | Enable the firewall (or deploy a settings policy that does); re-sync |
| **Machine risk (Defender)** | Active/high-severity detection, or connector off | Resolve the Defender alert on the device; confirm the **Intune ↔ Defender** connector is **Enabled**; if Defender isn't deployed, remove the machine-risk rule until it is |

## C. Compliance state not updating
- The Mac hasn't synced → Company Portal → **check status**, or wait for the next sync cycle; then
  re-run `MACCA-Report.ps1`.
- Policy not assigned → confirm `macOS - Zero-Trust Compliance` targets a group the Mac is in
  (`MACCA-Set-ScopeTargeting.ps1 -WhatIf` previews membership).

## D. CA policy isn't applying to Macs
- **Device platforms** not set to macOS, or set to something else → confirm **Conditions → Device
  platforms → macOS** on `CA - macOS - Require Compliant Device`.
- Wrong target resource → the user's app isn't in the policy's **Target resources** (you scoped to
  Office 365) → widen resources or test against Office 365.
- Policy still in **Report-only** → it only logs; move **Enable policy → On** to enforce.

## E. "Require compliant device" blocks a device that looks compliant
- Intune shows **Compliant** but Entra still blocks → the Mac may not be **Entra-registered**, so
  Entra can't read its state → run `MACCA-Validation.ps1`; re-register/re-enroll the Mac.
- Compliance changed very recently → allow time to propagate to Entra; re-test.

## F. Report-only shows nothing
- No pilot sign-ins yet for the targeted resource → have pilot users actually sign in from their Macs;
  wait a few minutes for logs to populate.

## G. Diagnostics quick reference
- **Intune → Devices → Compliance → `macOS - Zero-Trust Compliance` → Device status** — per-Mac,
  per-signal pass/fail.
- **Entra → Conditional Access → What If** — simulate a macOS sign-in to predict the outcome before
  enforcing.
- **`MACCA-Report.ps1`** — the single artifact tying compliance state to the access decision.

## H. When to escalate
If a Mac is Intune-**Compliant** and Entra-registered but sign-in is still blocked with the
Report-only / Conditional Access tabs inconsistent, capture the sign-in **correlation ID** and open a
Microsoft support case.
