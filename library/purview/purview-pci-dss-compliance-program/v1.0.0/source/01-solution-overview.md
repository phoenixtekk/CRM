# 1. Solution Overview — Microsoft Purview PCI-DSS Compliance Program

## What this solution is
This solution stands up a **PCI-DSS-aligned compliance program in Microsoft Purview**: a **control
mapping** from the PCI-DSS requirements to the Purview capabilities that satisfy them, the **technical
controls** themselves configured (cardholder-data DLP, a cardholder-data sensitivity label, unified
audit logging, least-privilege access), and an **audit-ready evidence record** tying each control to
who owns it, its status, and the proof. The spine is **Compliance Manager** (the Purview capability
that turns compliance posture into a measured, points-based score with **improvement actions** and an
**evidence** store), built around the **PCI-DSS assessment template** and reinforced with the
data-protection controls PCI-DSS demands for stored account data.

It uses only the **Microsoft Purview portal** (`purview.microsoft.com`), **Security & Compliance
PowerShell** (`Connect-IPPSSession`), and **Microsoft Graph** — no third-party tooling. Every
high-impact control (notably the cardholder-data DLP policy) is **piloted in simulation/test mode
first**, validated, and only then enforced.

> **This delivers a Purview-backed control-and-evidence program — not a PCI attestation.** PCI-DSS is
> validated by a **Qualified Security Assessor (QSA)** or a **Self-Assessment Questionnaire (SAQ)**
> against your **Cardholder Data Environment (CDE)**. **Which** requirements and SAQ apply, **how** your
> CDE is scoped, and **whether** the evidence satisfies the standard are **QSA / compliance / legal
> determinations** — this solution provides the technical configuration method and the evidence, not
> the assessment verdict. It also covers only the requirements Purview can support (see the map below);
> network segmentation, firewalls, physical security, and anti-malware live in other systems.

## Why this matters
- **PCI-DSS obligations need mapped controls and evidence.** "Are we meeting Requirement 3 / 7 / 10?"
  has no defensible answer without a control-by-control record. Compliance Manager makes it a
  **measured, evidenced** position so gaps are visible, owned, and tracked instead of discovered in a
  QSA review.
- **Cardholder data is the crown jewel.** Requirement 3 (protect stored account data) is where Purview
  earns its keep: a **DLP policy** that detects the **Credit Card Number** sensitive information type,
  a **sensitivity label** for cardholder data, and classification insight into where Primary Account
  Numbers (PAN) live across the estate — configured the responsible way, **piloted in simulation**
  before it can block anything.
- **Evidence is the deliverable a QSA wants.** A control is only defensible with **who owns it, its
  status, its test date, and the proof**. Compliance Manager centralizes that; this solution makes
  producing it a routine, not a fire drill.
- **Control mapping avoids duplicated effort.** One well-implemented control (unified audit logging,
  say) satisfies PCI-DSS Requirement 10 **and** scores across NIST, ISO, and your internal baseline at
  once. The shared/control-mapping view shows that leverage so you fix once and score many.
- **CDE scoping and attestation are not technical calls.** *Which* systems are in the CDE, *which* SAQ
  applies, and *whether* the evidence satisfies the standard are **QSA / compliance / legal**
  determinations. This solution provides the method and the evidence; it does not decide scope or sign
  off adequacy.

## How it works
1. **Baseline and assess readiness (Assess).** Capture the current Compliance Score, confirm the
   **PCI-DSS assessment template** is available under your licensing, snapshot the role/separation
   posture, and inventory the cardholder-data signals already present (audit logging, any Credit Card
   Number DLP/label). Run `CMPPCI-Discovery.ps1` (read-only).
2. **Design the control map and scope (Design).** With your QSA/compliance stakeholders, agree the
   **in-scope PCI-DSS requirements**, the **CDE scope**, and the Purview-to-requirement **control map**
   (`PCI Control Map – Record`, `PCI Scope – Record`). CDE scoping and applicability are the
   stakeholders' determination.
3. **Configure the guardrails — least-privilege roles (Configure).** Assign the Purview/Compliance
   role groups least-privilege and separated (administer ≠ contribute ≠ read-only) — the auditable
   access control behind PCI-DSS Requirement 7, snapshotted as `PCI Roles – Separation Evidence`.
4. **Create the PCI-DSS assessment and action plan (Configure).** In Compliance Manager, create
   `PCI Assessment – Baseline – Pilot` from the PCI-DSS template; build the **improvement-action plan**
   (`PCI Action Plan – Pilot`) with an **owner, target date, status, and evidence source** per action.
5. **Configure the cardholder-data controls in SIMULATION (Configure — pilot-first).** Create the
   cardholder-data DLP policy `DLP-PCI-CardholderData` (detecting the **Credit Card Number** SIT) in
   **test/simulation mode**, and the `Label-PCI-CardholderData` sensitivity label — so you can see what
   *would* be caught before anything is blocked. `CMPPCI-Configuration.ps1` is **`-WhatIf` by default**.
6. **Validate the evidence (Pilot → Validate).** Confirm the technical state behind the controls
   (audit enabled, DLP simulation matching PAN, label published, roles separated) matches what the
   assessment claims; attach the evidence; set test status/date. `CMPPCI-Validation.ps1` (read-only) is
   the cross-check.
7. **Report and expand (Validate → Expand).** Roll up the posture (`PCI Posture – Report`), then move
   the validated DLP policy from **simulation to enforce** under change control, extend the action plan
   to the full requirement set, and stand up the maintenance cadence (re-test, re-evidence, watch for
   template/standard updates).

## The PCI-DSS → Purview control map (what Purview can and cannot cover)
| PCI-DSS requirement (v4.x) | Purview capability in this program | Coverage |
|---|---|---|
| **Req 3 — Protect stored account data** | Cardholder-data **DLP** (Credit Card Number SIT), **sensitivity label**, **content/classification explorer** to locate PAN | **Direct** |
| **Req 7 — Restrict access by need-to-know** | Least-privilege **Purview role groups** + separation (evidence of RBAC governance) | **Supporting** |
| **Req 10 — Log and monitor all access** | **Unified audit logging** (Purview Audit) enabled + retained | **Direct** |
| **Req 12 — Information-security policy** | **Compliance Manager** evidence store: documented policies, owners, review dates | **Supporting** |
| **Req 9 — Physical access · Req 1/2 — Network · Req 5 — Anti-malware · Req 11 — Testing** | *Not a Purview control* — tracked as **evidence links** to the owning system in Compliance Manager | **Out of scope (evidence only)** |
> Purview directly implements the **data-protection, access-governance, and logging** requirements and
> centralizes **evidence** for the rest. It does **not** replace firewalls, segmentation, vulnerability
> scanning, or physical controls. **Confirm the exact requirement set and versions against the PCI-DSS
> version and SAQ your acquirer/QSA requires — do not assume.**

## The role-separation model (least privilege — PCI-DSS Req 7)
| Role group | Who | Can (typical) |
|---|---|---|
| **Compliance Manager Administrators / Compliance Administrator** | Program owners / IT config | Manage assessments, settings, role assignment; configure DLP/labels/audit |
| **Compliance Manager Assessors** | Assessment leads | Create assessments, implement actions, set **test** status |
| **Compliance Manager Contributors** | Action owners | Edit improvement actions and evidence (not test status) |
| **Compliance Manager Readers** | QSA / oversight / auditors | **Read-only** access to the program data |
> Global Administrator only where genuinely required. **Verify the exact role-group names and rights in
> your tenant** — Purview role naming evolves; do not assume. Least privilege is the point.

## Named artifacts (used verbatim in every doc and script)
Every artifact this solution creates or tracks is named and reused verbatim across docs, scripts, and
the portal:

| Artifact | Name |
|---|---|
| PCI-DSS assessment (pilot) | `PCI Assessment – Baseline – Pilot` |
| PCI-DSS assessment (production) | `PCI Assessment – Production` |
| Cardholder-data DLP policy (simulation-first) | `DLP-PCI-CardholderData` |
| Cardholder-data DLP rule | `DLP-PCI-CardholderData-Rule` |
| Cardholder-data sensitivity label | `Label-PCI-CardholderData` |
| Improvement-action plan (pilot) | `PCI Action Plan – Pilot` |
| Evidence register | `PCI Evidence – Register` |
| Control-mapping record | `PCI Control Map – Record` |
| Posture / score report | `PCI Posture – Report` |
| Role-separation evidence snapshot | `PCI Roles – Separation Evidence` |
| Scope / CDE / owners record | `PCI Scope – Record` |
| Pilot scope group | `SG-PCI-Pilot` |

## Limitations (be honest with buyers)
- **Purview covers a subset of PCI-DSS.** It directly implements the **data-protection (Req 3)**,
  **access-governance (Req 7)**, and **logging (Req 10)** requirements and centralizes **evidence** for
  the rest; it does **not** provide firewalls, segmentation, vulnerability scanning, or physical
  controls. This is a **compliance program in Purview**, not a whole-standard implementation.
- **Premium content is licensing-gated.** The **PCI-DSS assessment template** in Compliance Manager is
  a **premium template** requiring **Microsoft 365 E5 / E5 Compliance** or the **Compliance Manager
  Premium Assessment Add-On**; advanced DLP and auto-labeling likewise require E5-class licensing.
  **Verify entitlement — do not assume a template or feature is available.**
- **Compliance Manager measures; DLP/labels enforce.** Compliance Manager scores and records evidence;
  it does **not** change your tenant. The cardholder-data **DLP** and **label** are the controls that
  actually protect data — and they are **piloted in simulation/test first** because enforcement is
  high-impact.
- **Attestation is not technical.** *Which* SAQ applies, *how* the CDE is scoped, and *whether* the
  evidence satisfies PCI-DSS are **QSA / compliance / legal** determinations, not outputs of this tool.
- **No secrets in automation.** The provided scripts use interactive modern-auth sign-in; they never
  embed credentials.

## The standard deployment model
> Baseline and assess → design the control map, CDE scope, and owners → configure least-privilege roles,
> create the PCI-DSS assessment and action plan, configure the cardholder-data DLP/label **in
> simulation** → validate the evidence behind the controls → report the posture → move DLP to enforce and
> expand to the full requirement set with a maintenance cadence.
> Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand** — CDE scoping,
> SAQ applicability, and attestation adequacy deferred to QSA / compliance / legal at every step.
