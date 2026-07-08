# Executive Summary — Microsoft Purview for Government

## The problem
Government and public-sector organizations hold data that carries obligations most enterprises never face:
**Criminal Justice Information (CJI)** under the FBI CJIS Security Policy, **Controlled Unclassified
Information (CUI)** under CMMC / NIST SP 800-171, and **ITAR-controlled technical data** whose export — even
access by a foreign person — is regulated. An auditor or assessor comes down to two demands: *"show me the
control"* and *"show me the evidence."* Too often the protection exists as policy on paper, with no mapped
technical control behind it, no encryption binding protection to the data, no barrier to it leaving, and no
evidence that can be produced on demand. Left unaddressed, that is both a compliance gap and a data-risk
exposure — and it surfaces at the worst possible moment: mid-assessment.

## The solution
A complete, self-guided **Government-tailored Purview program** — an industry bundle that curates and
sequences the Purview capabilities into one defensible whole on **Microsoft Purview**. It maps the in-scope
obligations to configured controls: **sensitivity labels with encryption** for CJI/CUI/ITAR (protection
travels with the data), **DLP including endpoint DLP** to stop egress of that controlled data — **built and
piloted in simulation first** — **records retention and an audit-evidence trail**, all **tracked in
Compliance Manager** against CJIS / CMMC / NIST SP 800-171 assessment templates. Five safe-by-default
PowerShell tools (read-only or `-WhatIf` until you commit) do the assessment, scoping, configuration,
validation, and evidence reporting. It references the granular Purview products for deep how-to rather than
re-teaching them — its value is selecting, naming, and evidencing the right controls for a government tenant.

## What you get
- **An obligation-to-control register** — every in-scope obligation (CJIS, CMMC/NIST 800-171, ITAR) mapped to
  the Purview object that protects it, with the required retention/audit and a named approver.
- **CJI/CUI/ITAR sensitivity labels with encryption** — piloted for access outcomes first (an encrypting label
  changes who can open a file; ITAR access is a legal constraint) and published under sign-off.
- **DLP and endpoint DLP, simulation-first** — services and device egress (USB/print/cloud-upload) policies
  built **in simulation**, tuned against real matches, and enforced only after validation.
- **Records retention and an audit-evidence trail** — government records preservation, unified audit on, and a
  long-term retention policy keeping the evidence CJIS/CMMC call for.
- **An assessor-ready evidence binder** — control → configuration → proof, plus a DLP simulation-match
  summary, regenerated on a cadence so it is always current.

## Approach
Delivery follows a disciplined, reversible model — **Assess → Design → Configure → Pilot (simulate/test) →
Validate → Expand (enforce)** — piloting every high-impact control on a limited scope before enforcement, with
pass/fail gates and documented rollback. DLP and endpoint DLP are built in **simulation** and enforced only
after they match the right content without disrupting the mission; encrypting labels are piloted for access
before broad publish.

## Boundaries
Microsoft Purview is **licensing-/plan-dependent** (label encryption, advanced/endpoint DLP, and Audit Premium
require E5 or the E5 Compliance add-on) and **cloud-dependent** — **GCC, GCC High, and DoD differ** in feature
availability and connection endpoints, and ITAR/CUI often **require** GCC High or higher. Capabilities and
paths are cited or flagged **"verify your licensing/tenant/cloud,"** never assumed. Above all: **which data is
CJI/CUI/ITAR, which CMMC level applies, retention adequacy, ITAR access sufficiency, and whether a
configuration satisfies CJIS/CMMC/ITAR are deferred to your compliance, security, records, and legal
functions** — this solution provides the technical control and the evidence, not the determination, and makes
**no certification or authorization-to-operate claim.**

## The bottom line
A Government program that is **configured, piloted, validated, and evidenced** in Microsoft Purview — so when
an assessor asks to see the control and the proof, both are already in hand.
