# Google Workspace + Gemini Enterprise Target Architecture Blueprint (Enterprise/150k+)

> **Version 1.0.0** · Category: Google · Solution code: GWARCH

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary

## The problem

In a 150,000-user shift from Microsoft 365 to Google Workspace and Gemini Enterprise, whoever owns the
**target architecture** owns the outcome. When no one owns the end state, each partner and each
migration wave invents its own design: identity fragments across shadow directories, sharing and DLP
drift, coexistence bridges never sunset, and AI enablement outruns governance. The result is
architectural rework wave after wave — the most expensive failure mode in an enterprise transformation.

## The approach

This blueprint defines and keeps authoritative the **end-state Google Workspace + Gemini + identity
architecture** — and the principles that govern every workstream. It is an architecture-authority
product: **principles, reference patterns, architecture decision records (ADRs), and non-functional
requirements**, not a click-by-click runbook.

The architecture is organized into five domains, designed in dependency order:

1. **Identity integration** — one authoritative source, one provisioning path, federated SSO
   (the spine every other domain resolves access through).
2. **Collaboration** — Google Workspace as the single email/calendar/Chat/Meet plane, with bounded,
   sunsetting coexistence.
3. **Drive / content replacement** — shared drives as the SharePoint/OneDrive successor, migrated by
   content class with permissions remodeled, not copied.
4. **Data governance & retention** — Vault + Workspace DLP + the AI control center as a shared
   governance plane, with a bounded Purview→Vault hold transition.
5. **AI enablement** — Gemini Enterprise and governed agents, enabled by scope and **only where the
   data-class governance already exists**.

Nine enterprise principles (one owned end-state, identity-first, govern-by-scope, least standing
access, bounded coexistence, governance-before-AI, avoid needless lock-in, NFRs first-class, and the
Assess → Configure → Pilot → Validate → Expand lifecycle) constrain every design and are enforced by an
**Architecture Review Board** through pass/fail conformance gates.

## What's included

The architecture-definition method across all five domains; a reusable ADR/NFR/standards framework;
five source-side PowerShell scripts (current-state discovery, conformance validation, coverage/gap
report, safe remediation guidance, and scope targeting — read-only where they touch live systems); and
a **Target-Architecture document template outline** you populate to produce the authoritative artifact
the program governs against.

> **Vendor-accuracy note.** Google Admin console and Microsoft/Entra patterns are drawn from current
> public vendor documentation; **Gemini Enterprise capabilities that are preview or rolling out are
> flagged "verify in your tenant"** and carried in a preview-capability risk register — never assumed
> GA.

## The bottom line

An approved, stable enterprise target architecture — every workstream aligned to one end-state design,
every decision recorded, every wave gated by the ARB — so migration waves execute **without
architectural rework**. Define it, own it, align every workstream to it. Self-guided and validated, at
a fraction of the cost of open-ended architecture consulting.


---


# Solution Overview — Target Architecture Blueprint

## What this blueprint is (and is not)

This is an **architecture-authority** product for a large-scale (150,000-user) transformation from
Microsoft 365 to **Google Workspace + Gemini Enterprise**. It defines the **end-state target
architecture** and the **architectural principles, reference patterns, decision records (ADRs), and
non-functional requirements (NFRs)** that every migration workstream is measured against. It is the
document the chief architect owns so the transformation stays scalable, supportable, and under
enterprise control.

It is **not** a click-by-click configuration runbook. Individual workstreams (mail cutover, Drive
migration, SSO federation, DLP, Vault) each have their own build procedures; this blueprint governs
**how those builds must be designed** so they compose into one coherent, defensible end state instead
of fragmenting across partners and waves.

> **Authority statement.** When a workstream design conflicts with a principle or ADR in this
> blueprint, the blueprint wins unless the Architecture Review Board (ARB) records a superseding
> decision. That is what "owning the architecture" means in practice.

## The end-state architecture at a glance

The target estate is organized into five **architecture domains**, each with an owning principle set,
reference patterns, and ADRs (detailed in `03-implementation.md`):

| Domain | End-state anchor | Source-side coexistence |
| --- | --- | --- |
| **Collaboration** (email, calendar, Chat, Meet, Docs) | Google Workspace as the single collaboration plane | M365 mailboxes decommissioned wave-by-wave; dual-delivery only during coexistence |
| **Content / Drive replacement** | Google Drive + shared drives as the SharePoint/OneDrive successor | SharePoint/OneDrive read-only then retired per content class |
| **Identity integration** | One authoritative identity source federated to Google via SSO + automated provisioning | Entra ID / on-prem AD retained as source of truth or transitional IdP |
| **Data governance & retention** | Google Vault + Workspace DLP + AI control center as the governance plane | Microsoft Purview retained for legacy holds until legal sunset |
| **AI enablement** | Gemini Enterprise + agentic workflows governed by the AI control center | N/A (net-new capability) |

These five domains sit on a **shared foundation**: the identity source of truth, the organizational
unit (OU) and group model, DNS/mail-flow control, and change control. Every domain design must trace
back to that foundation — this is the **GWARCH-Foundation** principle set (see below).

## How the workstreams fit together

The transformation runs many parallel workstreams (mail, calendar, Drive, Chat, identity, governance,
AI, endpoint/Chrome). Left uncoordinated they drift. The blueprint binds them with three integration
contracts:

1. **Identity contract.** Every domain consumes users and groups from **one** provisioning pipeline
   (see the *Identity integration* domain). No workstream provisions its own shadow identities. This
   is the **GWARCH-ID-1** principle: *one authoritative identity source, one provisioning path.*
2. **OU/group targeting contract.** Every policy (DLP, sharing, Gemini access, retention) is applied
   to the **same** named OU/group taxonomy — the **GWARCH-Scope** model — so scope is consistent and
   auditable across domains. `GWARCH-Set-ScopeTargeting.ps1` operationalizes this on the source side.
3. **Governance contract.** Every domain exposes its policy surface to the governance plane (Vault,
   DLP, AI control center) rather than governing itself in isolation. This is **GWARCH-GOV-1**:
   *governance is a shared plane, not a per-app setting.*

## Enterprise architecture principles (the constraints on every design)

These principles constrain all five domains. Each is named so downstream designs and ADRs can cite it.

- **GWARCH-P1 — One end-state, owned centrally.** There is a single approved target architecture;
  partner/wave designs conform to it or raise an ARB exception. No workstream defines its own end
  state.
- **GWARCH-P2 — Identity is the spine.** Collaboration, content, governance, and AI all resolve
  access through one authoritative identity and one provisioning pipeline (GWARCH-ID-1). Identity
  decisions are made first and constrain everything else.
- **GWARCH-P3 — Govern by scope, not by exception.** Policy is applied to the named OU/group
  taxonomy (GWARCH-Scope), never to ad-hoc individuals. New capabilities inherit governance by
  landing in the right scope.
- **GWARCH-P4 — Least standing access; sharing is a decision, not a default.** External sharing,
  broad admin roles, and AI data access are closed by default and opened per scope with justification.
- **GWARCH-P5 — Coexistence is bounded and temporary.** Every M365↔Google coexistence bridge (mail
  routing, directory, holds) has a defined sunset condition. Nothing "temporary" becomes permanent
  without an ARB decision.
- **GWARCH-P6 — Data governance precedes AI enablement.** Gemini/agent access to Workspace data is
  only enabled where DLP, sharing, and retention controls for that data class are already in place
  (GWARCH-GOV-1). AI does not outrun governance.
- **GWARCH-P7 — Avoid one-way lock-in where reversible costs little.** Prefer open, exportable data
  formats and portable identity patterns so a future change of tooling touches integration layers,
  not the whole estate.
- **GWARCH-P8 — Non-functional requirements are first-class.** Availability, scale (150k users),
  supportability, security, and compliance NFRs are stated per domain and validated at conformance
  gates, not assumed.
- **GWARCH-P9 — Assess → Configure → Pilot → Validate → Expand.** Every domain change follows this
  model with explicit pass/fail gates and a documented rollback for production-affecting changes.

## Deployment / decision model

The blueprint itself is delivered and kept authoritative through the same lifecycle the workstreams
use:

**Assess** current-state (source M365/Entra discovery via `GWARCH-Discovery.ps1`) →
**Configure** the target architecture (principles, domain patterns, ADRs, NFRs) →
**Pilot** the architecture against one wave/OU and validate conformance
(`GWARCH-Validation.ps1`) → **Validate** coverage and close gaps (`GWARCH-Report.ps1`,
`GWARCH-Remediation.ps1`) → **Expand** the approved architecture to all waves under ARB control.

## Who uses this

Chief/enterprise architect and the ARB (own and enforce it); workstream leads (design to it);
security, legal/eDiscovery, and data-governance stakeholders (validate their controls are expressed
in it); program leadership (measure wave readiness against it). Audience is **senior**: the document
assumes fluency in identity, collaboration, and governance concepts and is decision-oriented, not
tutorial.

## What you get

The `source/` docs (overview, requirements, the architecture-definition method, conformance testing,
troubleshooting, best practices, deliverables, executive summary), five source-side PowerShell scripts
(discovery, validation, coverage/gap report, remediation guidance, scope targeting), and a
**Target-Architecture document template outline** (`08-deliverables-summary.md`) you populate to
produce the authoritative artifact your program governs against.


---


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


---


# Global Requirements — Google Workspace & Gemini Solutions

These requirements apply to **every** solution in the **Google** category. They are the common
foundation each Google Workspace / Gemini solution assumes is already in place (or stands up as part
of its own Requirements section). Verify each before starting a solution's implementation steps.

> **Vendor boundary (applies to every Google solution).** The **Google Admin console**
> (admin.google.com), **Google Cloud / Cloud Identity**, and the **Microsoft / Entra** sides are
> authored at exact, current click-by-click detail from the vendors' public documentation. **Gemini
> Enterprise** capabilities that are in preview or rolling out are **cited or flagged "verify in your
> tenant"** — never invented. **Third-party migration tools** (e.g. for mail/Drive/Chat data movement)
> and **third-party enterprise apps** (ServiceNow, SAP, Databricks, etc.) are integrated at the
> pattern/architectural level; their internal console steps are deferred to the vendor's own docs.

## 1. Google Workspace / Cloud Identity tenant
- **Description:** A provisioned Google Workspace (or Cloud Identity) tenant with a **super-admin**
  account for configuration, and the appropriate Workspace edition/licensing for the capability in
  scope (e.g. Enterprise Plus for Vault/CAA/DLP, Gemini/AI add-on where required).
- **Why required:** All configuration, policy, and API work is performed against this tenant.
- **How to verify:** Sign in to **admin.google.com** as a super-admin; confirm edition and license
  counts under **Billing / Subscriptions**.
- **How to implement if missing:** Provision the tenant and licenses through Google or an authorized
  reseller before starting.

## 2. Source Microsoft 365 / Entra environment (for migration & coexistence)
- **Description:** For migration/coexistence/identity solutions, administrative access to the source
  **Microsoft 365** tenant and **Microsoft Entra ID** (Global Administrator or the least-privilege
  roles the solution names).
- **Why required:** Migration, directory sync, SSO federation, and coexistence read from and change
  the Microsoft side.
- **How to verify:** Confirm access to the M365 admin center and the Entra admin center with the
  required role.
- **How to implement if missing:** Obtain the role from the M365/Entra tenant owner.

## 3. DNS control for the routed domains
- **Description:** Ability to create/modify **DNS records** (MX, SPF, DKIM, DMARC, TXT, CNAME) for the
  domains being migrated, coexisting, or verified.
- **Why required:** Domain verification, mail routing/coexistence, and authentication all depend on
  DNS changes.
- **How to verify:** Confirm access to the authoritative DNS zone for each domain.
- **How to implement if missing:** Coordinate with whoever controls DNS; stage changes under change
  control (mail-flow changes are high-impact).

## 4. Identity & provisioning source of truth
- **Description:** A defined **identity source of truth** (on-prem AD, Entra ID, or an HR/IGA system)
  and the sync mechanism (e.g. **Google Cloud Directory Sync (GCDS)** or SCIM-based provisioning).
- **Why required:** Consistent users/groups across ecosystems underpin SSO, licensing, and access.
- **How to verify:** Confirm which directory is authoritative and how objects flow into Google.
- **How to implement if missing:** Define the source of truth and provisioning model before configuring
  SSO or migrating.

## 5. A pilot scope (OU / group) and change control
- **Description:** A **pilot organizational unit or group** to validate on before fleet-wide rollout,
  and a **change-control** process for production changes (especially mail flow, DNS, identity, and DLP).
- **Why required:** Every solution follows an **Assess → Configure → Pilot → Validate → Expand** model;
  the pilot proves the design and change control protects production.
- **How to verify:** Confirm a named pilot OU/group exists and a change window/approval path is available.
- **How to implement if missing:** Create a pilot OU/group and agree the change-control process with the
  owners before making production changes.

## 6. Security, compliance & governance stakeholders
- **Description:** Engagement with the **security (CISO), legal/eDiscovery, and data-governance**
  stakeholders whose policies the configuration must satisfy (DLP, retention, Vault/Purview, and any
  regulatory regime such as ITAR/DFARS/Assured Controls where applicable).
- **Why required:** Data governance, eDiscovery, DLP, and regulated-workload settings must align to
  enterprise policy and legal requirements, not just technical defaults.
- **How to verify:** Confirm the applicable policies and named stakeholders/approvers.
- **How to implement if missing:** Identify the owners and obtain the policy/compliance requirements
  before configuring governance controls.

*The deployment model across every Google solution is the same: **Assess → Configure → Pilot →
Validate → Expand**, with explicit pass/fail gates and a documented rollback for production changes.*


---


# Implementation — The Architecture-Definition Method

This is the **method** for producing and owning the target architecture, not a configuration runbook.
It walks the five architecture domains — **collaboration, Drive replacement, identity, data
governance & retention, and AI enablement** — and for each provides **principles**, **reference
patterns**, and **architecture decision records (ADRs)**. Work the domains in dependency order:
**identity first** (it is the spine — GWARCH-P2), then collaboration and Drive replacement, then
governance, then AI enablement (governance must precede it — GWARCH-P6).

Each domain is authored using the same six-step loop, mapped to the **Assess → Configure → Pilot →
Validate → Expand** model:

1. **Assess** — establish current state (discovery) and constraints (NFRs, compliance, licensing).
2. **Decide** — record the domain's ADRs; every ADR states *context / decision / consequences /
   status* and cites the principle(s) it implements.
3. **Pattern** — capture the reference pattern(s) the workstreams must follow.
4. **Constrain** — state the non-functional requirements (NFRs) and standards the design must meet.
5. **Validate** — define the conformance gate (see `05-testing.md`).
6. **Expand** — publish to the ARB and roll to all waves.

> **ADR numbering standard.** `GWARCH-ADR-DOMAIN-NN` (e.g. `GWARCH-ADR-ID-01`, where DOMAIN is the
> domain code ID/COL/DRV/GOV/AI). Every ADR has one of
> `Proposed / Accepted / Superseded` status and, if superseded, names the ADR that replaces it. This
> is the reusable standard the whole program cites.

---

## Domain 1 — Identity integration (the spine)

**Design this first.** Everything else resolves access through it.

### Principles
- **GWARCH-ID-1 — One authoritative source, one provisioning path.** A single directory is
  authoritative; users and groups flow into Google through exactly one pipeline. No shadow
  provisioning (implements GWARCH-P2).
- **GWARCH-ID-2 — Federate authentication, automate provisioning, separate the two.** SSO
  (authentication) and provisioning (lifecycle) are distinct concerns designed independently so
  either can change without breaking the other.
- **GWARCH-ID-3 — Deprovisioning is a first-class path.** Joiner/mover/leaver flows are designed with
  equal rigor to onboarding; orphaned access is an architecture defect.

### Reference patterns
- **Pattern ID-A — Entra ID as IdP + automated provisioning to Google.** Microsoft Entra ID federates
  authentication to Google Workspace via a **SAML SSO profile** (Admin console → *Security → SSO with
  third-party IdP → Add SAML profile*), while user/group lifecycle is provisioned via **Entra
  provisioning (SCIM)** or the Google connector. Legacy SSO profiles are deprecated — target SAML
  profiles. *(Verify current connector/SCIM behavior in your tenant.)*
- **Pattern ID-B — Directory as source of truth via GCDS.** Where on-prem AD/LDAP remains
  authoritative, **Google Cloud Directory Sync (GCDS)** syncs users/groups/OUs into Google on a
  schedule; authentication may still federate to Entra. Build the GCDS config with the Configuration
  Manager (it stores generated/encrypted settings) rather than hand-editing XML.
- **Pattern ID-C — Cloud Identity as the eventual authoritative directory.** For the end state where
  Google becomes authoritative, plan the migration of the source of authority (AD/Entra → Cloud
  Identity) as an explicit, sequenced ADR — not an implicit side effect.

Choose **one** primary pattern per identity population and record it; mixing patterns for the same
users violates GWARCH-ID-1.

### ADRs to record
- **GWARCH-ADR-ID-01** — Authoritative identity source (context: two live directories; decision: name
  the one source; consequences: all provisioning conforms).
- **GWARCH-ADR-ID-02** — SSO/federation model (IdP choice, SAML profile, session/MFA posture).
- **GWARCH-ADR-ID-03** — Provisioning mechanism (SCIM vs GCDS vs Admin SDK) and attribute mapping.
- **GWARCH-ADR-ID-04** — Joiner/mover/leaver + deprovisioning path and orphan-detection standard.

### NFRs / standards
Provisioning latency target; SSO availability target (identity is on the critical path for 150k
users); attribute-mapping standard; break-glass admin access that does **not** depend on the federated
IdP (so an IdP outage cannot lock out administration).

---

## Domain 2 — Collaboration (email, calendar, Chat, Meet, Docs)

### Principles
- **GWARCH-COL-1 — Google Workspace is the single collaboration plane at end state.** Dual systems
  exist only during bounded coexistence (GWARCH-P5).
- **GWARCH-COL-2 — Coexistence is routed, not replicated.** Mail/calendar coexistence uses controlled
  routing and free/busy federation with a sunset date; avoid permanent bidirectional replication.
- **GWARCH-COL-3 — Collaboration policy is applied by scope.** Sharing, external chat, and Meet
  settings bind to the GWARCH-Scope OU/group model (GWARCH-P3).

### Reference patterns
- **Pattern COL-A — Wave-based mailbox cutover with dual-delivery bridge.** During a wave, mail routes
  to both systems until MX/user cutover completes; the bridge sunsets when the wave's mailboxes are
  decommissioned. Calendar free/busy federates across the transition.
- **Pattern COL-B — Chat/Meet as the successor to Teams collaboration.** Define which Teams
  capabilities map to Google Chat spaces vs Meet vs Drive, and which are retired, so the successor
  design is explicit rather than emergent.

### ADRs to record
- **GWARCH-ADR-COL-01** — Coexistence routing model and per-wave sunset criteria.
- **GWARCH-ADR-COL-02** — Teams → Chat/Meet/Spaces mapping and retirement decisions.
- **GWARCH-ADR-COL-03** — External sharing/communication default posture per scope.

### NFRs / standards
Mail-flow change control (high-impact); free/busy accuracy target during coexistence; a documented
rollback for any MX/routing change.

---

## Domain 3 — Content / Drive (SharePoint & OneDrive replacement)

### Principles
- **GWARCH-DRV-1 — Shared drives are the unit of team content ownership.** Team content lives in
  **shared drives** with a defined ownership/lifecycle model, not in personal My Drive, so ownership
  survives staff changes.
- **GWARCH-DRV-2 — Migrate by content class, not by volume.** Content is classified (active
  collaboration, reference, records-retention, dark data) and each class gets a distinct
  migrate/archive/retire decision.
- **GWARCH-DRV-3 — Sharing is closed by default and opened by scope** (GWARCH-P4).

### Reference patterns
- **Pattern DRV-A — SharePoint/OneDrive → shared-drive taxonomy mapping.** Map source sites/libraries
  to a target shared-drive structure aligned to the GWARCH-Scope model; source becomes read-only, then
  retires, once the class is validated.
- **Pattern DRV-B — Records/retention content routed to the governance plane.** Content with retention
  or hold obligations is routed to Vault-governed locations (see Domain 4), never migrated as ordinary
  active content.
- **Pattern DRV-C — Permission remodeling, not permission copying.** Rebuild access from the
  identity/group model rather than replicating source ACLs, which propagate legacy over-sharing.

### ADRs to record
- **GWARCH-ADR-DRV-01** — Shared-drive taxonomy and ownership/lifecycle standard.
- **GWARCH-ADR-DRV-02** — Content-classification scheme and per-class disposition.
- **GWARCH-ADR-DRV-03** — Permission-remodeling standard (no raw ACL copy).

### NFRs / standards
Migration fidelity/validation sampling target; external-sharing default per scope; large-tenant scale
considerations (150k users' content) documented as a constraint.

---

## Domain 4 — Data governance & retention (Vault / Purview coexistence)

Design this **before** AI enablement (GWARCH-P6).

### Principles
- **GWARCH-GOV-1 — Governance is a shared plane, not a per-app setting.** Retention, DLP, holds, and
  classification are expressed centrally (Vault + Workspace DLP + AI control center) and inherited by
  every domain (implements GWARCH-P3).
- **GWARCH-GOV-2 — Legacy holds are preserved until legal sunset.** Purview holds/retention on source
  data are honored until legal confirms release; the Purview↔Vault transition is an explicit,
  bounded coexistence (GWARCH-P5).
- **GWARCH-GOV-3 — Classify once, enforce everywhere.** A single data-classification scheme drives
  DLP, sharing, retention, and AI-access decisions across all domains.

### Reference patterns
- **Pattern GOV-A — Vault as the end-state retention/eDiscovery plane.** Retention rules and holds are
  defined in Google Vault by scope; the retention schedule from the governance stakeholders is the
  input.
- **Pattern GOV-B — Bounded Purview→Vault hold transition.** Existing legal holds remain in Purview on
  source data until each matter is either migrated to Vault-governed content or legally released; each
  hold has a sunset owner and date.
- **Pattern GOV-C — DLP by scope and classification.** Workspace DLP rules bind to the GWARCH-Scope
  model and the classification scheme, closed-by-default externally.

### ADRs to record
- **GWARCH-ADR-GOV-01** — End-state retention/eDiscovery plane (Vault) and schedule.
- **GWARCH-ADR-GOV-02** — Purview→Vault hold transition and sunset criteria per matter.
- **GWARCH-ADR-GOV-03** — Classification scheme and DLP enforcement standard.

### NFRs / standards
Retention-schedule conformance; hold-continuity guarantee (no gap during transition); DLP
false-positive/appeal path; regulated-workload controls where applicable.

---

## Domain 5 — AI enablement (Gemini Enterprise + agentic)

Enable AI **only where** the governing controls for the data class already exist (GWARCH-P6).

### Principles
- **GWARCH-AI-1 — AI inherits governance; it does not bypass it.** Gemini/agent access to Workspace
  data (Gmail, Drive, Calendar, NotebookLM, Search) is constrained by the same identity, sharing, DLP,
  and retention controls as any user — enabled per scope through the **AI control center**.
- **GWARCH-AI-2 — Agents are governed workloads with an owned lifecycle.** Every agent has an owner,
  a defined data/actions scope, and passes through the agent-platform governance surface — no
  ungoverned agents in production.
- **GWARCH-AI-3 — Enable by scope, measure, then expand** (GWARCH-P9). AI is piloted on a scope,
  validated for governance conformance, then expanded.

### Reference patterns
- **Pattern AI-A — Scoped Gemini enablement via the AI control center.** Gemini Enterprise settings
  (service on/off, data-sharing) are managed in the Admin console's Generative-AI section and the AI
  control center; enable per OU/group in the GWARCH-Scope model rather than tenant-wide.
  *(Some Gemini Enterprise admin capabilities are preview/rolling-out — **verify in your tenant** and
  design to the capabilities actually present.)*
- **Pattern AI-B — Governed agent onboarding.** Agents that search/act on Workspace data are
  registered through the agent-platform governance surface with an owner, a data-and-actions scope,
  and a review; access to Workspace data stores is granted per scope, not blanket.
- **Pattern AI-C — Data-access gating.** An OU/group only receives Gemini/agent access to a data class
  after that class's DLP, sharing, and retention controls (Domain 4) are in place — the enforcement of
  GWARCH-P6.

### ADRs to record
- **GWARCH-ADR-AI-01** — Gemini enablement scope model and data-sharing posture.
- **GWARCH-ADR-AI-02** — Agent governance lifecycle (registration, ownership, review, retirement).
- **GWARCH-ADR-AI-03** — AI data-access gating tied to governance readiness per class.

### NFRs / standards
AI data-access auditability; agent inventory completeness; preview-capability risk register (what is
GA vs preview and the contingency if a previewed capability changes).

---

## Cross-domain: NFRs, standards, and the decision log

Beyond per-domain NFRs, the blueprint maintains program-wide standards:

- **Scale** — every design states how it holds at 150k users (limits, sync windows, admin-role
  blast radius).
- **Supportability** — each domain names its operational owner and runbook location.
- **Security** — least standing access, break-glass, and closed-by-default sharing across domains.
- **Compliance** — retention/hold continuity and any regulatory regime, honored end-to-end.
- **The ADR log** — the single running record of every decision above, its status, and supersessions;
  it is the artifact the ARB governs against and the one auditors read.

Once all five domains have ADRs, patterns, and NFRs recorded and validated (`05-testing.md`), compile
them into the **Target-Architecture document** using the template outline in
`08-deliverables-summary.md`. That compiled document — not this method — is what the program executes
against.


---


# Testing — Architecture-Conformance Validation Gates

You do not "test" an architecture by running it; you test whether the **designs and the built estate
conform** to the blueprint's principles, patterns, ADRs, and NFRs. This section defines the
**conformance gates** — explicit pass/fail checks — that a domain, a wave, or the whole program must
clear. `GWARCH-Validation.ps1` automates the source-side, machine-checkable subset; the rest are
review gates the ARB signs.

**Every gate is pass/fail with a documented remediation path.** A domain does not advance from Pilot
to Expand until its gates pass or the ARB records an exception ADR.

## Gate 0 — Foundation conformance (blocks everything)

| Check | Pass criterion |
| --- | --- |
| Single identity source of truth named | ADR GWARCH-ADR-ID-01 exists and is Accepted |
| GWARCH-Scope OU/group taxonomy defined | Named taxonomy exists incl. pilot scope |
| ARB + ADR log stood up | Charter and log present; cadence set |
| Governance stakeholders engaged | RACI + policy inputs collected |

*Fail → stop. No domain proceeds on an undefined foundation (GWARCH-P1/P2).*

## Gate 1 — Identity conformance

- **No shadow provisioning:** every population traces to the one provisioning pipeline (GWARCH-ID-1).
  *Check:* discovery shows no workstream-owned identity source. **Pass/fail.**
- **SSO ≠ provisioning coupling:** federation and lifecycle are separable (GWARCH-ID-2).
- **Break-glass admin independent of IdP:** an admin path survives an IdP outage. **Must pass.**
- **Deprovisioning path exists and orphan detection is defined** (GWARCH-ID-3).

## Gate 2 — Collaboration conformance

- **Coexistence is bounded:** every mail/calendar bridge has a sunset condition recorded
  (GWARCH-COL-2 / GWARCH-P5). **Pass/fail.**
- **Collaboration policy binds to scope,** not individuals (GWARCH-COL-3).
- **MX/routing change has a documented rollback.** **Must pass** before any mail-flow change.

## Gate 3 — Drive / content conformance

- **Team content lands in shared drives** with an ownership/lifecycle owner (GWARCH-DRV-1).
- **Content is classified and each class has a disposition** (GWARCH-DRV-2).
- **Permissions are remodeled, not raw-copied** (GWARCH-DRV-3 / no legacy over-sharing).
- **Retention-bearing content routed to the governance plane,** not migrated as active.

## Gate 4 — Governance & retention conformance

- **Retention schedule expressed in Vault by scope** and matches the stakeholders' schedule
  (GWARCH-ADR-GOV-01).
- **Hold continuity:** no gap between Purview holds and Vault governance; each matter has a sunset
  owner/date (GWARCH-GOV-2). **Must pass — a hold gap is a legal defect.**
- **DLP binds to scope + classification, closed-by-default externally** (GWARCH-GOV-3 / GWARCH-P4).

## Gate 5 — AI enablement conformance (gated by Gate 4)

- **AI enabled only where governance exists:** no OU/group has Gemini/agent access to a data class
  whose DLP/sharing/retention controls are not yet in place (GWARCH-P6 / Pattern AI-C). **Must pass.**
- **Every production agent is governed:** owner, data/actions scope, and review recorded
  (GWARCH-AI-2). No ungoverned agents. **Pass/fail on the agent inventory.**
- **Preview-capability risk register maintained:** each Gemini capability marked GA vs preview with a
  contingency (**verify in tenant** items are tracked, not assumed GA).
- **AI enablement is scoped, not tenant-wide,** and auditable (GWARCH-AI-1/AI-3).

## Gate 6 — Cross-domain NFR conformance

- **Scale stated at 150k users** per domain (limits, sync windows, admin blast radius).
- **Every domain names an operational owner + runbook** (supportability).
- **Least standing access + break-glass** verified across domains (security).
- **Compliance continuity** end-to-end (retention/holds/regulatory).

## Gate 7 — ADR completeness & authority

- **Every domain has its required ADRs recorded** with status; supersessions are linked.
- **No un-reconciled design conflicts:** any workstream deviation from a principle/pattern is either
  removed or carried as an explicit exception ADR (GWARCH-P1). **Pass/fail.**
- **The ADR log is the single source** the ARB governs against and is current.

## How to run the machine-checkable subset

`GWARCH-Validation.ps1` performs read-only source-side checks that feed Gates 0–2 (e.g. detecting
multiple potential identity sources, unscoped targeting, missing break-glass indicators) and emits a
pass/fail summary. `GWARCH-Report.ps1` rolls the results plus the design-review gates into a
**coverage/gap** view the ARB uses to decide Pilot→Expand. The review gates (patterns, ADRs, NFR
sign-off) are human ARB decisions the scripts surface but do not replace.

**Exit criterion for "architecture approved":** Gates 0–7 pass (or carry ARB-approved exceptions), the
Target-Architecture document is compiled, and the ADR log is current. Only then does the architecture
Expand to all waves.


---


# Troubleshooting — Common Architecture Pitfalls

These are the failure modes that erode an owned target architecture in a large Google Workspace +
Gemini transformation, with the symptom, root cause, and the corrective move. Each references the
principle or gate it protects.

## 1. Competing identity sources of truth (shadow provisioning)

- **Symptom:** duplicate/mismatched users, licensing gaps, access that "shouldn't exist." Discovery
  finds more than one thing creating identities.
- **Root cause:** a workstream provisioned its own users instead of consuming the one pipeline —
  violates **GWARCH-ID-1**.
- **Fix:** name the single authoritative source (ADR GWARCH-ADR-ID-01), collapse shadow sources onto
  the one provisioning path, and re-run `GWARCH-Validation.ps1` until Gate 1 passes. Prevent recurrence
  with the identity contract in `03`.

## 2. Break-glass admin depends on the federated IdP

- **Symptom:** a plausible scenario where an Entra/IdP outage locks administrators out of a 150k-user
  Google estate.
- **Root cause:** SSO and administrative access were coupled — violates **GWARCH-ID-2** and the Gate 1
  "must pass" break-glass check.
- **Fix:** stand up an emergency super-admin path that does **not** traverse the federated IdP; test it
  after every federation change. Never ship a federation change without this.

## 3. Coexistence bridges that never sunset

- **Symptom:** mail dual-delivery, directory bridges, or legacy holds still running long after the wave
  they supported completed.
- **Root cause:** the bridge had no sunset condition — violates **GWARCH-P5 / GWARCH-COL-2**.
- **Fix:** attach a written sunset condition and owner to every bridge; review the list at each ARB;
  escalate any bridge past its date. Gate 2 fails until every bridge is bounded.

## 4. Permissions copied instead of remodeled (legacy over-sharing)

- **Symptom:** post-migration, content is over-shared exactly as it was in SharePoint/OneDrive;
  external exposure appears in the target.
- **Root cause:** source ACLs were replicated rather than rebuilt from the group model — violates
  **GWARCH-DRV-3** and closed-by-default (**GWARCH-P4**).
- **Fix:** remodel access from the identity/group taxonomy (Pattern DRV-C), default external sharing
  closed per scope, and validate a sample at Gate 3.

## 5. AI enabled ahead of governance

- **Symptom:** Gemini/agents can reach a data class whose DLP, sharing, or retention controls aren't in
  place yet.
- **Root cause:** AI enablement outran governance — violates **GWARCH-P6 / Pattern AI-C**; fails the
  Gate 5 "must pass" check.
- **Fix:** disable Gemini/agent access for that class until Domain 4 controls exist; enable per scope
  through the AI control center only after the data-class governance is validated. Track the gate in
  the ADR log.

## 6. Ungoverned agents in production

- **Symptom:** agents acting on Workspace data with no recorded owner, scope, or review.
- **Root cause:** no agent lifecycle — violates **GWARCH-AI-2**.
- **Fix:** register every production agent through the agent-platform governance surface with an owner
  and a data/actions scope; retire orphans. The agent inventory must be complete for Gate 5.

## 7. Designing on preview capabilities as if GA

- **Symptom:** a design depends on a Gemini Enterprise feature that changes, disappears, or behaves
  differently than the screenshot it was drawn from.
- **Root cause:** a preview/rolling-out capability was assumed GA instead of **verified in tenant**.
- **Fix:** maintain the preview-capability risk register (GA vs preview + contingency); design to the
  capabilities actually present in your tenant; re-verify at each ARB. Never invent behavior.

## 8. Policy applied to individuals, not scopes

- **Symptom:** inconsistent DLP/sharing/retention/Gemini access; exceptions multiply; new capabilities
  land ungoverned.
- **Root cause:** governance by exception instead of by scope — violates **GWARCH-P3**.
- **Fix:** refactor ad-hoc, individual-level policy onto the GWARCH-Scope OU/group model; keep
  source→target scope mapping deterministic (`GWARCH-Set-ScopeTargeting.ps1`). Treat any individual-level
  policy as a defect.

## 9. Decisions made outside the ADR log

- **Symptom:** two workstreams build conflicting things; no one can say why a choice was made; auditors
  find undocumented design.
- **Root cause:** decisions live in slides/email, not the ADR log — erodes **GWARCH-P1** authority.
- **Fix:** every consequential decision becomes an ADR (supersede, never overwrite); the ARB governs
  against the single log; Gate 7 fails on un-reconciled conflicts.

## 10. The architecture drifts from the real estate

- **Symptom:** the compiled document, the ADR log, and the built estate disagree.
- **Root cause:** no re-baselining; the design was validated once and never re-measured
  (**GWARCH-P8**).
- **Fix:** re-run `GWARCH-Discovery.ps1` + `GWARCH-Validation.ps1` on a cadence; feed drift back as
  gaps into the ADR log and ARB; keep the three surfaces coherent (`07` §9).

## Script-level issues

- **`Connect-MgGraph` fails / insufficient scopes:** consent the exact read scopes listed in each
  script header; a Global Reader role covers the discovery scopes. Re-run after consent.
- **Empty or partial output at 150k scale:** discovery/report scripts page and can run long on a large
  tenant; let them complete, run from a stable session, and export to file rather than console.
- **Remediation script "did nothing":** by design — `GWARCH-Remediation.ps1` defaults to `-WhatIf` and
  only prints guidance; it makes no changes unless explicitly run with `-WhatIf:$false` after review.


---


# Best Practices — Keeping the Architecture Authoritative

Defining the target architecture is the easy half; keeping it **authoritative** across a multi-year,
multi-partner, 150k-user program is the hard half. These practices keep the blueprint the thing every
workstream conforms to instead of a document that drifts into irrelevance.

## 1. Make the ADR the currency of decisions

- **Every consequential decision becomes an ADR** (`GWARCH-ADR-DOMAIN-NN`, status
  Proposed/Accepted/Superseded). If a decision isn't in the log, it isn't a decision — it's a rumor.
- **Never edit a decision in place; supersede it.** A new ADR references the one it replaces. The
  history is the audit trail.
- **The ADR log is singular and current.** One log, owned by the ARB, is the authority — not slides,
  not email threads.

## 2. Govern by scope, everywhere (GWARCH-Scope discipline)

- Bind **every** policy — sharing, DLP, retention, Gemini access — to the named OU/group taxonomy, so
  new capabilities inherit governance by landing in the right scope.
- Treat a policy applied to an ad-hoc individual as a **defect**; refactor it onto a scope.
- Keep source-side group→target-scope mapping deterministic (`GWARCH-Set-ScopeTargeting.ps1`) so scope
  can't silently diverge between the M365 source and the Google target.

## 3. Identity-first, always

- Resolve identity ADRs before any dependent domain proceeds (GWARCH-P2). A late identity change
  invalidates downstream designs across four domains.
- Keep **break-glass admin access independent of the federated IdP** — verify it after every
  federation change. An IdP outage must never lock out administration of a 150k-user estate.

## 4. Keep coexistence on a leash

- Give **every** coexistence bridge (mail routing, directory, holds) a written sunset condition and an
  owner (GWARCH-P5). Review the list at every ARB.
- A "temporary" bridge past its sunset date is an escalation item, not a footnote.

## 5. Governance precedes AI — hold the line

- Do not let AI enablement outrun governance (GWARCH-P6). The Pattern AI-C gate is non-negotiable: no
  Gemini/agent access to a data class until that class's DLP/sharing/retention controls exist.
- Maintain a **preview-capability risk register.** Gemini Enterprise capabilities move fast and some
  are preview/rolling-out — mark each GA vs preview, carry a contingency, and **verify in tenant**
  rather than designing on a screenshot.
- Keep a complete **agent inventory** with owners; an ungoverned production agent is a governance
  breach, not a convenience.

## 6. Run the ARB as a conformance engine

- **Standing cadence, quorum, decision rights.** The ARB approves ADRs, grants exceptions (as
  exception ADRs), and owns the sunset list.
- **ARB hooks into the program:** wave gates (`05-testing.md`) feed the ARB; a wave doesn't advance
  Pilot→Expand without an ARB conformance sign-off. This is the enforcement mechanism that makes the
  blueprint authoritative rather than advisory.
- **Exceptions are visible and time-boxed.** Every deviation is an explicit, dated exception ADR with
  a remediation plan — never a silent divergence.

## 7. Re-baseline against reality on a cadence

- Re-run `GWARCH-Discovery.ps1` and `GWARCH-Validation.ps1` on a schedule so the architecture is
  measured against the *current* source estate, not the one it was drafted against (GWARCH-P8).
- Feed drift (new shadow identity sources, unscoped policies, expired coexistence bridges) back into
  the ADR log and the ARB as gaps to close.

## 8. Design for reversibility where it's cheap

- Prefer exportable formats and portable identity patterns (GWARCH-P7) so a future tooling change
  touches integration layers, not the whole estate. Record any deliberate one-way lock-in as an ADR
  with its rationale so it's a chosen risk, not an accident.

## 9. Keep the three surfaces coherent

The **compiled Target-Architecture document**, the **ADR log**, and the **built estate** must agree.
When the estate changes, the ADR log and document change with it (supersede, don't overwrite). A gap
between the three is exactly what erodes authority — close it before it compounds.

---

*Bottom line:* authority comes from **one owned end-state, one ADR log, scope-based governance, an ARB
that gates every wave, and periodic re-baselining against the real estate.* Hold those and the
architecture stays the thing the program conforms to — which is the entire point of owning it.


---


# Deliverables Summary

This blueprint's purpose is to produce **one authoritative artifact** — the compiled
**Target-Architecture document** — governed by an **ADR log** and enforced by an **ARB**. This section
lists what the solution delivers and provides the **Target-Architecture document template outline** you
populate to create that artifact.

## What the solution delivers

| Deliverable | Purpose |
| --- | --- |
| **Solution overview** (`01`) | The end-state architecture, how workstreams fit, and the enterprise principles (GWARCH-P1…P9) |
| **Requirements** (`02`) | Prerequisites to run the architecture-authority function (tenants, identity source of truth, scope taxonomy, governance stakeholders, ARB, tooling) |
| **Architecture-definition method** (`03`) | The per-domain method — principles, reference patterns, and ADRs for identity, collaboration, Drive replacement, governance/retention, AI enablement |
| **Conformance gates** (`05`) | Pass/fail validation gates (0–7) a domain/wave/program must clear |
| **Troubleshooting** (`06`) | Common architecture pitfalls and how to correct them |
| **Best practices** (`07`) | Keeping the architecture authoritative; ARB hooks |
| **This summary + template** (`08`) | Deliverables list and the Target-Architecture document template outline |
| **5 source-side scripts** | Discovery, conformance validation, coverage/gap report, remediation guidance, scope targeting (Microsoft Graph, read-only where they read live systems) |
| **Executive summary** | One-page framing for sponsors/ARB |

## The five architecture domains (recap)

Identity (the spine) · Collaboration · Drive / content replacement · Data governance & retention ·
AI enablement. Each carries principles, reference patterns, ADRs, and NFRs (see `03`), and is gated
for conformance (see `05`).

---

## Target-Architecture Document — template outline

Populate this outline to produce the authoritative document the program executes against. Keep it
white-label and reusable; every section cites the principles/ADRs it implements.

**0. Front matter**
- Document owner (chief/enterprise architect), version, status, ARB approval date, supersession note.

**1. Executive summary**
- The end state in one page: Google Workspace + Gemini + one identity spine; why it's owned centrally;
  the bottom-line outcome (every workstream aligned to one end-state design so waves execute without
  architectural rework).

**2. Context, scope & drivers**
- Transformation scope (150k users, M365 → Google Workspace + Gemini), business drivers, in/out of
  scope, key constraints and assumptions.

**3. Architecture principles**
- The enterprise principles (GWARCH-P1…P9) verbatim, each with its rationale and implications. These
  constrain everything that follows.

**4. Current-state summary**
- Source M365/Entra estate as discovered (`GWARCH-Discovery.ps1` output): identity sources, mail,
  content, governance/holds, tenant/licensing. The reality the design starts from.

**5. Target-state architecture — per domain**
For each of the five domains (Identity, Collaboration, Drive replacement, Governance/Retention, AI
enablement):
- 5.x.1 **Principles** (domain principle set)
- 5.x.2 **Reference pattern(s)** chosen, with a diagram
- 5.x.3 **Key ADRs** (`GWARCH-ADR-DOMAIN-NN`, with status)
- 5.x.4 **Non-functional requirements & standards**
- 5.x.5 **Coexistence & sunset** (where applicable)

**6. Integration contracts**
- The identity contract (one provisioning path), the OU/group targeting contract (GWARCH-Scope), and
  the governance contract (shared plane) that bind the domains together.

**7. Non-functional requirements (cross-domain)**
- Scale (150k), availability, supportability, security (least standing access, break-glass),
  compliance (retention/hold continuity, regulatory).

**8. Governance & the ARB**
- ARB charter, cadence, decision rights; how wave gates feed the ARB; exception-ADR process.

**9. ADR log**
- The complete running decision record (or a pointer to it), every ADR with status and supersessions.

**10. Conformance & validation**
- The gates (0–7) and how designs/waves are measured; how the scripts feed them.

**11. Roadmap & wave alignment**
- How the architecture maps onto the wave plan (Assess → Configure → Pilot → Validate → Expand) and
  what each wave must satisfy.

**12. Risk register**
- Including the **preview-capability register** (Gemini GA vs preview / "verify in tenant" items with
  contingencies) and any deliberate lock-in decisions.

**13. Appendices**
- Glossary of named standards (GWARCH-Scope, ADR numbering, principle IDs), stakeholder RACI, and the
  script outputs referenced.

---

*Definition of done:* the Target-Architecture document is compiled from the domain work in `03`, all
conformance gates in `05` pass or carry ARB exceptions, the ADR log is current, and the ARB has
approved it. At that point the architecture is authoritative and Expands to all waves.
