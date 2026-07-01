# 6. Troubleshooting Guide — Conditional Access Integration

Use **`CAI-Validation.ps1`** / **`CAI-SignInReport.ps1`** to see why a sign-in was controlled, and
**`CAI-BreakGlassCheck.ps1`** before any enforcement change.

## A. Lockout risk / admins blocked
| Symptom | Cause | Remediation |
|---|---|---|
| Admin locked out by a policy | Break-glass not excluded, or policy too broad | Sign in with a **break-glass** account; fix the exclusion; never enforce without break-glass verified |
| Everyone blocked after enabling | Policy enabled with a misconfigured grant | Use break-glass to set the policy back to **Report-only**; review the grant controls |

## B. "Require compliant device" blocks legitimate users
| Symptom | Cause | Remediation |
|---|---|---|
| Compliant-looking device blocked | Device not actually Compliant in Intune, or not Entra-registered | Run `CAI-Validation.ps1`; confirm Intune shows **Compliant**; fix compliance (DCP solution) |
| Browser blocked but app works | Device registration/SSO state differs per client | Ensure the device is Entra-registered/joined and the browser uses the work account |

## C. MFA issues
- Users repeatedly prompted → expected on new sessions; confirm "remember MFA"/sign-in frequency settings.
- Users with no method → enable authentication methods and have them register before enforcing.

## D. Legacy auth still working
- Block-legacy policy in Report-only → it only logs. Move to **On** to enforce.
- Some "modern-looking" clients still use legacy endpoints → confirm via sign-in logs **Client app** column.

## E. Report-only shows nothing
- No sign-ins yet for the targeted users/apps → have pilot users actually sign in; wait for logs to populate (a few minutes).

## F. Diagnostics quick reference
```powershell
dsregcmd /status        # device join/registration state (affects compliant-device control)
```
Entra → **Sign-in logs → (a sign-in) → Conditional Access / Report-only** tabs show exactly which
policies applied and why. The **What If** tool (Conditional Access → What If) simulates a sign-in.

## G. When to escalate
If a sign-in is blocked with all controls apparently satisfied (device Compliant, MFA passed) and
the Report-only/CA tabs are inconsistent, capture the sign-in correlation ID and open a Microsoft support case.
