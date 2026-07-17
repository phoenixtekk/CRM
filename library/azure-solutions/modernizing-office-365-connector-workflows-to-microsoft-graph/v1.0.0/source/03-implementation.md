# 3. Implementation Guide — Modernizing Office 365 Connector Workflows to Microsoft Graph

This is the **program runbook**. Follow the phases **in order**. The program follows the standard model — **Inventory → Classify → Configure (pilot targets) → Pilot → Validate (pilot gate) → Expand (waves) → Govern** — mapping to **Assess → Configure → Pilot → Validate → Expand**. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, test, and rollback.

> **Sibling boundary (read first):** the **program-level** work — inventory, classification, wave sequencing, parity, rollback, governance — is given here as exact steps. The **per-flow engineering** (how to build one managed-identity Graph workflow) is **not reproduced**; each flow's cutover step says *"apply the pattern from the relevant sibling product"* and *"scope the permission per sibling #4."* See `01-solution-overview.md` for the sibling map.

> **Verify-against-Microsoft (read first):** connector managed-identity support, exact Graph permission names, change-notification lifetimes, the Application-Access-Policy-vs-Graph-RBAC choice, Logic Apps Standard-vs-Consumption differences, the Power Platform enumeration method, and national-cloud endpoints are **confirmed against current Microsoft documentation at migration time** — this runbook states the target and flags the specifics.

## Naming (set once, reuse verbatim)

- Inventory register (CSV): `Connector-Flow-Inventory – Estate – Program.csv` — the **Connector Flow Inventory – Estate – Program**.
- Classified migration register (CSV): `Migration-Register – Estate – Program.csv` — the **Migration Register – Estate – Program**.
- Pilot cohort (Entra security group for pilot owners/testers, and the tag in the register): `PILOT – Connector Migration – Pilot`.
- Wave cohorts (Entra security group + register tag): `Wave NN – Connector Migration – Wave NN` (`Wave 01`, `Wave 02`, …).
- Per migrated Logic App's managed identity: `<FlowName> – Graph MI – Target` (one per migrated Logic App; reuse the exact Logic App name).
- The scoped mailbox-access construct for a migrated flow: named and built **per sibling #4** (Application Access Policy or Graph RBAC scope), tagged in the register against the flow.

---

## Phase 1 — Inventory the connector estate and its authentication

**Goal:** one authoritative register of every connector-based flow and **how each authenticates**.

1. **Logic Apps side (Azure):** run the read-only `scripts\O365GRAPH-Discovery.ps1`. It enumerates Logic Apps across the in-scope subscriptions, flags those whose workflow definition uses an **Office 365 connector** (Office 365 Outlook / Office 365 Users / Excel Online), and records **how each authenticates** — the API connection's identity (interactive user, shared service account, or stored secret) vs. an existing managed identity.
2. **Power Automate side (Power Platform):** enumerate flows and their **connection references** across the in-scope environments using your Power Platform admin method, and record the same fields (which connector, authenticated as whom). **The exact enumeration method is a `verify against current Microsoft documentation` item** — the discovery script flags where the Power Platform data must be supplied.
3. **Merge** both sides into `Connector-Flow-Inventory – Estate – Program.csv`, one row per flow, with at minimum: flow name, platform (Logic App / Power Automate), connector(s) used, auth model (user / service account / secret), owner, and the mailbox(es) or resources it touches.
4. **Reconcile** service accounts: flag every flow that shares a service-account credential — one compromised account behind many flows is a top-risk finding.

**Exit gate:** a signed-off `Connector-Flow-Inventory – Estate – Program.csv` covering 100% of in-scope Logic Apps and Power Automate flows, with an auth model recorded for each.

---

## Phase 2 — Classify by risk and Graph-migratability

**Goal:** turn the inventory into a risk-ranked, migration-sequenced plan.

1. Run `scripts\O365GRAPH-Classify.ps1 -InputCsv "Connector-Flow-Inventory – Estate – Program.csv" -OutputCsv "Migration-Register – Estate – Program.csv"`. It scores each flow on two axes:
   - **Risk** — standing credentials (service account > interactive user > already-managed-identity), over-scope (touches many mailboxes / broad access), and shared-service-account blast radius.
   - **Graph-migratability** — how cleanly the flow maps to a managed-identity Graph pattern: **Clean** (a Logic App whose action has a direct Graph equivalent and can take a managed identity), **Redesign** (behaviour maps to Graph but the flow needs restructuring), or **Re-platform** (a Power Automate flow that cannot take an Azure managed identity — see the note below).
2. **Assign each flow its sibling pattern** in the register — the migration target pattern:
   - send/read/move mail or general mailbox automation → **#1**;
   - "when a new email arrives" / event-driven → **#2**;
   - scheduled/recurring polling → **#3**;
   - the managed-identity + app-permission foundation underneath → **#5**;
   - and every mail-touching flow is tagged **"scope per #4."**
3. **Power Automate honesty:** flows that **cannot consume an Azure managed identity** are tagged **Re-platform** — their modern target is a re-platform into a Logic App, or a least-privilege service-principal/connection, not a drop-in managed-identity swap. **Whether a given Power Automate flow or Office 365 connector trigger can take a managed identity is a `verify against current Microsoft documentation` item** — confirm before committing the target.
4. **Sequence:** sort the register — highest risk + Clean migratability first (fast, high-value wins), Redesign/Re-platform into later waves. Tag the pilot cohort `PILOT – Connector Migration – Pilot` from the top of the list, spanning the sibling patterns.

**Exit gate:** an approved `Migration-Register – Estate – Program.csv` with a risk score, a migratability class, an assigned sibling pattern, and a wave tag per flow.

---

## Phase 3 — Configure the pilot cohort's managed-identity Graph targets

**Goal:** build the modern target for each pilot flow, using the sibling patterns, before any cutover. **Prerequisites 2.1–2.6 must be satisfied.**

For **each** flow in `PILOT – Connector Migration – Pilot`:

1. **Capture the parity baseline** (requirement 2.7): record the legacy flow's trigger, schedule, inputs, and outputs from `O365GRAPH-Discovery.ps1`, so parity can be judged later.
2. **Build the managed-identity Graph target by applying the assigned sibling pattern** — do **not** re-derive it here:
   - Stand up the managed-identity + application-permission foundation per **sibling #5**, naming the Logic App's identity `<FlowName> – Graph MI – Target`.
   - Build the flow's Graph logic per **sibling #1 / #2 / #3** (send/read, change-notification, or polling) as the flow's type dictates.
3. **Scope the mailbox permission per sibling #4** — constrain the flow's Graph mail **application** permission to only the mailbox(es) the flow touches (Application Access Policy or Graph RBAC-for-Exchange). **Which mechanism is a `verify against current Microsoft documentation` item.** Never grant tenant-wide mailbox access where a scoped grant suffices.
4. **Assign the application permission to the managed identity** with `scripts\O365GRAPH-Set-AppRole.ps1` (defaults to `-WhatIf` — review the plan, then re-run with `-Apply` once approved). **The exact permission name is a `verify against current Microsoft documentation` item** — supply the current least-privilege permission.
5. **Leave the legacy flow enabled** — the migrated target is built alongside it; cutover happens in the pilot phase.

**Exit gate:** each pilot flow has a built managed-identity Graph target, a scoped permission (per #4), and a captured parity baseline — legacy flows still running.

---

## Phase 4 — Pilot the migration

**Goal:** cut over the pilot cohort and prove the method.

For each flow in `PILOT – Connector Migration – Pilot`, run the **per-flow playbook**:

1. **Enable** the migrated managed-identity Graph target.
2. **Cut over:** disable the legacy connector flow (do **not** delete it) so only the migrated flow runs. For an event/trigger flow, follow **sibling #2** for the change-notification handover; for a polling flow, **sibling #3**.
3. **Validate parity immediately** with `05-testing.md` Test 2 and `scripts\O365GRAPH-Validate.ps1` for that flow — the migrated flow must produce the same behaviour as the captured baseline.
4. **Rollback if parity breaks:** re-enable the legacy flow, disable the migrated one (requirement 2.7). Fix, then retry. The legacy flow is only retired after the migrated flow passes and a grace period elapses.

Capture real timings and any redesign surprises to refine the wave plan. **No production wave starts until Phase 5 passes.**

---

## Phase 5 — Validate the pilot (the gate)

**Goal:** the program's go/no-go.

1. Run `scripts\O365GRAPH-Validate.ps1` across the pilot cohort — every migrated flow must be **PASS**: it uses a managed identity + Graph, has **no stored-credential connection**, and its scoped permission is present.
2. Run `scripts\O365GRAPH-Report.ps1` — confirm the pilot flows show as migrated with no residual connector/credential.
3. Complete the manual parity gates in `05-testing.md`. **The pilot gate passes only when every pilot flow passes parity and shows no residual credential.** Record results as `Validation Results – Program – Pilot`.

**Do not expand until this gate is green.**

---

## Phase 6 — Expand in waves

**Goal:** migrate the rest of the estate, wave by wave, with per-flow rollback.

For each wave `Wave NN – Connector Migration – Wave NN` (in the sequence set in Phase 2):

1. **Configure** each wave flow's managed-identity Graph target exactly as Phase 3 (apply the assigned sibling pattern; scope per #4; assign the permission with `O365GRAPH-Set-AppRole.ps1`).
2. **Cut over** each flow exactly as Phase 4's per-flow playbook (enable migrated, disable legacy, validate parity, rollback per flow if it breaks).
3. **Validate the wave** with `O365GRAPH-Validate.ps1` and the `05-testing.md` gates — every flow PASS, no residual credential.
4. **Track progress** with `O365GRAPH-Report.ps1` (total connector flows, migrated, remaining, risk buckets).
5. **Retire legacy flows** only after their migrated replacements pass and the grace period elapses — disable first, delete last, under change control.

**Exit gate per wave:** every flow in the wave validated and parity-confirmed; report shows the wave migrated with no residual connector/credential.

---

## Phase 7 — Govern the end state (prevent regression)

**Goal:** keep the estate credential-free after migration.

1. **Baseline the end state:** run `O365GRAPH-Report.ps1` at fleet completion — the target is **zero** connector-based flows with stored credentials remaining (or an approved, tracked exception list).
2. **Scheduled governance scan:** run `O365GRAPH-Discovery.ps1` + `O365GRAPH-Validate.ps1` on a recurring cadence to catch any **new** connector-based flow or any migrated flow that **reverted** to a stored-credential connection.
3. **Standard for new automation:** adopt the rule that new mailbox/M365 automation is built managed-identity-Graph-first (per the sibling patterns), scoped per #4 — so the estate does not re-accumulate the risk this program retired.
4. **Report the trend** each cycle: a falling count of connector/credential flows is the evidence the program worked and the governance is holding.

---
### Order of operations
`Inventory (Logic Apps + Power Automate) → classify (risk + migratability + sibling pattern) → configure pilot targets (apply #1/#2/#3/#5, scope per #4) → pilot cutover + parity → pilot gate → expand in waves (per-flow rollback) → govern (prevent regression)`
