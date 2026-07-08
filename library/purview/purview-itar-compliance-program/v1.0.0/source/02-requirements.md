# 2. Requirements Guide — Microsoft Purview ITAR Compliance Program

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-purview.md` (licensing,
least-privilege roles, S&C PowerShell/Graph toolchain, in-scope data, compliance/records/legal
stakeholders, and a pilot scope with change control) — this guide adds the **ITAR-specific**
prerequisites and does not repeat the six.

## 2.1 Microsoft 365 + Purview licensing and a U.S. sovereign cloud (GCC High)
**Description:** Licensing that includes the capabilities the program uses — labels + baseline DLP in
**E3 / Business Premium**; **auto-labeling at rest, endpoint DLP, trainable classifiers, advanced
records, premium Compliance Manager** in **E5 / E5 Compliance** — **and** the appropriate **U.S.
sovereign cloud (typically GCC High)** for ITAR technical data.
**Why:** The advanced controls are plan-gated; ITAR data generally must reside in a U.S.-person-operated
sovereign cloud (GCC High), a legal/tenant determination.
**Verify:** M365 admin center → **Billing → Licenses**; confirm the cloud/tenant (GCC High) with
export-control/legal; run `ITAR-Discovery.ps1`. **Verify your licensing/tenant** — availability and cloud
are determinative.
**Implement:** Assign the required plan; confirm the correct sovereign cloud with export-control/legal
**before** placing ITAR data. **The cloud/tenant determination is deferred** to those functions.

## 2.2 Least-privilege Purview roles with export-control role separation
**Description:** Least-privilege roles to create labels, DLP, retention, and read posture — e.g.
**Compliance Administrator** (or **Information Protection Admin** + **Data Loss Prevention**), **Records
Management**, and **Compliance Manager** roles — held by **authorized U.S. persons** where they can
access technical data, with HR/privacy-sensitive roles separated.
**Why:** Purview uses fine-grained role groups; ITAR expects least privilege and that persons with access
to technical data are authorized U.S. persons.
**Verify:** `https://purview.microsoft.com` → **Settings → Roles and scopes → Role groups**; confirm
membership and that access-bearing roles are held by authorized U.S. persons; capture as `ITAR Roles –
Separation Evidence`.
**Implement:** Assign least-privilege role groups under change control; the **U.S.-person determination
for role holders is an export-control/HR determination**, deferred.

## 2.3 ITAR/USML scope and authorized-U.S.-person list decided
**Description:** A determination of **what technical data is ITAR/USML-controlled** (which categories,
programs, documents) and **who the authorized U.S. persons** are — the two inputs that drive the label's
permissions and the DLP recipient conditions.
**Why:** The label encryption (restrict to authorized U.S. persons) and DLP hard-block depend on knowing
what is controlled and who may access it; both are export-control determinations, not IT defaults.
**Verify:** A scope statement (controlled data categories) and an authorized-U.S.-person list exist,
recorded as `ITAR Scope – Record`, signed off by export-control/legal.
**Implement:** Convene export-control, legal, and program owners to set scope and the authorized-person
list **before** authoring policies (Implementation Step 2). **The determinations are deferred.**

## 2.4 Detection building blocks (USML/ITAR markers, export-control SITs)
**Description:** The identifiers that flag ITAR technical data — **USML category / program markings,
export-control banners, part/drawing patterns** — captured so a **custom sensitive-information type (SIT)**
can detect them, plus a decision on using any available **export-control SITs**.
**Why:** Generic PII/financial detectors miss export-controlled technical data; a custom SIT keyed to your
markings materially improves DLP and auto-labeling accuracy.
**Verify:** A sample of real ITAR markings/patterns exists (regex-able); confirm export-control SIT
availability in the Purview portal.
**Implement:** Provide sample markers so `SIT - ITAR/USML Markers` can be built (Implementation Step 5);
confirm SIT availability before relying on it.

## 2.5 External-sharing / recipient model agreed (authorized recipients only)
**Description:** How technical data may (and may not) be shared — the **authorized recipients** (named
U.S. persons/domains under an approved agreement) and the rule that **unauthorized/foreign recipients are
hard-blocked**.
**Why:** ITAR lives on strict recipient control; the label permissions and DLP recipient conditions
enforce it. Getting this wrong is an unauthorized export.
**Verify:** An authorized-recipient list and the per-label/DLP sharing rule exist, tied to any approved
licenses/agreements (a legal input).
**Implement:** Capture authorized recipients and the hard-block rule with export-control/legal before
configuring label encryption and DLP recipient conditions.

## 2.6 Export-records retention captured
**Description:** The **retention schedule** for **export records** (the records ITAR/recordkeeping rules
require be kept, and for how long) — sourced from records/compliance/legal, not guessed.
**Why:** ITAR recordkeeping obligations require export records be retained; durations are records/legal
determinations.
**Verify:** A retention schedule source for export records exists with named approvers.
**Implement:** Obtain the schedule; configure `Retention Label - Export Records - Retention`
accordingly (Implementation Step 5). **Retention determinations are deferred.**

## 2.7 Audit logging enabled
**Description:** Microsoft Purview **audit** (unified audit log) is on — the evidence source for DLP
tuning, technical-data access, and export-control audit evidence.
**Why:** DLP tuning, coverage reporting, and export-control/NIST evidence read audit/activity data.
**Verify:** Purview → **Audit** returns results; run `ITAR-EvidenceReport.ps1`.
**Implement:** Turn on auditing in the Purview **Audit** solution; allow time to populate.

## 2.8 Export-control / NIST 800-171 control baseline captured
**Description:** The control set the program must evidence — an **ITAR/export-control** template where
available, or **NIST SP 800-171** / a custom assessment where an ITAR-specific template is absent —
sourced from export-control/compliance.
**Why:** The control baseline drives which Purview controls you evidence in Compliance Manager; template
availability varies by plan/cloud.
**Verify:** The applicable control baseline is documented with named approvers; confirm template
availability in **Compliance Manager**.
**Implement:** Load the available template (Implementation Step 3); where an ITAR template is absent,
evidence against **NIST SP 800-171** / a custom assessment. **Applicability is an export-control
determination**, deferred.

## 2.9 Change control for enforce-mode changes
**Description:** A documented change-control / rollback process for switching DLP from audit to enforce,
turning auto-labeling out of simulation, or activating a retention policy that deletes export records.
**Why:** Enforce-mode DLP can block legitimate program work; auto-labeling mistakes are user-visible;
retention deletion is irreversible — but under-blocking export-controlled data is an unauthorized export.
**Verify:** A change ticket exists with an approver, `ITAR - Authorized Persons Pilot` scope, and a
documented rollback.
**Implement:** Record the change, name the pilot scope, define the rollback, and get approval before
enforcing.

---
## Checklist
- [ ] M365 + Purview licensing (E3/Business Premium for labels + basic DLP; **E5 / E5 Compliance** for advanced controls) **and GCC High** for ITAR data — `ITAR-Discovery.ps1`
- [ ] Least-privilege Purview roles; access-bearing roles held by authorized U.S. persons — `ITAR Roles – Separation Evidence`
- [ ] ITAR/USML scope + authorized-U.S.-person list decided (determinations deferred) — `ITAR Scope – Record`
- [ ] Detection building blocks (USML/ITAR markers) supplied; export-control SIT availability confirmed
- [ ] Authorized-recipient model + hard-block-to-unauthorized rule agreed (legal/agreements)
- [ ] Export-records retention schedule captured (records/compliance/legal)
- [ ] Purview audit logging enabled — `ITAR-EvidenceReport.ps1`
- [ ] Export-control / NIST 800-171 control baseline captured; Compliance Manager template confirmed
- [ ] Change control + rollback for enforce-mode / auto-labeling / retention deletion
