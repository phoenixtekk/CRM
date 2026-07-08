# 1. Solution Overview — Microsoft Purview NIST 800-53 Compliance Program

## What this solution is
NIST SP 800-53 obligations arrive as a catalog of controls — access control, audit and accountability,
media protection, system and communications protection, and more — that someone must **map to what your
tenant actually does**, **configure where there's a gap**, and **evidence** so an assessor can see the
control is real. Too many organizations answer "how do you meet AU-2 / SC-28 / MP-7?" with a slide
instead of a policy object and an audit record. This solution stands up a **NIST 800-53-aligned program
inside Microsoft Purview**: it builds the assessment in **Microsoft Purview Compliance Manager** from the
**NIST SP 800-53 Rev. 5** template, **maps each relevant control family to the Purview capability that
implements it** (Audit, DLP, sensitivity labels, retention/records, DSPM), **configures the supporting
controls** — piloted in **simulation/test** mode first — and produces a **control-to-evidence report**
the assessment package can cite. It uses only the **Microsoft Purview portal**
(`https://purview.microsoft.com`), **Security & Compliance PowerShell** (`Connect-IPPSSession`),
**Exchange Online PowerShell**, and **Microsoft Graph** — no third-party tooling.

## What it does — and does not — decide
- **It delivers** the technical control mapping, the configured Purview controls, and the audit/assessment
  evidence: the *how*.
- **It does not make the authorization determination.** Whether the system is **authorized to operate**,
  the **authorization boundary**, the acceptance of **residual risk**, control **tailoring/applicability**,
  and the **retention/records/legal** schedule are decisions for your **Authorizing Official (AO), security,
  compliance, records, privacy, and legal** functions under your Risk Management Framework (RMF). Purview
  supplies the evidence and the configured control; the **authorization and applicability determinations
  are deferred** to those functions. This boundary is stated in every document.

## Why this matters
- **Assessors ask for control implementation, not intent.** A NIST 800-53 assessment tests whether a control
  is *implemented, documented, and evidenced*. A published DLP policy, a sensitivity label with encryption,
  an audit retention policy, and a Compliance Manager improvement action with an uploaded artifact are
  concrete implementation — a policy statement alone is not.
- **Purview implements a large slice of the technical families.** Microsoft's Compliance Manager NIST SP
  800-53 template ships the control set and improvement actions; the underlying controls are delivered by
  Purview **Audit** (AU), **DLP** (SC/MP/SI), **sensitivity labels & encryption** (AC/SC/MP), **data
  lifecycle & records** (AU/SI/retention), and **DSPM** (RA/CA visibility). Getting them mapped and
  configured once turns a recurring scramble into a maintained program.
- **The controls are licensing-dependent and the portal evolves.** The Compliance Manager **premium
  templates** (including NIST 800-53), advanced DLP, auto-labeling, and DSPM require **Microsoft 365 E5**
  or the **E5 Compliance** add-on; Compliance Manager's improvement-action count and the portal paths
  change over time. This solution **cites or flags "verify your licensing/tenant"** — it does not assert a
  capability you may not have.

## How it works
1. **Assess (map).** Confirm licensing and roles, create the **`NIST 800-53 – Rev5 – Assessment`** in
   Compliance Manager from the NIST SP 800-53 Rev. 5 template, and inventory the Purview controls already
   in place (audit state, DLP policies, published labels, retention policies) so you can see, per control
   family, what exists and what's a gap.
2. **Design (control-to-Purview map).** Record the **`NIST 800-53 – Control-to-Purview – Map`** — which
   control family each Purview capability satisfies, and which controls are **not** technical (deferred to
   process/AO). Agree the **pilot scope** `NIST Pilot – Control Set – Stage1`.
3. **Configure (pilot in simulation/test).** Where a supporting control is missing, create it **safe-first**:
   DLP policies in **simulation/test mode**, sensitivity/retention objects in a limited scope, audit
   retention enabled — every change previewed under `-WhatIf` and committed only with `-Commit`.
4. **Validate.** Run the validation scorecard: for each mapped control family, confirm the Purview evidence
   exists (audit on, the DLP policy present, labels published, retention configured, the assessment created).
5. **Evidence & report.** Produce **`NIST 800-53 – Control Evidence – Report`** — the control-family-to-Purview
   artifact map with status — and attach the concrete artifacts (policy exports, audit configuration,
   Compliance Manager improvement-action evidence) to the assessment package. The **authorization
   determination on that package is the AO's**, not ours.
6. **Expand & maintain.** Once the pilot passes, move DLP from simulation to enforce, extend scope, and
   schedule the read-only Discovery→Validate→Report chain so control drift is caught and the evidence stays
   current between assessments.

## The control families this solution addresses in Purview
| NIST 800-53 family | Purview capability that supports it | Notes |
|---|---|---|
| **AU — Audit & Accountability** | Purview **Audit** (unified audit log, mailbox auditing, audit retention policies) | Audit is not retroactive — enable early. |
| **AC — Access Control** | **Sensitivity labels** (encryption/usage rights), DLP sharing controls | Identity/Conditional Access controls live in **Entra**, not Purview — noted, not claimed. |
| **SC — System & Communications Protection** | Sensitivity-label **encryption**, **message encryption**, DLP | SC-8/SC-28 protection of data in transit/at rest. |
| **MP — Media Protection** | **Endpoint/removable-media DLP**, labels | MP-7 restrict removable media. |
| **SI — System & Information Integrity** | **DLP** monitoring, **DSPM** posture | Detection/alerting evidence. |
| **CA / RA — Assessment / Risk** | **Compliance Manager** assessment + **DSPM** | CA/RA visibility; **authorization = AO decision (deferred)**. |
| **CM / PL / PM — Config / Planning / Program** | Compliance Manager improvement actions & program record | Program governance evidence. |
| **AT, IR, PS, PE, others** | Largely **process/organizational** | Mostly **deferred** to your program; Purview supplies partial technical evidence only. |

> Purview does **not** implement every NIST 800-53 control — many are physical, personnel, or procedural.
> The map is explicit about which families Purview covers technically and which are deferred to your
> program. **Verify current family/template coverage against Microsoft documentation and your licensing.**

## What you can control
- Which control families are **in scope** for the Purview program and which are handled by process.
- Which supporting Purview controls to configure, and their **simulation → enforce** progression.
- The **pilot scope** validated before any tenant-wide enforcement.
- The **evidence set** attached to the assessment package (policy exports, audit config, improvement-action
  artifacts).

## Limitations (be honest with buyers)
- **The authorization/ATO determination is not ours.** This solution configures and evidences controls;
  **whether the system is authorized, the boundary, residual-risk acceptance, and control applicability are
  the AO's / security's / legal's decisions — deferred.**
- **Purview covers a subset of NIST 800-53.** Physical (PE), personnel (PS), awareness (AT), and much of IR
  are organizational; Purview provides partial or no technical evidence for them. Don't represent Purview as
  full 800-53 coverage.
- **Premium features are license-gated.** The Compliance Manager NIST 800-53 **premium template**, advanced
  DLP, auto-labeling, and DSPM require **E5 / E5 Compliance**. **Verify your licensing/tenant.**
- **Compliance Manager is primarily portal-driven.** Assessment creation, improvement-action evidence upload,
  and score are done in the **Purview portal**; the scripts inventory and validate the **underlying Purview
  controls** (audit, DLP, labels, retention, roles) that supply the evidence — they do not invent a
  Compliance Manager cmdlet. **Verify current Compliance Manager automation options for your tenant.**
- **Audit is not retroactive.** Audit-based control evidence (AU family) accrues from the enablement date
  forward — enable it before, not during, an assessment.
- **The portal and templates evolve.** Control counts, improvement actions, and paths change; treat the map
  as maintained, and verify against current Microsoft documentation.

## Naming convention (used in every doc and script)
Every artifact this solution creates is named `<Purpose> – <Framework/Family> – <Stage>` and reused verbatim
across the docs, scripts, and portal:

| Artifact | Name |
|---|---|
| Compliance Manager assessment (NIST SP 800-53 Rev. 5 template) | `NIST 800-53 – Rev5 – Assessment` |
| Control-to-Purview mapping workbook | `NIST 800-53 – Control-to-Purview – Map` |
| Audit-evidence retention policy (AU family) | `Control Evidence – NIST AU – Audit Retention` |
| Control-support DLP policy (SC/MP, simulation-first) | `Control Evidence – NIST SC-MP – DLP (Simulation)` |
| Control-evidence report / package export | `NIST 800-53 – Control Evidence – Report` |
| Pilot scope | `NIST Pilot – Control Set – Stage1` |

## The standard deployment model
> Assess what NIST 800-53 requires and what Purview already does → design the control-to-Purview map →
> configure the supporting controls → **pilot in simulation/test** on a limited scope → validate the
> evidence exists per family → expand to enforcement and maintain. Pattern:
> **Assess → Design → Configure → Pilot (simulate) → Validate → Expand (enforce).**
> The **authorization determination** on the resulting evidence is the **AO's** — deferred, by design.
