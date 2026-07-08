# 1. Solution Overview — Microsoft Purview FERPA Compliance Program

## What this solution is
An education institution or any organization holding student education records lives under one recurring
demand from a regulator, an auditor, or a parent: *"Show me the control"* and *"Show me the evidence."*
FERPA obligations — protecting the personally identifiable information (PII) in student education records
and governing its **disclosure** — need to be **mapped to concrete controls**, those controls
**configured**, and the whole thing **evidenced** in a form you can produce on demand. This solution
builds that program on **Microsoft Purview**: it maps the technical control surface (classification &
labeling of education records, data-loss prevention of unauthorized disclosure, and retention/audit
evidence of access) to a FERPA-aligned control register, **configures** the controls in Purview,
**pilots the high-impact ones in simulation/test/disabled mode first**, validates, and produces an
**evidence binder** you can defend. It uses only the **Microsoft Purview portal**
(`purview.microsoft.com`), **Security & Compliance PowerShell** (`Connect-IPPSSession`), and
**Microsoft Graph** — no third-party tooling.

> **This is a technical-control-and-evidence program, not a legal opinion.** *Which* data are "education
> records," who are "eligible students" and "school officials with a legitimate educational interest,"
> which disclosures are permitted, and whether any given configuration *satisfies* FERPA (34 CFR Part 99)
> are **compliance, registrar, records, and legal determinations** deferred to your **compliance,
> registrar/records, privacy, and legal functions**. This solution provides the Purview method, the
> configured control, and the evidence — **not** the determination that it meets FERPA.

## Why this matters
- **Unauthorized disclosure is the core FERPA risk, and it is preventable.** FERPA governs the disclosure of PII from education records. Purview **Data Loss Prevention (DLP)** is the Microsoft control that detects and blocks that disclosure across email, files, Teams, and endpoints — but it is **high-impact**, which is why it is always **piloted in simulation mode** before any enforcement.
- **You cannot protect what you have not identified.** Education records must first be **classified** — with **sensitive information types**, trainable classifiers, and **sensitivity labels** — so DLP, retention, and encryption controls have something to key off. Classification is the foundation control.
- **Evidence is the deliverable auditors actually want.** A control that works but can't be *shown* to work fails a review. This solution's reporting produces a **control-to-configuration-to-evidence** binder so "the control is in place" is provable, not asserted, and access to records is auditable.
- **The controls are licensing-dependent and evolving.** Auto-labeling, advanced/endpoint DLP, trainable classifiers, and Audit Premium require **Microsoft 365 E5** or the **E5 Compliance** add-on; the portal and tooling change. Capabilities are **cited or flagged "verify your licensing/tenant"**, never assumed.

## How it works
1. **Assess.** Discover what you already have — compliance licensing/plans, the least-privilege roles, existing sensitivity labels, DLP policies, sensitive information types, retention labels/policies, unified-audit state, and audit retention — so the program is built on facts, not assumptions.
2. **Design the control map.** With compliance/registrar/records/legal, map the in-scope FERPA obligations to the three Purview control domains (classify & label education records, DLP against unauthorized disclosure, retention & audit evidence) and to the **named artifacts** below. Which data are education records and which disclosures are permitted are the institution's determinations; this solution provides the register structure and the technical control.
3. **Configure — in simulation/test first.** Create the education-record sensitivity label and publish policy, the DLP policy **in simulation mode**, the education-record retention policy, and the audit evidence-retention policy. Every high-impact change is piloted simulated/disabled before enforcement.
4. **Pilot & validate.** Prove the label applies and protects, DLP matches education records and generates simulation events (in simulation mode) without blocking users, retention holds, and audit evidence is retained — on a bounded **pilot scope** before tenant-wide enforcement.
5. **Produce the evidence.** Generate the control-mapping + evidence binder (control → Purview object → configuration → proof) for the compliance/audit file.
6. **Expand & operate.** Move DLP from simulation to enforcement on the approved scope, schedule the read-only re-assessment so drift is caught, and hand the binder and runbook to the compliance/registrar function as a standing procedure.

## The control stack this solution configures
- **Classification & sensitivity labels** — **sensitive information types** / **trainable classifiers** that recognize education-record PII, and a **sensitivity label** (`Protect – FERPA Education Records – Confidential`) that marks and, where designed, encrypts education-record data across Exchange, SharePoint, OneDrive, and Teams — the identification-and-protection control.
- **Data Loss Prevention (DLP)** — the policy that detects and (once enforced) blocks unauthorized disclosure of education records across **Exchange, SharePoint, OneDrive, Teams, and Endpoint**, built and validated **in simulation mode** first — the disclosure-prevention control. *High-impact.*
- **Data lifecycle & retention** — retention **labels/policies** governing how long education records are kept and when they are disposed — the records-lifecycle control.
- **Audit (Standard/Premium)** — unified audit logging and **audit log retention policies** keeping the evidence of who accessed/disclosed what — the access-evidence control.
- **Compliance Manager** — a FERPA **assessment** (`Assessment – FERPA Controls – Program`) that tracks improvement actions and scores control implementation — the control-tracking layer (configured in-portal; applicability determination is compliance's).

## What you can control
- Which **sensitive information types / classifiers** and the **sensitivity label** identify and protect education records, and their scope.
- The **DLP policy** scope, conditions, and actions — built and validated in **simulation mode** first, enforced only after sign-off.
- Which **retention labels/policies** govern the education-record lifecycle and disposition.
- Which record types/operations/users get **extended audit retention** as access evidence.
- The **control register** (which FERPA obligation maps to which Purview object) and the **evidence binder** contents.
- The **pilot scope** validated in simulation/test/disabled mode before any enforcement.

## Limitations (be honest with buyers)
- **We configure the control; we do not make the determination.** What is an "education record," who is an "eligible student" or a "school official," which disclosures are permitted (consent, directory information, health/safety emergency, audit/evaluation), and whether a configuration satisfies FERPA are **compliance/registrar/records/legal** determinations. **Verify with your governance functions.**
- **DLP is high-impact and must be piloted in simulation.** An enforced DLP policy can block legitimate work if mis-scoped; it is always built in **simulation mode**, validated, and enforced only under sign-off on an approved scope, with a documented rollback.
- **Protection is largely not retroactive.** Labels, DLP, and retention policies act from application/enable forward; they do not reach back to reclassify or recover history that wasn't captured.
- **Classification accuracy needs tuning.** Sensitive information types and trainable classifiers produce false positives/negatives; the pilot exists to tune them before enforcement, and the adequacy of the match logic is a compliance/registrar decision, not a technical default.
- **No certification claim.** This solution does not assert FERPA compliance or certify the institution; it delivers the technical control configuration and the evidence. **Rule applicability and adequacy are your governance functions' determinations.**

## Naming convention (used in every doc and script)
Every artifact this solution creates is named `<Purpose> – <Scope> – <Stage>` and reused verbatim
across the docs, scripts, and portal. The standard set:

| Artifact | Name |
|---|---|
| Education-record sensitivity label | `Protect – FERPA Education Records – Confidential` |
| Sensitivity-label publish policy | `Protect – FERPA Education Records – Publish` |
| DLP policy (simulation-first) | `DLP – FERPA Education Records – Simulate` |
| Education-record retention policy | `Retention – FERPA Records – Publish` |
| Audit evidence retention policy | `Audit Retention – FERPA Evidence – LongTerm` |
| Compliance Manager assessment | `Assessment – FERPA Controls – Program` |
| Disposition-review stage | `Disposition – FERPA Records – Review` |
| Control-mapping register | `Control Map – FERPA – Purview` |
| Evidence binder export | `Evidence – FERPA Controls – Binder` |
| Pilot validation scope | `FERPA Pilot – Education Records – Stage1` |

## The standard deployment model
> Assess the controls and licensing you have → design the FERPA-obligation-to-control map with
> compliance/registrar/legal → configure classification & labels, DLP, and retention & audit evidence →
> **pilot in simulation/test/disabled mode** on a limited scope → validate the controls work and produce
> evidence → expand to enforcement. Pattern: **Assess → Design → Configure → Pilot (simulate/test) →
> Validate → Expand (enforce).** High-impact controls (DLP, labels, retention) are always piloted before
> enforcement.
