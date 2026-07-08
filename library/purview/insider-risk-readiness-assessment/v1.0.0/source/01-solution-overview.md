# 1. Solution Overview — Insider Risk Readiness Assessment (Microsoft Purview)

## What this solution is
**Microsoft Purview Insider Risk Management (IRM)** correlates signals from across Microsoft 365 — data
exfiltration activity, downloads, sharing, DLP matches, device events, and HR context such as a resignation
or a role change — to surface *potentially risky user activity* for human review. It is one of the most
powerful capabilities in Purview and also the most **privacy- and HR-sensitive**: it looks at what named
people do. Turned on carelessly — every indicator enabled, real usernames visible to everyone, one
over-broad policy scoped to the whole tenant on day one — it becomes an employee-surveillance liability, a
works-council/privacy problem, and a flood of un-triageable, un-actionable alerts.

This solution is deliberately **not** a full enforced IRM deployment. It is an **Insider Risk Readiness
Assessment** — the *groundwork you do before you deploy*: confirming licensing, establishing the
**privacy-by-design** posture (pseudonymization/anonymization on, minimal indicators, data-minimizing
scope), standing up **strict role separation** (Insider Risk Management **Admins**, **Analysts**,
**Investigators**, and **Auditors** as distinct people, kept separate from HR and Legal), preparing the
**connectors** (HR, Entra, DLP, Defender for Endpoint) that feed the signals, and **scoping** the first
policy and priority-user group — then proving readiness with a tenant **Analytics** scan (aggregated,
anonymized insights that require *no* policy) before any named-user policy is created. Everything is done in
the **least-exposing mode first**: analytics/insights and pseudonymized data before policies; a disabled or
minimal-scope readiness policy before any expansion.

> **Scope boundary — case and policy OUTCOMES are deferred.** This solution delivers the **technical
> readiness method and the evidence** — is the tenant licensed, is privacy configured, are roles separated,
> are connectors healthy, is the scope correct. It does **not** make insider-risk determinations. **Whether**
> to open a case, **what** a risk score means for a specific person, any **HR, disciplinary, or legal
> action**, and the **applicability** of employment/privacy law (works-council consultation, regional
> monitoring rules, notice obligations) are **HR, privacy, and legal determinations** — deferred to those
> functions. Purview surfaces signals for review; people decide. This assessment prepares the capability
> responsibly; it does not operate it against anyone.

## Why this matters
- **Privacy groundwork is the deployment.** IRM without a privacy posture is a surveillance tool. Purview
  ships **pseudonymization** (anonymized usernames) that should be **on before any analyst sees data**, and
  the deployment should collect the **minimum** indicators needed — getting this right *first* is what makes
  the capability defensible to employees, privacy officers, and works councils.
- **Role separation is not optional.** The people who *configure* policies (Admins), *triage* alerts
  (Analysts), *investigate* case content and forensic evidence (Investigators), and *audit the auditors*
  (Auditors) must be **different people**, and IRM must be **separate from HR and Legal** — who are
  stakeholders and reviewers, not holders of the technical investigation role. Collapsing these roles is the
  classic governance failure.
- **Connectors gate the signals.** The high-value templates (e.g. *data theft by departing users*) do
  nothing without the **HR data connector** (resignation dates, role changes) and/or the Entra
  account-deletion signal; security-violation indicators need **Defender for Endpoint** integration. A policy
  with no connected signal is inert.
- **Analytics-first is the least-exposing on-ramp.** Purview **Insider Risk Analytics** scans the tenant and
  returns **aggregated, anonymized** insight into potential risk — *without configuring a policy and without
  naming anyone*. Running analytics before creating a named-user policy is how you validate that IRM has
  signal to work with, at the lowest possible privacy exposure.
- **IRM is largely portal-configured.** Unlike DLP, IRM exposes a **limited** PowerShell/Graph surface. This
  assessment is honest about that: the delivered scripts report the readiness signals they *can* (role-group
  membership and separation, audit-log state, licensing signal, the backing scope group) and **direct the
  operator to the Purview portal** for the parts that are portal-only (analytics scan, connector health,
  policy/priority-user configuration, pseudonymization toggle) — flagged **"verify in the Purview portal /
  verify your licensing/tenant"** rather than inventing a cmdlet.

## How it works
1. **Privacy-by-design settings** define *how much* IRM exposes. In **Purview portal → Insider Risk
   Management → Settings → Privacy**, **anonymization ("Show anonymized versions of usernames")** is turned
   **on** so analysts triage pseudonymized identities; only an authorized **Investigator** can de-anonymize
   within a case. Indicators are enabled to the **minimum** needed.
2. **Role groups** define *who can do what*. Purview provides distinct IRM role groups — **Insider Risk
   Management Admins**, **Analysts**, **Investigators**, **Auditors** (and the all-powerful **Insider Risk
   Management** super-group, held by almost no one). This assessment assigns them as **separated** duties.
3. **Connectors** define *what signal exists*. The **HR data connector** imports resignation/role-change/
   performance events; **Entra** provides account-deletion; **DLP** and **Defender for Endpoint** provide
   data-movement and security-violation indicators; optional **healthcare** and **physical-badging**
   connectors add domain signal. Readiness confirms the ones the intended policy needs are present and
   healthy.
4. **Analytics (insights, no policy)** scans the tenant and returns **aggregated, anonymized** potential-risk
   insight — the least-exposing way to confirm IRM has something to detect, run **before** any named policy.
5. **Scoping** defines *who a policy watches*. A **priority user group** (backed by an Entra security group)
   and a policy **template** (e.g. *data theft by departing users*) are scoped **narrowly** — created
   **disabled or minimal** as a readiness pilot, never broadly enforced from the assessment.
6. **Validation** proves each readiness gate (licensing, privacy, roles/separation, connectors, scope) with
   pass/fail evidence, and a **pseudonymized scorecard** is produced for stakeholder review — containing no
   personal data.

## The IRM role-separation model (the core discipline)
| Role group | Can do | Kept separate from |
|---|---|---|
| **Insider Risk Management Admins** | Create/edit policies, settings, connectors — *configuration only* | Triage, investigation, audit |
| **Insider Risk Management Analysts** | Triage alerts and work cases on **pseudonymized** data; **cannot** view forensic/case content in Content Explorer | Configuration, de-anonymized content |
| **Insider Risk Management Investigators** | Full case content, forensic evidence, **de-anonymized** identity within a case | Policy configuration, being the sole auditor |
| **Insider Risk Management Auditors** | Review the **IRM audit trail** (what admins/analysts/investigators did) | Being anyone they audit |
| **Insider Risk Management** (super-group) | **All of the above** — grant to almost no one | Everyone; hold under tight change control |

> **HR and Legal are stakeholders and reviewers — not the technical investigation role.** They receive
> escalations and make the employment/legal determination; they should **not** by default hold the
> Investigator role that de-anonymizes and reads case content.

## The least-exposing → scoped journey
> Confirm licensing → turn **anonymization ON** and enable **minimum** indicators (privacy-by-design) →
> separate the **Admin / Analyst / Investigator / Auditor** roles (and keep IRM separate from HR/Legal) →
> prepare and health-check **connectors** (HR, Entra, DLP, Defender) → run **Analytics** (aggregated,
> anonymized insight, **no policy**) → scope a **priority-user group** and a **readiness policy** narrowly,
> **disabled/minimal** → **validate** every readiness gate → hand the **pseudonymized readiness scorecard**
> to HR/privacy/legal, who own the decision to expand and operate.

## What you can control
- The **privacy posture**: anonymization on/off, which **indicators** are enabled, how data-minimizing the
  scope is.
- **Role separation**: who is an Admin vs Analyst vs Investigator vs Auditor, and that no one holds
  conflicting roles or the super-group unnecessarily.
- Which **connectors** are prepared (HR, Entra, DLP, Defender for Endpoint, healthcare, physical badging) and
  whether they are healthy.
- The **priority-user group** membership (readiness scope) and the **policy template** chosen for the
  readiness pilot.
- Whether IRM is validated with **Analytics only** first, and whether the first policy is **disabled/minimal**
  before any expansion.

## Limitations (be honest with buyers)
- **IRM is licensing-gated** — it typically requires **Microsoft 365 E5**, the **E5 Compliance** add-on, or a
  dedicated **Insider Risk Management** add-on (some capabilities are in preview). A policy or the analytics
  scan will not be available without the plan — **verify your licensing/tenant**.
- **IRM is largely portal-configured with a limited PowerShell/Graph surface.** The scripts here report what
  *is* scriptable (role groups & separation, audit-log state, licensing signal, the backing scope group) and
  **direct you to the Purview portal** for analytics, connector health, pseudonymization, and policy/priority
  configuration. We do **not** invent cmdlets for the portal-only parts.
- **Signal depends on connectors and audit logging.** No HR connector → no departing-user context; audit
  logging off → little to correlate; Defender not integrated → no security-violation indicators.
- **Case and policy outcomes are HR/privacy/legal determinations**, not technical defaults. This assessment
  prepares and proves the capability; it does not investigate, score, or act against any individual, and it
  does not opine on the legality of monitoring in your jurisdiction.

## Naming convention (used in every doc and script)
Every artifact this assessment references uses `<Purpose> – <Scope> – <Stage>`, reused verbatim across the
docs, scripts, and the Purview portal. The standard set:

| Artifact | Name |
|---|---|
| Priority user group (backing Entra security group) | `IRM Priority Users – Readiness – Scope` |
| Tenant analytics scan (insights, no policy) | `IRM Analytics – Insights – Tenant` |
| Readiness policy (created disabled/minimal, analytics-informed) | `IRM – Data Theft Departing Users – Readiness Pilot` |
| HR data connector | `HR Connector – Readiness` |
| Role-separation model | `IRM Roles – Admins / Analysts / Investigators / Auditors` |
| Priority physical assets list (optional) | `IRM Physical Assets – Readiness` |
| Privacy / anonymization setting | `Anonymization – On – Readiness` |
| Readiness scorecard (pseudonymized) | `IRM Readiness Scorecard – Stakeholder Review` |

## The standard deployment model
> **Assess** licensing, current IRM posture, roles, and connectors → **Design** the privacy posture, role
> separation, connector set, and initial scope → **Configure** privacy-by-design (anonymization on, minimum
> indicators), the backing scope group, and the readiness policy **disabled/minimal** → **Pilot** with an
> **Analytics** scan (aggregated, anonymized — no named policy) and a minimal-scope readiness policy →
> **Validate** every readiness gate with pass/fail evidence → **Expand** to operational IRM **only** on the
> HR/privacy/legal decision. Everything starts in the least-exposing mode, with a documented rollback and the
> outcome decision deferred to the governance functions.
