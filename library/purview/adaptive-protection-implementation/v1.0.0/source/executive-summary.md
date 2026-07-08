# Executive Summary — Adaptive Protection in Microsoft Purview

## The problem

Most data-protection controls treat everyone the same. The person who has never put a foot wrong is
constrained exactly as much as the person quietly copying sensitive files on the way out the door.
Static, one-size-fits-all controls force a bad trade-off: set them tight and you slow the whole
organization down; set them loose and you leave the genuinely risky user under-controlled. Either way,
protection is not aligned to where the risk actually is — and that is both an efficiency cost and a
data-risk exposure.

## The solution

This solution implements **Microsoft Purview Adaptive Protection**: protection that **dials up with
the user's risk and relaxes as it subsides**. It takes the **insider risk level** Purview computes for
a user — **Elevated, Moderate, or Minor** — and feeds it as a **live condition** into your protective
controls:

- **Data Loss Prevention** — the **same** attempted action on sensitive, labeled content is **audited**
  for a low-risk (Minor) user, **warned/overridable** for a Moderate user, and **blocked** for an
  Elevated user.
- **Conditional Access** — access for an **Elevated-risk** user can be blocked, stepped up, or limited,
  while everyone else signs in normally.

The risk level is **dynamic and time-bound**: it rises when behavior warrants and **decreases
automatically** as behavior normalizes — so controls are responsive, not permanent punishments.

## How it works

We follow a repeatable model — **Assess → Design → Configure → Pilot → Validate → Expand** — that
confirms the **insider-risk source signal and its privacy guardrails first**, enables Adaptive
Protection (Microsoft's recommended **Quick setup**, or a mapped **Custom setup**), then builds the DLP
enforcement in **simulation/test** and the Conditional Access control in **report-only** before
anything blocks. Every high-impact control is piloted, proportionate to risk, and reversible.

The solution ships as **self-guided documentation plus five PowerShell tools** (Security & Compliance
PowerShell / Graph) that assess readiness and the source signal, scaffold and validate the adaptive DLP
policy, check the end-to-end wiring, and produce a leadership rollup — all **read-only or
`-WhatIf`/simulation by default**, with **no credentials in code**.

## Why it matters

- **Protection where the risk is** — strong for the genuinely risky user, frictionless for everyone
  else, instead of blunt controls that punish the whole organization.
- **Automatic and self-adjusting** — risk levels rise and fall on their own; protection follows,
  without manual re-classification.
- **Proportionate and defensible** — audit → warn → block scaled to risk, keyed to your most sensitive
  labeled content, with an evidence trail.
- **A fraction of consulting cost** — the same disciplined method a specialist would use, delivered as
  a repeatable, tested runbook.

## Important boundaries

Adaptive Protection is **driven by Insider Risk Management**, which monitors **people's activity**: in
many jurisdictions the underlying monitoring requires notice, consultation, or a specific **lawful
basis** before it runs — that applicability is a **legal determination** for your organization, and
this solution provides the technical method and guardrails, not the legal decision. A user's risk level
tightens **controls**, not judgement — whether risky activity reflects misconduct, and any consequence,
remains an **HR/legal determination**. Adaptive Protection is **licensing-dependent** (Microsoft 365
E5 / E5 Compliance for IRM + DLP; **Entra ID P2** for the Conditional Access integration; some
capabilities may be in preview) and the Purview/Entra portals are **evolving** — capability
availability and paths should be **verified against your licensing and tenant**.
