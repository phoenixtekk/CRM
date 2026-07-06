# Requirements

These are the prerequisites for **defining and owning** the target architecture — not for executing any
single workstream. The category-wide prerequisites in `global-requirements-google.md` (Google tenant,
source M365/Entra access, DNS control, identity source of truth, pilot scope, governance stakeholders)
apply in full and are assumed here. This section adds the requirements specific to running the
architecture-authority function. Each follows **Description / Why / Verify / Implement if missing**.

## 1. Named target and source tenants, with edition clarity

- **Description:** A provisioned **Google Workspace** tenant (target) at the edition the end state
  requires — Enterprise Plus (or the current top-tier equivalent) for Vault, context-aware access,
  and enterprise DLP; the **Gemini/AI add-on** where AI enablement is in scope — and administrative
  read access to the **source Microsoft 365 / Entra ID** estate.
- **Why:** The architecture must be designed against the *actual* license entitlements and tenant
  configuration on both sides, not against assumptions. Edition determines which governance and AI
  controls are even available to design around.
- **Verify:** In **admin.google.com → Billing/Subscriptions**, confirm edition and seat counts;
  confirm the Gemini/AI subscription state (note: some Gemini Enterprise capabilities are
  preview/rolling-out — **verify in your tenant**). On the source side, confirm read access to the
  M365 admin center and Entra admin center.
- **Implement if missing:** Provision/true-up licenses via Google or a reseller; obtain least-privilege
  read roles on the source (Global Reader on Entra is sufficient for discovery).

## 2. A single, agreed identity source of truth

- **Description:** One authoritative directory (on-prem AD, Entra ID, or an HR/IGA system) formally
  designated as the source of truth for the target estate, and the intended provisioning path into
  Google (Entra provisioning/SCIM, Google Cloud Directory Sync, or Admin SDK).
- **Why:** Principle **GWARCH-P2 / GWARCH-ID-1** makes identity the spine of the architecture. The
  entire design is undefined until "who is authoritative, and how do objects flow into Google" is
  settled. Competing sources of truth are the single biggest cause of enterprise-migration rework.
- **Verify:** A written statement naming the authoritative directory and the provisioning mechanism,
  signed off by the identity owner. Confirm no workstream plans to provision users independently.
- **Implement if missing:** Convene the identity owner and decide the source of truth **before** any
  domain design proceeds. Record the decision as ADR **GWARCH-ADR-ID-01**.

## 3. OU and group taxonomy (the GWARCH-Scope model)

- **Description:** A defined organizational-unit and group taxonomy in Google that all policy targets
  (collaboration settings, sharing, DLP, retention, Gemini access) will bind to — including at least
  a **pilot** scope, per-wave scopes, and any regulated/high-sensitivity scope.
- **Why:** Principle **GWARCH-P3** requires governing by scope, not by exception. A stable, named
  taxonomy is what makes policy consistent and auditable across all five domains, and lets
  `GWARCH-Set-ScopeTargeting.ps1` map source groups to target scopes deterministically.
- **Verify:** The OU tree and control groups exist (or are designed) with documented naming; a pilot
  OU/group is named.
- **Implement if missing:** Design the taxonomy before configuring any policy; align source-side
  groups so scope maps cleanly. Record as ADR **GWARCH-ADR-SCOPE-01**.

## 4. Governance, security, legal & compliance stakeholders engaged

- **Description:** Named owners for **security (CISO/DLP), legal & eDiscovery (Vault/holds), data
  governance (retention/classification), and any regulatory regime** in scope, engaged as
  architecture stakeholders — not merely consulted at the end.
- **Why:** Principle **GWARCH-P6** makes governance a precondition for AI enablement and a first-class
  domain. Retention, hold, DLP, and classification requirements are *inputs* to the architecture; the
  design cannot be finalized without their sign-off.
- **Verify:** A stakeholder RACI naming each owner and the policies (retention schedules, DLP rules,
  hold obligations, regulatory controls) the architecture must satisfy.
- **Implement if missing:** Identify owners and collect their policy requirements before the data
  governance/retention and AI domains are designed.

## 5. An Architecture Review Board (ARB) and decision-record process

- **Description:** A standing **Architecture Review Board** with a defined cadence and a lightweight
  **ADR** process for recording decisions, exceptions, and supersessions against the blueprint.
- **Why:** The blueprint is only authoritative if there is a body that enforces conformance and a
  record that captures why deviations were allowed. Without the ARB, "owning the architecture" has no
  teeth (principle **GWARCH-P1**).
- **Verify:** ARB charter, membership, cadence, and an ADR log location exist.
- **Implement if missing:** Charter the ARB and stand up the ADR log (the templates in
  `08-deliverables-summary.md` seed both) before Pilot.

## 6. Bounded coexistence design inputs (DNS, mail flow, directory bridge)

- **Description:** Control over DNS for routed domains and a documented intended **coexistence** model
  for the transition period — mail routing/dual-delivery, directory bridging, and legacy holds — each
  with a **sunset condition**.
- **Why:** Principle **GWARCH-P5** requires coexistence to be bounded and temporary. These bridges are
  high-impact (mail flow, identity) and must be designed, change-controlled, and given an explicit end
  date, not left to accrete.
- **Verify:** Access to the authoritative DNS zones is confirmed; a coexistence design with sunset
  criteria per bridge is drafted.
- **Implement if missing:** Confirm DNS control and draft the coexistence model with sunset conditions
  under change control before cutover waves begin.

## 7. Current-state discovery tooling and access

- **Description:** A workstation able to run the **Microsoft Graph PowerShell SDK** against the source
  M365/Entra tenant (read scopes), plus super-admin/read access to admin.google.com for target-side
  confirmation.
- **Why:** The Assess phase depends on repeatable, read-only current-state discovery
  (`GWARCH-Discovery.ps1`) to ground the architecture in reality rather than assumption
  (principle **GWARCH-P8**).
- **Verify:** `Connect-MgGraph` succeeds with the read scopes listed in each script header; the
  scripts run and emit their reports.
- **Implement if missing:** Install the Graph SDK (`Install-Module Microsoft.Graph`), consent the
  read scopes, and confirm target-side console access.

---

*Deployment/decision model reminder:* every requirement above is validated in **Assess**; the
architecture is authored in **Configure**; the requirements' sufficiency is proven in **Pilot** and
**Validate** before **Expand**.
