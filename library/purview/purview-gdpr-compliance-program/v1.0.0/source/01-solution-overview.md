# 1. Solution Overview — Microsoft Purview GDPR Compliance Program

## What this solution is
This solution stands up a **GDPR-aligned compliance program inside Microsoft Purview**: it maps the
**EU General Data Protection Regulation** obligations to the **Microsoft Purview** technical controls
that satisfy them, measures the program with **Compliance Manager**, wires the **data-subject-request
(DSR) method** that answers access/erasure/portability requests, and produces the **evidence** —
owners, implementation status, test status, and proof — that makes the posture **defensible**. The
output is a scored, control-by-control GDPR program with an article-to-control map, an improvement-
action plan, an evidence register, a DSR runbook, and a posture report — configured, piloted where
high-impact, and validated.

It is the **program umbrella**, not a single control. It uses **Compliance Manager** (the **GDPR**
assessment template) to score, and it maps each obligation to the Purview capability that evidences
it — **Audit**, **sensitivity labels**, **Data Loss Prevention (DLP)** over **EU personal-data
sensitive-information types**, **data lifecycle / retention** (the storage-limitation principle),
**sensitive information types**, and (where scoped) **Insider Risk Management**, **Communication
Compliance**, and **eDiscovery / content search** as the DSR locate method. It uses only the
**Microsoft Purview portal** (`purview.microsoft.com`), **Security & Compliance PowerShell**
(`Connect-IPPSSession`), and **Microsoft Graph** — no third-party tooling.

> **This is a program, not a legal determination.** Purview and Compliance Manager give you the
> **measurement, control mapping, and evidence**. Whether the GDPR **applies** to a given processing
> activity, the **lawful basis** you rely on, your **records of processing (Art. 30)** content, the
> outcome of a **Data Protection Impact Assessment (Art. 35)**, retention **schedules**, and whether
> the collected evidence **satisfies** a supervisory authority are **compliance, privacy, records,
> and legal determinations** — this solution provides the technical method and the proof, not the
> ruling.

> **Distinct from the GDPR PII DLP pack.** A GDPR **DLP pack** configures a *specific* control (DLP
> over EU personal-data types). **This program sits above it**: it maps *all* the in-scope GDPR
> obligations to Purview controls, scores the whole program in Compliance Manager, wires the DSR
> workflow, and collects the cross-control evidence. It **references** the individual technical
> controls; it does not re-implement each one — where an obligation needs a high-impact technical
> change (a new DLP, label, or retention policy), that change is **piloted in simulation/test** under
> its own change control, and this program **evidences** that it is in place.

## Why this matters
- **"Are we GDPR-compliant?" has no defensible answer without a scored control map.** GDPR is a set
  of principles and rights (Art. 5 principles; Art. 15–22 data-subject rights; Art. 25
  privacy-by-design; Art. 30 records of processing; Art. 32 security of processing; Art. 33–34 breach
  notification). Compliance Manager turns the technical subset into a **measured score** with a
  per-control status and evidence, so gaps are **visible, owned, and tracked** instead of discovered
  in a complaint, an audit, or a breach.
- **DSRs are an operational obligation with a clock.** Access, erasure, and portability requests
  (Art. 15/17/20) must be answered within **one month**. Without a defined **locate-review-produce**
  method they become a scramble. This program wires the **DSR runbook** — Priva Subject Rights
  Requests where licensed, or Purview **eDiscovery / content search** as the locate method — so a
  request is a routine, not a fire drill.
- **Evidence is what a supervisory authority (or a controller audit) asks for.** A posture is only
  defensible if each control carries **who owns it, whether it is implemented, when it was tested, and
  the proof**. This program centralizes that record — audit-log configuration, DLP over EU personal
  data, labels, retention — so producing it is repeatable.
- **Control mapping means you evidence once and score many.** One well-implemented control — unified
  **audit logging**, say — satisfies GDPR Art. 32/33 *and* maps across ISO 27701, NIST, and your
  internal baseline in Compliance Manager's **shared-control** model. You fix once and the score
  updates in every assessment that shares the control.
- **Applicability, lawful basis, and adequacy are not technical calls.** *Which* obligations apply,
  the **lawful basis**, the **ROPA** content, DPIA outcomes, and whether the evidence is **sufficient**
  are **compliance/privacy/legal** determinations. This program supplies the configuration method and
  the evidence; it does not decide sufficiency.

## How it works
1. **Baseline the posture (Assess).** Confirm licensing and the Compliance Manager role groups,
   capture the current **Compliance Score** and technical-control state (audit on/off,
   DLP/label/retention presence, EU sensitive-information-type usage), and record the readiness
   snapshot (`GDPR Roles – Separation Evidence`).
2. **Design the assessment, scope, and article map (Design).** With compliance/privacy/legal
   stakeholders, confirm the **GDPR assessment template**, the **scope** (workloads holding EU
   personal data, the systems in scope), the **DSR method**, and the **article-to-Purview control
   map** (`GDPR Control Map – Articles`, `GDPR Scope – Record`). Applicability, lawful basis, and
   ROPA content are the stakeholders' determinations.
3. **Configure roles, assessment, plan, evidence, and DSR (Configure).** Set least-privilege role
   separation, create the pilot **GDPR assessment**, build the **action plan** and **evidence
   register**, enable **automatic testing** for eligible actions, and wire the **DSR runbook** —
   piloting any new high-impact control (a DLP, label, or retention policy) in **simulation/test**
   first.
4. **Validate (Validate).** Confirm the technical evidence behind each mapped control — audit on,
   DLP over EU personal data present, labels published, retention scoped — with explicit **pass/fail
   gates**, and run a **test DSR** end to end.
5. **Report and expand (Expand).** Produce the **posture report**, expand the assessment to the full
   program, and run the maintenance cadence. Enforce high-impact controls only after their pilot
   passes; keep a documented rollback.

## What this does *not* do (limitations)
- **Licensing-gated.** The **GDPR assessment template** and premium capabilities (auto-labeling at
  rest, endpoint DLP, Audit Premium, DSPM, Insider Risk, Communication Compliance) require **Microsoft
  365 E5** or the **E5 Compliance** add-on; **Priva Subject Rights Requests** requires **Microsoft
  Priva** licensing. Availability is plan-/tenant-dependent — **verify your licensing/tenant**; the
  portal is evolving and paths may differ.
- **Compliance Manager is portal-driven.** Assessments, improvement actions, evidence upload, and the
  authoritative score are managed in the **Purview portal**. Compliance Manager does **not** expose a
  broad public PowerShell/Graph API to create assessments or set action status; the provided scripts
  assess **readiness, roles, and the technical evidence** behind the controls and structure the
  plan/evidence artifacts — they do **not** replace the portal.
- **Automatic testing is partial.** Only **eligible** actions auto-test from Microsoft 365 signals;
  others need manual implementation/test and uploaded evidence. Availability is plan/action-dependent
  — verify.
- **Legal determinations are deferred.** GDPR applicability, lawful basis, ROPA (Art. 30) content,
  DPIA (Art. 35) outcomes, retention schedules, and evidence adequacy are **compliance/privacy/legal**
  determinations, not outputs of this tool.
- **No secrets in automation.** The scripts use interactive modern-auth sign-in; they never embed
  credentials.

## Naming convention (used in every doc and script)
Every artifact is named `<Purpose> – <Scope> – <Stage>` and reused verbatim across docs, scripts, and
the portal. The standard set:

| Artifact | Name |
|---|---|
| GDPR assessment (pilot) | `GDPR Assessment – Regulation – Pilot` |
| GDPR assessment (production) | `GDPR Assessment – Regulation – Production` |
| Article → control map | `GDPR Control Map – Articles` |
| Improvement-action plan (pilot) | `GDPR Action Plan – Pilot` |
| Evidence register | `GDPR Evidence – Register` |
| Automatic-testing setting | `GDPR Automatic Testing – Setting` |
| Score / posture report | `GDPR Posture – Report` |
| Role-separation evidence snapshot | `GDPR Roles – Separation Evidence` |
| Scope / owners record | `GDPR Scope – Record` |
| Sensitivity label (personal data) | `Sensitivity Label - Personal Data (GDPR) - All Users` |
| DLP policy (EU personal data) | `DLP Policy - EU Personal Data - Audit` (→ `... - Enforce` at the gate) |
| Auto-labeling policy | `Auto-Label - EU Personal Data - Pilot` |
| Retention label (storage limitation) | `Retention Label - Personal Data - Storage Limitation` |
| DSR access search (content search method) | `DSR - Data Subject Access - Search` |

## The standard deployment model
> Baseline the posture → design the assessment, scope, article map, and DSR method with
> compliance/privacy/legal → configure roles (separation), create the pilot assessment, build the
> action plan and evidence register, enable automatic testing, wire the DSR runbook → validate the
> technical evidence behind each control (piloting any new high-impact control in simulation/test) and
> run a test DSR → report the posture → expand to the full program and run the maintenance cadence.
> Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand** — GDPR
> applicability, lawful basis, ROPA content, DPIA outcomes, and evidence adequacy deferred to
> compliance/privacy/legal at every step.
