# Executive Summary — Microsoft Purview Reporting & Power BI Framework

## The problem
Microsoft Purview holds a rich compliance picture — data-loss events, sensitivity- and retention-label
activity, audit trails, alerts, and posture scores — but that picture is trapped inside the Purview
portal, one capability at a time, behind admin roles and licensing. Leadership almost never opens the
portal, so the compliance posture never reaches the people accountable for it. The result is a real
gap: the data exists, but the organization cannot show, at a glance, that its controls are working — a
weakness in any audit, board review, or regulatory conversation.

## The solution
A repeatable **reporting framework** that turns Purview's scattered signal into a small set of **Power
BI dashboards a leader actually reads** — refreshed on a schedule, with a documented, defensible data
lineage. It pulls data **read-only** from Microsoft Graph and Security & Compliance PowerShell into a
governed, contract-shaped export set, then binds Power BI dashboards to that set: one page per
capability (DLP & labels, retention & records, audit activity, compliance posture, and *aggregate-only*
risk) plus an executive summary. It uses only Microsoft-native tooling — no third-party product.

## How it is delivered
The framework follows a disciplined model — **Assess → Design → Configure → Pilot (validate) →
Validate → Expand**. Dashboards are built and **reconciled against the portal's own numbers in a pilot
workspace before any leadership audience sees them**, then promoted to production with a scheduled
refresh. Five PowerShell tools automate discovery, the data pipeline, validation, and pipeline
health — all safe-by-default (read-only, with writes gated behind an explicit switch, and no stored
credentials).

## What it protects
- **Privacy-by-design.** Insider-risk and communication-compliance data is reported as **aggregate
  counts only** — never case content or named subjects — with strict role separation.
- **Defensibility.** Every number has a named source, a refresh cadence, and a reconciliation record —
  the answer to "how do you know."
- **Honesty about licensing.** Purview reporting sources are plan-gated (many require E5 / E5
  Compliance) and some are preview; the framework verifies each source in your tenant and labels any it
  cannot license, rather than inventing a figure.

## The boundary
This solution delivers the **reporting capability and the evidence** behind each number. It does **not**
make the **regulatory, records, or legal determinations** — what to retain, what a signal means, whether
a posture is sufficient. Those remain with the organization's compliance, records, privacy, HR, and
legal functions.

## The bottom line
Reporting leaders actually read — the Purview compliance posture, delivered as validated, scheduled,
defensible dashboards, at a fraction of the cost of a bespoke consulting engagement.
