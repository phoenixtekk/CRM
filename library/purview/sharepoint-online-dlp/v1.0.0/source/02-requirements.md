# 2. Requirements Guide — SharePoint Online DLP (Microsoft Purview)

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-purview.md` (the six
shared requirements: compliance licensing, least-privilege Purview roles, the S&C PowerShell + Graph
toolchain, in-scope data sources, compliance/records/privacy/legal stakeholders, and a pilot scope with
change control) — those are referenced here, not repeated.

## 2.1 DLP licensing (E3 baseline; E5 for advanced)
**Description:** A tenant licensed for **Data Loss Prevention** for SharePoint/OneDrive — **Microsoft 365
E3** includes DLP for Exchange/SharePoint/OneDrive/Teams; some advanced DLP capabilities (certain
classifiers, richer conditions) require **E5 / E5 Compliance**. (Global Requirement 1.)
**Why:** Core content/sharing DLP works on E3; specific advanced conditions/classifiers are plan-gated.
**Verify:** M365 admin center → `Billing → Licenses`; in the Purview portal confirm **Data Loss
Prevention → Policies** is available. `DLPSPO-Check-Prereqs.ps1` reports the DLP signal. **Verify against
your own plan.**
**Implement:** Assign the required licensing; where an advanced capability is unavailable, scope to what
your plan supports and record the rest as **deferred**.

## 2.2 Least-privilege DLP/compliance role
**Description:** A least-privilege role that can manage DLP — **Compliance Administrator**,
**Compliance Data Administrator**, or the **DLP Compliance Management** role group — in the Purview
portal. Reserve **Global Administrator** for one-time enablement only. (Global Requirement 2.)
**Why:** Creating/editing DLP policies and rules requires the matching role; DLP enforcement is
high-impact, so least privilege matters.
**Verify:** Purview portal → `Settings → Roles & scopes → Permissions` shows the DLP/compliance role;
`Connect-IPPSSession` succeeds and `Get-DlpCompliancePolicy` runs.
**Implement:** Assign the least-privilege role under change control; do not use Global Administrator for
day-to-day DLP authoring.

## 2.3 Security & Compliance PowerShell toolchain
**Description:** A workstation with **ExchangeOnlineManagement** (provides `Connect-IPPSSession` for
`Get-/New-/Set-DlpCompliancePolicy` and `...Rule`, and `Get-DlpSensitiveInformationType`), with a
modern-auth / MFA admin. (Global Requirement 3.)
**Why:** DLP policies/rules and sensitive information types are read/authored through Security &
Compliance PowerShell; the provided scripts run there.
**Verify:** `Get-Module -ListAvailable ExchangeOnlineManagement`; `Connect-IPPSSession` succeeds and
`Get-DlpCompliancePolicy` returns. `DLPSPO-Check-Prereqs.ps1` reports module/connection state.
**Implement:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser`; confirm modern-auth sign-in
before running steps.

## 2.4 The sensitive content and sharing to govern (compliance owned)
**Description:** The **sensitive information types / sensitivity labels / keywords** the policy must
detect, and the **sharing actions** to govern (external sharing, "everyone" sharing, external access),
translated into rule conditions and owned/signed off by **compliance/security/privacy**. (Global
Requirements 4 & 5.)
**Why:** DLP acts on the content and actions you define; which content is sensitive and which sharing is
unacceptable is a business/compliance **determination**, not a technical default.
**Verify:** The in-scope sensitive info types/labels and the sharing conditions are documented and
approved; named approvers recorded in `DLP Scope – Map`.
**Implement:** Confirm the sensitive info types and sharing conditions before authoring rules; where the
determination is incomplete, run in **test mode** and defer enforcement until agreed.

## 2.5 In-scope SharePoint/OneDrive locations and a pilot scope
**Description:** The **SharePoint sites and OneDrive accounts in scope**, and a **limited pilot scope**
(`SPO DLP – Pilot Sites – Stage1`) to validate on before enforcing tenant-wide. (Global Requirements 4 &
6.)
**Why:** DLP keys off the in-scope locations; the wrong scope either misses content or over-blocks
collaboration.
**Verify:** `DLPSPO-Discover.ps1` reports existing policies and covered locations; confirm the intended
in-scope and pilot locations with SharePoint/compliance owners.
**Implement:** Enumerate the in-scope sites/accounts and define the pilot scope before configuring.

## 2.6 Test/simulation mode understood and used
**Description:** Understanding that DLP policies support **test mode** (test with policy tips / test
without policy tips) and **enforce** mode, and the discipline to **start in test mode** so the policy's
matches and would-be blocks are reviewed on real content before enforcement.
**Why:** DLP enforcement blocks real sharing; a mistuned policy generates help-desk tickets and blocks
legitimate work. Test mode reveals the impact first.
**Verify:** Confirm test mode is available (it is, for DLP) and that the plan starts in test mode;
`DLPSPO-Validate.ps1` reports the policy's current mode.
**Implement:** Create the policy in **test mode**; move to enforce only after validation and approval.

## 2.7 Notification/alert design and exceptions
**Description:** The **policy-tip text**, **user notification**, and **admin alert** design, plus the
**exceptions** (sites, groups, or conditions that should not match), agreed with stakeholders.
**Why:** Policy tips educate users and alerts drive response; well-chosen exceptions prevent
false-positive friction. These are part of a usable DLP policy, not an afterthought.
**Verify:** The tip text, notification/alert recipients, and exceptions are documented in
`DLP Scope – Map`.
**Implement:** Define the notifications and exceptions before enforcing; tune them during the test-mode
pilot.

---
## Checklist
- [ ] DLP licensing confirmed (E3 baseline; E5 for advanced classifiers/conditions, else deferred)
- [ ] Compliance/DLP-management role assigned least-privilege
- [ ] ExchangeOnlineManagement installed; `Connect-IPPSSession` succeeds; `Get-DlpCompliancePolicy` runs
- [ ] Sensitive info types/labels + sharing conditions to govern documented and approved
- [ ] In-scope SharePoint/OneDrive locations enumerated; `SPO DLP – Pilot Sites – Stage1` defined
- [ ] Test/simulation mode understood; plan **starts in test mode**
- [ ] Policy-tip text, notifications/alerts, and exceptions designed and captured in `DLP Scope – Map`
