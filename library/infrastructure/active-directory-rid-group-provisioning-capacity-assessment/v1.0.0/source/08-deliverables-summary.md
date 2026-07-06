# Deliverables Summary

## What's in this package

A complete, reusable Active Directory capacity-and-architecture assessment you run against your own
domain — documentation plus five read-only-by-default PowerShell scripts.

### Documentation
- **Solution Overview** — RID / RID Master / per-domain pool fundamentals, what drives consumption,
  and the go/no-go decision this assessment supports.
- **Requirements & Inputs** — every prerequisite with Description / Why / Verify / Implement-if-missing.
- **Assessment Methodology** — the five-step method: measure RID consumption, project pool lifetime
  (app-only + blended, with worked example tables), evaluate non-RID risks, review authorization
  architecture, and produce findings + conditions of approval.
- **Testing & Validation** — nine pass/fail gates confirming monitoring and guardrails are in place.
- **Troubleshooting** — RID Master unhealthy, token-size auth failures, orphan detection, large-group
  replication.
- **Best Practices** — naming, dedicated OU, AGDLP, lifecycle automation, monitoring thresholds.
- **Deliverables Summary** — this document, plus the reusable Assessment Report template outline.

### Scripts (`scripts/`)
| Script | Mode | Purpose |
|---|---|---|
| `RIDCAP-Discovery.ps1` | read-only | RID-pool consumption, % consumed, remaining, RID Master identity/health |
| `RIDCAP-Validation.ps1` | read-only | Guardrail validation: dedicated OU, naming conformance, ownership metadata, scope |
| `RIDCAP-Report.ps1` | read-only | Project-group growth & orphan report by project ID + projected lifetime |
| `RIDCAP-TokenExposure.ps1` | read-only | Kerberos token-size / group-SID-count exposure for high-membership principals |
| `RIDCAP-LifecycleCleanup.ps1` | preview by default (`-WhatIf`) | Disable→stage→delete of orphaned project groups per an active-projects list |

## Outcome

An evidence-based **go/no-go on the group-provisioning model**: RID lifetime projected from your own
measurements, the real risks (token bloat, sprawl, lifecycle) assessed, a scalable AGDLP/RBAC design
confirmed, and a reusable report and scripts you keep and re-run on every recertification cycle.

---

## Reusable "Assessment Report" template (one-page outline)

Fill this in from the methodology outputs. Every value comes from your own measured data.

**1. Header**
- Domain / scope · Assessment type: AD capacity + authorization-architecture review · Date · Reviewer.

**2. Restated requirement**
- One sentence: *is the proposed per-object group-provisioning model sustainable long-term without
  RID exhaustion, scalability issues, or unmanageable operational risk?*

**3. Current state & workload**
- Groups per project/object · Projects/objects per period · Derived groups/year · Any prior/retired
  model.

**4. RID measurement (Step 1)**
- RIDs consumed · Pool maximum · RIDs remaining · Percent consumed · RID Master identity & health.

**5. RID projection (Step 2)**
- Annual app burn · Years-to-exhaust (app-only, worst & low case) · Blended whole-domain table ·
  Extended-pool note · **Finding** (e.g. RID risk = Very Low).

**6. Non-RID risk findings (Step 3)**
- Token bloat (named high-membership identities + SID counts) · Sprawl/lifecycle (current group count,
  orphan count) · Replication/GC · Backup/DIT · Admin overhead · SYSVOL (not impacted).

**7. Authorization-architecture findings (Step 4)**
- AGDLP conformance · Growth-bounding options considered · Recommendation on model shape.

**8. Decision & conditions of approval (Step 5)**
- Go / No-go · The guardrail conditions (lifecycle automation, dedicated OU + naming, AGDLP,
  ownership metadata, RID/token/orphan monitoring, recertification) · Re-review triggers.

**9. Sign-off**
- Reviewed by · Date · Next review (on material design change or annually).
