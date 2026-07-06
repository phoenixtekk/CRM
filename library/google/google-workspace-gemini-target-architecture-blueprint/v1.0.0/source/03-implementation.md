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
