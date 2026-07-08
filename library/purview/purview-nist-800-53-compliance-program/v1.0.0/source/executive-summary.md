# Executive Summary — Microsoft Purview NIST 800-53 Compliance Program

## The problem
NIST SP 800-53 arrives as a catalog of controls that someone must **map to what the tenant actually does**,
**configure where there's a gap**, and **evidence** so an assessor can see the control is real. Too often the
answer to "how do you meet AU-2 / SC-28 / MP-7?" is a slide, not a policy object and an audit record. Left
unaddressed, that's both a compliance gap and a data-risk exposure — and audit-based evidence is **not
retroactive**, so the window to capture it closes quietly.

## The solution
A complete, self-guided **NIST 800-53-aligned program inside Microsoft Purview**. It creates the assessment
in **Compliance Manager** from the **NIST SP 800-53 Rev. 5** template, **maps each relevant control family to
the Purview capability that implements it** — Audit (AU), DLP (SC/MP/SI), sensitivity labels & encryption
(AC/SC), retention/records, and DSPM — **configures the supporting controls** (piloted in **simulation/test**
first), and produces a **control-to-evidence report** the assessment package can cite. Five safe-by-default
PowerShell tools (read-only or `-WhatIf`/simulation until you commit) do the scope check, posture discovery,
configuration, per-family validation, and evidence reporting.

## What you get
- **A concrete control-to-Purview map** — which family each Purview capability satisfies, and which controls
  are non-technical and deferred to your program (honest coverage, not overstated).
- **The AU foundation** — unified audit logging on and an audit-evidence retention policy, so accountability
  evidence exists across the assessment window.
- **A configured SC/MP control** — a DLP policy created **in simulation** that evidences detection without
  blocking users, then promoted to enforce after the pilot passes.
- **Access/protection evidence** — sensitivity-label encryption and usage rights referenced for AC-3/SC-28.
- **A defensible evidence package** — a family-to-artifact report plus the concrete artifacts attached to
  Compliance Manager improvement actions, kept current by a scheduled read-only monitoring chain.

## Approach
Delivery follows a disciplined, reversible model — **Assess → Design → Configure → Pilot (simulate) →
Validate → Expand (enforce)** — configuring high-impact controls **in simulation/test on a limited pilot**
before any tenant-wide enforcement, with pass/fail gates and documented rollback at every step.

## Boundaries
This solution provides the technical control configuration and the evidence. **Control
applicability/tailoring, evidence sufficiency, residual-risk acceptance, the authorization boundary, and the
authorization determination (ATO) are deferred to your Authorizing Official, security, compliance, records,
privacy, and legal functions.** Microsoft Purview implements a **subset** of NIST 800-53 — physical,
personnel, awareness, and much of incident response are organizational. Capabilities are
**licensing-/plan-dependent** (the NIST premium template, advanced DLP, and DSPM require E5 / E5 Compliance)
and the portal and templates are **actively evolving** — availability and paths are cited or flagged
**"verify your licensing/tenant,"** never assumed.

## The bottom line
A NIST 800-53-aligned Purview program — controls mapped, configured, piloted in simulation, validated, and
evidenced — so the capability is **in place and defensible**, and the authorization decision that follows
rests on real artifacts instead of assertions.
