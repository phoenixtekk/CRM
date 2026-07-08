# 1. Solution Overview — Microsoft Purview HIPAA Compliance Program

## What this solution is
This solution stands up a **HIPAA-aligned compliance program inside Microsoft Purview**: it maps the
**HIPAA Security Rule** safeguards (and the HITECH/Breach-Notification and, where scoped, HITRUST CSF
overlays) to the **Microsoft Purview** technical controls that satisfy them, measures the program with
**Compliance Manager**, and produces the **evidence** — owners, implementation status, test status, and
proof — that makes the posture **defensible**. The output is a scored, control-by-control HIPAA program
with a control map, an improvement-action plan, an evidence register, and a posture report — configured,
piloted where high-impact, and validated.

It is the **program umbrella**, not a single control: it uses **Compliance Manager** (the
**HIPAA/HITECH** assessment template, plus **HITRUST CSF** where entitled) to score, and it maps each
safeguard to the Purview capability that evidences it — **Audit**, **sensitivity labels**, **Data Loss
Prevention (DLP)**, **data lifecycle / retention**, **sensitive information types**, and (where scoped)
**Insider Risk Management**, **Communication Compliance**, and **eDiscovery/legal hold**. It uses only
the **Microsoft Purview portal** (`purview.microsoft.com`), **Security & Compliance PowerShell**
(`Connect-IPPSSession`), and **Microsoft Graph** — no third-party tooling.

> **This is a program, not a determination.** Purview and Compliance Manager give you the **measurement,
> control mapping, and evidence**. Whether a given safeguard is **required** or **addressable** for your
> organization, how you satisfy an addressable specification, the outcome of your **risk analysis**, and
> whether the collected evidence **satisfies** your HIPAA obligation are **compliance, privacy, security,
> and legal determinations** — this solution provides the technical method and the proof, not the ruling.

> **Distinct from the endpoint / DLP HIPAA products.** A HIPAA **endpoint** or **PHI DLP** solution
> configures a *specific* control (device policy, or DLP for electronic PHI). **This program sits above
> them**: it maps *all* the HIPAA Security-Rule safeguards to Purview controls, scores the whole program
> in Compliance Manager, and collects the cross-control evidence. It **references** the individual
> technical controls; it does not re-implement each one — where a safeguard needs a high-impact technical
> change (a new DLP, label, or retention policy), that change is **piloted in simulation/test** under its
> own solution and change control, and this program **evidences** that it is in place.

## Why this matters
- **"Are we HIPAA-compliant?" has no defensible answer without a scored control map.** HIPAA's Security
  Rule is a set of **Administrative, Physical, and Technical safeguards** (§164.308/310/312) plus
  organizational and documentation requirements (§164.314/316). Compliance Manager turns that into a
  **measured score** with a per-control status and evidence, so gaps are **visible, owned, and tracked**
  instead of discovered in an audit or a breach investigation.
- **Evidence is what an OCR investigation or a business associate audit asks for.** A posture is only
  defensible if each safeguard carries **who owns it, whether it is implemented, when it was tested, and
  the proof**. This program centralizes that record — audit-log configuration, DLP for ePHI, labels,
  retention, access controls — so producing it is a routine, not a fire drill.
- **Control mapping means you evidence once and score many.** One well-implemented control — unified
  **audit logging**, say — satisfies HIPAA §164.312(b) *and* maps across HITRUST, NIST, and your internal
  baseline in Compliance Manager's **shared-control** model. You fix once and the score updates in every
  assessment that shares the control.
- **Applicability and adequacy are not technical calls.** *Which* safeguards apply, how each
  **addressable** specification is met, and *whether* the evidence is sufficient are
  **compliance/privacy/legal** determinations. This program supplies the configuration method and the
  evidence; it does not decide sufficiency.

## How it works
1. **Baseline the posture (Assess).** Confirm licensing and the Compliance Manager role groups, capture
   the current **Compliance Score** and technical-control state (audit on/off, DLP/label/retention
   presence), and record the readiness snapshot (`HIPAA Roles – Separation Evidence`).
2. **Design the assessment, scope, and safeguard map (Design).** With compliance/privacy/legal
   stakeholders, confirm the **in-scope assessment template** (HIPAA/HITECH, plus HITRUST CSF where
   entitled), the **scope** (workloads holding ePHI, the systems in scope), and the **safeguard-to-Purview
   control map** (`HIPAA Control Map – Safeguards`, `HIPAA Scope – Record`). Applicability is the
   stakeholders' determination.
3. **Populate roles with separation (Configure — guardrails).** Assign the Compliance Manager role groups
   least-privilege so program **administrators** are separated from action **contributors** and read-only
   **readers/auditors** — the auditable access record for the evidence you produce.
4. **Create the assessment and build the action plan (Configure).** Create `HIPAA Assessment – HITECH –
   Pilot` from the template, then build the **improvement-action plan** (`HIPAA Action Plan – Pilot`):
   each action mapped to its safeguard, assigned an **owner**, a **target date**, an **implementation
   status**, and a **test status**, with **evidence** attached.
5. **Turn on automatic testing where it applies (Configure).** Compliance Manager can **auto-test**
   eligible actions by reading Microsoft 365 configuration signals (`HIPAA Automatic Testing – Setting`);
   enable it so technical safeguards update their status without manual re-checks. Availability is
   plan/action-dependent — verify.
6. **Validate the evidence behind the safeguards (Pilot → Validate).** Confirm the **technical state**
   backing the mapped controls — **audit enabled**, **DLP for ePHI present**, **sensitivity labels /
   encryption**, **retention**, **Conditional Access / MFA** — matches what the assessment claims; attach
   evidence and set test status/date. Pilot any *new* high-impact technical control in **simulation/test**
   first, under its own change control.
7. **Report and expand (Validate → Expand).** Roll up the score, safeguard-status breakdown, and evidence
   register (`HIPAA Posture – Report`); then add the remaining production assessment(s), lean on shared
   controls, and stand up the **maintenance cadence** (re-test, re-evidence, review owners, watch
   template/regulation updates).

## The HIPAA safeguard → Purview control map (the technical method, not the ruling)
This is the **method** for evidencing each safeguard with a Purview capability. *Whether* a safeguard
applies and *how* an **addressable** specification is satisfied are compliance/privacy/legal
determinations; **verify feature availability against your licensing/tenant**.

| HIPAA Security Rule safeguard | Purview capability that evidences it |
|---|---|
| **Audit controls** — §164.312(b) | **Purview Audit** (unified audit log ingestion on; Audit Premium where entitled) |
| **Access control** — §164.312(a) | **Sensitivity labels** (+ encryption), **DLP**, and **Conditional Access / MFA** (Entra) |
| **Person/entity authentication** — §164.312(d) | **Conditional Access / MFA** evidence (Entra, via Graph) |
| **Transmission security** — §164.312(e) | **Message encryption**, label-based encryption, **DLP** on ePHI in transit |
| **Integrity** — §164.312(c) | **Data lifecycle / retention** and records controls; label protection |
| **Information access management** — §164.308(a)(4) | **DLP** + **sensitivity labels** scoping access to ePHI |
| **Identify ePHI** (basis for many safeguards) | **Sensitive information types** (U.S. health/HIPAA SITs) + **classification** |
| **Contingency / data availability** — §164.308(a)(7) | **Retention** policies preserving ePHI-bearing content |
| **Security incident / monitoring** — §164.308(a)(6) | **Insider Risk Management**, **Communication Compliance** (where scoped; HR/privacy-gated) |
| **Breach investigation / legal hold** — §164.400–414 | **eDiscovery** + **legal hold** for evidence preservation |
| **Documentation / evaluation** — §164.308(a)(8), §164.316 | **Compliance Manager** evidence store + posture report |

> Insider Risk Management and Communication Compliance are **HR/privacy-sensitive** — configure them
> **privacy-by-design** (pseudonymization where available, strict **role separation**), and defer all case
> **outcomes** to HR/legal. This program evidences that the *capability* exists, not any case action.

## The role-separation model (least privilege)
| Role group | Who | Can (typical) |
|---|---|---|
| **Compliance Manager Administrators** | Program owners / IT config | Read and edit all Compliance Manager data; manage settings, templates, role assignment |
| **Compliance Manager Assessors** | Assessment leads | Read data, **create assessments**, implement actions, edit **test** status |
| **Compliance Manager Contributors** | Safeguard/action owners | Read data, create assessments, **edit improvement actions** (not test status) |
| **Compliance Manager Readers** | Oversight / auditors / HIPAA Security Officer review | **Read-only** access |
> Global Administrator, Compliance Administrator, and Compliance Data Administrator also have access.
> **Verify the exact role-group names and rights in your tenant** — Purview role naming evolves; do not
> assume. The HIPAA **Security Officer** and **Privacy Officer** are typically *readers/oversight*, with
> configuration done by least-privilege assessors/contributors.

## What you can control
- The **in-scope assessment template(s)** — HIPAA/HITECH (and HITRUST CSF where entitled) — and how
  assessments are **grouped**.
- The **safeguard-to-control map** and the **improvement-action plan** — owners, target dates,
  implementation status, test status, and the **evidence** attached to each action.
- Whether **automatic testing** of eligible actions is on, so technical safeguards self-update.
- The **role-group membership** enforcing least-privilege separation.
- The **pilot subset** (one HIPAA assessment) validated first before the full program is expanded.

## Limitations (be honest with buyers)
- **Compliance Manager measures; it does not enforce.** It scores and recommends; it does **not** change
  the tenant. Acting on an improvement action (a new DLP/label/retention/CA policy) is a **separate**,
  **piloted-in-simulation** change owned by that feature's solution.
- **Premium content is licensing-gated.** The **Data Protection Baseline** is included, but the
  **HIPAA/HITECH** and **HITRUST CSF** premium templates require **Microsoft 365 E5 / E5 Compliance** or
  the **Compliance Manager Premium Assessment Add-On**, and the **number** of premium assessments depends
  on your entitlement. **Verify — do not assume a template is available.** GCC/GCC High and sovereign
  clouds may differ.
- **Portal-driven.** Assessments, improvement actions, evidence upload, and the authoritative score are
  managed in the **Purview portal**. Compliance Manager does **not** expose a broad public PowerShell/Graph
  API to create assessments or set action status; the provided scripts assess **readiness, roles, and the
  technical evidence** behind the safeguards and structure the plan/evidence artifacts — they do **not**
  replace the portal.
- **Automatic testing is partial.** Only **eligible** actions auto-test from Microsoft 365 signals; others
  need manual implementation/test and uploaded evidence. Availability is plan/action-dependent — verify.
- **Applicability, addressable-spec choices, risk-analysis outcomes, and adequacy are not technical.**
  They are **compliance/privacy/legal** determinations, not outputs of this tool. Records-retention
  schedules and legal holds are likewise deferred.
- **No secrets in automation.** The scripts use interactive modern-auth sign-in; they never embed
  credentials.

## Naming convention (used in every doc and script)
Every artifact is named `<Purpose> – <Scope> – <Stage>` and reused verbatim across docs, scripts, and the
portal. The standard set:

| Artifact | Name |
|---|---|
| HIPAA assessment (pilot) | `HIPAA Assessment – HITECH – Pilot` |
| HIPAA assessment (production) | `HIPAA Assessment – Security Rule – Production` |
| HITRUST assessment (where entitled) | `HIPAA Assessment – HITRUST CSF – Production` |
| Safeguard → control map | `HIPAA Control Map – Safeguards` |
| Improvement-action plan (pilot) | `HIPAA Action Plan – Pilot` |
| Evidence register | `HIPAA Evidence – Register` |
| Automatic-testing setting | `HIPAA Automatic Testing – Setting` |
| Score / posture report | `HIPAA Posture – Report` |
| Role-separation evidence snapshot | `HIPAA Roles – Separation Evidence` |
| Scope / owners record | `HIPAA Scope – Record` |

## The standard deployment model
> Baseline the posture → design the assessment, scope, and safeguard map with compliance/privacy/legal →
> configure roles (separation), create the pilot assessment, build the action plan and evidence register,
> enable automatic testing → validate the technical evidence behind each safeguard (piloting any new
> high-impact control in simulation/test) → report the posture → expand to the full program and run the
> maintenance cadence.
> Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand** — HIPAA
> applicability, addressable-spec choices, risk-analysis outcomes, and evidence adequacy deferred to
> compliance/privacy/legal at every step.
