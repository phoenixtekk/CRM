# 2. Requirements Guide — Automatic Sensitivity Labeling at Scale

Verify **every** requirement below before starting the Implementation Guide. These are the
**solution-specific** prerequisites for standing up automatic sensitivity labeling; they build on the
shared **Global Requirements — Microsoft Purview Solutions** (compliance licensing, least-privilege
roles, Security & Compliance PowerShell + Graph toolchain, in-scope workloads, compliance/records/legal
stakeholders, and a pilot scope with change control). Read the Global Requirements first; this guide
does not repeat them.

> **Deferral note.** *Which* content is sensitive, and *which* label it should carry, is a
> **classification/records determination** owned by your compliance, records, privacy, and data owners
> — not a technical default. This solution provides the **method to apply labels accurately and at
> scale, and the evidence** that it does; it does not decide the classification scheme.

---

## 2.1 Sensitivity labels already exist and are published *(hard prerequisite)*
- **Description:** The labels you intend to auto-apply (e.g. `Confidential \ All Employees`) must already be **created and published** to users via a sensitivity label policy, with any encryption/content-marking already configured and validated. This solution automates the *application* of existing labels — it does not create the taxonomy.
- **Why required:** An auto-labeling policy can only apply a label that exists; if the label encrypts, that protection must already be proven to enforce before you apply it at scale.
- **How to verify:** `Get-Label` lists the target label; `Get-LabelPolicy` shows it is published; a user can see and manually apply it in Office.
- **How to implement if missing:** Design, build, and publish the label taxonomy first (a separate labels-implementation effort). Do not proceed until the target labels exist and — if they encrypt — encryption is proven to enforce.

## 2.2 Licensing for automatic labeling (E5 / E5 Compliance)
- **Description:** **Automatic** sensitivity labeling — **client-side** automatic labeling in Office apps **and** **service-side** auto-labeling for SharePoint/OneDrive/Exchange — is a **premium** capability that typically requires **Microsoft 365 E5** or the **E5 Compliance** add-on. Manual labeling is available more broadly; the automation in this solution is E5-tier.
- **Why required:** The auto-labeling policies and client-side auto-labeling conditions in this solution are not available without the right plan.
- **How to verify:** M365 admin center → subscriptions/add-ons; confirm **Information Protection → Auto-labeling** is visible in the Purview portal and that `New-AutoSensitivityLabelPolicy` is available in Security & Compliance PowerShell. **Verify your licensing/tenant** — Microsoft's licensing tables are the authority.
- **How to implement if missing:** Assign/purchase E5 or E5 Compliance for at least the pilot population before configuring auto-labeling.

## 2.3 Information Protection role (least privilege)
- **Description:** The Purview role group this solution needs is **Information Protection Admin** (create/manage sensitivity labels, label policies, and **auto-labeling** policies/rules). Read-only assessment needs **Information Protection Reader** or **Information Protection Analyst**. Global Administrator is **not** required for day-to-day auto-labeling work.
- **Why required:** The auto-labeling cmdlets (`New-AutoSensitivityLabelPolicy`, `New-AutoSensitivityLabelRule`, `Set-AutoSensitivityLabelPolicy`) and `Set-Label` are gated by this role group.
- **How to verify:** Purview portal → **Roles & scopes → Permissions**; confirm the admin account is in *Information Protection* (or *Information Protection Admin*).
- **How to implement if missing:** Add the admin to the least-privilege role group under change control; wait for role propagation before running cmdlets.

## 2.4 Security & Compliance PowerShell connectivity
- **Description:** A workstation with the **ExchangeOnlineManagement** module (which provides `Connect-IPPSSession` for Security & Compliance PowerShell) and, where Graph is used for evidence, **Microsoft Graph PowerShell** — with a modern-auth / MFA-capable admin account.
- **Why required:** All five provided scripts and every configuration cmdlet run through `Connect-IPPSSession`.
- **How to verify:** `Connect-IPPSSession` succeeds and `Get-AutoSensitivityLabelPolicy` returns without error.
- **How to implement if missing:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser`; confirm modern-auth sign-in. See the Global Requirements for the full toolchain.

## 2.5 A classification scheme and the match conditions
- **Description:** An agreed **classification scheme** that maps *what makes content sensitive* to a label — the **sensitive information types (SITs)**, **keywords**, or **trainable classifiers** that will drive each auto-labeling rule, and the **minimum instance count / confidence** thresholds. For example: "apply `Confidential \ All Employees` where content contains ≥ N instances of a financial-account SIT."
- **Why required:** Auto-labeling precision is entirely a function of the rule conditions; without an agreed scheme the policy is arbitrary and will misfire.
- **How to verify:** Confirm the priority SITs/classifiers exist in Purview → **Data classification → Sensitive info types / Trainable classifiers**; agree the thresholds with the data owner.
- **How to implement if missing:** Define the conditions and thresholds (and create any custom SITs/classifiers) before authoring rules. Prefer a small number of high-precision conditions to start.

## 2.6 In-scope workloads and a pilot location subset
- **Description:** The **workloads in scope** (SharePoint, OneDrive, Exchange for service-side; the Office apps for client-side) and a **pilot location subset** — a named set of sites/mailboxes to enforce on first before expanding to `All`. Service-side auto-labeling location scoping can also use **adaptive scopes** where available (**verify your licensing/tenant**).
- **Why required:** Enforcing across the whole tenant at once removes the ability to catch problems cheaply; the house model enforces on a subset first, then expands *at scale*.
- **How to verify:** Confirm the in-scope workloads and the pilot site/mailbox subset with stakeholders.
- **How to implement if missing:** Identify the pilot locations (and the eventual full scope) before creating policies.

## 2.7 A simulation-first commitment and change control
- **Description:** An explicit commitment that **every service-side auto-labeling policy is created in simulation** (`TestWithoutNotifications`), reviewed for precision with the data owner, and only enforced after sign-off — and that **enforcement expands by location** (pilot subset → tenant) under a change window.
- **Why required:** Auto-labeling at scale is high-impact and (where the label encrypts) hard to reverse cleanly; simulation and staged expansion are the safety controls.
- **How to verify:** Confirm the data owner who will review the simulation match set, the false-positive threshold, a change window, and an approver.
- **How to implement if missing:** Agree the review owner, threshold, and change-control path before creating any policy.

## 2.8 Behavior toward existing / manually-set labels agreed
- **Description:** A decision on how auto-labeling should behave toward content that **already carries a label** — by default the service does not lower or override a higher-priority label a user set manually, but the treatment of existing labels is configurable and **tenant/version-sensitive**.
- **Why required:** The wrong setting can silently overwrite deliberate manual classification (or fail to upgrade obviously-sensitive content) — both erode trust and must be a conscious choice, confirmed in simulation.
- **How to verify:** Confirm the intended behavior with the data owner; **verify the current setting/behavior in your tenant** and observe it in the simulation results before enforcing.
- **How to implement if missing:** Decide and document the intended behavior; validate it against the simulation match set (Testing Guide) before enforcement.
