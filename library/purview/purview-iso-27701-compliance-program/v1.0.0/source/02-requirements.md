# 2. Requirements Guide — Microsoft Purview ISO 27701 Compliance Program

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-purview.md` (licensing,
least-privilege roles, S&C PowerShell/Graph toolchain, in-scope data, compliance/records/privacy/legal
stakeholders, and a pilot scope with change control) — this guide adds the **ISO 27701-specific**
prerequisites and does not repeat the six.

## 2.1 Microsoft 365 + Purview compliance licensing (PIMS controls + Compliance Manager)
**Description:** Licensing that includes the capabilities the program uses. Sensitivity labels and
baseline DLP ship in **Microsoft 365 E3 / Business Premium**; **auto-labeling at rest, endpoint DLP,
trainable classifiers, advanced records, premium Compliance Manager assessments (including ISO 27701),
and Priva** require **Microsoft 365 E5** (or the **E5 Compliance** add-on / Priva licensing).
**Why:** The PIMS technical controls and the ISO 27701 assessment template are plan-gated.
**Verify:** M365 admin center → **Billing → Licenses**; confirm the **ISO 27701** template appears in
Purview → **Compliance Manager → Assessment templates**; run `ISO27701-Discovery.ps1`. **Verify your
licensing/tenant** — availability evolves and is cloud-dependent.
**Implement:** Assign the required plan/add-on before starting; confirm the assessment template and
Priva (if the DSR workflow will use it) are available.

## 2.2 Least-privilege Purview roles with privacy role separation
**Description:** Least-privilege roles to create labels, DLP, retention, and to read compliance posture
— e.g. **Compliance Administrator** (or **Information Protection Admin** + **Data Loss Prevention**),
**Records Management** for disposition, and **Compliance Manager** assessment roles — with
**HR/privacy-sensitive** roles (Insider Risk, Communication Compliance, Priva) held by **separate**
owners.
**Why:** Purview uses fine-grained role groups; a PIMS expects least privilege and separation of duties.
**Verify:** `https://purview.microsoft.com` → **Settings → Roles and scopes → Role groups**; confirm
membership and separation; capture it as `ISO 27701 Roles – Separation Evidence`.
**Implement:** Assign least-privilege role groups under change control; separate privacy-sensitive roles.

## 2.3 PIMS scope and controller/processor role decided
**Description:** The **scope of the PIMS** (which workloads/systems process PII) and whether the
organization acts as a **PII controller**, **PII processor**, or both for each processing activity —
because ISO 27701's control set differs by role.
**Why:** The control map and evidence depend on scope and role; controller and processor obligations
are not identical.
**Verify:** A scope statement and controller/processor determination exist per processing activity
(recorded as `ISO 27701 Scope – Record`), signed off by privacy/compliance/legal.
**Implement:** Convene privacy (DPO), compliance, and legal to set scope and roles **before** authoring
the control map (Implementation Step 2). **The determination is deferred** to those functions.

## 2.4 PII classification building blocks (sensitive-information types)
**Description:** The **personal-data / PII sensitive-information types** the program keys off (built-in
identity/health/financial SITs, EU/national identifiers, and any **custom SIT** for organization-
specific PII), decided so DLP and auto-labeling detect PII accurately.
**Why:** PIMS controls act on personal data; accurate detection is the basis of protection and evidence.
**Verify:** The relevant SITs are identified and available in the Purview portal; sample content tests
them.
**Implement:** Select the built-in PII SITs; build a custom SIT where a PII pattern is organization-
specific (Implementation Step 5).

## 2.5 Existing ISO 27001 ISMS (if any) identified
**Description:** Whether an **ISO/IEC 27001 ISMS** already exists (Compliance Manager assessment,
Statement of Applicability, existing labels/DLP/retention) so the PIMS **extends** it rather than
duplicating controls.
**Why:** ISO 27701 is an extension of ISO 27001; reusing existing controls avoids conflicting policies
and rework.
**Verify:** Any existing ISO 27001 assessment and reusable controls are identified.
**Implement:** Reference and reuse existing controls where present; only add the privacy-specific overlay.

## 2.6 Retention schedule for personal data captured
**Description:** The **retention schedule** for PII (how long each category is kept and the disposal
action) — sourced from records management, privacy, and legal, not guessed.
**Why:** ISO 27701 requires PII retention limitation and secure disposal; durations are records/legal
decisions.
**Verify:** A retention schedule source for PII exists with named approvers.
**Implement:** Obtain the schedule; configure `Retention Label - PII - Retention Limitation`
accordingly (Implementation Step 5). **Retention determinations are deferred** to records/privacy/legal.

## 2.7 DSR (data-subject-request) method decided
**Description:** How the organization will fulfil **data-subject requests** (access, correction,
erasure, portability) — **Microsoft Priva Subject Rights Requests** where licensed, or Purview
**eDiscovery/content search** as the locate method.
**Why:** ISO 27701 requires a method to meet PII-principal rights; Purview provides the locate/produce
tooling.
**Verify:** The chosen method is available (Priva licensing or eDiscovery) and a runbook owner is named.
**Implement:** Wire the method (Implementation Step 7). **Erasure/production decisions remain
privacy/legal.**

## 2.8 Audit logging enabled
**Description:** Microsoft Purview **audit** (unified audit log) is on — the accountability evidence
source for the PIMS.
**Why:** Accountability and evidence (management review, certification) read audit/activity data.
**Verify:** Purview → **Audit** returns results; run `ISO27701-EvidenceReport.ps1`.
**Implement:** Turn on auditing in the Purview **Audit** solution; allow time to populate.

## 2.9 Change control for enforce-mode changes
**Description:** A documented change-control / rollback process for switching DLP from audit to enforce,
turning auto-labeling out of simulation, or activating a retention policy that deletes PII.
**Why:** Enforce-mode DLP can block legitimate work; auto-labeling mistakes are user-visible; retention
deletion is irreversible.
**Verify:** A change ticket exists with an approver, a pilot scope, and a documented rollback.
**Implement:** Record the change, name `ISO 27701 - Pilot Scope`, define the rollback, and get approval
before enforcing.

---
## Checklist
- [ ] M365 + Purview licensing (E3/Business Premium for labels + basic DLP; **E5 / E5 Compliance** for advanced controls + ISO 27701 assessment + Priva) — `ISO27701-Discovery.ps1`
- [ ] Least-privilege Purview roles + privacy role separation — `ISO 27701 Roles – Separation Evidence`
- [ ] PIMS scope + controller/processor role decided (determination deferred) — `ISO 27701 Scope – Record`
- [ ] PII sensitive-information types identified (built-in + custom where needed)
- [ ] Existing ISO 27001 ISMS identified for reuse (extend, don't duplicate)
- [ ] PII retention schedule captured (records/privacy/legal)
- [ ] DSR method decided (Priva or eDiscovery/content search)
- [ ] Purview audit logging enabled — `ISO27701-EvidenceReport.ps1`
- [ ] Change control + rollback for enforce-mode / auto-labeling / retention deletion
