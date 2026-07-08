# 1. Solution Overview — Microsoft Purview ISO 27001 Compliance Program

## What this solution is
**ISO/IEC 27001** is the international standard for an **Information Security Management System (ISMS)**.
Certification against it requires that a defined set of **controls** — the standard's clauses plus the
**Annex A** control set — are selected, implemented, operated, and **evidenced**. A large portion of the
controls an organization already runs Microsoft 365 for are **technical** — data classification, data
leakage prevention, logging and monitoring, cryptography, information deletion, access restriction — and
**Microsoft Purview** is where those controls are configured and where the **evidence** lives.

This solution is a repeatable, deploy-it-today way to stand up an **ISO 27001-aligned Purview program**:
map the in-scope Annex A controls to the **Purview capabilities** that satisfy them, use **Compliance
Manager's ISO/IEC 27001 assessment template** as the scoring and evidence spine, **configure** the
supporting technical controls (sensitivity labels, DLP, retention/disposition, unified audit,
encryption), **pilot every high-impact policy in simulation/test first**, **validate** the technical
evidence against pass/fail gates, and **expand** to enforcement with a maintenance cadence. It uses only
the **Microsoft Purview portal**, **Security & Compliance PowerShell** (`Connect-IPPSSession`), and
**Microsoft Graph** — no third-party GRC tooling.

> **Certification determinations are deferred.** This solution delivers the **technical control
> configuration and the evidence** that an ISO 27001 audit consumes. It does **not** make the
> certification determinations: the **scope of the ISMS**, the **risk assessment and risk treatment
> plan**, the **Statement of Applicability (SoA)** — which Annex A controls are applicable and why —
> the **management-system clauses** (Clause 4–10: context, leadership, planning, support, operation,
> performance evaluation, improvement), and the **Stage 1 / Stage 2 certification-body audit** are
> **ISMS, compliance, risk, and certification-body determinations**. The solution provides the
> configured control and the proof; it does not decide applicability, adequacy, or certification.

## Why ISO 27001 maps onto Purview (and where it doesn't)
ISO/IEC 27001:2022 restructured Annex A into **93 controls** across **four themes** — **Organizational
(37)**, **People (8)**, **Physical (14)**, and **Technological (34)**. This solution addresses the
**subset that is technically satisfiable in Microsoft 365 / Purview** and provides the evidence for it.
The **organizational, people, and physical** controls (policies, HR screening, awareness, physical
security, supplier management) are **out of Purview's scope** — they are governance and operational
matters this solution explicitly defers to the ISMS. Where a Purview control provides only *partial*
evidence for an Annex A control, this solution says so; it never claims a control is "met" — that is the
auditor's determination.

**Representative Annex A (2022) technological/organizational controls this program provides evidence for**
(verify applicability against your SoA — the mapping is a starting point, not a determination):

| Annex A (2022) control | Purview capability that provides evidence |
|---|---|
| **A.5.12 Classification of information** · **A.5.13 Labelling of information** | **Sensitivity labels** + label policy |
| **A.8.12 Data leakage prevention** | **DLP policies** (email, SharePoint, OneDrive, Teams, endpoint) |
| **A.8.10 Information deletion** · **A.5.33 Protection of records** | **Retention & disposition** (data lifecycle / records management) |
| **A.8.15 Logging** · **A.8.16 Monitoring activities** | **Unified audit log** (Audit Standard/Premium) |
| **A.8.24 Use of cryptography** · **A.5.14 Information transfer** | **Encryption / Message encryption**, label-applied encryption |
| **A.8.11 Data masking** | Label/DLP-driven protection where applicable (verify) |
| **A.5.34 Privacy & protection of PII** | PII SITs + DLP + retention (evidence only; determinations deferred) |
| **A.5.15 / A.8.3 Access control / Information access restriction** | Label-applied access + Conditional Access signals (evidence) |
| **A.5.7 Threat intelligence** · **A.6.8 reporting / A.8.16 monitoring** | Insider Risk / audit signals (HR-sensitive — privacy-by-design, deferred outcomes) |

> The **authoritative control set and applicability are your SoA's**, produced by the ISMS/risk
> function. This table is the technical mapping the program configures and evidences.

## How it works
1. **Baseline (Assess).** Capture the current posture: whether **unified audit logging** is on, what
   **DLP / labels / retention** already exist and in what mode, the **licensing** that gates the ISO
   template and advanced controls, and Compliance Manager's current **score** on the included Data
   Protection Baseline. Delivered read-only scripts produce this.
2. **Design the control map (Design).** With the ISMS/risk stakeholders, take the **in-scope Annex A
   controls from the SoA** and map each to the Purview capability that satisfies it — the
   `ISO27001 Control Map – AnnexA-to-Purview` register. Applicability is the SoA's determination.
3. **Stand up the assessment spine (Configure).** In **Compliance Manager**, create the **ISO/IEC 27001
   assessment** from its **premium template** (licensing-gated — verify entitlement), and build the
   **improvement-action / evidence plan** (`ISO27001 Action Plan – Evidence`): each action owned, dated,
   status-tracked, with evidence attached.
4. **Configure the supporting technical controls (Configure — pilot in simulation/test).** Build the
   **sensitivity-label scheme** (A.5.12/5.13), **DLP policies** for data leakage (A.8.12), and
   **retention/disposition** for records/deletion (A.8.10/5.33) — **each piloted in
   simulation/test/disabled mode first**, then validated, then enforced. Confirm **unified audit**
   (A.8.15/8.16) and **cryptography/message encryption** (A.8.24) evidence.
5. **Validate the evidence (Pilot → Validate).** Confirm the **technical state** behind each mapped
   control matches what the assessment claims, collect it into the `ISO27001 Evidence – Register`, and
   set test status/date — piloting any high-impact change in simulation/test first.
6. **Report and expand (Validate → Expand).** Roll up control coverage, evidence, and the score posture
   (`ISO27001 Control Map` + evidence register); then move piloted policies to enforcement, add remaining
   in-scope controls, and stand up the **maintenance/continual-improvement cadence** (re-test,
   re-evidence, review owners, watch template/standard updates) that ISO's Clause 10 expects.

## What you can control
- Which **Annex A controls** (from your SoA) the program configures and evidences in Purview.
- The **control-to-capability mapping** and the **evidence register** — owners, dates, status, proof.
- The **sensitivity-label scheme, DLP policies, and retention/disposition** that back the technical
  controls — and, per the house model, whether each is in **simulation/test** or **enforced**.
- The **pilot scope** validated first (a pilot ring / a single assessment) before tenant-wide expansion.
- The **Compliance Manager role separation** (administrators / assessors / contributors / readers) that
  makes the access record auditable.

## Limitations (be honest with buyers)
- **This is not certification.** The program produces **configured controls and audit-ready evidence**;
  it does not perform the **risk assessment**, write the **SoA/risk-treatment plan**, satisfy the
  **management-system clauses (4–10)**, or conduct the **certification-body Stage 1/2 audit**. Those are
  ISMS/risk/certification-body determinations — deferred.
- **Purview covers a subset of Annex A.** Organizational, people, and physical controls are largely
  **outside** Purview and outside this solution; where Purview evidence is only **partial**, the program
  says so rather than claiming the control is met.
- **Premium content and advanced controls are licensing-gated.** The **ISO/IEC 27001 Compliance Manager
  template** is a **premium template** (typically **Microsoft 365 E5 / E5 Compliance** or the Compliance
  Manager Premium Assessment Add-On), and advanced DLP/auto-labeling/Audit Premium are **E5 / E5
  Compliance**. Some capabilities are **preview** and portal paths **evolve** — the program **verifies
  licensing/tenant**, never assumes.
- **Compliance Manager is portal-driven.** It has **no broad public PowerShell/Graph API** to create
  assessments or set action status programmatically; the delivered scripts assess **readiness, roles, and
  the technical evidence** behind controls — they do not replace the portal.
- **Insider Risk / Communication Compliance are HR/privacy-sensitive.** Where used for A.5.7/A.6.8/A.8.16
  evidence, apply **privacy-by-design, pseudonymization where applicable, and strict role separation** —
  case outcomes are **HR/legal** determinations, deferred.
- **No secrets in automation.** The scripts use interactive modern-auth sign-in; they never embed
  credentials.

## Naming convention (used in every doc and script)
Every artifact this solution creates or tracks is named `ISO27001 <Purpose> – <Scope> – <Stage>` and
reused verbatim across the docs, scripts, and the Purview portal. The standard set:

| Artifact | Name |
|---|---|
| ISO 27001 assessment (pilot) | `ISO27001 Assessment – Baseline – Pilot` |
| ISO 27001 assessment (production) | `ISO27001 Assessment – Annex A – Production` |
| Annex A → Purview control map | `ISO27001 Control Map – AnnexA-to-Purview` |
| Improvement-action / evidence plan | `ISO27001 Action Plan – Evidence` |
| Sensitivity-label scheme (A.5.12/5.13) | `ISO27001 Label – Classification – Pilot` |
| DLP policy — data leakage (A.8.12) | `ISO27001 DLP – Data Leakage – Simulation` |
| Retention / disposition (A.8.10/5.33) | `ISO27001 Retention – Records – Simulation` |
| Audit / logging evidence (A.8.15/8.16) | `ISO27001 Audit – Logging – Evidence` |
| Evidence register | `ISO27001 Evidence – Register` |
| Pilot user ring | `ISO27001 Pilot Ring – Stage1` |
| Role-separation evidence snapshot | `ISO27001 Roles – Separation Evidence` |

## The standard deployment model
> **Assess** the posture and licensing → **Design** the Annex A → Purview control map from the SoA →
> **Configure** the assessment spine and the supporting technical controls **in simulation/test** →
> **Pilot** (simulate/test → validate → enforce to a ring) → **Validate** the evidence behind each mapped
> control against pass/fail gates → **Expand** to enforcement, the full in-scope control set, and the
> continual-improvement cadence. Every high-impact change is piloted in simulation/test first, with a
> documented rollback. **Certification, applicability, and adequacy determinations are deferred to the
> ISMS/risk/compliance/certification-body functions at every step.**
