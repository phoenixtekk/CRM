# 6. Troubleshooting Guide — Conditional Access Integration (Government / GCC High)

Use **`CAIG-Validation.ps1`** / **`CAIG-Report.ps1`** to see why a sign-in was controlled, and run
**`CAIG-Validation.ps1`** (break-glass exclusion check) before any enforcement change. All scripts
must connect with **`-Environment USGov`**.

## A. Sovereign-cloud / wrong-endpoint mistakes (GCC-High-specific)
| Symptom | Cause | Remediation |
|---|---|---|
| Portal shows a different tenant / no policies | Opened a `*.com` portal (Commercial cloud) | Use the **`*.us`** portals: `entra.microsoft.us`, `intune.microsoft.us`, `portal.office365.us` |
| `CAIG-Report.ps1` returns nothing / auth error | `Connect-MgGraph` ran **without** `-Environment USGov` (hit `graph.microsoft.com`) | Reconnect with `Connect-MgGraph -Environment USGov`; confirm `Get-MgContext` shows the USGov environment. `CAIG-Discovery.ps1` reports the active Graph host |
| Sign-in/auth failures after firewall change | `.us` domains blocked by proxy/filtering | Allow `login.microsoftonline.us`, `graph.microsoft.us`, `*.auth.microsoft.us`, and the GCC High URL/IP ranges |
| A demoed CA feature isn't in the blade | GCC High **lags Commercial 2–6 weeks**, or the feature is Gov-absent | Check `gcc-high-parity-notes.md`; **verify for GCC High** before designing around it |

## B. Lockout risk / admins blocked
| Symptom | Cause | Remediation |
|---|---|---|
| Admin locked out by a policy | Break-glass not excluded, or policy too broad | Sign in with a **break-glass** account (`…@<tenant>.onmicrosoft.us`); fix the exclusion; never enforce without break-glass verified via `CAIG-Validation.ps1` |
| Everyone blocked after enabling | Policy enabled with a misconfigured grant | Use break-glass to set the policy back to **Report-only** (or run `CAIG-Remediation.ps1` to revert it); review the grant controls |

## C. "Require compliant device" blocks legitimate users
| Symptom | Cause | Remediation |
|---|---|---|
| Compliant-looking device blocked | Device not actually Compliant in Intune, or not Entra-registered | Run `CAIG-Validation.ps1`; confirm Intune (`intune.microsoft.us`) shows **Compliant**; fix compliance (Device Compliance GCC High solution) |
| Browser blocked but app works | Device registration/SSO state differs per client | Ensure the device is Entra-registered/joined and the browser uses the work account |

## D. MFA issues
- Users repeatedly prompted → expected on new sessions; confirm "remember MFA" / sign-in frequency
  settings.
- Users with no method → enable authentication methods and have them register before enforcing.
  Confirm each method is available in GCC High before relying on it.

## E. Legacy auth still working
- Block-legacy policy in Report-only → it only logs. Move to **On** to enforce.
- Some "modern-looking" clients still use legacy endpoints → confirm via sign-in logs **Client app**
  column.

## F. Location policy not behaving as expected
- Built on **legacy MFA Trusted IPs** instead of **named locations** → rebuild the condition on an
  IP-based **named location** (Implementation Step 3), which is the supported GCC High approach.
- Expecting **Global Secure Access** network signals → **GSA is not available in GCC High**; express
  network trust with named locations. [Microsoft — GSA
  limitations](https://learn.microsoft.com/en-us/entra/global-secure-access/reference-current-known-limitations)

## G. Report-only shows nothing
- No sign-ins yet for the targeted users/apps → have pilot users actually sign in (via
  `login.microsoftonline.us`); wait for logs to populate (a few minutes).

## H. Diagnostics quick reference
```powershell
dsregcmd /status        # device join/registration state (affects compliant-device control)
Get-MgContext           # confirm the connection is USGov (graph.microsoft.us), not Commercial
```
`entra.microsoft.us` → **Sign-in logs → (a sign-in) → Conditional Access / Report-only** tabs show
exactly which policies applied and why. The **What If** tool (Conditional Access → What If)
simulates a sign-in and works in GCC High. Note the **PowerPoint export** of policies is
Commercial-only — use `CAIG-Report.ps1` for exportable evidence instead.

## I. When to escalate
If a sign-in is blocked with all controls apparently satisfied (device Compliant, MFA passed) and
the Report-only/CA tabs are inconsistent, capture the sign-in correlation ID and open a Microsoft
support case **against the GCC High / US Government tenant** (specify the sovereign cloud so the case
is routed correctly).
