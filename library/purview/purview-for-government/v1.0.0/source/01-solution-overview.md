# 1. Solution Overview — Microsoft Purview for Government

## What this solution is
A government or public-sector organization holds data that carries obligations most enterprises never
face: **Criminal Justice Information (CJI)** under the FBI CJIS Security Policy, **Controlled Unclassified
Information (CUI)** under CMMC / NIST SP 800-171, and **ITAR-controlled technical data** whose export —
even a view by a foreign person — is regulated. Each demands the same two answers from an auditor or
assessor: *"show me the control"* and *"show me the evidence."* This solution delivers a **Government-tailored
Purview program** that curates and sequences the Purview capabilities into one coherent, defensible whole:
**sensitivity labels** (with encryption) for CJI/CUI/ITAR, **DLP including endpoint DLP** to stop egress of
that controlled data — **piloted in simulation first** — **retention and audit evidence**, all **tracked in
Compliance Manager** against CJIS / CMMC / NIST 800-171 assessment templates. It uses only the **Microsoft
Purview portal** (`purview.microsoft.com`), **Security & Compliance PowerShell** (`Connect-IPPSSession`), and
**Microsoft Graph** — no third-party tooling.

> **This is an industry bundle — a curated program, not a re-teaching of each granular product.** It
> references the deep how-to of the individual Purview capabilities (endpoint DLP, sensitivity-label
> encryption, retention, insider risk) rather than duplicating them; its value is **selecting, naming, and
> sequencing** the right controls for a government tenant and evidencing them together.

> **This is a technical-control-and-evidence program, not a compliance determination or an
> authorization.** *Which* data is CJI, CUI, or ITAR-controlled; *which* CMMC level applies; and whether any
> configuration *satisfies* the CJIS Security Policy, CMMC, NIST SP 800-171, or the ITAR are **compliance,
> security, and legal determinations** deferred to your organization's governance functions. This solution
> provides the register, the technical control, and the evidence — **never** the determination, a
> certification, or an authorization-to-operate claim.

## The sovereign-cloud caveat (read first)
Many government tenants run in a **sovereign cloud** — **GCC**, **GCC High**, or **DoD** — not commercial
Microsoft 365. **Feature availability, portal endpoints, and the PowerShell/Graph connection endpoints
differ** in those clouds, and ITAR/CUI workloads are frequently *required* to run in **GCC High** or higher.
This solution **never asserts** a capability is present in a given government cloud: every capability and path
is **cited or flagged "verify for your cloud/tenant."** Connection specifics — `Connect-IPPSSession
-ConnectionUri …` and `Connect-MgGraph -Environment …` for USGov/USGovDoD — are called out in the
Implementation Guide and scripts and must be confirmed for your environment.

## Why this matters
- **CJI, CUI, and ITAR carry export and handling rules with teeth.** CJI mishandling can cost CJIS access; a
  CUI lapse can sink a CMMC assessment and the contract behind it; an ITAR export — including a foreign
  person merely accessing controlled technical data — is a legal event. A **sensitivity label with encryption**
  is the Purview control that binds protection to the data itself; **DLP/endpoint DLP** is the control that
  stops it leaving. This solution puts both in place, named and evidenced.
- **The controls must fit government, not generic defaults.** A generic label/DLP build does not distinguish
  CJI from CUI from ITAR, does not encrypt, and does not map to CJIS/CMMC/NIST controls. This program tailors
  the labels, the DLP conditions, and the assessment to the government control set.
- **Egress controls are high-impact — simulate before you enforce.** A DLP or endpoint-DLP rule flipped
  straight to *block* can halt legitimate mission work. Every DLP control here is **created and piloted in
  simulation/test mode**, validated, and only then enforced.
- **Evidence is the deliverable an assessor actually wants.** A control that works but can't be *shown* fails
  an assessment. The reporting here produces a **control → configuration → proof** binder so "the control is
  in place" is provable, not asserted.
- **The controls are licensing-dependent, cloud-dependent, and evolving.** Label encryption, auto-labeling,
  advanced/endpoint DLP, Audit Premium, and Compliance Manager premium templates require **Microsoft 365 E5**
  or the **E5 Compliance** add-on (government SKUs), and behavior differs by cloud. Capabilities are **cited
  or flagged "verify your licensing/tenant/cloud,"** never assumed.

## How it works
1. **Assess.** Discover what you already have — compliance licensing/plans (in the government SKU), the
   least-privilege roles, existing sensitivity labels and label policies, DLP policies (and endpoint-DLP
   onboarding), retention labels/policies, unified-audit state and audit retention, and which cloud you are
   in — so the program is built on facts.
2. **Design the control map.** With compliance/security/records/legal, map the in-scope obligations (CJIS,
   CMMC/NIST 800-171, ITAR) to the Purview control domains and to the **named artifacts** below. The
   data-classification and rule-applicability calls are the governance functions' determination; this
   solution provides the register structure and the technical control.
3. **Configure — labels first, then DLP in simulation.** Create the CJI/CUI/ITAR sensitivity labels (with
   encryption) and their publish policy, then the DLP and endpoint-DLP policies **in simulation/test mode**,
   and the retention and audit-evidence controls. Every high-impact change is piloted before enforcement.
4. **Pilot & validate.** Prove the labels apply and encrypt, the DLP policies *match* the right controlled
   content in simulation (without blocking), retention preserves, and audit evidence is retained — on a
   bounded **pilot scope** before tenant-wide enforcement.
5. **Produce the evidence.** Generate the control-mapping + evidence binder (control → Purview object →
   configuration → proof) and the DLP simulation-match report for the compliance/assessment file.
6. **Expand & enforce.** Move DLP from simulation to enforce on the approved scope, extend the labels,
   retention, and audit-evidence policies, schedule the read-only re-assessment so drift is caught, and hand
   the register, binder, and runbook to the compliance function as a standing procedure.

## The control stack this solution curates
- **Sensitivity labels (with encryption)** — the labels `Protect – Gov CJI – Restricted`,
  `Protect – Gov CUI – Controlled`, and `Protect – Gov ITAR – Controlled` bind classification and encryption
  to CJI/CUI/ITAR data so protection travels with the file. *The label taxonomy operationalizes the
  classification your security/compliance function defines.* (Deep label-encryption/how-to: the granular
  sensitivity-labeling product — referenced, not re-taught here.)
- **Data Loss Prevention, incl. endpoint DLP** — `DLP – Gov Controlled Data – Simulate` (Exchange/SharePoint/
  OneDrive/Teams) and `DLP – Gov Endpoint Egress – Simulate` (devices: USB/print/cloud-upload) detect and
  prevent egress of CJI/CUI/ITAR — **built and validated in simulation first.** (Deep endpoint-DLP onboarding:
  the granular endpoint-DLP product — referenced.)
- **Records & data lifecycle** — retention labels/policies (`Retention – Gov Records – Publish`) for
  government records preservation and disposition.
- **Audit (Standard/Premium)** — unified audit logging and an audit-log retention policy
  (`Audit Retention – Gov Evidence – LongTerm`) keeping the who-did-what evidence.
- **Compliance Manager** — an `Assessment – Gov Controls (CJIS/CMMC/NIST 800-171) – Program` built from the
  relevant assessment template(s), tracking improvement actions and control scores — the control-tracking
  layer (configured in-portal; applicability is compliance's determination).

## What you can control
- Which **sensitivity labels** (and whether they **encrypt**) implement CJI/CUI/ITAR protection, and their
  publish scope.
- The **DLP** and **endpoint-DLP** policy scope and conditions — built in **simulation** first, enforced only
  after validation.
- Which **retention labels/policies** implement records preservation, and which record types/operations get
  **extended audit retention** as evidence.
- The **control register** (which obligation maps to which Purview object) and the **evidence binder**
  contents.
- The **pilot scope** (`Gov Pilot – Controlled Data – Stage1`) validated before any enforcement.

## Limitations (be honest with buyers)
- **We configure the control; we do not make the determination.** Which data is CJI/CUI/ITAR, which CMMC
  level applies, retention schedules, and whether a configuration satisfies CJIS/CMMC/NIST 800-171/ITAR are
  **compliance/security/records/legal** determinations. **Verify with your governance functions.** This
  solution makes **no certification or authorization-to-operate claim.**
- **Sovereign-cloud differences are real and must be verified.** GCC/GCC High/DoD differ in feature
  availability and endpoints; ITAR/CUI often mandate GCC High. **Do not assume** a capability shown here is
  present in your cloud — verify.
- **Egress enforcement can disrupt the mission.** DLP/endpoint-DLP set to *block* can stop legitimate work —
  which is why every DLP control is **piloted in simulation** and enforced only after validation, with a
  documented rollback.
- **Label encryption changes access and portability.** An encrypting label restricts who can open a file and
  can affect downstream tooling; pilot it and confirm access outcomes before broad publish.
- **Endpoint DLP requires device onboarding and the right licensing/cloud.** Devices must be onboarded and
  the endpoint-DLP capability licensed/available in your cloud — **verify** before expecting device egress
  control.

## Naming convention (used in every doc and script)
Every artifact this solution creates is named `<Purpose> – <Scope> – <Stage>` and reused verbatim across the
docs, scripts, and portal. The standard set:

| Artifact | Name |
|---|---|
| CJI sensitivity label (encrypt) | `Protect – Gov CJI – Restricted` |
| CUI sensitivity label (encrypt) | `Protect – Gov CUI – Controlled` |
| ITAR sensitivity label (encrypt) | `Protect – Gov ITAR – Controlled` |
| Controlled-data DLP policy (simulation) | `DLP – Gov Controlled Data – Simulate` |
| Endpoint egress DLP policy (simulation) | `DLP – Gov Endpoint Egress – Simulate` |
| Government records retention publish policy | `Retention – Gov Records – Publish` |
| Audit evidence retention policy | `Audit Retention – Gov Evidence – LongTerm` |
| Compliance Manager assessment | `Assessment – Gov Controls (CJIS/CMMC/NIST 800-171) – Program` |
| Control-mapping register | `Control Map – Gov – Purview` |
| Evidence binder export | `Evidence – Gov Controls – Binder` |
| Pilot validation scope | `Gov Pilot – Controlled Data – Stage1` |

## The standard deployment model
> Assess the controls, licensing, and cloud you have → design the obligation-to-control map with
> compliance/security/legal → configure sensitivity labels, DLP/endpoint DLP, retention, and audit evidence →
> **pilot in simulation/test mode** on a limited scope → validate the controls work and produce evidence →
> expand to enforcement. Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand
> (enforce).** High-impact controls (encrypting labels, DLP, endpoint DLP, retention) are always piloted
> before enforcement.
