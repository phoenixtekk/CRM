# 2. Requirements Guide — Source-Code & IP Protection DLP (Microsoft Purview)

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-purview.md` (the six
shared requirements: compliance licensing, least-privilege Purview roles, the S&C PowerShell + Graph
toolchain, in-scope data sources, compliance/records/privacy/legal stakeholders, and a pilot scope with
change control) — those are referenced here, not repeated.

## 2.1 DLP licensing (E3 baseline; E5 for Endpoint DLP + trainable classifiers)
**Description:** A tenant licensed for **Data Loss Prevention** — **Microsoft 365 E3** includes DLP for
Exchange/SharePoint/OneDrive/Teams; **Endpoint DLP** and **trainable classifiers** (including the
**Source Code** classifier) generally require **E5 / E5 Compliance**. (Global Requirement 1.)
**Why:** Cross-channel content DLP works on E3, but the endpoint (USB/upload) coverage and the Source Code
classifier that make this solution effective are plan-gated.
**Verify:** M365 admin center → `Billing → Licenses`; in the Purview portal confirm **DLP → Policies**,
**Endpoint DLP**, and the **Source Code** classifier are available. `DLPCODE-Check-Prereqs.ps1` reports the
DLP signal. **Verify against your own plan.**
**Implement:** Assign E5/E5 Compliance for the endpoint + classifier coverage; where unavailable, scope to
email/collaboration DLP with custom IP types and record endpoint/classifier coverage as **deferred**.

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
`Get-DlpCompliancePolicy` returns. `DLPCODE-Check-Prereqs.ps1` reports module/connection state.
**Implement:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser`; confirm modern-auth sign-in
before running steps.

## 2.4 Endpoint DLP device onboarding (for USB/upload coverage)
**Description:** For endpoint coverage (copy to USB/removable media, upload to personal cloud/unmanaged
browser), the in-scope devices must be **onboarded to Endpoint DLP** (onboarding is shared with Microsoft
Defender for Endpoint), and the relevant **egress activities** enabled in Purview **Endpoint DLP
settings**.
**Why:** Email/SharePoint DLP can't see a USB copy or a browser upload; Endpoint DLP requires onboarded
devices to observe and govern those actions.
**Verify:** Purview portal → **Settings → Endpoint DLP** shows onboarded devices and the egress-activity
settings; confirm the pilot devices are onboarded. **Verify the onboarding path against current Microsoft
guidance.**
**Implement:** Onboard the pilot devices to Endpoint DLP and enable the egress activities before authoring
the endpoint rule; where endpoint coverage is out of plan (2.1), record it **deferred**.

## 2.5 The Source Code classifier and custom IP detection (security/IP owned)
**Description:** The **detection design** — the built-in **Source Code trainable classifier** plus **custom
sensitive information types / keyword dictionaries** for project code-names, internal IP markings, and
proprietary identifiers — translated into rule conditions and owned/signed off by **security/IP/legal**.
(Global Requirements 4 & 5.)
**Why:** DLP acts on what you define as source code / IP; which content is protected IP is a
business/security **determination**, not a technical default.
**Verify:** The Source Code classifier is available; the custom IP types/dictionaries are documented and
approved; named approvers recorded in `Source-Code DLP – Map`. `DLPCODE-Discover.ps1` reports available
info types.
**Implement:** Confirm the classifier availability and author the custom IP types before enforcing; where
the determination is incomplete, run in **test mode** and defer enforcement.

## 2.6 In-scope channels, a pilot ring, and test-mode discipline
**Description:** The **channels in scope** (Exchange, SharePoint, OneDrive, Teams, Endpoint), a **pilot
ring** (`Source-Code DLP – Pilot Ring – Stage1`: a small set of developer users/devices), and the
discipline to **start in test mode**. (Global Requirements 4 & 6.)
**Why:** DLP keys off channels and scope; enforcement blocks real developer workflow. Prove the policy in
test mode on a pilot ring before enforcing tenant-wide.
**Verify:** The in-scope channels and pilot ring are agreed; `DLPCODE-Validate.ps1` reports the policy's
mode; a change window exists.
**Implement:** Define the channels and pilot ring; create the policy in **test mode**; move to enforce only
after validation and approval.

## 2.7 Notification/alert design and exceptions (approved egress)
**Description:** The **policy-tip text**, **user notification**, and **admin alert** design, plus the
**exceptions** — approved repositories, developer tools, partner-sharing paths, and build systems that must
not be blocked — agreed with stakeholders.
**Why:** Policy tips educate and alerts drive response; well-chosen exceptions keep legitimate developer
workflow from being blocked. These are essential to a usable code/IP DLP policy.
**Verify:** The tip text, notification/alert recipients, and the approved-egress exceptions are documented
in `Source-Code DLP – Map`.
**Implement:** Define notifications and exceptions before enforcing; tune them during the test-mode pilot.

---
## Checklist
- [ ] DLP licensing confirmed (E3 baseline; E5/E5 Compliance for Endpoint DLP + Source Code classifier, else deferred)
- [ ] Compliance/DLP-management role assigned least-privilege
- [ ] ExchangeOnlineManagement installed; `Connect-IPPSSession` succeeds; `Get-DlpCompliancePolicy` runs
- [ ] Endpoint DLP device onboarding + egress-activity settings in place for pilot devices (or deferred)
- [ ] Source Code classifier available; custom IP types/dictionaries documented and approved
- [ ] In-scope channels + `Source-Code DLP – Pilot Ring – Stage1` defined; plan **starts in test mode**
- [ ] Policy-tip text, notifications/alerts, and approved-egress exceptions captured in `Source-Code DLP – Map`
