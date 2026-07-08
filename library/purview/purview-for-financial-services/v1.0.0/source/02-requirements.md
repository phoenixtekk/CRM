# 2. Requirements Guide — Microsoft Purview for Financial Services

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-purview.md` (the six
shared Purview requirements) — this guide names the **Financial Services-specific** licensing, roles,
scope, and stakeholders and does not repeat the six.

> **Determination boundary.** Requirements that name a regulation (FINRA/SEC/GLBA) describe the
> **technical prerequisite**, not the regulatory obligation. The applicability, the record set, the
> retention periods, and the supervision scheme are **compliance/records/privacy/legal
> determinations** — capture them from those owners; do not infer them here.

## 2.1 Microsoft 365 + Purview licensing for the FS capabilities
**Description:** Licensing that covers all four capabilities this program uses. Sensitivity labels and
basic DLP are in Microsoft 365 E3 / Business Premium; **auto-labeling at rest, endpoint DLP, records
management, communication compliance, and Audit (Premium)** require **Microsoft 365 E5** or the **E5
Compliance** add-on.
**Why:** The FS capabilities (auto-labeling NPI at rest, endpoint DLP, regulatory records,
communication compliance) are plan-gated and will not appear without the higher plan.
**Verify:** Microsoft 365 admin center → **Billing → Licenses**; confirm the feature is visible in the
Purview portal; run `FS-Purview-Discovery.ps1`.
**Implement:** Assign the required plan before starting; **verify your tenant** — availability evolves.

## 2.2 Least-privilege Purview roles, with role separation for communication compliance
**Description:** The operator holds the least-privilege roles for each capability — for example
**Compliance Administrator** (or **Information Protection Admin** + **Data Loss Prevention**),
**Records Management**, and for supervision the **Communication Compliance** role groups. Communication
compliance MUST use **separated roles**: *Communication Compliance Admins* (configure), *Analysts*
(triage pseudonymized alerts), and *Investigators* (resolve cases) held by **different** people.
**Why:** Purview uses fine-grained role groups; supervision is HR/privacy-sensitive and its roles must
be separated so no single person configures policy, triages, and investigates.
**Verify:** `https://purview.microsoft.com` → **Settings → Roles and scopes → Role groups**; confirm
membership and that the three communication-compliance roles are held by different people.
**Implement:** Assign the least-privilege role groups under change control; separate the three
communication-compliance roles. Reserve Global Administrator for tenant-wide changes only.

## 2.3 FS sensitivity-label taxonomy defined (NPI / MNPI)
**Description:** A short, agreed set of labels with clear meaning — the taxonomy this solution
publishes: `Sensitivity Label - FS Public`, `Sensitivity Label - FS Internal`,
`Sensitivity Label - FS Confidential (NPI/GLBA)`, `Sensitivity Label - FS Restricted (MNPI)`.
**Why:** Labels only work if users understand them; NPI (GLBA nonpublic personal information) and MNPI
(material nonpublic information) need distinct handling and the taxonomy must say so.
**Verify:** A one-page taxonomy exists (label name, meaning, protection, who applies it).
**Implement:** Agree a 3–5 label taxonomy with data owners and compliance before configuring
(Implementation Step 1).

## 2.4 Records schedule and supervision scheme from compliance/records/legal
**Description:** The **record set and retention schedule** (which communications and books-and-records,
kept how long, disposed how) and the **supervision scheme** (which communications are reviewed, by
whom, with what lexicons) — supplied by the compliance, records, and legal owners.
**Why:** Retention durations, regulatory-record declarations, Preservation Lock, and the communication-
compliance policy are **business/legal decisions**, not IT defaults; without them the configuration
will be wrong or over-reaching. Example anchors the firm's owners may reference — **FINRA Rule 4511 /
SEC Rule 17a-4** (broker-dealer books & records), **SEC Rule 204-2** (investment-adviser records),
**FINRA Rule 3110** (supervision), **GLBA / Reg S-P** (protection of NPI) — *cited for context only;
applicability and periods are the firm's determination.*
**Verify:** A named owner and a written schedule/supervision requirement exist per record category.
**Implement:** Obtain the schedule and supervision requirement from the owners; capture the source so
it is defensible. Do **not** apply Preservation Lock until this is signed off.

## 2.5 In-scope workloads and data sources
**Description:** The **workloads** in scope for FS data — Exchange, SharePoint, OneDrive, Teams, and
endpoints — and the customer/financial data types that drive labels, DLP, and retention (NPI, account
data, MNPI).
**Why:** Purview policies key off the in-scope workloads and the classification scheme.
**Verify:** Confirm the in-scope workloads and the financial data types with stakeholders; run
`FS-Purview-Discovery.ps1` for what exists today.
**Implement:** Define scope and the FS classification intent before authoring policies.

## 2.6 Pilot scope (users and, for endpoint DLP, devices)
**Description:** A Microsoft Entra security group `Purview - FS Pilot Users` for label/DLP/retention/
supervision piloting and — for endpoint DLP — devices onboarded to Microsoft Purview.
**Why:** Every policy is piloted before firm-wide rollout; DLP and supervision in particular must run
in audit/limited-pilot first.
**Verify:** Entra → **Groups** — `Purview - FS Pilot Users` exists; Purview → **Settings → Device
onboarding** shows pilot devices onboarded (endpoint DLP only).
**Implement:** Build the pilot group with `FS-Purview-Set-ScopeTargeting.ps1`; onboard pilot devices
via the Purview device-onboarding package.

## 2.7 Audit logging enabled
**Description:** Microsoft Purview audit (unified audit log) is on.
**Why:** DLP tuning, records evidence, supervision, and coverage reporting read audit/activity data.
**Verify:** Purview → **Audit** returns results; run `FS-Purview-Report.ps1`.
**Implement:** Turn on auditing in the Purview **Audit** solution; allow time for events to populate.

## 2.8 Change control — enforce, records lock, and supervision
**Description:** A documented change-control / rollback process for (a) switching any DLP policy from
audit to enforce, (b) declaring a **regulatory record** or applying **Preservation Lock**, and (c)
activating a communication-compliance policy.
**Why:** Enforce-mode DLP can block work; **Preservation Lock is effectively irreversible**;
supervision is HR/privacy-sensitive. Each needs a pilot gate, named approver, and rollback.
**Verify:** A change ticket exists per change with an approver, pilot scope, and rollback (revert DLP
to test; **note that a locked retention policy cannot be rolled back**; disable the supervision
policy).
**Implement:** Record the change, name the pilot scope, define the rollback, and get approval —
especially records/legal sign-off before any Preservation Lock.

---
## Checklist
- [ ] M365 + Purview licensing (E5 / E5 Compliance for auto-labeling, endpoint DLP, records, comms compliance) — `FS-Purview-Discovery.ps1`
- [ ] Least-privilege roles assigned; communication-compliance roles **separated** (Admin/Analyst/Investigator)
- [ ] FS label taxonomy defined (Public / Internal / Confidential-NPI / Restricted-MNPI)
- [ ] Records schedule + supervision scheme obtained from compliance/records/legal (periods/applicability = their determination)
- [ ] In-scope workloads + FS data types confirmed
- [ ] Pilot group `Purview - FS Pilot Users` created — `FS-Purview-Set-ScopeTargeting.ps1`
- [ ] Endpoint devices onboarded (endpoint DLP only)
- [ ] Purview audit logging enabled — `FS-Purview-Report.ps1`
- [ ] Change control + rollback for enforce / records-lock / supervision (records+legal sign-off before Preservation Lock)
