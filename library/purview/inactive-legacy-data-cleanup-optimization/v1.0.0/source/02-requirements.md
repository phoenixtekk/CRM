# 2. Requirements — Inactive & Legacy Data Cleanup & Storage Optimization (Microsoft Purview)

These are the **solution-specific** prerequisites for identifying ROT / inactive / legacy data and defensibly
cleaning it up with Microsoft Purview Data Lifecycle Management and Records Management. They build on — and do
not repeat — the six shared prerequisites in **`global-requirements-purview.md`** (tenant + compliance
licensing, least-privilege Purview roles, S&C PowerShell + Graph toolchain, in-scope data sources,
compliance/records/privacy/legal stakeholders, and a pilot scope + change control). Verify each item below
before starting the Implementation Guide.

For every requirement: **Description** (what it is), **Why required**, **How to verify**, **How to implement if
missing**.

> **E3 baseline vs E5 — verify your licensing.** Basic **retention policies** and **retention labels** (manual
> apply, static scope) are available on **Microsoft 365 E3**. The capabilities that make *targeted, automated,
> reviewable* cleanup possible — **auto-apply based on trainable classifiers / query / sensitive info type**,
> **adaptive scopes**, **Records Management**, and **disposition review** — generally require **Microsoft 365
> E5** or the **E5 Compliance** add-on, and some are in **preview**. Where a step below needs an E5-class
> capability it is flagged **"verify your licensing/tenant."**

---

## 2.1 Licensing sufficient for the lifecycle features you will use (E3 baseline vs E5)
- **Description:** Confirm your plan covers the specific DLM/Records features this cleanup uses. **E3** covers
  manual retention labels and basic retention/deletion policies with **static** scopes. **E5 / E5 Compliance**
  (or the standalone Records Management / Information Protection & Governance add-ons) is generally required for
  **adaptive scopes**, **auto-apply label policies** (classifier/query/SIT-based, including **simulation mode**),
  **Records Management**, and **disposition review**. This extends GR-#1 with the lifecycle-specific plan detail.
- **Why required:** A policy that relies on an adaptive scope, auto-apply, or disposition review your plan does
  not include will not be creatable or will not function — and you may fall back to a manual/static approach.
- **How to verify:** In the **Microsoft 365 admin center** confirm the subscription/add-ons (E3 / E5 / E5
  Compliance); in the **Purview portal → Data Lifecycle Management** and **Records Management** confirm the
  **Adaptive scopes**, **Auto-apply a label**, and **Disposition** areas are visible. **Flag "verify your
  licensing/tenant"** — availability evolves.
- **How to implement if missing:** Acquire/assign the required licensing before building adaptive/auto-apply/
  disposition controls; otherwise scope the first wave to **manual labels + static-scope retention policies**
  (E3-capable) and defer the E5 capabilities.

## 2.2 Data-lifecycle / records least-privilege roles
- **Description:** The Purview **role groups** for lifecycle work — **Records Management** (create/manage
  retention labels, label policies, file plan, and **disposition**), **Compliance Administrator** or **Compliance
  Data Administrator** (retention policies), **Retention Management** where present, and **Disposition
  Management** / the **Disposition Reviewers** membership for the review step. **View-Only** equivalents for
  read-only assessment. Global Administrator only where genuinely required. Extends GR-#2. Reading **inactive
  mailboxes** and mailbox statistics also needs Exchange Online recipient-read roles.
- **Why required:** Purview enforces fine-grained role groups; creating labels/policies, running disposition
  review, and enumerating inactive mailboxes each require the matching role, and least privilege keeps a
  destructive capability tightly held.
- **How to verify:** **Purview portal → Settings → Roles & scopes → Permissions** (Microsoft Purview roles) —
  confirm membership in Records Management / Compliance roles and the Disposition Reviewers group; in **Exchange
  admin** confirm the account can read recipients/inactive mailboxes.
- **How to implement if missing:** Assign the least-privilege role group under change control; keep **who can
  author a delete policy** and **who can approve a disposition** separated where possible.

## 2.3 A storage / ROT baseline and the signals to compute it
- **Description:** The **data and reports** needed to size ROT and find stale content: **existing retention
  policies, labels, and label policies**; the **holds** in force; **inactive-mailbox inventory**
  (`Get-Mailbox -InactiveMailboxOnly`); **mailbox last-logon / size** (Exchange mailbox statistics); and
  **SharePoint/OneDrive site last-activity and storage** via **Microsoft Graph usage reports**
  (`getSharePointSiteUsageDetail`, `getOneDriveUsageAccountDetail`, `getMailboxUsageDetail`). Extends GR-#4.
- **Why required:** Cleanup targets must be *identified and sized* from evidence, not guessed. Without the
  activity/storage signals you cannot name a stale-site or inactive-mailbox candidate list or measure savings.
- **How to verify:** Confirm you can run the delivered **Discovery** and **Report** scripts (Graph
  `Reports.Read.All` and Exchange/S&C read roles) and that **audit logging / usage reports** are enabled in the
  tenant.
- **How to implement if missing:** Enable the Graph reports permission and audit logging; use this solution's
  Discovery/Report scripts to build the baseline before designing any policy.

## 2.4 An inventory of existing holds (litigation, eDiscovery case, retention) — the safety gate
- **Description:** A **complete enumeration of every hold** that could protect content from deletion:
  **litigation holds** (`Get-Mailbox | … LitigationHoldEnabled`), **In-Place / eDiscovery case holds**
  (`Get-CaseHoldPolicy`), and **retain-action retention policies** (`Get-RetentionCompliancePolicy`). Any
  content within a hold's scope is **protected from purge** by Purview's retention principles.
- **Why required:** This is the **defensibility gate**. A delete policy must not be assumed to remove held
  content, and — more importantly — you must be able to **prove** no in-scope item is under hold before
  enforcing. Deleting something later found to be under legal hold is a serious failure; the platform blocks the
  purge, but you still validate and evidence it.
- **How to verify:** Run the **Discovery** and **Validate** scripts to list all holds and confirm overlap with
  your cleanup scope; confirm with the legal/eDiscovery function that the hold inventory is complete.
- **How to implement if missing:** Enumerate all holds first; if hold state is uncertain, **do not enforce any
  deletion** — resolve the hold question with legal before proceeding.

## 2.5 A records / retention-schedule decision source (deferred, but required as input)
- **Description:** The **records-management decision** for each in-scope data class — *how long* it must be kept,
  whether it is a **record** (immutable), and whether deletion requires **disposition review**. This is a
  records/compliance/legal determination (**deferred**), but the configuration cannot proceed without it as an
  input. Extends GR-#5.
- **Why required:** A retention label's period and delete action *encode* a retention decision. Setting them
  without the records schedule means the tool is inventing a legal retention period — which this solution must
  never do.
- **How to verify:** Confirm the applicable **retention schedule / file plan** and the named approver(s) for
  each data class in scope; confirm which classes require disposition review.
- **How to implement if missing:** Capture the schedule from the records/compliance function before authoring
  labels; where a class's schedule is undecided, treat it as **retain / do-not-delete** until decided.

## 2.6 A limited pilot scope, adaptive-scope attribute data, and change control
- **Description:** A named **limited pilot scope** (`DLC Cleanup Pilot – Stage1` — a small set of pilot
  sites/mailboxes that are known to be safe to act on, ideally non-production or clearly-obsolete), the
  **directory attributes** an adaptive scope will query (e.g. `Department`, account-enabled state, or a custom
  attribute marking a site/user/mailbox as decommissioned), and the **change-control window** to move
  from pilot to expansion. Extends GR-#6.
- **Why required:** Deletion is destructive, so it must be proven on a **small, safe scope first**. Adaptive
  scopes need reliable attribute data or they target the wrong objects; a query that mis-selects is how a
  cleanup deletes live content.
- **How to verify:** Confirm the pilot scope membership, that the attributes an adaptive scope needs are
  **populated and accurate**, and the approval path to expand.
- **How to implement if missing:** Define the pilot scope and validate/populate the adaptive-scope attributes
  before building any adaptive policy; agree change control before enforcing deletion anywhere.

## 2.7 A disposition review board and workflow (where deletion needs a human gate)
- **Description:** A named **disposition review board** (`DLC Disposition Review – Board`) — the reviewers who,
  for labels configured with **mandatory disposition review**, **approve, extend, or relabel** content reaching
  end-of-life — plus the workflow and evidence-retention expectation. Disposition review is an **E5 / Records
  Management** capability (verify licensing). Reviewers need the **Disposition Reviewers** role membership.
- **Why required:** For anything sensitive or of record value, permanent deletion should have a **human
  approval step** that produces **auditable disposition evidence** (who approved deleting what, when) — the
  backbone of a defensible cleanup.
- **How to verify:** Confirm the reviewer membership, that labels requiring review are configured with
  **disposition review = on**, and that **Purview portal → Records Management → Disposition** is available in
  your tenant.
- **How to implement if missing:** Where disposition review is not licensed, restrict E5-gated auto-cleanup and
  use **manual, evidenced disposition** on a limited scope; assign reviewers and define the workflow before
  enabling delete labels on record-value content.

---

### Requirements summary

| # | Requirement | Gate |
|---|---|---|
| GR 1–6 | Category prerequisites (`global-requirements-purview.md`) | Tenant/licensing, roles, toolchain, scope, stakeholders, pilot + change control |
| 2.1 | Lifecycle licensing (E3 baseline vs E5 for adaptive/auto-apply/disposition; verify) | Needed features available |
| 2.2 | Data-lifecycle / records least-privilege roles | Author + reviewer roles assigned, separated |
| 2.3 | Storage / ROT baseline + signals (Graph usage reports, mailbox stats) | Candidates identified and sized |
| 2.4 | Complete inventory of holds (litigation, eDiscovery case, retention) | **No held item deletable — proven** |
| 2.5 | Records / retention-schedule decision source (deferred input) | Labels encode a real schedule, not a guess |
| 2.6 | Limited pilot scope + adaptive-scope attribute data + change control | Deletion proven on a safe small scope first |
| 2.7 | Disposition review board + workflow (where required) | Human gate + disposition evidence |

> **Deferred to records / compliance / privacy / legal:** the retention schedule (how long to keep each class),
> whether content is a record, what is under legal hold, and whether a given deletion is defensible. This
> solution identifies candidates, configures the control, proves no held item would be deleted, and produces the
> disposition evidence — it does not make the retention or deletion determination.
