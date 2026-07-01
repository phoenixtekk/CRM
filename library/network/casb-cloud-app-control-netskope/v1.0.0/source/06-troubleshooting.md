# 6. Troubleshooting Guide — CASB & Cloud App Control with Netskope

Use `NSCASB-Validation.ps1` / `NSCASB-Discovery.ps1` for readiness signals and
`NSCASB-Report.ps1` for the cloud-app usage and risk picture, `NSCASB-Remediation.ps1`
(default `-WhatIf`) for safe fixes. Netskope console specifics are deferred to the official Netskope
documentation.

## A. Controls not firing / app not seen by policy
| Symptom | Cause | Remediation |
|---|---|---|
| Activity not controlled | Traffic not steered through Netskope | Confirm steering for the user; run `NSCASB-Validation.ps1`; ensure the pilot user is in scope |
| App visible but actions not inspected | SSL/TLS inspection not covering the category | Enable inspection for the in-scope category; confirm the decryption certificate is trusted |
| Policy seems ignored | Policy scoped to the wrong group | Confirm scope is `CASB Pilot – Pilot users – Pilot`; run `NSCASB-Validation.ps1` |

## B. Over-blocking / business impact
- Replace a hard block with restrict or coach on the activity controls — Inline – Configure profile.
- Narrow the policy to the specific risky activity (for example upload only) instead of the whole app.
- Roll the control back to monitor-only, then re-tune before re-enabling enforcement.

## C. Discovery / risk register gaps
| Symptom | Cause | Remediation |
|---|---|---|
| New shadow-IT app not governed | Register stale | Re-run discovery; add the app to the app risk register with a disposition |
| Sanctioned app has no policy | Disposition decided but policy not built | Run `NSCASB-Remediation.ps1` (flags sanctioned apps lacking a policy); build the Sanctioned apps policy |

## D. API CASB issues
| Symptom | Cause | Remediation |
|---|---|---|
| At-rest findings missing | API connection unhealthy/expired | Re-authorize the API connections — Sanctioned apps – Configure per Netskope's connector flow |
| Legitimate sharing quarantined | API response too aggressive | Return the connection response to alert/monitor mode; re-tune before active response |

## E. Identity / scoping
- Users not matching policy: confirm the user resolves in Entra ID and is in the scope group; rebuild
  membership with `NSCASB-Set-ScopeTargeting.ps1`.

## F. Diagnostics quick reference
```powershell
# Inventory + readiness signals (read-only)
.\NSCASB-Discovery.ps1
# Confirm steering/inspection readiness and pilot scoping (read-only)
.\NSCASB-Validation.ps1
# Cloud-app usage and risk report (read-only)
.\NSCASB-Report.ps1
# Preview safe fixes (no changes)
.\NSCASB-Remediation.ps1 -WhatIf
```

## G. When to escalate
If steering and inspection are confirmed, the user is in the correct scope group, and a control still
will not fire, capture the `NSCASB-Validation.ps1` output and the relevant Netskope policy/event logs
and open a case with Netskope support.
