# 2. Requirements Guide — Sensitivity Label Migration Project

Verify **every** requirement below before starting the Implementation Guide. These are the
**solution-specific** prerequisites for migrating legacy/third-party classifications onto Microsoft
Purview sensitivity labels; they build on the shared **Global Requirements — Microsoft Purview
Solutions** (compliance licensing, least-privilege roles, Security & Compliance PowerShell + Graph
toolchain, in-scope workloads, compliance/records/legal stakeholders, and a pilot scope with change
control). Read the Global Requirements first; this guide does not repeat them.

> **Deferral note (records/security/legal).** Whether a mapped Purview label should **encrypt** or
> reproduce protection the legacy tool applied, and whether a legacy value maps to a "record," are
> **determinations owned by your records, security, compliance, and legal functions** — not technical
> defaults. This solution provides the **mapping method, detection, and evidence**; it does not decide
> the target protection. Confirm every mapping and any encryption with the accountable owner before
> enforcing.

---

## 2.1 Licensing for auto-labeling (the reclassification engine)
- **Description:** The reclassification is performed by **service-side auto-labeling** for
  SharePoint/OneDrive and Exchange, which requires **Microsoft 365 E5** or the **E5 Compliance**
  add-on. **Client-side** auto-labeling (labels applied/recommended in Office apps) and several
  advanced classifiers are also E5-tier. Manual sensitivity labels and publishing are available at E3,
  but the **automated migration** in this solution depends on auto-labeling.
- **Why required:** Without auto-labeling licensing there is no supported way to reclassify existing
  content at scale onto the mapped labels.
- **How to verify:** M365 admin center → subscriptions/add-ons; confirm **Information Protection →
  Auto-labeling** is visible and usable in the Purview portal. **Verify your licensing/tenant** —
  Microsoft's licensing tables are the authority.
- **How to implement if missing:** Assign/purchase E5 or E5 Compliance for the migration scope before
  configuring auto-labeling. (Manual re-labeling by users is a fallback but does not scale for a
  migration.)

## 2.2 The target sensitivity labels already exist and are published
- **Description:** The **destination** Microsoft Purview sensitivity labels every legacy value will map
  to must **already exist** in the tenant (created here or by the separate labels-implementation
  solution) and, for the pilot scope, be **published** so they can be applied. Each target label's
  protection (marking/encryption) must be the intended end state.
- **Why required:** Auto-labeling can only apply a label that exists and is available; the mapping
  matrix has no valid target otherwise.
- **How to verify:** `Get-Label` / Purview → **Information Protection → Sensitivity labels** shows every
  intended target label; `Get-LabelPolicy` shows it published to the pilot scope.
- **How to implement if missing:** Build/publish the target taxonomy first (see the sensitivity &
  retention labels implementation solution). Do not invent target labels inside this migration.

## 2.3 A legacy classification export from the source tool
- **Description:** An export/report from the **source classification tool** (or a representative sample)
  listing the **distinct classification values** in use and, where the tool provides it, **how each
  value is written** (a document property/metadata field, an email header, a footer marking string).
  This is the input to the mapping matrix.
- **Why required:** You cannot map or detect values you haven't enumerated; the detection method depends
  on *where* the source tool wrote the marking.
- **How to verify:** Obtain the source tool's classification list / reporting; confirm it enumerates the
  full set of values and, ideally, the metadata/marking each writes.
- **How to implement if missing:** Extract the value list from the source tool's admin console or a
  content sample before authoring the mapping. Capture at least one **example file/email per value** for
  detection testing.

## 2.4 Detectability confirmed per legacy value
- **Description:** For each legacy value, a confirmed answer to **"can Purview detect this?"** — i.e.
  whether the marking appears in **extractable content** (matchable by a keyword/regex custom SIT),
  in **document metadata Purview can index**, or in an **email x-header**, versus an opaque/proprietary
  store Purview cannot read.
- **Why required:** Detection precision is the whole migration risk. A value Purview cannot reliably
  detect cannot be reclassified automatically and must be handled another way (manual, or source-tool
  remediation first).
- **How to verify:** For a sample file/email per value, confirm the marking string or metadata is
  present in a way Purview can match; validate empirically in the **simulation** step. **Verify what
  your specific source tool writes** — common tools (e.g. Titus/Fortra, Boldon James, Janusseal, or a
  legacy Microsoft AIP client) differ, and the exact property/header names must be confirmed, never
  assumed.
- **How to implement if missing:** Where a value is undetectable, escalate: remediate at the source tool
  (re-stamp to a detectable form), plan manual re-labeling for that subset, or scope it out with owner
  sign-off.

## 2.5 Information Protection role (least privilege)
- **Description:** The Purview role group this solution needs: **Information Protection Admin** (create/
  manage sensitivity labels, label policies, auto-labeling policies) and **Compliance Administrator** or
  the appropriate role for **sensitive information types**. Global Administrator is **not** required for
  the migration work.
- **Why required:** The auto-labeling and SIT cmdlets (`New-AutoSensitivityLabelPolicy`,
  `New-AutoSensitivityLabelRule`, `Set-AutoSensitivityLabelPolicy`, and SIT management) are gated by
  these role groups.
- **How to verify:** Purview portal → **Roles & scopes → Permissions**; confirm membership in
  *Information Protection* (and the SIT-management role).
- **How to implement if missing:** Add the admin to the least-privilege role group under change control;
  wait for propagation before running cmdlets.

## 2.6 Security & Compliance PowerShell + Graph connectivity
- **Description:** A workstation with the **ExchangeOnlineManagement** module (providing
  `Connect-IPPSSession` for Security & Compliance PowerShell) and, where Graph is used for licensing/
  evidence, **Microsoft Graph PowerShell** — with a modern-auth / MFA-capable admin account.
- **Why required:** All five provided scripts and every configuration cmdlet run through
  `Connect-IPPSSession`.
- **How to verify:** `Connect-IPPSSession` succeeds and `Get-Label` / `Get-AutoSensitivityLabelPolicy`
  return without error.
- **How to implement if missing:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser`; confirm
  modern-auth sign-in. See the Global Requirements for the full toolchain.

## 2.7 A pilot scope and a simulation-first commitment
- **Description:** A named **pilot scope** — a limited set of SharePoint sites / OneDrive accounts /
  mailboxes to reclassify first — and an explicit commitment that **every reclassification auto-labeling
  policy is created in *simulation* mode** and its precision validated before it is enforced. Encrypting
  target labels are piloted before any broad enforcement.
- **Why required:** Reclassifying existing content (and especially applying encryption to it) is
  high-impact and hard to reverse cleanly; the house model requires a simulate/measure pass first.
- **How to verify:** Confirm the pilot locations, a change window, and a named approver; confirm the
  target labels are published to the pilot scope (§2.2).
- **How to implement if missing:** Define the pilot locations and agree the change-control path before
  configuring any auto-labeling.

## 2.8 A residual-marking reconciliation decision
- **Description:** A decision, per mapping, on what happens to the **old legacy marking** once the
  Purview label is applied — leave it in place, let the Purview label's own marking co-exist/overwrite,
  or plan a source-tool cleanup. And the plan for **decommissioning the source tool** once migration is
  complete.
- **Why required:** Without this, content ends up double-marked indefinitely, which confuses users and
  undermines the "one scheme" goal of the migration.
- **How to verify:** Confirm the reconciliation approach with the content/records owner and the source
  tool's admin; confirm whether the Purview label's content marking should replace the legacy footer.
- **How to implement if missing:** Agree the reconciliation and source-tool decommission plan before
  broad enforcement; capture it in the mapping matrix.
