# Best Practices — Microsoft Purview Health Check

Field-tested guidance for running a Purview health check that produces **evidence and action**, not
just a wall of red. It follows the same order the check runs: read everything, score against **intent**,
prioritize by **severity and owner**, and hand fixes to the solutions that own them — piloted, never
flipped.

## 1. Score against intent, not against a maximum

- A "Gap" is only a Gap against what the organization **intended** to run (R4). A tenant with no
  insider-risk policy is **Healthy** if it never adopted insider risk, and a **Gap** if it did. Grade
  against the **baseline**, or you will manufacture false findings and lose credibility.
- Separate **"missing"** from **"deliberately not adopted"** from **"unlicensed"**. Only the first is a
  drift Gap; the third is a **licensing decision** — tag it and **verify against your licensing/tenant.**

## 2. Read-only first — the check itself changes nothing

- The whole assessment runs **read-only**. The single exception — re-enabling the unified audit log —
  is offered **`-WhatIf` first** and committed only with `-Commit` under change control. Keep it that
  way; a health check that starts *changing* the estate is no longer a health check.
- Never use the health check to enable/enforce DLP, publish labels, create retention/records policies,
  or configure insider risk. Those are **high-impact** and belong to the owning capability solution,
  **piloted in simulation/test/report-only** first.

## 3. "Stuck in test" is drift, not safety

- A DLP or retention policy left in **simulation/test** for months is not "being careful" — it is
  **not protecting anything** while everyone assumes it is. Score long-lived test-mode policies as **At
  Risk** and put a date on graduating them (via the owning solution's pilot→enforce path).
- Equally, a **disabled** policy that everyone forgot to re-enable after an incident is a **Gap**, not a
  historical artifact.

## 4. Coverage is where the real risk hides

- "We have DLP / labels / retention" almost always hides a **workload blind spot** — email but not
  endpoints, a label published to a pilot group two years ago, retention on SharePoint but not
  OneDrive. **Map every policy to its workloads** (`OPSHEALTH-ScopeCheck.ps1`) and compare to the
  in-scope map — the gaps between *intended* and *actual* coverage are the findings that matter most.
- For endpoint actions, **no onboarded devices** means endpoint DLP does nothing regardless of policy —
  check device onboarding, not just policy existence.

## 5. Treat the unified audit log as foundational

- The unified audit log is the **evidence base** for eDiscovery, insider risk, and every "prove what
  happened" question. If it is **off**, that is a **High**-severity Gap and the one thing this solution
  will safely re-enable directly. Enable it early — audit data is not retroactive.

## 6. Least privilege is a health metric, not a one-time setup

- Review role groups every run: **Global Admin sprawl**, **single-member (SPOF)** groups, **empty**
  critical groups, and **stale** members who moved on. All are auditable risks that accrue silently.
- Prefer **more than one** trained admin per critical compliance role (no single point of failure), and
  **no Global Admin** for routine compliance work. Keep **Insider Risk** roles **separated** — do not
  fold them into general compliance admin for convenience.

## 7. Respect privacy on the sensitive surfaces

- On **Insider Risk** and **Communication Compliance**, report **posture only** — that the capability
  exists and its **privacy guardrails (anonymization, role separation)** are on — **never** case
  contents or any person's identity. A health check must not become a snooping tool (R5).
- Conduct the role review as least-privilege and authorized; who-can-see-what is itself sensitive.

## 8. Severity + owner is what turns findings into fixes

- Every non-Healthy result gets a **severity** (High/Medium/Low) and a **named owner** (R6). Unowned
  High findings are the ones that rot for another year. High = audit log off, missing DLP on a regulated
  workload, GA sprawl; Low = cosmetic naming, a single stale reviewer.
- Sequence remediation **High → Medium → Low**, and route each to its **owning capability** so the fix
  happens where the expertise and the pilot discipline live.

## 9. Defer determinations — you provide the method, not the verdict

- Any finding touching a **retention schedule, records file plan, legal hold, regulatory obligation, or
  insider-risk/communication-compliance policy** is marked **"determination required"** and routed to
  **compliance/records/privacy/legal** (R8). The health check reports the **technical** state and
  evidence — **whether** it is correct is their call, not the assessor's.

## 10. Make it recurring — drift comes back

- A one-time health check ages the moment it is delivered. Re-run it on a **cadence** (quarterly, and
  before any audit) and keep each scorecard. A **falling** trend of At Risk/Gap items over time is the
  proof the estate is staying healthy — and the recurring baseline makes the *next* drift obvious fast.

## 11. Verify against your tenant — the surfaces evolve

- Purview capabilities are **licensing-dependent** and the portal **changes**. Cmdlet availability,
  policy modes, and read surfaces differ by tenant and plan. Where a script notes a capability may be
  portal-only or plan-gated, **confirm against your licensing/tenant** rather than assuming — and treat
  preview capabilities as preview.
