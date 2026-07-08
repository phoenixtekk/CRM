# Executive Summary — Sensitive Information Types Implementation (Microsoft Purview)

## The problem
You can't protect what you can't detect. Every data-protection control in Microsoft Purview — DLP, auto-
labeling, retention, insider risk — depends on the same underlying layer: **sensitive information types
(SITs)**, the classifiers that recognize credit-card numbers, national IDs, health identifiers, and
hundreds of other data patterns. If that detection layer is inaccurate — missing real sensitive data, or
firing on internal reference numbers that just *look* sensitive — every control built on top of it is
either blind or drowning in false positives. The common failure is switching on a built-in detector at its
default settings, without ever testing it, and watching false positives train users to ignore every alert.

## The solution
**Select, test, and tune the built-in SITs Microsoft already ships** — a large, tested library covering the
common data patterns — using only the Microsoft Purview portal, Security & Compliance PowerShell, and
Microsoft Graph. Each in-scope data category is mapped to the most specific built-in SIT, **tested against a
corpus of clearly-fake positive and look-alike-negative samples**, then **measured against real production
content in a DLP policy run in SIMULATION** (zero user impact) and **tuned** using the two dials that matter
— **confidence level** and **instance count** — until the false-positive rate is at/under an agreed
threshold. Where the shipped SIT genuinely can't separate real data from look-alikes, an **editable copy**
is tuned — the original built-in is never touched. The result is a detection layer the whole Purview estate
can trust.

## What it delivers
- A **category→SIT selection register** — the right built-in detector for each in-scope data category,
  reusing built-in wherever it fits and flagging only genuine gaps for the custom/EDM/trainable solutions.
- **Tested accuracy** — every selected SIT proven to detect true positives and reject look-alike negatives
  against a fake-data corpus, in the portal and at scale.
- A **measured, tuned false-positive rate** kept at/under an agreed threshold — the difference between a
  detector people trust and one they ignore — with matches inspected in Content Explorer.
- A **threshold register** (confidence + instance count per SIT) that every downstream control inherits, so
  DLP, auto-labeling, and retention all detect consistently.
- **Five PowerShell tools** (SIT inventory, accuracy tester, simulation measurement builder, match/false-
  positive report, scope helper) — read-only or `-WhatIf` by default, simulation-only, no credentials in
  code.

## Business outcomes
- **Accurate detection** of the data that matters, across every control that consumes it — because the
  detection layer was tested, not assumed.
- **Low false positives** — simulation-first measurement plus dial-tuning means the detector catches real
  sensitive data without a wave of noise that gets it disabled.
- **No user disruption** — this solution introduces **no enforcement**; all measurement is in simulation or
  the portal Test experience.
- **Self-guided at a fraction of consulting cost** — the same method a specialist would use, documented and
  tooled to run in-house.

## Boundaries (so scope is clear)
This solution covers **built-in** SITs; custom SITs, Exact Data Match, and trainable classifiers for gaps
are adjacent solutions. Several measurement surfaces (Content/Activity Explorer, auto-labeling) are
**licensing-/plan-dependent** (E5 / E5 Compliance; verify your tenant). The solution provides the
**technical selection, testing, and tuning method and the evidence**; *which* data categories are in scope,
*which* SITs legally satisfy a regulation, and the **acceptable false-positive threshold** are
**compliance, privacy, and legal determinations**, captured alongside the delivered evidence.
