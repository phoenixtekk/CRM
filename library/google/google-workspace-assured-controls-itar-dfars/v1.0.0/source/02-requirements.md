# 2. Requirements Guide — Regulated Google Workspace: Assured Controls, ITAR & DFARS

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-google.md`.

> **Vendor boundary.** Google Workspace Admin console paths are authored from Google's current public
> documentation. **Assured Controls / Access Management policy options and edition gating are
> contract-/edition-dependent and evolve** — confirm exactly what applies to *your* licensing.
> Anything not confirmable from public documentation is flagged **"verify in your tenant."**

> **Regulatory interpretation is deferred to legal / compliance.** The requirements below are
> **technical prerequisites**. Which controlled-data categories apply and whether a control set is
> sufficient are **legal/compliance determinations** — see requirement 2.2.

## 2.1 Assured Controls / Assured Controls Plus add-on on a qualifying edition
**Description:** The **Google Workspace Assured Controls** (or **Assured Controls Plus**) paid add-on,
on **Frontline Plus or Enterprise Plus**, licensed for the users/OUs in scope for controlled data.
**Why:** Access Management, Access Approvals, and the bundled compliance/reporting features require the
add-on; policies apply **only to users in OUs that hold the license**. **Access Management** in
particular requires **Assured Controls Plus** (or legacy Assured Controls purchased before the cutover
Google documents) — *verify which SKU carries each feature for your contract.*
**Verify:** Admin console (`https://admin.google.com`) → **Billing → Subscriptions**; confirm the
Assured Controls / Assured Controls Plus add-on and the base edition (Frontline Plus / Enterprise Plus)
and license counts. *(Verify in your tenant — SKU-to-feature mapping evolves.)*
**Implement:** **Contact Google Workspace sales** or an authorized reseller to acquire the add-on and
qualifying base edition for the controlled-data population; do **not** assume it is bundled.

## 2.2 Compliance / legal / export-control stakeholders and requirements (the interpretation owners)
**Description:** Engagement with **legal / export-compliance**, **security (CISO)**, and
**data-governance** owners who define which regime(s) apply (ITAR, DFARS/NIST 800-171, CJIS,
IRS 1075, internal policy), which data is in scope, and which Access-Management / residency posture is
**required** — and who **sign off** that the technical configuration is sufficient.
**Why:** This solution provides configuration and evidence, **not** legal determinations. The required
data region, the required Access-Management policy (e.g. U.S.-only vs CJIS/IRS-1075), and whether CSE's
ITAR carve-out is being relied upon are **their** decisions, not technical defaults.
**Verify:** Named owners exist; the applicable regime(s), in-scope data categories, and the required
control posture are documented and approved.
**Implement:** Identify the owners and obtain the written control requirements **before** configuring;
record who approves the pilot exit and the fleet expansion (global requirement 6).

## 2.3 Data classification / controlled-data scope
**Description:** A defined mapping of **which users, OUs, and data** are controlled (CUI /
export-controlled / regulated) versus general, so residency and access controls target the right scope.
**Why:** Applying U.S.-residency and U.S.-only-support policies to *everyone* is unnecessary and
disruptive; applying them too narrowly leaves controlled data exposed. The scope decision drives the OU
design.
**Verify:** A data-classification/scope document exists and maps to OUs/groups; run
`GWREG-Discovery.ps1` to see current residency/CSE/OU posture as a baseline.
**Implement:** Work with the stakeholders in 2.2 to classify data and map it to a controlled-data OU
structure; stage the OU targeting with `GWREG-Set-ScopeTargeting.ps1` before applying controls.

## 2.4 Data-regions capability for residency
**Description:** The **Data regions** capability (fundamental data regions, plus **Advanced settings**
for per-OU/group control), available with **Frontline Plus, Enterprise Plus, or the Data Regions
add-on**.
**Why:** Residency (data at rest = **United States** for ITAR/DFARS, typically) is configured here;
Advanced settings let you control cross-region processing per OU/group.
**Verify:** Admin console → **Data → Compliance → Data regions**; confirm the page is present and
**Advanced settings** is available. *(Advanced settings require the qualifying edition/add-on — verify
in your tenant.)*
**Implement:** Ensure the qualifying edition/add-on is licensed; assign the operator the compliance/data
admin privileges to edit data regions.

## 2.5 Client-Side Encryption (CSE) readiness — only if relied upon (legal-gated)
**Description:** If your compliance team relies on the **ITAR end-to-end-encryption carve-out**, a
configured **CSE** setup: an external key service / IdP for CSE, enabled per-service, scoped to the
controlled OUs.
**Why:** Google positions Workspace CSE, properly configured, as usable to meet the ITAR e2ee carve-out
([Google Cloud — ITAR][itar]) — but this is a **legal interpretation**. CSE also affects functionality
(some features cannot read CSE content), so scope must be deliberate.
**Verify:** Admin console → **Data → Compliance → Client-side encryption**; confirm the key
service/IdP and which services are CSE-enabled. *(Whether CSE is required is a legal decision — 2.2.)*
**Implement:** Only if legal requires it: stand up the CSE key service/IdP per Google's CSE
documentation, then enable CSE for the controlled OUs. Defer key-service internals to the vendor's docs.

## 2.6 Super-admin / scoped admin access for the compliance surfaces
**Description:** The operator holds the roles to configure **Access Management, Access Approvals, Data
regions, and CSE** — these live under **Data → Compliance** and require **super administrator** access
for Access Management ([Google — Access Management][am]).
**Why:** These compliance controls are high-impact and gated to super-admin (Access Management) or
scoped compliance-admin roles.
**Verify:** Admin console → **Account → Admin roles**; confirm super-admin (for Access Management) and
compliance/data privileges (Data regions, Access Approvals, CSE).
**Implement:** Assign the least-privilege roles for each surface; reserve super-admin for the
Access-Management change and record who holds it.

## 2.7 Pilot scope (controlled-data OU or group) and change control
**Description:** A **pilot OU or group** of representative controlled-data users
(e.g. `Regulated Workspace – Controlled Data – Pilot`) and a documented **change/rollback** process for
residency, access, and CSE changes.
**Why:** Every control is validated on a small, curated scope before fleet expansion; residency and CSE
changes are high-impact and must be reversible under change control (global requirement 5).
**Verify:** Admin console → **Directory → Organizational units** (or **Groups**); the pilot scope
exists. Or run `GWREG-Set-ScopeTargeting.ps1`.
**Implement:** Create the pilot OU/group (with `GWREG-Set-ScopeTargeting.ps1` or Admin console →
**Directory**), add a few representative controlled-data users, and agree the change window/rollback
with the owners in 2.2.

## 2.8 Evidence / audit destination
**Description:** A defined destination and cadence for the **evidence** this solution produces —
Access Transparency logs, compliance data exports, and policy-compliance log events — to satisfy
auditors.
**Why:** Controlled-data programs must **demonstrate** coverage, not just configure it; the evidence
must be collected and retained.
**Verify:** Confirm where Access Transparency / policy-compliance log events are reviewed
(Admin console reporting, or exported to your SIEM/evidence store) and the retention requirement.
**Implement:** Define the export/retention path; `GWREG-Report.ps1` compiles a coverage/evidence report
you can attach to the audit record.

---
## Checklist
- [ ] Assured Controls / Assured Controls Plus add-on on Frontline Plus / Enterprise Plus licensed for the controlled scope (verify SKU-to-feature)
- [ ] Legal/export-compliance + security stakeholders named; applicable regime, in-scope data, and required posture documented **and approved**
- [ ] Data classification / controlled-data scope mapped to OUs — baseline via `GWREG-Discovery.ps1`
- [ ] Data regions capability (Advanced settings) available for residency
- [ ] CSE readiness confirmed **only if** legal relies on the ITAR e2ee carve-out
- [ ] Admin roles assigned (super-admin for Access Management; compliance/data for Data regions, Access Approvals, CSE)
- [ ] `Regulated Workspace – Controlled Data – Pilot` scope created; change control / rollback documented
- [ ] Evidence/audit destination and retention defined

---
[am]: https://support.google.com/a/answer/10343878 "Access Management — Google Workspace Admin Help"
[itar]: https://cloud.google.com/security/compliance/itar "International Traffic in Arms Regulations (ITAR) — Google Cloud"
