# 2. Requirements Guide — Microsoft Purview for Manufacturing

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-purview.md` (licensing,
least-privilege roles, S&C PowerShell/Graph toolchain, in-scope data, compliance/records/legal
stakeholders, and a pilot scope with change control) — this guide adds the **Manufacturing-specific**
prerequisites and does not repeat the six.

## 2.1 Microsoft 365 + Purview compliance licensing (IP + CUI features)
**Description:** Licensing that includes the capabilities this program uses. Sensitivity labels and
baseline DLP ship in **Microsoft 365 E3 / Business Premium**; **auto-labeling at rest, endpoint DLP,
trainable classifiers, advanced records management, and Compliance Manager premium assessments**
require **Microsoft 365 E5** (or the **E5 Compliance / Information Protection & Governance** add-on).
DIB tenants often run in **GCC / GCC High** — confirm the CUI-appropriate cloud.
**Why:** The IP/CUI features here are plan-gated and cloud-gated; they will not appear without the
right plan (and, for CUI, often the government cloud).
**Verify:** M365 admin center → **Billing → Licenses**; confirm the feature is visible in the Purview
portal; run `PURVIEW-MFG-Discovery.ps1`. **Verify your licensing/tenant** — availability evolves.
**Implement:** Assign the required plan (E3/Business Premium for labels + basic DLP; **E5 or the E5
Compliance add-on** for auto-labeling at rest, endpoint DLP, trainable classifiers, advanced records,
Compliance Manager). Confirm the correct sovereign cloud with your compliance/legal team for CUI.

## 2.2 Least-privilege Purview roles
**Description:** The operator holds the least-privilege roles to create labels, DLP, retention, and to
read compliance posture — for example **Compliance Administrator** (or **Information Protection Admin**
plus **Data Loss Prevention** roles) and, for records/disposition, **Records Management**; **Compliance
Manager** read/assessment roles for the CMMC template.
**Why:** Purview uses fine-grained role groups; Global Administrator alone is not the least-privilege
choice.
**Verify:** `https://purview.microsoft.com` → **Settings → Roles and scopes → Role groups**; confirm
membership.
**Implement:** Assign the least-privilege role group under change control; reserve Global Administrator
for tenant-wide changes.

## 2.3 Manufacturing data classification decided (IP + CUI + export control)
**Description:** A one-page classification decision from the business: what is **IP** (designs, CAD/CAM,
process specs, formulas, BOMs, firmware/source), what is **CUI** (per the contract / DFARS 252.204-7012),
and what is **export-controlled** (**ITAR / EAR**) — feeding the label taxonomy this solution publishes.
**Why:** Labels, DLP conditions, and retention are business/legal decisions, not IT defaults; the
CUI and export-control determinations are made by compliance/legal/export-control, not by IT.
**Verify:** A named data owner exists per category and a marked CUI/export-control determination is
recorded (or explicitly deferred to the responsible function).
**Implement:** Convene data owners + compliance/legal/export-control to agree the categories and
markings **before** authoring policies (Implementation Step 1). **Determinations are deferred** to
those functions.

## 2.4 Custom classification building blocks (part/drawing numbers, CUI)
**Description:** The identifiers that flag Manufacturing IP — e.g. a **drawing/part-number pattern** —
captured so a **custom sensitive-information type (SIT)** can detect them, plus a decision on using the
**CUI trainable classifier / CUI SITs** (availability varies by plan/cloud — **verify your tenant**).
**Why:** Generic financial/PII detectors miss engineering IP; a custom SIT keyed to your part-number
format materially improves DLP and auto-labeling accuracy.
**Verify:** A sample of real part/drawing numbers and their format (regex-able) exists; confirm CUI
classifier availability in the Purview portal.
**Implement:** Provide sample identifiers so `SIT - MFG Part/Drawing Number` can be built
(Implementation Step 4); confirm CUI SIT/classifier availability before relying on it.

## 2.5 Pilot scope (users and, for endpoint DLP, devices)
**Description:** A Microsoft Entra security group of pilot users — engineering + a CUI/contracts
team — named `Purview - Manufacturing Pilot`, and, for endpoint DLP, **engineering workstations
onboarded to Microsoft Purview** (the same onboarding used by Defender for Endpoint).
**Why:** Every policy is piloted before rollout; DLP must run in audit on a pilot first, and endpoint
rules (copy to USB, print a drawing, upload to a browser) require onboarded devices.
**Verify:** Entra → **Groups** shows the group; Purview → **Settings → Device onboarding → Devices**
shows pilot devices (endpoint DLP only); run `PURVIEW-MFG-Discovery.ps1`.
**Implement:** Build the group with `PURVIEW-MFG-Set-ScopeTargeting.ps1`; onboard pilot engineering
devices via the Purview onboarding package (or Intune).

## 2.6 Supplier / external-sharing model agreed
**Description:** How drawings and specs are shared externally (OEMs, suppliers, contract
manufacturers) — the collaboration boundaries the labels/DLP must respect (e.g. **encrypt-and-restrict
to named partner domains**, block export-controlled data to unauthorized recipients).
**Why:** Manufacturing lives on external collaboration; protection that blocks legitimate supplier
sharing will be bypassed, while unrestricted sharing leaks IP/CUI.
**Verify:** A list of trusted partner domains and the allowed sharing pattern per label exists.
**Implement:** Capture partner domains and the per-label sharing rule with the business before
configuring label encryption and DLP recipient conditions.

## 2.7 Audit logging enabled
**Description:** Microsoft Purview **audit** (unified audit log) is on — the evidence source for DLP
tuning, CUI access, and CMMC audit-control evidence.
**Why:** DLP tuning, coverage reporting, and 800-171/CMMC audit evidence read audit/activity data.
**Verify:** Purview → **Audit**; searching returns results; run `PURVIEW-MFG-Report.ps1`.
**Implement:** Turn on auditing in the Purview **Audit** solution and allow time for events to
populate.

## 2.8 Records schedule & CMMC/NIST 800-171 requirements captured
**Description:** The **retention schedule** (quality records, contract/CUI records, export records)
and the **CMMC / NIST 800-171** control set the program must evidence — sourced from records
management, compliance, and the contract (DFARS), not guessed.
**Why:** Retention durations and records determinations are legal/records decisions; CMMC control
scope drives which Purview controls you evidence in Compliance Manager.
**Verify:** A records schedule source and the applicable CMMC level / 800-171 baseline are documented
with named approvers.
**Implement:** Obtain the schedule and control baseline from records/compliance; load the **NIST
800-171 / CMMC** assessment template in **Compliance Manager** (Implementation Step 10). **Retention
and records determinations are deferred** to records/compliance/legal.

## 2.9 Change control for enforce-mode changes
**Description:** A documented change-control / rollback process for switching any DLP policy from
audit to enforce, turning auto-labeling out of simulation, or activating a retention policy that
deletes content.
**Why:** Enforce-mode DLP can block engineering/supplier work; auto-labeling mistakes are user-visible;
retention deletion is irreversible.
**Verify:** A change ticket exists with an approver, a pilot scope, and a documented rollback.
**Implement:** Record the change, name the pilot scope, define the rollback, and get approval before
enforcing.

---
## Checklist
- [ ] M365 + Purview licensing (E3/Business Premium for labels + basic DLP; **E5 / E5 Compliance** for auto-labeling at rest, endpoint DLP, trainable classifiers, advanced records, Compliance Manager); correct sovereign cloud for CUI — `PURVIEW-MFG-Discovery.ps1`
- [ ] Least-privilege Purview roles assigned (Compliance Admin / Information Protection + DLP; Records Management)
- [ ] Manufacturing classification decided — IP / CUI / export-controlled (determinations by compliance/legal/export-control)
- [ ] Custom SIT identifiers (part/drawing numbers) supplied; CUI classifier availability confirmed
- [ ] Pilot group `Purview - Manufacturing Pilot` created; engineering devices onboarded (endpoint DLP) — `PURVIEW-MFG-Set-ScopeTargeting.ps1`
- [ ] Supplier / external-sharing model + trusted partner domains agreed
- [ ] Purview audit logging enabled — `PURVIEW-MFG-Report.ps1`
- [ ] Records schedule + CMMC/NIST 800-171 baseline captured (records/compliance)
- [ ] Change control + rollback for enforce-mode / auto-labeling / retention deletion
