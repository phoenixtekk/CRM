# 3. Implementation Guide — eDiscovery Readiness Assessment (Microsoft Purview)

Follow the model **Assess → Design → Configure → Pilot (readiness proof in test) → Validate →
Expand.** The assessment scores four domains — **Roles (R)**, **Holds/preservation (H)**,
**Scope/coverage (S)**, **Process (P)** — each **Not Ready → Partial → Ready**, records every gap in a
**gap register**, remediates **dry-run first**, and then **proves** the capability non-destructively on
a **dedicated test account**. Every proof artifact uses the Section 1 naming and the same names flow
through Testing, Troubleshooting, and the scripts.

Portal: `https://purview.microsoft.com` → **eDiscovery** / **Audit** / **Settings → Roles & scopes**
(Government clouds use a different host, e.g. `*.office365.us` — **verify in your tenant**).
PowerShell: `Connect-IPPSSession` (Security & Compliance) for compliance objects; `Connect-ExchangeOnline`
for mailbox/inactive coverage; `Microsoft.Graph.Security` for optional Premium signals.

> **Legal owns the determination** of scope, custodians, holds, and production. Everything below is
> the technical assessment method and a **test-account rehearsal** — not a real matter, not a real
> preservation. Do not place a hold on a real custodian as part of this assessment.

---

## Stage A — Assess (read-only, nothing changes)
1. **Inventory current state.** Run **`EDREADY-Discovery.ps1`** (read-only). It reports: eDiscovery
   **role-group membership** (Manager/Administrator) and whether Global Admin appears in either;
   existing **cases**, **Content Searches**, and **case-hold policies/rules**; **unified audit log**
   status; and case-type signals for the **tier** (Standard vs Premium). This feeds domains **R** and
   **H**.
2. **Map data-source coverage.** Run **`EDREADY-Scope.ps1`** (read-only). It reports mailbox count and
   **litigation-hold** state, **inactive/legacy mailboxes**, and any existing retention holds, and
   lists the workloads to confirm (Exchange incl. **Teams chat in mailboxes**, SharePoint, OneDrive,
   Teams/M365 Group sites). This feeds domain **S**.
3. **Interview for process.** With the named legal/records owner (Requirement 2.5), confirm whether a
   **matter-intake** step, **naming standard**, **change control/rollback**, and **evidence-pack**
   routine exist. This feeds domain **P**.

**Gate A (pass/fail):** discovery + scope reports captured and the process interview complete — you
have the raw current state for all four domains. Fail → resolve access/module gaps (Requirements
2.2, 2.6) and re-run.

---

## Stage B — Design (the scorecard + gap register)
4. **Score each domain against the rubric.** Using the Stage-A evidence, score **R/H/S/P** as **Not
   Ready / Partial / Ready** with the named criteria:
   - **R — Roles:** operators in **eDiscovery Manager**; a small **eDiscovery Administrator** lead
     group; **no standing Global Admin** for matters; **coverage ≥ 2** trained operators.
   - **H — Holds/preservation:** **audit log on**; a hold can be **proven** to preserve (Stage D);
     **inactive mailboxes** and **litigation-hold**/retention interplay understood and covered.
   - **S — Scope/coverage:** all in-scope workloads discoverable, **Teams messages and M365 Group
     sites** included, **unindexed/imported** data accounted for.
   - **P — Process:** **matter-intake + legal sign-off**, **naming standard**, **change
     control/rollback**, **evidence-pack** ownership all present.
5. **Record every gap.** For each below-Ready criterion, add a **gap-register** row: domain, finding,
   severity (High/Med/Low), owner, and remediation action. Audit-off and Global-Admin-for-matters are
   **High** by default.
6. **Design the target state and order.** Sequence remediation: enable audit and fix roles first
   (they gate everything and the proof), then scope/process. `EDREADY-Reporting.ps1` renders the
   scorecard + gap register.

**Gate B:** a completed scorecard and a prioritized gap register with owners. Fail → gather missing
evidence and re-score.

---

## Stage C — Configure / Remediate (simulation/-WhatIf first)
7. **Remediate the gaps — dry-run by default.** Run **`EDREADY-Remediation.ps1`** with **`-WhatIf`**
   (the default) to preview every change; re-run with **`-Commit`** only after sign-off (Requirement
   2.8). It can:
   - **Enable the unified audit log** (`Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled
     $true`) — closing the highest-severity H gap.
   - **Add named operators** to **eDiscovery Manager** / the **eDiscovery Administrator** lead group
     (`Add-RoleGroupMember`) — closing R gaps and building coverage.
   - **Stand up the readiness-proof case + hold** shell (see Stage D) named to the Section 1 pattern.
   It **never removes** holds or role members silently, and it prints every action it would take.
8. **Adopt the process artifacts.** Put the **matter-intake template**, **naming standard**, and
   **change-control/rollback** and **evidence-pack** routine in place (documentation deliverables) —
   closing P gaps. These need no tenant change, only adoption.

**Gate C:** audit log **on**; role groups least-privilege with coverage; process artifacts adopted.
Fail → complete remediation (re-run `-WhatIf`, then `-Commit`).

---

## Stage D — Pilot: the readiness proof (non-destructive, test account only)
Prove the capability end to end on the **dedicated test account** (Requirement 2.7), never a real
custodian. This is the "pilot in test" gate — a rehearsal that is removed at the end.
9. **Create the proof case.** `New-ComplianceCase -Name "eDiscovery Readiness – Proof – Pilot"
   -CaseType eDiscovery` (portal: **eDiscovery → Cases → Create a case**). `EDREADY-Remediation.ps1
   -Commit` can create it.
10. **Place the proof hold on the test account.** Create `Readiness Hold Policy – Proof – Pilot`
    (`New-CaseHoldPolicy` over the **test mailbox only**) and `Readiness Hold Rule – Proof – Pilot`
    (`New-CaseHoldRule`). `EDREADY-Remediation.ps1` builds these dry-run first; `-Commit` applies.
    Portal: case → **Holds → Create**.
11. **Run the proof search.** Create and start `Readiness Search – Proof – Pilot`
    (`New-ComplianceSearch`/`Start-ComplianceSearch`) scoped to the test mailbox with a simple query
    matching the seeded content. Portal: case → **Searches → New search**.
12. **Confirm preservation.** As the test account, delete a seeded held item and confirm it remains
    recoverable/preserved (recoverable items / preservation hold). This is the proof that a hold
    **actually preserves** in your tenant.
13. **Remove the proof hold (clean up).** Delete `Readiness Hold Rule – Proof – Pilot` then
    `Readiness Hold Policy – Proof – Pilot` (`Remove-CaseHoldRule` / `Remove-CaseHoldPolicy`), leaving
    the tenant as it was. The **capability is proven; nothing is left preserving.**

**Gate D (the core readiness gate):** proof case created; hold placed and **proven** to preserve on
the test account; scoped search returned the seeded items; proof hold **removed**. Fail any → the
capability is not demonstrably ready — fix and re-run before claiming readiness.

---

## Stage E — Validate
14. Run the **testing procedures in `05-testing.md`** and **`EDREADY-Validation.ps1`** — every rubric
    gate (R/H/S/P) must return **pass**, and the audit log must show the proof activity.
    `EDREADY-Reporting.ps1` produces the final evidence pack (scorecard, gap register closed-state,
    proof audit records).

**Gate E:** all validation gates pass; audit shows the proof case/hold/search. Fail → remediate and
re-validate.

---

## Stage F — Expand (operate for real)
15. **You are ready to run live matters.** With gaps closed and the proof passing, operate real
    matters using the **eDiscovery Administration** solution — legal owning every determination.
    Re-run this assessment **periodically** (e.g. quarterly, and after a tenant/licensing change) so
    readiness does not drift.

---

## Rollback (documented before you commit anything)
- **Proof hold:** delete `Readiness Hold Rule – Proof – Pilot` then `Readiness Hold Policy – Proof –
  Pilot` (`Remove-CaseHoldRule` / `Remove-CaseHoldPolicy`) — it only ever covered the **test
  account**, so removal releases nothing real. This is a normal step of Stage D.
- **Proof case/search:** searches are non-destructive; `Remove-ComplianceSearch` and
  `Remove-ComplianceCase` remove the rehearsal artifacts.
- **Role change:** `Remove-RoleGroupMember` to revert an added operator.
- **Audit log:** enabling auditing is not reverted (it is a readiness improvement); if you must,
  `Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $false` — **not recommended.**
