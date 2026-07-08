# 2. Requirements Guide — Mandatory vs Recommended Labeling Policy Design

Verify **every** requirement below before starting the Implementation Guide. These are the
**solution-specific** prerequisites for designing and configuring label-policy behaviour (mandatory,
default, downgrade justification, recommended prompts); they build on the shared **Global Requirements
— Microsoft Purview Solutions** (licensing, least-privilege roles, Security & Compliance PowerShell +
Graph toolchain, in-scope workloads, compliance/records/legal stakeholders, and a pilot scope with
change control). Read the Global Requirements first; this guide does not repeat them.

> **Determination note.** *Which* populations must be mandated, *what* the enterprise default
> classification should be, and the downgrade rules are **information-governance determinations** owned
> by your compliance/security/records stakeholders — not technical defaults. This solution provides
> the **configuration method and evidence**; confirm the policy intent with the accountable owner
> before enforcing.

---

## 2.1 A published sensitivity-label taxonomy already exists
- **Description:** This solution designs the **policy behaviour** over labels; the **labels themselves** (e.g. `Public`, `General`, `Confidential \ All Employees`, `Highly Confidential`) must already be created and available. If they do not exist, build them first (the taxonomy/labels-implementation solution) — you cannot set a default label or a recommended prompt for a label that does not exist.
- **Why required:** `Set-LabelPolicy` default-label and the recommend prompt reference specific labels by name/GUID.
- **How to verify:** `Get-Label | Format-Table DisplayName,Name,Priority` returns the intended taxonomy; the labels appear in Purview → **Information Protection → Sensitivity labels**.
- **How to implement if missing:** Create the taxonomy first; return here once labels exist and are (or are about to be) published.

## 2.2 Licensing for labeling and recommended (client-side) labeling
- **Description:** Manual sensitivity labeling, mandatory labeling, default labels, and downgrade justification are available broadly (Microsoft 365 **E3** tier covers manual labeling and label policies). **Recommended / automatic client-side labeling in Office apps** — including the conditions that trigger a recommend prompt — requires **Microsoft 365 E5** or the **E5 Compliance** add-on for the advanced classifiers, though basic sensitive-info-type-based recommendations are broadly available. **Verify your licensing/tenant** — Microsoft's licensing tables are the authority.
- **Why required:** The recommended-labeling step will not work as designed without the plan the condition type requires.
- **How to verify:** M365 admin center → subscriptions/add-ons; confirm the label's *Auto-labeling for Office apps* page is available in the Purview portal.
- **How to implement if missing:** Assign/purchase the required plan for the pilot users before configuring recommended prompts; mandatory/default/downgrade still work at E3.

## 2.3 Information Protection role (least privilege)
- **Description:** The Purview role group this solution needs is **Information Protection Admin** (create/manage sensitivity **label policies** and the labels' auto-labeling settings). Global Administrator is **not** required for label-policy work.
- **Why required:** `Set-LabelPolicy`, `New-LabelPolicy`, and the label auto-labeling cmdlets/settings are gated by this role group.
- **How to verify:** Purview portal → **Roles & scopes → Permissions**; confirm the admin account is in *Information Protection* (or *Information Protection Admin*).
- **How to implement if missing:** Add the admin to the least-privilege role group under change control; wait for role propagation before running cmdlets.

## 2.4 Security & Compliance PowerShell connectivity
- **Description:** A workstation with the **ExchangeOnlineManagement** module (which provides `Connect-IPPSSession` for Security & Compliance PowerShell), with a modern-auth / MFA-capable admin account.
- **Why required:** All five provided scripts and every configuration cmdlet run through `Connect-IPPSSession`.
- **How to verify:** `Connect-IPPSSession` succeeds and `Get-LabelPolicy` returns without error.
- **How to implement if missing:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser`; confirm modern-auth sign-in. See the Global Requirements for the full toolchain.

## 2.5 A pilot ring and a pilot-policy commitment
- **Description:** A named **pilot ring** (a small group of users — the group backing `LabelPolicy – Pilot – Ring1`) to receive the mandatory/default/downgrade/recommend settings **first**, and an explicit commitment that these settings are validated on the pilot policy before they are applied to `LabelPolicy – Broad – AllUsers`. Because label-policy settings have **no simulation mode**, the pilot ring **is** the safety mechanism.
- **Why required:** Mandatory labeling and downgrade justification change every user's save/send experience; the pilot surfaces friction (send-blocking, ticket volume) before it hits everyone.
- **How to verify:** Confirm the pilot group membership, a change window, and an approver.
- **How to implement if missing:** Create the pilot group and agree the change-control path before configuring anything.

## 2.6 An agreed default classification and downgrade rule
- **Description:** A decision, from your governance owners, on the **enterprise default label** (the classification every new document/email should start at — commonly `General`, never a protected/encrypting label) and whether **downgrade/removal requires a justification** (and what the justification prompt should say).
- **Why required:** The default label is a real business decision — defaulting too high causes over-classification and encryption surprises; too low defeats the purpose. `Set-LabelPolicy` needs a specific label as the default.
- **How to verify:** Confirm the named default label and the downgrade decision with the accountable owner; confirm the default label is **non-encrypting** unless explicitly intended.
- **How to implement if missing:** Get the default-classification and downgrade decisions signed off before configuring the policy.

## 2.7 Per-app friction decisions (documents vs Outlook)
- **Description:** A decision on whether mandatory labeling applies **equally to documents and Outlook**, or whether **Outlook is relaxed** (many organisations disable *mandatory-in-Outlook* to avoid blocking email send, using the documented `DisableMandatoryInOutlook` advanced setting), and whether Outlook has its own **default label** (`OutlookDefaultLabel`).
- **Why required:** Blocking email send on every message drives the loudest adoption backlash; the per-app split is a common, deliberate design choice that this solution configures.
- **How to verify:** Confirm the documents-vs-Outlook mandatory decision and any Outlook-specific default with stakeholders.
- **How to implement if missing:** Decide the per-app behaviour before applying advanced settings; default to piloting mandatory on **documents** first, Outlook relaxed, then tighten if needed.
