# 6. Troubleshooting Guide — Zero Trust Network Access (ZTNA) with Netskope Private Access

Use `NSZTNA-Validation.ps1` for endpoint/identity state and `NSZTNA-Report.ps1` for entitlement and
usage; use `NSZTNA-Remediation.ps1` (default `-WhatIf`) for safe fixes. Netskope console specifics
are deferred to the official Netskope documentation.

## A. A published app is unreachable
| Symptom | Cause | Remediation |
|---|---|---|
| Entitled app will not connect | `Publisher – <Site> – Pilot` down, or app object maps the wrong host/port | Confirm the `publisher` is healthy in the console; re-check the host/port/protocol on `Private App – <App> – Pilot` |
| App name will not resolve | DNS not configured through the ZTNA path | Fix private DNS for the app (Requirements 2.7); re-test with `NSZTNA-Validation.ps1` |
| Works on VPN, not on ZTNA | App not yet published, or user not in the entitlement group | Publish the app; add the user to `Access Group – <App or Role> – Pilot` with `NSZTNA-Remediation.ps1` |

## B. User reaches the wrong set of apps
- Too few apps: the user is missing from an `Access Group – <App or Role>` group — add them (run
  `NSZTNA-Remediation.ps1 -WhatIf` first, then commit).
- Too many apps: a policy is too broad or default-deny is not in place — tighten
  `Access Policy – <App or Role> – Pilot` to grant only its named `Private App` object.

## C. Posture check blocks a healthy device
| Symptom | Cause | Remediation |
|---|---|---|
| Compliant device denied | Device not reporting compliant/managed, or certificate missing | Confirm Intune compliance and any required certificate; re-evaluate posture |
| Access intermittently drops | Posture signal flapping | Stabilize the compliance/certificate signal; review the posture condition on the policy |

## D. Client steering problems
- Client not steering: confirm the Netskope client is installed and enrolled (`NSZTNA-Validation.ps1`);
  redeploy via Intune if absent.
- Some traffic bypasses ZTNA: confirm the app is published and steered, and that no VPN split-tunnel
  route still shadows it during coexistence.

## E. Coexistence and cutover issues
- Users lose access at cutover: a wave was cut over before passing the gate — re-enable VPN access for
  that wave, fix the failing app/policy, re-run the Testing Guide, then cut over again.
- VPN still in use after cutover: an app was never published — find it with `NSZTNA-Report.ps1` usage
  data, publish it, validate, then remove the VPN dependency.

## F. Diagnostics quick reference
```powershell
.\NSZTNA-Discovery.ps1     # endpoint posture, VPN routes/hosts, candidate publisher hosts (read-only)
.\NSZTNA-Validation.ps1    # client state, group membership, posture, app resolution (read-only)
.\NSZTNA-Report.ps1        # entitlement + usage report (read-only)
.\NSZTNA-Remediation.ps1   # safe fixes, default -WhatIf (e.g. add user to entitlement group)
```
Netskope-side diagnostics (publisher health, session logs, policy hits) are in the Netskope console
and are deferred to the official Netskope documentation.

## G. When to escalate
If the `publisher` is healthy, the app object maps the correct host/port, DNS resolves through ZTNA,
the user is in the right entitlement group with a compliant device, and an entitled app still will
not connect, collect the Netskope session/policy logs for that user and app and open a Netskope
support case. Keep the affected users on the VPN fall-back until resolved.
