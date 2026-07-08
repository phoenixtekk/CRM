# 1. Solution Overview — Microsoft Purview FedRAMP Compliance Program

## What this solution is
An organization pursuing (or maintaining) a FedRAMP authorization lives and dies by two questions from
an assessor: *"Show me the control"* and *"Show me the evidence."* FedRAMP is built on the **NIST SP
800-53** control baselines, and its data-protection expectations — protecting controlled information,
preventing unauthorized data loss, and preserving a demonstrable audit trail — need to be **mapped to
concrete controls**, those controls **configured**, and the whole thing **evidenced** in a form you can
hand to an assessor without a scramble. This solution builds that program on **Microsoft Purview**: it
maps the technical control surface (information protection, data-loss prevention, retention and audit
evidence) to a FedRAMP-aligned control register, **configures** the controls in Purview — sensitivity
labels/encryption, DLP, and audit/retention evidence — **pilots them in simulation/test/disabled mode
first**, validates, and produces an **evidence binder** you can defend. It uses only the **Microsoft
Purview portal** (`purview.microsoft.com`), **Security & Compliance PowerShell** (`Connect-IPPSSession`),
and **Microsoft Graph** — no third-party tooling.

> **This is a technical-control-and-evidence program, not an authorization.** Whether your tenant meets
> FedRAMP, which **baseline** applies (Low / Moderate / High), which NIST 800-53 control an object
> satisfies, and whether any configuration supports an **Authorization to Operate (ATO)** are
> **compliance, security, and legal determinations** deferred to your **security, compliance, and
> authorizing functions**. This solution provides the Purview method, the configured control, and the
> evidence — **not** the determination and **not** any certification or ATO claim.

## Why this matters
- **FedRAMP is control-mapping plus evidence.** FedRAMP inherits the **NIST SP 800-53** control families — Access Control (**AC**), Audit & Accountability (**AU**), System & Communications Protection (**SC**), Media Protection (**MP**), Identification & Authentication (**IA**), Configuration Management (**CM**) — and an assessor expects each in-scope control to have an implementing mechanism and evidence. Purview provides implementing mechanisms for the data-centric families and, via **Compliance Manager**, a place to track them.
- **DLP is a high-impact control — pilot it in simulation first.** Data-loss prevention aligned to SC/AC can block real user actions if enforced blind. Purview DLP supports a **test / simulation** mode; this solution **always** creates and pilots DLP in test mode first, and enforces only after validation and sign-off.
- **Evidence is the deliverable assessors actually want.** A control that works but can't be *shown* to work fails an assessment. This solution's reporting produces a **control-to-configuration-to-evidence** binder so "the control is in place" is provable, not asserted.
- **The controls are licensing-dependent and evolving.** Sensitivity labels with encryption, DLP, auto-classification, and Audit Premium require **Microsoft 365 E5** or the **E5 Compliance** add-on; the portal and assessment templates change. Capabilities are **cited or flagged "verify your licensing/tenant"**, never assumed.

## How it works
1. **Assess.** Discover what you already have — compliance licensing/plans, the least-privilege roles, existing sensitivity labels and label policies, DLP policies (and their mode), retention labels/policies, unified-audit state, and audit retention — so the program is built on facts, not assumptions.
2. **Design the control map.** With security/compliance, map the in-scope FedRAMP (NIST 800-53) controls to the three Purview control domains (information protection, DLP, retention & audit evidence) and to the **named artifacts** below. The control-to-object mapping is the security/compliance function's determination; this solution provides the register structure and the technical control.
3. **Configure — in simulation/test first.** Create the sensitivity label (with encryption where designed), the DLP policy **in test/simulation mode**, and the audit-evidence and retention policies. Every high-impact change is piloted disabled/simulated before enforcement.
4. **Pilot & validate.** Prove the label applies and protects, the DLP policy matches and reports (in test mode, no blocking) against benign test content, and audit evidence is retained — on a bounded **pilot scope** before tenant-wide enforcement.
5. **Produce the evidence.** Generate the control-mapping + evidence binder (control → Purview object → configuration → proof) for the security/compliance package.
6. **Expand & operate.** Move DLP from test to enforce and expand label/retention scope on the approved scope, schedule the read-only re-assessment so drift is caught, and hand the binder and runbook to the security/compliance function as a standing procedure.

## The control stack this solution configures
- **Information protection** — sensitivity **labels** (with **encryption**/rights protection where designed) and **label policies** across Exchange, SharePoint, OneDrive, and Teams — the controlled-data protection mechanism supporting NIST **AC** (access control), **MP** (media protection), and **SC** (protection at rest/in transit).
- **Data Loss Prevention (DLP)** — **DLP policies and rules** that detect and (once enforced) restrict egress of controlled data across the same workloads and endpoints — the unauthorized-data-flow mechanism supporting NIST **SC**/**AC**. *High-impact — always piloted in test/simulation mode first.*
- **Audit (Standard/Premium) & Retention** — unified audit logging and **audit log retention policies** (the **AU** evidence trail), plus retention **labels/policies** preserving controlled records.
- **Compliance Manager** — the FedRAMP **assessment template** (e.g. **FedRAMP Moderate / FedRAMP High**, subject to your licensing) that tracks improvement actions and scores control implementation — the control-tracking layer (configured in-portal; determination of baseline/applicability is security/compliance's).

## What you can control
- Which **sensitivity label(s)** protect controlled data, whether they apply **encryption**/rights protection, and their **label policy** scope.
- The **DLP** policy scope, conditions (which sensitive info types / labels), and actions — built and piloted in **test/simulation mode** first.
- Which record types/operations/users get **extended audit retention** as evidence, and which controlled records get retention.
- The **control register** (which NIST 800-53 control maps to which Purview object) and the **evidence binder** contents.
- The **pilot scope** validated in simulation/test/disabled mode before any enforcement.

## Limitations (be honest with buyers)
- **We configure the control; we do not make the determination.** The applicable FedRAMP **baseline** (Low/Moderate/High), which NIST 800-53 controls are in scope, which controls a Purview object satisfies, and whether the tenant supports an **ATO** are **security/compliance/legal** determinations. **Verify with your security and authorizing functions.**
- **No certification or ATO claim.** This solution produces configured controls and evidence; it does **not** assert FedRAMP compliance, an ATO, or a 3PAO assessment outcome. Those are outside its scope.
- **DLP can disrupt users if enforced blind.** DLP is created and validated in **test/simulation mode** first; enforcement (blocking) is a separate, approved step after the pilot passes.
- **Encryption/labels are consequential.** Applying encryption to controlled data changes access — piloted on benign content first, with recovery/super-user and offboarding considerations understood before wider use.
- **Preservation and evidence are largely not retroactive.** Labels, retention, DLP telemetry, and audit evidence apply/accrue from configuration forward; they do not reach back to create history that wasn't captured — which is why configuring *now* matters.

## Naming convention (used in every doc and script)
Every artifact this solution creates is named `<Purpose> – <Scope> – <Stage>` and reused verbatim
across the docs, scripts, and portal. The standard set:

| Artifact | Name |
|---|---|
| Controlled-data sensitivity label | `Protect – FedRAMP Controlled – Confidential` |
| Sensitivity-label publish policy | `Protect – FedRAMP Controlled – Publish` |
| DLP policy (test/simulation) | `DLP – FedRAMP Controlled – Simulate` |
| Controlled-records retention policy | `Retention – FedRAMP Records – Publish` |
| Audit evidence retention policy | `Audit Retention – FedRAMP Evidence – LongTerm` |
| Compliance Manager assessment | `Assessment – FedRAMP Controls – Program` |
| Control-mapping register | `Control Map – FedRAMP – Purview` |
| Evidence binder export | `Evidence – FedRAMP Controls – Binder` |
| Pilot validation scope | `FedRAMP Pilot – Controlled Data – Stage1` |

## The standard deployment model
> Assess the controls and licensing you have → design the NIST-800-53-to-Purview control map with
> security/compliance → configure information protection, DLP, and audit/retention evidence → **pilot in
> simulation/test/disabled mode** on a limited scope → validate the controls work and produce evidence →
> expand to enforcement. Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate →
> Expand (enforce).** High-impact controls (DLP, encryption labels, retention) are always piloted before
> enforcement.
