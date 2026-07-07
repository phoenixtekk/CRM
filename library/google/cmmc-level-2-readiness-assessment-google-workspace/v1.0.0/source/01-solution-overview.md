# Solution Overview

## What this is

This solution is a **readiness and assessment-preparation playbook** for organizations that handle
**Controlled Unclassified Information (CUI)** on **Google Workspace** and must reach **CMMC Level 2** —
the maturity level that maps to the **110 security requirements of NIST SP 800-171** across **14
control families**. It takes an enterprise from "we hold CUI in Workspace but our controls are
unmapped and unevidenced" to "the CUI boundary is defined, the applicable NIST 800-171 controls are
mapped to concrete Workspace configuration, the controls are applied and **evidenced**, and the
**System Security Plan (SSP)** and **Plan of Action & Milestones (POA&M)** are in hand" — the state a
**C3PAO (Certified Third-Party Assessment Organization)** expects to find at the start of a Level 2
assessment.

It builds on and references the organization's existing **Assured Controls / ITAR / DFARS data-region
posture** (the separate regulated-workload solution) but is the distinct **certification-journey**
product: its job is to produce the *control mapping, configuration method, and evidence* that a CMMC
assessment consumes.

> **Critical boundary — read first.** This is **readiness and preparation**, not assessment,
> certification, or legal interpretation. The solution provides the **technical control mapping,
> configuration procedure, and evidence artifacts**. It does **not** — and cannot — produce a CMMC
> assessment *result*, decide **NIST 800-171 applicability/scoping** for your organization, interpret
> **ITAR / DFARS 252.204-7012 / DFARS 252.204-7019/7020/7021**, or schedule/represent a C3PAO
> assessment. Every one of those is a **determination reserved to your organization's assessor,
> compliance officer, and legal counsel**. Where this document cites NIST SP 800-171 or CMMC, it cites
> them at the **framework level** to structure the technical work — it never asserts that a given
> configuration "satisfies" a control as a matter of assessment fact. Treat control-satisfaction
> language throughout as "*configured to support*," pending your assessor's determination.

## The problem it solves

A defense-supply-chain organization that has standardized on Google Workspace for mail, files,
collaboration, and meetings, and that receives or generates CUI under a DoD contract, faces a
recurring, expensive gap:

- The **110 NIST 800-171 requirements** are written technology-neutrally; nobody has mapped them to the
  **specific Workspace setting, admin path, or API** that implements each one.
- The **CUI boundary** — which users, groups, organizational units (OUs), Shared Drives, and data
  flows are *in scope* — has never been drawn, so the assessment scope is undefined and unbounded.
- Controls may in fact be *configured*, but there is **no evidence** — no exported configuration, no
  audit-log extract, no screenshots — to show an assessor.
- There is **no SSP** describing how each requirement is met, and **no POA&M** tracking the gaps, so
  the organization cannot even submit a self-assessment score to **SPRS**, let alone host a C3PAO.

The result is a stalled certification, repeated ad-hoc consulting, and contract risk. This solution
replaces that with a **repeatable, evidenced, self-guided path**.

## How it works — the reference model

The solution organizes the work around a **CUI-boundary-first, control-family-driven** reference model
on Google Workspace:

1. **Define the CUI boundary.** A dedicated **`CUI – Boundary – Org` organizational unit** (and, where
   the design calls for it, a **`CUI – Enclave – Org` sub-OU**) collects the users, groups, and Shared
   Drives that store, process, or transmit CUI. Everything inside the boundary is **in assessment
   scope**; everything outside is explicitly out (subject to your assessor's scoping determination).

2. **Map the 14 families to Workspace capability.** Each of the 14 NIST 800-171 families —
   **Access Control (AC), Awareness & Training (AT), Audit & Accountability (AU), Configuration
   Management (CM), Identification & Authentication (IA), Incident Response (IR), Maintenance (MA),
   Media Protection (MP), Personnel Security (PS), Physical Protection (PE), Risk Assessment (RA),
   Security Assessment (CA), System & Communications Protection (SC), and System & Information
   Integrity (SI)** — is mapped to the Workspace/Cloud-Identity mechanism that implements it:
   context-aware access, 2-step verification / security keys, DLP, Vault retention, audit logs and log
   export, client-side / default encryption, data-region and Assured Controls, admin-role separation,
   and so on. The mapping is captured in a **`NIST 800-171 – Control Map – Org` matrix**
   (control → Workspace setting → status → evidence pointer), the single spreadsheet that drives the
   rest of the engagement.

3. **Configure the controls** against the boundary OU, pilot-first, following the house deployment
   model, each configured artifact named to a consistent convention.

4. **Evidence every control.** For each control the solution captures the **configuration state**
   (exported policy/setting via Admin SDK) and the **operational evidence** (audit-log extract from the
   Reports API) into an **`Evidence – CUI Boundary – <date>` package**.

5. **Author the SSP and POA&M.** The completed control map feeds a **`SSP – CUI Boundary – Org`**
   document (one implementation statement per requirement) and a **`POA&M – CUI Boundary – Org`**
   register (one row per not-yet-met or partially-met requirement, with owner and milestone).

6. **Reach an assessment-ready gate** — controls configured + evidenced, boundary enforced, SSP/POA&M
   complete — at which point the organization engages its C3PAO. **The assessment itself and its
   outcome are out of scope.**

## The deployment model (house standard)

All production changes follow **Assess → Design → Configure → Pilot → Validate → Expand**, pilot-first,
with explicit **pass/fail gates** and a **documented rollback** for every high-impact change (DLP
enforcement, sharing restriction, context-aware access, log export, encryption). Nothing enforced
fleet-wide until it has passed on the **`CUI – Pilot – Org`** group.

## Benefits

- **Assessment-ready, not just "secure."** The deliverable is the exact evidence + SSP + POA&M an
  assessor asks for — configured, exported, and organized to the 110 requirements.
- **Boundary discipline.** A defined, enforced CUI boundary shrinks and stabilizes assessment scope.
- **Repeatable and evidenced by tooling.** Five Python tools read the live tenant to produce the
  control-status map, the evidence package, the boundary-exposure check, and the SSP/POA&M draft — so
  the state is *measured*, not asserted.
- **Lower cost, faster.** Self-guided steps replace open-ended readiness consulting; the certification
  determination stays where it belongs (your assessor).

## Limitations (boundary restated)

- **No assessment result or certification.** Configuration and evidence only; the C3PAO determines
  conformance.
- **No applicability/scoping/legal call.** Which requirements apply, what counts as CUI, and any
  ITAR/DFARS interpretation are your compliance/legal/assessor's to make.
- **Vendor behavior may vary by edition/rollout.** Assured Controls, data-region, client-side
  encryption, and some log-export/DLP capabilities depend on your **Workspace edition and add-ons** and
  on features that roll out over time. Every such item is flagged **"verify your edition / Assured
  Controls availability in your tenant."** This solution never asserts a Google feature exists or
  behaves a certain way beyond current public documentation.
