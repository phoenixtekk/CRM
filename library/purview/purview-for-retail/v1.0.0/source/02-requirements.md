# 2. Requirements Guide — Microsoft Purview for Retail

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-purview.md` (the six
shared Purview requirements — licensing, roles, S&C PowerShell/Graph toolchain, in-scope data, the
compliance/records/privacy/legal stakeholders, and a pilot scope with change control). The entries
below are the **retail-/PCI-specific** additions on top of those.

## 2.1 Microsoft 365 + Purview compliance licensing (PCI/PII features)
**Description:** Licensing that covers the features this solution uses. Sensitivity labels and basic
DLP ship in **Microsoft 365 E3 / Business Premium**; **auto-labeling at rest, endpoint DLP, advanced
records management, and Compliance Manager premium assessment templates (including PCI-DSS)** require
**Microsoft 365 E5** or the **E5 Compliance** add-on.
**Why:** The PCI cardholder-data detection at scale (auto-labeling/endpoint DLP) and the PCI-DSS
Compliance Manager template are plan-gated; they will not appear without the higher plan.
**Verify:** M365 admin center → **Billing → Licenses**; confirm the PCI-DSS template is offered in
Purview → **Compliance Manager → Assessment templates**. Run `RETAIL-Discovery.ps1`. **Verify your
licensing/tenant** — availability evolves.
**Implement:** Assign E3/Business Premium for labels + basic DLP; add E5 or the E5 Compliance add-on
for auto-labeling at rest, endpoint DLP, and the PCI-DSS Compliance Manager template.

## 2.2 Least-privilege Purview roles
**Description:** The operator holds the least-privilege roles to create labels, DLP, and retention —
**Compliance Administrator** (or **Information Protection Admin** + **Data Loss Prevention** roles),
and **Compliance Manager** access for the PCI assessment. Global Administrator only where genuinely
required.
**Why:** Purview uses fine-grained role groups; configuration requires the matching role, and
least-privilege is a PCI-DSS control in itself.
**Verify:** `https://purview.microsoft.com` → **Settings → Roles and scopes → Role groups**; confirm
membership.
**Implement:** Assign the least-privilege role group under change control; reserve Global Administrator
for tenant-wide changes.

## 2.3 Retail data map and PCI-scope decision (owner-provided)
**Description:** A statement, from the compliance/QSA and data owners, of **what customer and payment
data exists**, where it lives, and **which systems are in PCI-DSS scope** — and the confirmation that
Microsoft 365 (Exchange/SharePoint/OneDrive/Teams/endpoints) is intended to be **out** of PCI scope
(no cardholder data stored there).
**Why:** DLP conditions and retention durations follow the retail data map and the scope decision, not
IT defaults; **the PCI-scope determination is a compliance/QSA decision**, not a technical one.
**Verify:** A one-page data map exists (data type → system → PCI in/out-of-scope → owner).
**Implement:** Work with compliance/QSA and data owners to capture the data map and the scope decision
before authoring policies.

## 2.4 Retail sensitivity-label taxonomy defined
**Description:** A short, agreed label set with a clear meaning for each — the taxonomy this solution
publishes: `Sensitivity Label - Retail Public`, `Sensitivity Label - Retail Internal`,
`Sensitivity Label - Customer PII - Confidential`, `Sensitivity Label - Cardholder Data - Restricted`.
**Why:** Labels only work if store, e-commerce, and head-office staff understand them; too many labels
confuse, too few under-protect.
**Verify:** A one-page taxonomy exists (label name, meaning, protection, who applies it).
**Implement:** Agree the 4-label taxonomy with data owners before configuring (Implementation Step 1).

## 2.5 Sensitive-information types confirmed (PAN + customer PII)
**Description:** The Purview **sensitive-information types (SITs)** the policies key off — the built-in
**Credit Card Number** SIT (Luhn-validated) for PAN, and the country PII SITs relevant to your
customers (for example national ID, passport, driver's licence, and address/email patterns).
**Why:** DLP and auto-labeling match on these SITs; the wrong SITs mean missed PAN or PII noise.
**Verify:** Purview → **Data classification → Sensitive info types**; confirm **Credit Card Number**
and the relevant country PII SITs exist. Run `RETAIL-Discovery.ps1`.
**Implement:** Use the built-in SITs; add custom SITs (for example a loyalty-ID pattern) only if a data
owner defines the pattern.

## 2.6 Pilot scope (users and, for endpoint DLP, devices)
**Description:** A Microsoft Entra security group of pilot users — `Purview - Retail Pilot` — and, for
endpoint DLP, retail workstations onboarded to Microsoft Purview.
**Why:** Every policy is piloted before rollout; PCI/PII DLP in particular must run in audit on a pilot
before it can block safely (a false block at a checkout or fulfilment desk is disruptive).
**Verify:** Entra → **Groups** — `Purview - Retail Pilot` exists. Purview → **Settings → Device
onboarding** shows pilot devices (endpoint DLP only). Run `RETAIL-Set-Scope.ps1`.
**Implement:** Build the pilot group with `RETAIL-Set-Scope.ps1`; onboard pilot devices via the Purview
device-onboarding package.

## 2.7 Endpoint onboarding (endpoint DLP only)
**Description:** Windows devices (for example back-office and head-office workstations that handle
customer exports) onboarded to Microsoft Purview so endpoint DLP can monitor file activity (copy to
USB, upload to a browser, print).
**Why:** Endpoint DLP conditions require onboarded devices; un-onboarded devices are invisible to it —
and endpoints are a common path for a customer-data or PAN export to leave.
**Verify:** Purview → **Settings → Device onboarding → Devices**. Run `RETAIL-Discovery.ps1`.
**Implement:** Deploy the onboarding configuration (Intune or the script package) to the pilot group.

## 2.8 Audit logging enabled
**Description:** Microsoft Purview audit (unified audit log) is on.
**Why:** DLP tuning, PCI evidence, and coverage reporting read audit/activity data; without it you
cannot review the audit gate or evidence controls.
**Verify:** Purview → **Audit**; a search returns results. Run `RETAIL-Report.ps1`.
**Implement:** Turn on auditing in the Purview **Audit** solution; allow time for events to populate.

## 2.9 Change control for enforce-mode and retention deletion
**Description:** A documented change-control / rollback process for switching any DLP policy from
audit to **block**, or for activating a retention policy that **deletes** retail records.
**Why:** A block at a retail operations desk can halt legitimate work and retention deletion is
irreversible; a pilot gate and rollback are mandatory.
**Verify:** A change ticket exists with an approver, the pilot scope, and a documented rollback (revert
DLP to test/audit; disable the retention policy).
**Implement:** Record the change, name the pilot scope, define the rollback, and get approval before
enforcing.

---
## Checklist
- [ ] M365 + Purview licensing (E3/Business Premium for labels + basic DLP; E5/E5 Compliance for auto-labeling at rest, endpoint DLP, PCI-DSS Compliance Manager) — `RETAIL-Discovery.ps1` · **verify your licensing/tenant**
- [ ] Least-privilege Purview roles assigned (Compliance Administrator / Information Protection + DLP; Compliance Manager)
- [ ] Retail data map + PCI-scope decision captured (owner/QSA-provided)
- [ ] Retail 4-label taxonomy defined
- [ ] Sensitive-info types confirmed — Credit Card Number (PAN) + relevant country PII — `RETAIL-Discovery.ps1`
- [ ] Pilot group `Purview - Retail Pilot` created — `RETAIL-Set-Scope.ps1`
- [ ] Endpoint devices onboarded (endpoint DLP only) — `RETAIL-Discovery.ps1`
- [ ] Purview audit logging enabled — `RETAIL-Report.ps1`
- [ ] Change control + rollback for enforce-mode / retention deletion
