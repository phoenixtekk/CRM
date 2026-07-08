# Implementation — Microsoft Purview Health Check

This is the ordered, do-this-then-that guide for running the health check, scoring it, building the
remediation register, and closing the gaps. It follows the standard model
(**Assess → Design → Configure → Pilot (simulation/test) → Validate → Expand**), adapted for a
**read-first assessment**: the "Assess" and "Design" phases are the health check itself; "Configure /
Pilot" is remediation (routed to the owning capability, piloted in simulation/test — this solution
commits only the one safe fix); "Validate/Expand" is re-scoring and turning the check into a recurring
cadence. Every domain, rating, and register field is named verbatim so the scripts, testing, and
troubleshooting line up. Replace `contoso.com` and sample names with your own.

> **Portal note.** The Purview objects assessed here live in the **Microsoft Purview portal**
> (`purview.microsoft.com` → **Data Loss Prevention**, **Information Protection**, **Data Lifecycle
> Management**, **Audit**, **Insider Risk Management**, **Roles & scopes**). PowerShell (S&C PowerShell
> / Exchange Online / Graph) is used to **read** that state and to **plan** remediation. Where a
> capability is portal-only or its read surface differs by tenant/licence, the scripts say so —
> **verify against your licensing/tenant.**

> **Read-only by default.** Phases 0–2 (Assess, Design) and Phase 4 (Validate) change **nothing**. The
> only write in this entire solution is the optional **unified-audit-log re-enable** in Phase 3, gated
> behind `-Commit`. All higher-impact remediation is handed to the owning capability solution, which
> pilots it in **simulation/test/report-only** first.

---

## Phase 0 — Assess (run the health check, read-only)

1. **Confirm read access and the toolchain (R1, R2).** Verify you can read DLP, labels, retention,
   audit, and role state in the portal, and that `Connect-IPPSSession`, `Connect-ExchangeOnline`, and
   `Connect-MgGraph` all succeed with an MFA-capable admin.
2. **Capture the yardsticks (R3, R4).** Have the **in-scope workload + data map** and the **intended
   capability baseline** to hand — the Coverage and Policy domains score against these.
3. **Run the inventory.** Run **`OPSHEALTH-Discovery.ps1`** (read-only). It inventories:
   - **DLP** policies and their **Mode** (e.g. `Enable`, `TestWithNotifications`, `TestWithout...`,
     `Disable`) and enabled/health state.
   - **Sensitivity labels** and **label policies** (published vs orphaned labels).
   - **Retention / data-lifecycle** policies and **retention labels** (present, enabled, workloads).
   - **Unified audit log** status (on/off) — via Exchange Online.
   - **Insider-risk** policy **presence** and privacy posture (posture only — R5).
   - **Compliance role groups** and their membership.
   - **Gate 0:** the inventory completes and you can read each in-scope surface → continue. Where a
     surface cannot be read, record it as a **read-access** finding (not a drift Gap) and fix access.
4. **Run the coverage + role review.** Run **`OPSHEALTH-ScopeCheck.ps1`** (read-only) to map **which
   workloads** each DLP/retention/label policy actually reaches, and to run the **least-privilege role
   review** (Global Admin count, single-member / empty role groups, membership size).

## Phase 1 — Design (score the rubric, build the register)

Score every check **Healthy → At Risk → Gap** across the three domains, then record every non-Healthy
result in the **Remediation Register**.

- **Policy health (P):**
  - **Healthy** — the intended policy exists, is **enabled**, and is **healthy** (no error/unhealthy
    state).
  - **At Risk** — the policy exists but is **stuck in simulation/test** past its pilot, partially
    disabled, or shows a health warning.
  - **Gap** — an intended policy is **missing** or **disabled**, or the **unified audit log is off**.
- **Coverage (C):**
  - **Healthy** — every in-scope workload has the intended DLP / retention / label coverage.
  - **At Risk** — coverage exists but is incomplete (e.g. DLP on email only; labels published to a
    subset; endpoint actions intended but **no devices onboarded**).
  - **Gap** — an in-scope workload has **no** coverage of an intended capability.
- **Roles (R):**
  - **Healthy** — least privilege; more than one trained admin per critical role; no Global Admin used
    for routine compliance work; no stale/empty groups.
  - **At Risk** — a single-member (SPOF) role group, mild over-membership, or a stale member.
  - **Gap** — **Global Administrator sprawl**, an empty critical role group, or broad over-privilege.

**Remediation Register — one row per non-Healthy finding**, with these verbatim fields:

| Field | Meaning |
| --- | --- |
| **Finding** | The drift/gap, in one line (e.g. "DLP policy `DLP-Finance` stuck in test 6 months"). |
| **Domain** | **P** (Policy), **C** (Coverage), or **R** (Roles). |
| **Rating** | **At Risk** or **Gap**. |
| **Severity** | **High / Medium / Low** — audit-log off, missing DLP on a regulated workload, or GA sprawl are High. |
| **Owner** | The named domain owner (R6). |
| **Owning capability** | The solution that closes it (DLP / Labels / Lifecycle / Audit / Insider Risk / Roles), or "this solution" for the audit-log re-enable. |
| **Recommended action** | The next step (pilot in simulation/test; onboard devices; remove stale member; **determination required** for records/legal). |

- **Determination items.** Any finding touching a **retention schedule, records file plan, legal hold,
  regulatory obligation, or insider-risk/communication-compliance policy** is marked **"determination
  required"** and routed to compliance/records/privacy/legal (R8) — the register records the technical
  state, not the determination.
- **Licensing items.** A capability that is **absent because unlicensed** is a **licensing decision**,
  not a drift Gap — tag it accordingly and **verify against your licensing/tenant.**

## Phase 2 — Produce the scorecard (leadership rollup)

Run **`OPSHEALTH-Report.ps1`** (read-only) to roll the scored checks into the **health scorecard**:
per-domain **Healthy / At Risk / Gap** counts, the overall **health rating**, and a CSV of the
Remediation Register for circulation. This is the artifact leadership signs off on and the baseline you
compare future runs against.

- **Pass/fail:** the scorecard reconciles with what the portal shows (the portal is authoritative); the
  register has an owner and severity on every row.

## Phase 3 — Remediate (plan first; commit only the one safe fix)

1. **Generate the remediation plan.** Run **`OPSHEALTH-Remediate.ps1 -WhatIf`** (the default). It prints
   the prioritized plan — each register item, its severity, its owning capability, and the recommended
   action — and changes **nothing**.
2. **Commit the one safe, reversible fix (optional).** If the unified audit log is **off** and R7
   change control is signed off, run **`OPSHEALTH-Remediate.ps1 -EnableUnifiedAuditLog -Commit`**. This
   is the **only** direct write in the solution (`Set-AdminAuditLogConfig
   -UnifiedAuditLogIngestionEnabled $true` via Exchange Online) — safe, documented, and reversible.
   - **Pass/fail:** the unified audit log reads **enabled** after propagation. **Rollback:** re-run with
     the disable path (or set it back in Exchange Online); audit ingestion can take time to reflect —
     **verify in your tenant.**
3. **Route every other remediation to its owning capability solution.** DLP, sensitivity labels,
   retention/records, and insider-risk changes are **high-impact** — they are **not** flipped on from
   this health check. Each is handed to its owning solution and **piloted in simulation/test/report-only**
   first, validated, then enforced under that solution's discipline. The register's **Owning capability**
   field says where each one goes.
4. **Determination items go to governance, not to IT.** Records/legal/regulatory items wait on the
   relevant function's determination (R8) before any configuration.

> **Hard rule.** Do **not** use this solution to enable/enforce DLP, publish or change labels, create
> or change retention/records policies, or configure insider risk. Those belong to the owning capability
> solutions, piloted first. This solution **finds, prioritizes, and (only) re-enables the audit log.**

## Phase 4 — Validate (re-score, read-only)

Work the gates in `05-testing.md`. In summary:

- Re-run **`OPSHEALTH-Validate.ps1`** (read-only) and confirm each remediated item now reads **Healthy**
  against its criterion.
- Confirm the **unified audit log** is on (if remediated), that no intended DLP/retention/label policy
  is missing or disabled, that coverage matches the in-scope map, and that the role review is clean.
- Re-run **`OPSHEALTH-Report.ps1`** and confirm the overall **health rating** improved and the register's
  closed items are gone.

## Phase 5 — Expand (make it recurring)

1. **Set a cadence.** Re-run the read-only health check on a schedule (e.g. quarterly, and before any
   audit) so drift is caught early — the scripts are re-runnable and produce a comparable scorecard.
2. **Track the trend.** Keep each run's scorecard; a falling count of At Risk/Gap items over time is the
   evidence that the estate is staying healthy.
3. **Keep determinations with governance.** As the estate matures, records/retention/legal items keep
   flowing to their owners; the health check keeps surfacing the **technical** state, not the decision.

---

### Rollback summary

| Change | Rollback |
| --- | --- |
| Unified audit log re-enabled and you must revert | Disable ingestion again in Exchange Online (`Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $false`); propagation is not instant — verify in tenant. |
| A downstream remediation (DLP/label/retention/IRM) caused disruption | It was piloted in **simulation/test/report-only** by its owning solution — revert per that solution's rollback (set mode back to test/disable), not here. |
| Register mis-scored a licensing gap as a drift Gap | Re-tag as a **licensing decision**; re-run `OPSHEALTH-Report.ps1` to correct the scorecard. |
| A determination item was actioned before governance signed off | Halt; route to records/legal/compliance; the health check only surfaces technical state (R8). |

> **The health check changes almost nothing by design.** Its value is the **evidence and the ordered
> register** — the fixes happen, safely and piloted, in the capability solutions that own them.
