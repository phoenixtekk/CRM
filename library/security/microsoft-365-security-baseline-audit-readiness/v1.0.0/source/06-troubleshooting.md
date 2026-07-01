# 6. Troubleshooting Guide — Microsoft 365 Security Baseline & Audit Readiness

Use `M365SEC-Discovery.ps1` / `M365SEC-Validation.ps1` for posture and baseline state,
`M365SEC-Report.ps1` for the Secure Score + control-evidence report, and `M365SEC-Remediation.ps1`
(default `-WhatIf`) for safe fixes.

## A. Secure Score not improving
| Symptom | Cause | Remediation |
|---|---|---|
| Score unchanged after config | Improvement action not the one measured, or score not yet refreshed | Confirm which recommended action maps to the setting in `security.microsoft.com` to Secure Score; scores refresh on Microsoft's cadence, not instantly |
| Action shows not completed | Setting applied at wrong scope or partially | Re-run `M365SEC-Validation.ps1`; confirm the setting is applied tenant-wide or to the intended scope group |

## B. Baseline compliance gaps
| Symptom | Cause | Remediation |
|---|---|---|
| Validation lists deviations | Service not yet configured to the desired value | Configure the setting per the baseline register, then re-run `M365SEC-Validation.ps1`; use `M365SEC-Remediation.ps1 -WhatIf` to preview a safe fix |
| Setting reverts | A conflicting policy or a second admin change | Identify the conflicting policy; make the baseline register the single source of truth and re-apply |

## C. Compliance Manager assessment issues
| Symptom | Cause | Remediation |
|---|---|---|
| Target framework template missing | Licensing does not include the premium assessment template | Confirm E5 / compliance add-on (Requirement 2.2); use the included baseline template until licensed |
| Improvement action stuck at not implemented | Evidence/status not recorded | Work the action in `Compliance Assessment – Target Framework – Mapping`; set implementation and test status and attach evidence |

## D. Evidence pack incomplete
- Capture evidence at the moment of change, not at audit time; run `M365SEC-Report.ps1` each review
  cycle and file dated output into `Control Evidence Pack – Tenant Baseline – Audit` tied to each
  control.

## E. Pilot breakage (sign-in / mail / sharing)
- If a scoped change blocks pilot users, narrow or roll back the scoped policy per the change-control
  rollback step, confirm the pilot works, then re-apply. Keep all scoped pilots on `M365 Baseline
  Scope – Pilot – Users` so blast radius stays small.

## F. Graph / permissions problems
- If a script cannot read Secure Score or config, confirm the Microsoft Graph SDK is installed and
  consent was granted to the read scopes; sign in with an account holding Security Reader / Security
  Administrator. Re-run `M365SEC-Discovery.ps1`.

## G. When to escalate
If Secure Score and baseline validation both look correct but a framework control still shows a gap,
export the control-evidence report and the assessment status and raise it with the auditor of record
(or open a Microsoft support case for a Compliance Manager data issue).
