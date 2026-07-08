# 1. Solution Overview — Microsoft Purview CJIS Compliance Program

## What this solution is
Agencies that handle **Criminal Justice Information (CJI)** — including Criminal History Record
Information (CHRI) — must satisfy the **FBI CJIS Security Policy**, and must be able to **prove** it at a
formal audit. Microsoft Purview provides much of the technical machinery — classification, encryption,
data loss prevention, retention/records, and audit logging — but out of the box none of it is **mapped
to CJIS**, configured **against CJI**, or assembled into **audit evidence**. This solution delivers a
**CJIS-aligned Purview program**: a **control map** from the relevant CJIS Security Policy areas to
concrete Purview capabilities; the **configured controls** (a CJI sensitivity label with encryption, a
CJI-exfiltration DLP policy, CJI retention, and audit logging) **piloted in simulation/test first**; and
a repeatable **audit-evidence package** the agency's CJIS auditor and CSA can review. It uses only the
**Microsoft Purview portal**, **Security & Compliance PowerShell**, and **Microsoft Graph** — no
third-party tooling.

> **Environment boundary — read first.** CJIS compliance is generally satisfied only in a
> **US sovereign / government cloud** — **Microsoft 365 GCC High** or **Azure Government** — under a
> signed Microsoft **CJIS Security Addendum / agreement**, with personnel screening and other
> administrative controls the platform cannot provide. **Commercial Microsoft 365 is generally not
> CJIS-authorized.** This solution configures the **technical** Purview controls and produces evidence;
> **whether your environment, agreements, and personnel controls meet CJIS is a determination for your
> CJIS Systems Agency (CSA), CJIS Systems Officer (CSO), and auditor — not this solution.** Verify your
> cloud environment and agreements before relying on any control here.

## Why this matters
- **CJIS non-compliance has real consequences.** A failed formal audit can suspend an agency's access to
  CJI systems. The controls must be **in place** and, just as importantly, **evidenced**.
- **Purview is the technical toolset, but it's unmapped.** Sensitivity labels, DLP, retention, and audit
  each contribute to CJIS policy areas (auditing & accountability, access control, information
  protection, media protection), but only once they are **explicitly mapped** and **configured against
  CJI** — not left as generic tenant settings.
- **Auditors ask for evidence, not screenshots.** "Show me how CJI is protected and monitored" needs a
  repeatable package: which control, which Purview object, what state, and the audit trail — assembled
  the same way every cycle.
- **The capabilities are licensing-dependent and evolving.** Advanced DLP, auto-labeling, Audit
  (Premium), and Compliance Manager's premium/US-gov assessment templates require **E5 / E5 Compliance**
  (some preview), and availability differs in **GCC High / Azure Government** — the program shows what
  your tenant actually has and flags the rest.

## How it works
1. **Assess.** Discovery connects (read-only) and reports the tenant's licensing (E5 / E5 Compliance,
   Audit Premium), the existing CJI-relevant labels/DLP/retention/audit configuration, the **unified
   audit logging** state, and whether a **CJIS assessment template** is available in Compliance Manager —
   flagging environment/licensing items to **verify** (GCC High / Azure Government).
2. **Map.** Build the `CJIS Control Map – Purview – Baseline`: each relevant CJIS Security Policy area →
   the Purview capability that contributes to it → the specific object that will implement it. The
   **control-satisfaction determination stays with the CSA/auditor**; the map records the technical
   method and the evidence.
3. **Configure (simulation/test first).** Scaffold the `CJI – Protected – Label` (with encryption), the
   `CJI Protection – Exfiltration – Policy` DLP policy **in test/simulation mode**, the `CJI Records –
   Retention – Policy` (staged), and confirm audit logging is on — every high-impact policy piloted
   before enforcement.
4. **Pilot.** Validate on the bounded `CJIS Pilot – CJI Scope – Stage1` — a named set of users/sites —
   reviewing the DLP simulation results with the agency's security officer before anything enforces.
5. **Validate.** A read-only validation confirms each mapped control's Purview object exists, is in the
   expected state (label encrypts, DLP in test mode, retention staged, audit on), and that **role
   separation** holds — technical pass/fail, not an adequacy judgement.
6. **Evidence & expand.** Produce the `CJIS Evidence – Formal Audit – Package` for the auditor/CSA, then
   expand the controls to enforcement under change control once the pilot passes and the agency approves.

## The CJIS policy areas Purview contributes to (verify against your current CJIS Security Policy version)
- **Auditing & Accountability** — unified audit logging + **Audit (Premium)** retention of CJI-touching
  activity; formal-audit evidence.
- **Access Control / Information Flow** — **sensitivity labels** (encryption, access scoping) and **DLP**
  to prevent CJI leaving the authorized boundary.
- **Information / System & Communications Protection** — label-based **encryption** of CJI at rest;
  DLP-enforced handling.
- **Media Protection / Records** — **retention & records** management of CJI records per the agency's
  schedule (the **schedule itself is a records/legal determination**).
- **Personnel / Insider threat (aggregate)** — where licensed, **Insider Risk** aggregate indicators,
  privacy-by-design, outcomes **deferred to the agency's HR/legal and CJIS governance**.

> Exact CJIS control numbers and the mapping to NIST 800-53 differ between CJIS Security Policy versions
> (e.g. 5.9.x vs the 6.0 restructuring). This solution maps by **policy area / control intent** and
> flags **"verify against your current CJIS Security Policy version with your CSA/CSO"** — it does not
> assert a control number it cannot confirm.

## What you can control
- The **control map** — which CJIS policy areas are in scope and which Purview objects implement them.
- The **CJI classification scheme** (the label and any custom Sensitive Information Types — the specific
  CJI identifiers come from the agency, not invented here).
- The **DLP scope and actions**, the **retention schedule** (agency determination), and the **audit
  retention** target.
- The **pilot scope**, the **thresholds/gates**, and the **evidence package** format for your auditor.

## Limitations (be honest with buyers)
- **This does not make you CJIS-compliant by itself.** It configures **technical Purview controls** and
  assembles evidence. CJIS compliance also requires the **authorized environment** (GCC High / Azure
  Government), **signed agreements**, **personnel screening**, physical/network controls, and the
  **CSA/auditor's determination** — none of which a Purview program provides.
- **Environment- and licensing-gated.** Several capabilities require **E5 / E5 Compliance** and specific
  availability in **GCC High / Azure Government**; the program shows what your tenant has and flags the
  rest as *"verify your licensing/tenant/environment."*
- **The determination is not ours.** Whether a control **satisfies** its CJIS requirement, the **records
  retention schedule**, and **regulatory applicability** are **CSA / CJIS auditor / records / legal**
  determinations. The solution provides the technical method and the evidence, not the judgement.
- **Insider Risk is privacy-sensitive.** Only **aggregate, de-identified** indicators are used, under
  strict **role separation**; outcomes are **deferred to the agency's HR/legal and CJIS governance**.

## Naming convention (used in every doc and script)
Every artifact this solution creates is named `<Purpose> – <Scope> – <Stage>` and reused verbatim across
the docs, scripts, and portal. The standard set:

| Artifact | Name |
|---|---|
| The CJIS-to-Purview control map | `CJIS Control Map – Purview – Baseline` |
| The CJI sensitivity label (encryption) | `CJI – Protected – Label` |
| The CJI-exfiltration DLP policy | `CJI Protection – Exfiltration – Policy` |
| The CJI retention/records policy | `CJI Records – Retention – Policy` |
| The Compliance Manager assessment | `CJIS Assessment – Compliance Manager – Baseline` |
| The formal-audit evidence package | `CJIS Evidence – Formal Audit – Package` |
| The pilot scope validated first | `CJIS Pilot – CJI Scope – Stage1` |

## The standard deployment model
> Assess licensing/environment and current state → map CJIS policy areas to Purview controls → configure
> the CJI label, DLP, retention, and audit in **simulation/test** → **pilot** on a bounded CJI scope and
> review with the security officer → validate each control's technical state and role separation →
> expand to enforcement and produce the formal-audit evidence package. Pattern:
> **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).**
