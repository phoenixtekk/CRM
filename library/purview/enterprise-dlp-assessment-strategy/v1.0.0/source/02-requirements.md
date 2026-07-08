# 2. Requirements — Enterprise DLP Assessment & Strategy (Microsoft Purview)

These are the **solution-specific** prerequisites for running a DLP posture assessment, sensitive-data
discovery, and rollout-strategy exercise in Microsoft Purview. They build on — and do not repeat — the six
shared prerequisites in **`global-requirements-purview.md`** (tenant + compliance licensing, least-privilege
Purview roles, S&C PowerShell + Graph toolchain, in-scope data sources, compliance/records/privacy/legal
stakeholders, and a pilot scope + change control). Verify each item below before starting the Implementation
Guide.

For every requirement: **Description** (what it is), **Why required**, **How to verify**, **How to
implement if missing**.

---

## 2.1 Licensing sufficient for the discovery surfaces you will use
- **Description:** The **posture baseline** (existing policies, built-in SITs) is broadly available, but the
  discovery depth that makes this assessment valuable — **Content Explorer**, **Activity Explorer**,
  **on-demand / automatic classification**, **advanced & trainable classifiers**, and **Data Security
  Posture Management (DSPM)** — is **plan-gated**, typically **Microsoft 365 E5** or the **E5 Compliance**
  add-on, and some capabilities are in **preview**. This extends GR-#1 with the assessment-specific detail.
- **Why required:** A discovery exercise that cannot open Content Explorer or run a simulation policy can
  only inventory what exists on paper; the data map and movement measurement need these surfaces.
- **How to verify:** In the **Microsoft 365 admin center** confirm the subscription/add-ons; in the
  **Purview portal → Data classification** confirm **Content explorer** and **Activity explorer** are
  visible and populated. **Flag "verify your licensing/tenant"** — availability evolves.
- **How to implement if missing:** Acquire/assign E5 / E5 Compliance for the assessment window, or scope
  the assessment to the surfaces your plan covers (built-in SITs, DLP simulation, basic reporting) and note
  the coverage gap in the roadmap.

## 2.2 Assessment-specific least-privilege roles (read-heavy)
- **Description:** This is a **read-and-assess** engagement, so it needs read/reporting roles more than
  authoring ones: **Content Explorer List Viewer** and **Content Explorer Content Viewer** (to see where
  SITs/labels are detected and the underlying items), **View-Only DLP Compliance Management** (to read DLP
  policies), the **Compliance Administrator / Compliance Data Administrator** role only where the
  monitor-only simulation policy must be *created*, and **View-Only Audit Logs** for reporting. Global
  Administrator only where genuinely required. Extends GR-#2.
- **Why required:** Content Explorer's two viewer roles are **separately gated** and are the single most
  common blocker — without them the data map is empty. Separating read (assessment) from write (the one
  simulation policy) keeps the blast radius near zero.
- **How to verify:** **Purview portal → Settings → Roles & scopes → Permissions** — confirm your account's
  membership in the Content Explorer viewer roles and the DLP view/author roles you need.
- **How to implement if missing:** Assign the least-privilege role groups under change control; grant the
  Content Explorer **Content Viewer** role deliberately (it exposes item content) and log who holds it.

## 2.3 Audit logging enabled and retaining data
- **Description:** The **unified audit log** must be **enabled** and retaining events, because the movement
  measurement (simulation DLP matches, sharing activity) and the reporting script read from it and from
  Activity Explorer, both of which depend on audit ingestion.
- **Why required:** If audit logging is off or was only just turned on, there is no history of how sensitive
  content moves — the "how it moves" half of discovery is blank and priorities can't be ranked by movement.
- **How to verify:** **Purview portal → Audit** — confirm auditing is **On**; `Get-AdminAuditLogConfig`
  shows `UnifiedAuditLogIngestionEnabled : True`. The delivered Validation script checks this.
- **How to implement if missing:** Enable unified audit logging and allow ingestion/dwell time before
  relying on movement data; note that history only accrues from the enablement date.

## 2.4 A defined classification intent and a data-category shortlist
- **Description:** A documented view of **what sensitive data the organization believes it holds** (payment
  card data, national IDs, health identifiers, customer PII, source code, contracts, etc.) mapped to the
  **SITs/labels** that would detect it — used to focus Content Explorer and the simulation policy on the
  categories that matter. Extends GR-#4.
- **Why required:** Discovery is far more useful when aimed. A shortlist of candidate categories turns an
  open-ended scan into a targeted data map and makes the resulting prioritization legible to stakeholders.
- **How to verify:** **Purview portal → Data classification → Classifiers → Sensitive info types** lists
  built-in and custom SITs; confirm the ones matching your candidate categories exist. Confirm the shortlist
  with data owners.
- **How to implement if missing:** Build the candidate-category shortlist with the data owners before the
  scan; where no built-in SIT fits a category, note it as a **detector gap** for the roadmap (custom SIT /
  EDM / trainable classifier to be built during enforcement, not here).

## 2.5 Approval to create ONE monitor-only simulation DLP policy
- **Description:** Change-control approval to create a **single tenant-wide DLP policy in SIMULATION mode**
  (`DLP Baseline – All Locations – Simulation`) whose only purpose is to **measure** what would match — it
  takes **no enforcement action** and shows **no policy tips** to users. Extends GR-#6.
- **Why required:** Measuring movement needs a policy evaluating real traffic; simulation mode does exactly
  that with zero user impact. Even a zero-impact object should pass change control so its purpose and its
  simulation-only status are on record and it isn't mistaken for an enforcing policy.
- **How to verify:** Confirm the approval and that the intended mode is **simulation** (never enforce). The
  Validation script flags any policy found in **enforce** mode that the assessment did not intend.
- **How to implement if missing:** Obtain approval for the one simulation policy; if even that is not
  permitted, run discovery on **data-at-rest only** (Content Explorer) and note that movement data is
  unavailable in the roadmap.

## 2.6 An assessment scope, dwell time, and stakeholder sign-off path
- **Description:** The **workloads and (optionally) sites/users** the assessment covers, a **dwell time**
  for the simulation baseline (long enough to capture representative movement — often 2–4 weeks), and the
  **stakeholder path** (compliance/privacy/legal/records) that will **review and ratify** the resulting
  roadmap. Extends GR-#5 and GR-#6.
- **Why required:** The assessment's output is a *recommendation*; it only becomes an enforcement mandate
  once the governance owners ratify scope, legal applicability, and enforced actions. The dwell time governs
  how representative the movement data is.
- **How to verify:** Confirm the covered workloads, the agreed dwell time, and the named reviewers/approvers
  for the roadmap.
- **How to implement if missing:** Agree scope and dwell time and identify the roadmap reviewers before
  starting, so the deliverable has a home and an owner.

---

### Requirements summary

| # | Requirement | Gate |
|---|---|---|
| GR 1–6 | Category prerequisites (`global-requirements-purview.md`) | Tenant/licensing, roles, toolchain, scope, stakeholders, pilot + change control |
| 2.1 | Discovery-surface licensing (Content/Activity Explorer, DSPM; verify) | Data map + movement measurable |
| 2.2 | Read-heavy least-privilege roles (incl. Content Explorer viewers) | Discovery tools can read |
| 2.3 | Unified audit logging enabled + retaining | Movement history available |
| 2.4 | Classification intent + candidate-category shortlist | Discovery is aimed, results legible |
| 2.5 | Approval for ONE monitor-only simulation policy | Movement measurable, zero user impact |
| 2.6 | Assessment scope + dwell time + roadmap sign-off path | Representative data + a ratified output |

> **Deferred to compliance/privacy/legal:** which data categories are ultimately in scope, which classifiers
> legally apply, the enforced action per category, and any regulatory applicability. This solution delivers
> the assessment, the discovery evidence, and the proposed roadmap — not the determination.
