# 3. Implementation Guide — Microsoft Purview Architecture & Design

Follow these steps **in order**. Design work is done in the **Microsoft Purview portal**
(`https://purview.microsoft.com`), the **Microsoft 365 admin center**, and, where automated, via
**Security & Compliance PowerShell** (`Connect-IPPSSession`, for role groups, policies, and adaptive
scopes) and **Microsoft Graph** (for licensing/SKU, administrative units, and workload signals).
Artifact names follow the `<Purpose> – <Scope> – <Stage>` convention from the Overview and are reused
verbatim. **Portal paths, capability availability, role-group names, and cmdlets are plan-dependent and
the portal evolves — verify against your tenant.**

> **Model:** Baseline the tenant, map capabilities to licensing/phases, design the RBAC model + scoping
> strategy + naming standard, stand up the foundation guardrails, validate the design, then execute the
> roadmap phase by phase. Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate →
> Expand.** **This solution designs the architecture and the foundation guardrails; each capability's
> policies are built later, against this design, and piloted in simulation/test first.** Regulatory,
> records, and legal **determinations** are deferred to compliance/records/privacy/legal throughout.

---

## Step 1 — Baseline the tenant (Assess)
1. Confirm licensing (Requirement 2.1): Microsoft 365 admin center → `Billing → Licenses` for the
   E3 / E5 / E5 Compliance / add-on SKUs. **Verify entitlement with Microsoft licensing — do not assume.**
2. Run `PURVARCH-Discovery.ps1` (read-only). It reports: the subscribed SKUs it can read and an
   **indicative** capability-availability mapping; the current **role groups** and their membership; the
   existing **labels, DLP, and retention policies** and any **adaptive scopes**; and the **audit** state.
   Save this as the `PA Design Baseline – Tenant – Assess` snapshot.
3. **Pass/fail gate:** the baseline is captured — licensing, roles, existing policies/scopes, audit
   state — and the governance owners (Requirement 2.6) are engaged. **Do not proceed** to design until
   the baseline is agreed. Fail → complete the inventory first.

## Step 2 — Map the capabilities to licensing and phases (Assess → Design)
1. With the governance owners, decide which Purview capabilities are **in scope** (from the phase model:
   Foundation → Know → Protect → Prevent loss → Govern → Advanced), and for each confirm it is
   **licensable** on your plan (Requirement 2.1).
2. Assign each capability a **phase**, an **owner**, and a **status** (in scope / **deferred — not
   licensed** / out of scope). Use `PURVARCH-Report.ps1` to emit the `PA Capability Map – Tenant –
   Design` scaffold from the discovery data; complete it with the owners' decisions.
3. Sequence the phases into the `PA Phase Roadmap – Program – Design`, recording each phase's entry/exit
   gate and its dependency on the phase before it.
4. **Pass/fail gate:** every in-scope capability is licensable and assigned a phase and owner;
   unlicensed capabilities are recorded as **deferred**, not designed around. **Applicability is the
   owners' determination**, not a technical default. Fail → resolve licensing/scope before designing RBAC.

## Step 3 — Design the RBAC model with separation of duties (Design)
1. From the baseline (Step 1) and the agreed separation intent (Requirement 2.2), design the
   least-privilege **role groups per capability domain** — Information Protection, Data Lifecycle &
   Records, Insider Risk Management, Communication Compliance, eDiscovery, and Audit — mapping each to
   **administer / analyze-investigate / read-only** duties. Reserve Global Administrator and Compliance
   Administrator.
2. Record the design as `PA RBAC Model – Tenant – Design`, and run `PURVARCH-Validation.ps1` to produce
   the `PA RBAC SoD – Conflicts` register — e.g. a person administering **both** insider risk and
   eDiscovery, or a reader who also holds a broad admin role.
3. **Pass/fail gate:** each capability domain has named least-privilege role groups; separation of
   duties holds (information protection ≠ insider risk ≠ eDiscovery ≠ records); conflicts are recorded
   and accepted or resolved. **Verify the exact role-group names in your tenant.** Fail → resolve
   conflicts before applying.

## Step 4 — Design the scoping strategy (Design)
1. Decide, per capability, **adaptive** vs **static** scope (Requirement 2.4): adaptive scopes are
   query-based (user attributes, site properties, or group membership) and re-evaluate automatically;
   static scopes are explicit. Decide whether **administrative units** delegate scoped administration.
2. Confirm the in-scope **workloads/data sources** and define the **pilot ring** — a named population to
   validate every capability on first. Record all of this as `PA Scoping Plan – Tenant – Design`.
3. **Pass/fail gate:** each capability has a chosen scope type, the in-scope workloads are agreed, and a
   named pilot ring exists. Adaptive-scope availability is licensing-gated — **verify in your tenant**.
   Fail → complete the scoping plan before standing up guardrails.

## Step 5 — Set the naming standard (Design)
1. Adopt the `<Purpose> – <Scope> – <Stage>` convention (Requirement 2.5) — `Sim` for simulation/test,
   `Prod` for enforced — as the `PA Naming Standard – Tenant – Design`, and agree it with every
   capability owner.
2. Run `PURVARCH-Validation.ps1` to list existing objects that do **not** conform, so drift is visible
   and can be planned into remediation (renaming is done in the portal per object).
3. **Pass/fail gate:** the standard is documented and agreed; nonconforming existing objects are
   identified. Fail → finalize the standard before creating any new object.

## Step 6 — Stand up the foundation guardrails (Configure — guardrails)
1. **Apply the RBAC model.** Portal → `Settings → Roles & scopes → Permissions` (verify path): populate
   the designed role groups with least-privilege, separated membership. Or manage membership with
   `PURVARCH-Configuration.ps1` — it composes `Add-RoleGroupMember` / `Remove-RoleGroupMember`, **runs
   with `-WhatIf` by default** and prints exactly what it would change; add `-Commit` to apply.
2. **Scaffold the pilot ring and (where used) an adaptive scope.** Use `PURVARCH-Set-Scope.ps1` to
   preview and (with `-Commit`) create/populate the pilot group `SG-PA-Pilot`, and — where adaptive
   scopes are in the design — scaffold the example `AS-PA-Pilot` (`New-AdaptiveScope`, where available in
   your tenant). **`-WhatIf` by default.**
3. **This is the only thing this solution configures.** No capability policy (DLP, label, retention,
   insider risk) is created here — those are built in their own solutions, **against this design**, and
   **piloted in simulation/test first**. The naming standard and pilot ring are what make that pilot
   discipline enforceable.
4. **Pass/fail gate:** role groups hold the least-privilege, separated membership; the pilot ring (and
   any adaptive scope) exists; re-run `PURVARCH-Discovery.ps1` and confirm. **Rollback:** remove any
   over-granted membership with `PURVARCH-Configuration.ps1 -Commit`; remove the pilot group/scope in the
   portal — no capability policy references it yet, so removal is safe.

## Step 7 — Validate the design and report the posture (Validate)
1. Run the Testing Guide (`05-testing.md`). Confirm: every in-scope capability is licensable; the RBAC
   model is applied with separation holding and no unaccepted conflicts; the pilot ring/adaptive scope
   exists; the naming standard is documented and drift is identified.
2. Run `PURVARCH-Validation.ps1` (read-only) for the conformance checks and `PURVARCH-Report.ps1` for
   the `PA Design Posture – Report` (capability coverage vs licensing, RBAC separation, scope coverage,
   naming conformance, phase status).
3. **Pass/fail gate:** the design is conformant and the posture report is accurate. Fail → correct the
   guardrails and re-validate before executing the roadmap.

## Step 8 — Execute the roadmap phase by phase (Expand)
1. Begin **Phase 0/1** and proceed in sequence. For each capability, its **own solution** builds the
   policy **against this architecture** — using the designed role groups, the scoping plan, the pilot
   ring, and the naming standard — and **pilots it in simulation/test first**, passes that capability's
   gates, then expands. This solution's design is the **contract** every phase builds to.
2. At each phase boundary, re-run `PURVARCH-Validation.ps1` / `PURVARCH-Report.ps1` to confirm the new
   objects conform to the RBAC model, scoping plan, and naming standard, and to update the phase status
   on the roadmap.
3. Maintain the architecture as a living document: review the RBAC model on joiners/leavers, re-check
   licensing when plans change, watch for **portal/RBAC evolution** Microsoft ships, and re-baseline
   periodically.
4. **Pass/fail gate:** each completed phase's objects conform to the design; separation of duties still
   holds; the roadmap status is current. **Rollback:** a phase's capability policies are governed by
   their own solution's rollback; the architecture itself can be narrowed (scope, phase) at any time
   without deleting completed, conformant work.

---

### What this guide does NOT do
- **Build the capability policies.** DLP policies, label taxonomies, retention schedules, insider-risk
  policies, etc. are built in **their own solutions**, against this design, and **piloted in
  simulation/test first**. This guide designs the architecture and stands up the foundation guardrails.
- **Make the determinations.** Regulatory applicability, retention schedules, records file plans, and
  the lawful basis for insider-risk/communication monitoring are **compliance/records/privacy/legal**
  determinations. The architecture carries them; it does not decide them.
