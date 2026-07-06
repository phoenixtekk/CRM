# 6. Troubleshooting Guide — Vendor Technical Governance & Anti-Lock-In Playbook

Use `GWVEND-Discovery.ps1` for the register and source-environment recon, `GWVEND-Validation.ps1`
for conformance and disposition state, `GWVEND-Report.ps1` for the finding report, and
`GWVEND-Remediation.ps1` (preview first) to record remediation actions. This guide focuses on the
core challenge: **handling non-conformant designs** without either rubber-stamping them or stalling
the program.

## A. A vendor design fails one or more anti-lock-in criteria
This is the normal case, not an error — the method is working.
| Situation | Handling |
|---|---|
| Fails **portability** (proprietary-only pattern, no alternative) | Require the sanctioned/standard pattern, or a documented, accepted reason with an exit path. Disposition **Approved-with-conditions** (condition = adopt standard pattern or record accepted trade) or **Rejected**. |
| Fails **data ownership** (vendor-gated export, undocumented schema) | Require documented schema and on-demand full extract before build. Do not approve until the enterprise can get its data out unaided. |
| Fails **standards conformance** (proprietary where a standard exists) | Require the open standard (SAML/OIDC/SCIM, documented API, open format) or a recorded, accepted reason. |
| Fails **exit criteria** (no articulable exit) | Require the exit path, switching cost, and data-egress story at design time. "Deal with it later" is a fail. |

## B. A partner pushes back on the gate
| Symptom | Cause | Remediation |
|---|---|---|
| "The gate is slowing us down" | Gate seen as optional review, not a build precondition | Re-confirm in the RACI that architectural disposition is enterprise-Accountable and is a precondition for build; escalate to the Program/Enterprise Owner if unresolved. The friction is intended — manage it through escalation, not by waiving the gate. |
| Vendor disputes a criterion result | Assumption behind the design was never validated | Return to the Vendor Assumption Log; validate or reject the assumption, then re-score. A disagreement usually traces to an unvalidated assumption treated as fact. |
| Design blocked, schedule at risk | No time-boxed exception path in use | Grant an owner-accountable, dated **exception** with a remediation commitment; record it and track it to closure (see D). |

## C. Escalation ladder for a rejected/blocked design
1. **Architect ↔ vendor** — resolve against the specific failing criterion (not the whole design).
2. **Program/Enterprise Owner arbitrates** — RACI-Accountable for escalation; decides proceed with
   conditions, exception, or rework.
3. **Exception (time-boxed)** — owner-accountable, dated, with a remediation commitment; recorded,
   never a silent waiver.
Run `GWVEND-Report.ps1` to give the escalation the finding record it needs.

## D. Exceptions piling up / going stale
- Every granted exception is standing lock-in debt until closed. Run `GWVEND-Validation.ps1`
  (exception section) on a cadence; any exception past its close date is flagged. Drive each to
  closure — an unclosed exception means a non-conformant design is now in production unremediated.

## E. A vendor object exists with no approved design
| Symptom | Cause | Remediation |
|---|---|---|
| `GWVEND-Discovery.ps1` finds a vendor-created enterprise app / group / config in the source environment that maps to no approved design | Work was built ahead of the gate | Flag it, trace it to a partner and a (missing) design, run it through the review method retroactively, and disposition it. Repeated occurrences mean the gate is being bypassed — escalate. |

## F. Register out of date / discovery returns little
| Symptom | Cause | Remediation |
|---|---|---|
| Register missing in-flight designs | Not maintained on a multi-partner program | Re-run `GWVEND-Discovery.ps1` on a cadence and seed from current deliverables; make register intake step 1 of the runbook (§8). |
| Source-environment recon empty or errors | Graph SDK not installed / read scopes not consented / wrong tenant | `Install-Module Microsoft.Graph -Scope CurrentUser`; re-run and accept `Application.Read.All`, `Directory.Read.All`, `Policy.Read.All`; confirm the correct source tenant. |

## G. Diagnostics quick reference
```powershell
# Enumerate the register and source-environment vendor objects (read-only)
powershell -ExecutionPolicy Bypass -File .\GWVEND-Discovery.ps1 -RegisterPath .\vendor-design-register.csv

# Score conformance + disposition + exceptions
powershell -ExecutionPolicy Bypass -File .\GWVEND-Validation.ps1 -RegisterPath .\vendor-design-register.csv

# Finding report for the escalation
powershell -ExecutionPolicy Bypass -File .\GWVEND-Report.ps1 -RegisterPath .\vendor-design-register.csv
```

## H. When to escalate to program leadership
If a partner repeatedly builds ahead of the gate, disputes the anti-lock-in bar itself (rather than
a single criterion result), or an exception cannot be closed because the lock-in is now
irreversible, treat it as a program-governance issue: raise it to the Program/Enterprise Owner
(RACI-Accountable for escalation) with the finding report, and decide whether the design must be
reworked, contractually addressed, or accepted as a recorded, owned trade.
