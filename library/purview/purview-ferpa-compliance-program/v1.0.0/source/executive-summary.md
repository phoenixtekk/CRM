# Executive Summary — Microsoft Purview FERPA Compliance Program

## The problem
For any institution holding student education records, an audit or a data-incident review comes down to
two demands: *"show me the control"* and *"show me the evidence."* FERPA obligations — protecting the
personally identifiable information in education records and governing its disclosure — too often exist as
policy on paper with no mapped technical control behind them and no evidence that can be produced on
demand. Left unaddressed, that is both a compliance gap and a data-risk exposure, and it surfaces at the
worst possible moment: after an unauthorized disclosure has already happened.

## The solution
A complete, self-guided FERPA **control-and-evidence program** built on **Microsoft Purview**. It maps
the in-scope obligations to three configured Purview controls — **classification & sensitivity labeling**
of education records, **Data Loss Prevention** against unauthorized disclosure, and **retention & Audit**
(the records lifecycle and access-evidence trail) — **pilots the high-impact ones in simulation/test/
disabled mode**, validates them, and produces an **evidence binder** (control → configuration → proof)
you can hand to an auditor. Five safe-by-default PowerShell tools (read-only or `-WhatIf` until you
commit) do the assessment, scoping, configuration, validation, and evidence reporting.

## What you get
- **An obligation-to-control register** — every in-scope FERPA obligation mapped to the Purview object that implements it, with the classification/DLP/retention scope, permitted-disclosure exceptions, and a named approver.
- **Education-record classification & protection** — sensitive information types / trainable classifiers and a `Protect – FERPA Education Records – Confidential` sensitivity label that marks and, where designed, encrypts education-record data across email, files, and Teams.
- **Disclosure prevention, simulation-first** — a DLP policy built **in simulation mode** with permitted-disclosure exceptions, validated across Exchange/SharePoint/OneDrive/Teams/Endpoint, and enforced only under compliance/registrar sign-off.
- **A records lifecycle and access-evidence trail** — retention on education records, and unified audit with a long-term retention policy keeping the evidence of who accessed and disclosed records.
- **An audit-ready evidence binder** — control → configuration → proof, regenerated on a cadence so it is always current.

## Approach
Delivery follows a disciplined, reversible model — **Assess → Design → Configure → Pilot (simulate/test)
→ Validate → Expand (enforce)** — piloting every high-impact control on a limited scope before
enforcement, with pass/fail gates and documented rollback. The disclosure-prevention DLP control is
built and validated **in simulation mode** and moved to enforcement only under explicit
compliance/registrar sign-off on the approved scope.

## Boundaries
Microsoft Purview is **licensing-/plan-dependent** (auto-labeling, advanced/endpoint DLP, trainable
classifiers, and Audit Premium require E5 or the E5 Compliance add-on) and the portal is **actively
evolving** — capabilities and paths are cited or flagged **"verify your licensing/tenant,"** never
assumed. Above all: **which data are education records, who are eligible students and school officials,
which disclosures are permitted, retention adequacy, and whether a configuration satisfies FERPA (34 CFR
Part 99) are deferred to your compliance, registrar, records, privacy, and legal functions** — this
solution provides the technical control and the evidence, not the determination, and makes no
certification claim.

## The bottom line
A FERPA program that is **configured, piloted, validated, and evidenced** in Microsoft Purview — so when
an auditor or a parent asks to see the control and the proof, both are already in hand.
