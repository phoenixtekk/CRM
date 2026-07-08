# 2. Requirements Guide — Sensitivity Labeling for Power BI & Microsoft Fabric (Microsoft Purview)

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-purview.md` (the six
shared requirements: compliance licensing, least-privilege Purview roles, the S&C PowerShell + Graph
toolchain, in-scope data sources, compliance/records/privacy/legal stakeholders, and a pilot scope with
change control) — those are referenced here, not repeated.

## 2.1 Sensitivity-label entitlement plus Power BI Pro/PPU (or a capacity)
**Description:** A tenant licensed for **sensitivity labels** (Azure Information Protection P1/P2 —
included in Microsoft 365 E5 / E5 Compliance) **and** the users who create/consume labeled Power BI
content licensed for **Power BI Pro or Premium Per User**, or working in a **Premium/Fabric capacity**.
(Global Requirement 1.)
**Why:** Applying and enforcing sensitivity labels in Power BI/Fabric is gated on both the label
entitlement and the Power BI/Fabric licensing of the affected users.
**Verify:** M365 admin center → `Billing → Licenses` shows the AIP/label SKU and Power BI Pro/PPU (or a
capacity); `IPPBI-Check-Prereqs.ps1` reports the label and Power BI signals. **Verify against your own
plan.**
**Implement:** Assign the label entitlement and Power BI Pro/PPU (or assign the workspace to a capacity)
for the in-scope creators/consumers before enabling. Where unavailable, record affected capabilities as
**deferred**.

## 2.2 Least-privilege roles across Purview and Power BI/Fabric
**Description:** **Information Protection Admin** (or **Compliance Administrator**) to author/publish
sensitivity labels and label policies in Purview; a **Power BI administrator / Fabric administrator** to
configure the information-protection **tenant settings** in the Power BI/Fabric admin portal. Reserve
**Global Administrator** for one-time enablement only. (Global Requirement 2 — least privilege.)
**Why:** Labeling spans two surfaces — the label (Purview) and the analytics tenant settings (Power
BI/Fabric admin portal) — each with its own least-privilege role.
**Verify:** Purview portal → `Settings → Roles & scopes → Permissions` shows Information Protection Admin;
Power BI/Fabric admin portal access confirmed; `Connect-IPPSSession` succeeds.
**Implement:** Assign the least-privilege role on each surface under change control; do not use Global
Administrator for day-to-day label authoring.

## 2.3 Security & Compliance PowerShell + read-only Power BI toolchain
**Description:** A workstation with **ExchangeOnlineManagement** (provides `Connect-IPPSSession` for
`Get-Label` / `Get-LabelPolicy`) and, for read-only workspace inventory, the **MicrosoftPowerBIMgmt**
module (`Connect-PowerBIServiceAccount` / `Get-PowerBIWorkspace`), with a modern-auth / MFA admin.
(Global Requirement 3.)
**Why:** Labels/policies are read/authored through Security & Compliance PowerShell; workspace inventory
is read through the Power BI module; the provided scripts use both read-only where possible.
**Verify:** `Get-Module -ListAvailable ExchangeOnlineManagement, MicrosoftPowerBIMgmt`; the connect
cmdlets succeed. `IPPBI-Check-Prereqs.ps1` reports which modules/connections are present.
**Implement:** `Install-Module ExchangeOnlineManagement, MicrosoftPowerBIMgmt -Scope CurrentUser`; confirm
modern-auth sign-in before running steps.

## 2.4 Information-protection tenant settings available in the Power BI/Fabric admin portal
**Description:** The **information protection** section of the Power BI/Fabric **admin portal → Tenant
settings** must be available so you can enable **"Allow users to apply sensitivity labels for content"**,
**"Apply sensitivity labels from data sources to their data"** (source inheritance), **restrict content
that has protected/encrypted labels** (export behavior), and (later) mandatory labeling.
**Why:** These tenant settings — not a Purview policy — are what turn labeling, inheritance, and export
protection on for analytics.
**Verify:** In the Power BI/Fabric admin portal, open **Tenant settings → Information protection** and
confirm the settings are present and can be delegated to a security group. **Verify the exact setting
names against current Microsoft guidance for your tenant** — the analytics information-protection surface
is evolving.
**Implement:** Confirm availability for your licensing/tenant; complete any prerequisite Microsoft
documents (for example, that sensitivity labels are published and that AIP is enabled) before enabling.

## 2.5 A delegation security group and in-scope workspaces
**Description:** A **security group** (`BI Labeling – Enabled Users`) to which the information-protection
tenant settings are scoped, and the **in-scope Power BI/Fabric workspaces** where labeling applies —
starting with a **pilot workspace/group** before the estate.
**Why:** Tenant settings are best delegated to a group so labeling is enabled for the pilot first, not
tenant-wide on day one.
**Verify:** The security group exists and the intended pilot users/workspaces are members;
`IPPBI-Discover.ps1` reports the in-scope workspaces.
**Implement:** Create/populate the security group and confirm the pilot workspaces before enabling the
tenant settings.

## 2.6 Published sensitivity labels compatible with analytics
**Description:** The organizational sensitivity labels (`General`, `Confidential`, `Highly Confidential`
or your scheme) authored and **published** via a label policy (`Analytics Labels – Policy`) to the BI
creators, so they are available to apply in Power BI/Fabric.
**Why:** Power BI/Fabric consume published Purview labels; a label a creator can't see in the service
can't be applied.
**Verify:** `Get-Label` lists the labels; `Get-LabelPolicy` shows the policy publishing them to the
creators; the label picker appears in the Power BI service for a policy member. `IPPBI-Check-Prereqs.ps1`
confirms labels are present/published.
**Implement:** Publish the labels to the BI creators (Implementation Guide) before enabling analytics
labeling; pilot group first.

## 2.7 Labeled data sources for inheritance (where inheritance is in scope)
**Description:** For **source → content inheritance**, the upstream data sources whose labels should flow
into Power BI (for example labeled files, or database columns with sensitivity metadata) must actually
carry labels/classification.
**Why:** Inheritance only flows a label that exists on the source; unlabeled sources produce unlabeled
content regardless of the setting.
**Verify:** Confirm the in-scope sources are labeled/classified; `IPPBI-Discover.ps1` reports the tenant
setting state so you know inheritance is enabled.
**Implement:** Ensure the upstream sources are labeled (a separate labeling effort) where inheritance is
required; where sources are unlabeled, rely on artifact labeling and record inheritance as **partial**.

## 2.8 In-scope content, classification intent, stakeholders, and a pilot ring
**Description:** The **analytics content in scope**, the **classification intent** mapping content to
labels, engagement with **compliance, privacy, security, and data-governance** stakeholders (Global
Requirements 4 & 5), and a **pilot workspace/group** (`Analytics Labels – Pilot Ring – Stage1`) with
change control (Global Requirement 6).
**Why:** Which content gets which label is a business/classification decision; mandatory labeling and
export restrictions are high-impact and must be piloted before the estate.
**Verify:** In-scope content and the label mapping are agreed; named approvers recorded; the pilot
workspace/group and a change window exist.
**Implement:** Capture the classification intent and the pilot scope; agree change control before
enabling mandatory labeling or expanding beyond the pilot.

---
## Checklist
- [ ] Sensitivity-label entitlement (AIP/E5) + Power BI Pro/PPU (or capacity) confirmed for in-scope users
- [ ] Information Protection Admin (Purview) + Power BI/Fabric Administrator assigned least-privilege
- [ ] ExchangeOnlineManagement + MicrosoftPowerBIMgmt installed; `Connect-IPPSSession` succeeds
- [ ] Information-protection **tenant settings** available in the Power BI/Fabric admin portal (verified for your tenant)
- [ ] `BI Labeling – Enabled Users` security group + in-scope/pilot workspaces defined
- [ ] Sensitivity labels authored and `Analytics Labels – Policy` published to BI creators
- [ ] Labeled data sources confirmed where source inheritance is in scope (else recorded partial)
- [ ] In-scope content + label mapping agreed; stakeholders named; `Analytics Labels – Pilot Ring – Stage1` + change control
