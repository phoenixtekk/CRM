# 1. Solution Overview — Financial / FINRA Communications Compliance (Microsoft Purview)

## What this solution is
This solution stands up a **FINRA/SEC-aligned communications supervision program** on top of
Microsoft Purview **Communication Compliance**, tuned specifically for **regulated financial firms**
(broker-dealers, RIAs, and their affiliates). Where a general communication-compliance deployment
watches for harassment, threats, and data leaks, this program is built for the **regulatory conduct
duty**: supervising registered-person communications for **money-laundering, market-manipulation,
unauthorized-disclosure, insider-trading, guarantees/misrepresentation, gifts & entertainment, selling
away, and customer-complaint** signals, and — just as importantly — **evidencing** that the supervision
happened and preserving the underlying communications so the program is **defensible to a regulator**.

The program is organized around three pillars that match the way a financial-firm supervision program
is examined:

1. **Lexicons** — the detection layer: Purview **trainable classifiers** for regulated conduct plus
   **custom keyword dictionaries ("lexicons")** encoding the firm's own prohibited-conduct language,
   attached to a supervisory-review policy scoped to the **registered/supervised population**.
2. **Review** — the supervisory workflow: **designated principals** (reviewers separated from the
   people they supervise) triage flagged items on a **risk-based sample**, tag/escalate/resolve them,
   and leave a defensible reviewer trail — the Rule 3110 "reasonable supervision" mechanic.
3. **Evidence** — the recordkeeping layer: an **immutable retention** configuration over the supervised
   communications and the review activity, so the messages and the fact-of-review are **preserved and
   tamper-evident** (the SEC Rule 17a-4 style "books & records" posture) and producible on request.

It uses only the **Microsoft Purview portal** (`purview.microsoft.com`), **Security & Compliance
PowerShell** (`Connect-IPPSSession`; the `SupervisoryReview*` and `RetentionCompliance*` cmdlets), and
**Microsoft Graph** — no third-party archiving/surveillance tooling.

> **Reference vs this solution.** A separate solution covers **general Communication Compliance** (the
> broad harassment / offensive-language / data-leak use of the same Purview capability). **This
> solution is the financial-regulatory specialization**: the same engine, but scoped to the registered
> population, driven by **regulated-conduct classifiers and firm lexicons**, wrapped in a **designated-
> principal supervisory-review workflow**, and paired with an **immutable communications-retention
> evidence layer**. If you only need general offensive-language monitoring, use the general solution;
> if you must demonstrate a **FINRA/SEC communications-supervision program**, use this one.

> **This is the technical program, not the regulatory determination.** The solution configures the
> mechanism — detection, review workflow, and preservation — and produces the evidence. **What language
> constitutes a violation, which rules apply to which persons, what the retention period must be, and
> what supervisory action to take are determinations for the firm's Compliance, Legal, and designated
> supervisory principals** under the firm's Written Supervisory Procedures (WSPs) — never for IT and
> never for the tool.

## Why this matters
- Regulated financial firms have an affirmative **duty to supervise** the communications of their
  registered persons (FINRA Rule 3110 / supervisory-controls obligations) and to **preserve** those
  communications as books & records (SEC Rule 17a-4 / 17a-3, FINRA Rule 4511). Both the supervision and
  the recordkeeping are routinely examined, and gaps in either are a common cause of enforcement.
- Doing this **manually doesn't scale** and doing it **carelessly creates liability**: reviewing every
  message is impossible, but an undocumented or unpreserved review is treated as no review at all. A
  defensible program needs **risk-based sampling, a designated-principal workflow, and tamper-evident
  evidence** — not just a keyword alert.
- Supervision is **privacy- and conduct-sensitive**. The people who *review* must be **separated** from
  the people they supervise; reviewers must not be able to quietly change what they were required to
  look at; and the supervised scope must be the **approved registered population**, not "everyone."
- **Outcomes are a Compliance/Legal determination.** The program surfaces and preserves potentially
  problematic communications and records the supervisory review; **whether a communication actually
  violates a rule, and what happens next, is decided by the firm's supervisory principals, Compliance,
  and Legal** — the tooling provides the method and the evidence, not the verdict.

## How it works
1. **Role separation and the supervised scope are established first.** The Communication Compliance
   role groups (Admin / Analysts / Investigators / Viewers) are populated so the **policy-builders**,
   the **designated-principal reviewers**, the **escalation/investigation** handlers, and **oversight**
   are separated — agreed with Compliance and Legal. The supervised population is the **approved
   registered persons**, with an explicit **exclusion** set.
2. **A supervisory-review policy names the scope, the reviewers, and the channels.** The policy names
   the **supervised registered persons**, the **designated principals** who will review its items, and
   the **channels** inspected (Teams chat/channels, Exchange email, Viva Engage, and — where licensed
   and connected via Microsoft 365 data connectors — approved third-party sources).
3. **Lexicons + classifiers define what to surface.** Rules attach **regulated-conduct trainable
   classifiers** (money laundering, stock/market manipulation, unauthorized disclosure, regulatory
   collusion, gifts & entertainment, customer complaints — *availability is plan-dependent and some are
   in preview; verify in your tenant*), the firm's **custom keyword dictionaries (lexicons)**, sensitive
   information types, and conditions — plus a **risk-based sampling percentage**.
4. **The policy runs first in SIMULATION/TEST.** It is built narrow, validated, and tuned in a pilot
   scope before any broad rollout — the category's **Assess → Design → Configure → Pilot
   (simulate/test) → Validate → Expand (enforce)** model. High-impact supervision is never switched on
   firm-wide blind.
5. **Designated principals review on a risk-based sample.** Reviewers triage flagged items, tag them
   (compliant / questionable / non-compliant), add notes, resolve, or **escalate** to an investigator —
   producing the defensible reviewer trail that demonstrates reasonable supervision.
6. **The communications and the review are preserved as evidence.** An **immutable retention**
   configuration (retention policy/labels with **Preservation Lock** where the firm's records schedule
   requires it) preserves the supervised communications and the review activity in a **tamper-evident**
   form, and the program's reporting rolls the activity up for examiners — the "evidence" pillar. **The
   retention period and lock decision are set by Compliance/Records, not by IT.**

## The three pillars, mapped to the deliverables
| Pillar | What it delivers | Where it lives |
|---|---|---|
| **Lexicons** | Regulated-conduct classifiers + firm keyword dictionaries on a scoped supervisory-review policy | Implementation Steps 3–5; `CCFIN-Configuration.ps1` |
| **Review** | Designated-principal, risk-based-sample review workflow with tag/escalate/resolve and a defensible trail | Implementation Steps 2, 6; `CCFIN-Report.ps1` |
| **Evidence** | Immutable communications retention (17a-4 posture) + review-activity reporting, tamper-evident and producible | Implementation Step 7; `CCFIN-EvidenceCheck.ps1`, `CCFIN-Report.ps1` |

## What you get
- This **Solution Overview**, a **Requirements Guide**, a step-by-step **Implementation Guide**, a
  **Testing/validation** guide, a **Troubleshooting** guide, a **Best Practices** guide, and a
  **Deliverables Summary**.
- **Five PowerShell tools** — Discovery, Configuration (simulation/`-WhatIf` first), Validation,
  Reporting, and an Evidence/scope health helper — all **read-only or `-WhatIf` by default**, with no
  credentials in code.

## Scope and boundaries
- **In scope:** designing and configuring a FINRA/SEC-aligned communications-supervision program in
  Microsoft Purview Communication Compliance — role separation, supervised scope, regulated-conduct
  classifiers and firm lexicons, the designated-principal review workflow, immutable communications
  retention for evidence, and pass/fail validation.
- **Out of scope (deferred to the firm's governance functions):** the **regulatory determination** of
  which rules apply and whether a communication violates them (Compliance/Legal/supervisory
  principals); the **retention schedule and lock decision** (Compliance/Records); **disciplinary or
  regulatory action** (Compliance/Legal/HR); trade surveillance and order/execution monitoring (a
  different discipline); and any third-party archiving product. This solution delivers the **technical
  supervision-and-evidence mechanism**, configured, piloted, and validated.
