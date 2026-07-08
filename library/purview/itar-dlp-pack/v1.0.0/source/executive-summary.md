# Executive Summary — ITAR DLP Pack in Microsoft Purview

## The problem

ITAR **technical data** — the drawings, models, specifications, source code, and documentation tied to
defense articles on the U.S. Munitions List — must not reach a **foreign person** or leave the United
States without authorization. In a Microsoft 365 environment that data moves constantly: it is emailed,
shared, posted in Teams, and copied to USB drives and personal cloud storage. A single controlled file
forwarded to a personal mailbox, shared to "anyone with the link," or dropped on a thumb drive can be an
unauthorized export. Left unaddressed, that is both a **compliance gap** and a **serious data-risk
exposure** — and "we assume people are careful" is not a control an auditor accepts.

## The solution

This solution implements an **ITAR-aligned Data Loss Prevention pack in Microsoft Purview**: technical-data
**detection** plus **egress control**, with the **evidence** to prove it. It delivers:

- A **technical-data classification** tuned to export-control signals — the Arms Export Control Act / ITAR
  warning legend, distribution statements, USML references, controlled drawing/part conventions, and an
  **`Export Controlled // ITAR` sensitivity label** — not generic PII detection.
- A **DLP policy** that detects that content and **controls its egress** across Exchange, SharePoint,
  OneDrive, Teams, and (where licensed) endpoints — blocking or restricting external send, external
  sharing, and removable-media/cloud upload.
- The **evidence artifact** — matches, actions, and DLP alerts — that demonstrates the control is live and
  working, for internal review and external audit.

## How it works

We follow a repeatable model — **Assess → Design → Configure → Pilot (simulate) → Validate → Expand
(enforce)**. The policy is always built and run in **simulation/test first**, so you see exactly what it
*would* have caught, tune the detection until real technical data is caught and routine work is not, and
only then promote it to enforce — in a change window, reversibly. Every configuration change is previewed
(`-WhatIf`) before it is applied.

The solution ships as **self-guided documentation plus five PowerShell tools** (Security & Compliance
PowerShell / Microsoft Graph) that discover the estate, scaffold the policy in simulation, validate it
against pass/fail gates, produce the evidence report, and check coverage/licensing — all **read-only or
`-WhatIf`/simulation by default**, with **no credentials in code**.

## Why it matters

- **Detects and controls the exact ITAR risk** — the movement of technical data out of the tenant, across
  every channel it actually travels.
- **Defensible by design** — piloted in simulation, validated against explicit gates, and evidenced with an
  auditable artifact rather than a claim.
- **Tuned, not blunt** — detection keyed to export markings and a controlled-data label, so it protects the
  right content without blocking legitimate engineering work.
- **A fraction of consulting cost** — the same disciplined method a specialist would use, delivered as a
  repeatable, tested runbook.

## Important boundaries

This solution delivers the **technical control and the evidence — not the ITAR determinations**. Whether an
item **is** controlled technical data, whether a person is a **U.S. person** or a **foreign person**, USML
categorization, ITAR-vs-EAR jurisdiction, licensing/authorization, **deemed-export** access decisions, and
the required cloud environment (Commercial vs **GCC High / DoD**) are **legal/export determinations** made
by your **Empowered Official, export-compliance officer, and legal** functions. DLP controls **egress out
of the tenant**; preventing **internal access by foreign persons** (the deemed-export problem) is a
separate access-control design and is flagged, not solved, here. Purview DLP is **licensing-dependent**
(Endpoint DLP / EDM generally require Microsoft 365 **E5** or the **E5 Compliance** add-on; some
capabilities may be in preview) and the portal is **evolving** — capability availability and paths should
be **verified against your licensing and tenant**.
