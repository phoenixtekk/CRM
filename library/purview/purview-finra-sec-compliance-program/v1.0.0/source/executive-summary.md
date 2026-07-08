# Executive Summary — Microsoft Purview FINRA/SEC Compliance Program

## The problem
For a regulated broker-dealer or investment adviser, an examination comes down to two demands: *"show
me the control"* and *"show me the evidence."* FINRA and SEC obligations — supervision of electronic
communications, books-and-records preservation, and a defensible audit trail — too often exist as
policy on paper with no mapped technical control behind them and no evidence that can be produced on
demand. Left unaddressed, that is both a compliance gap and a data-risk exposure, and it surfaces at the
worst possible moment: mid-exam.

## The solution
A complete, self-guided FINRA/SEC **control-and-evidence program** built on **Microsoft Purview**. It
maps the in-scope obligations to three configured Purview controls — **records/regulatory-records
retention** (books-and-records preservation), **Communication Compliance** (supervision of registered
persons' communications), and **Audit** (the evidence trail) — **pilots them in simulation/test/disabled
mode**, validates them, and produces an **evidence binder** (control → configuration → proof) you can
hand to an examiner. Five safe-by-default PowerShell tools (read-only or `-WhatIf` until you commit) do
the assessment, scoping, configuration, validation, and evidence reporting.

## What you get
- **A rule-to-control register** — every in-scope obligation mapped to the Purview object that implements it, with the required retention/supervisory scope and a named approver.
- **Records preservation** — regulatory-records retention across email, files, and Teams, piloted with a **non-regulatory** label first and applied under compliance sign-off (regulatory records are irreversible by design).
- **Communication supervision, privacy-first** — a supervisory policy built **in test mode** with strict reviewer separation and pseudonymization where available, surfacing review items to designated reviewers.
- **An audit-evidence trail** — unified audit on, with a long-term retention policy keeping the evidence your compliance function requires.
- **An examiner-ready evidence binder** — control → configuration → proof, regenerated on a cadence so it is always current.

## Approach
Delivery follows a disciplined, reversible model — **Assess → Design → Configure → Pilot (simulate/test)
→ Validate → Expand (enforce)** — piloting every high-impact control on a limited scope before
enforcement, with pass/fail gates and documented rollback. The one deliberate exception, the irreversible
**regulatory-records** label, is gated hardest of all: applied only under explicit compliance sign-off.

## Boundaries
Microsoft Purview is **licensing-/plan-dependent** (records/regulatory records, Communication Compliance,
and Audit Premium require E5 or the E5 Compliance add-on) and the portal is **actively evolving** —
capabilities and paths are cited or flagged **"verify your licensing/tenant,"** never assumed.
**Communication Compliance is HR/privacy-sensitive** and is built privacy-by-design with reviewer role
separation; **case outcomes are HR/legal's.** Above all: **rule applicability, retention adequacy,
supervisory scope, 17a-4 compliance, and whether a configuration satisfies FINRA/SEC are deferred to your
compliance, records, privacy, and legal functions** — this solution provides the technical control and
the evidence, not the determination.

## The bottom line
A FINRA/SEC program that is **configured, piloted, validated, and evidenced** in Microsoft Purview — so
when an examiner asks to see the control and the proof, both are already in hand.
