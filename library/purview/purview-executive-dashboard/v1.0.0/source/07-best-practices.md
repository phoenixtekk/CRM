# 7. Best Practices — An Executive Dashboard the C-Suite Trusts

Operating principles for keeping the Purview executive dashboard accurate, credible, and useful.
Grounded in Microsoft's public guidance and the **Assess → Design → Configure → Pilot → Validate →
Expand** model.

## Report the truth, don't decorate it
- The dashboard's only job is to be **right**. A single wrong number in front of an executive costs more trust than a dozen correct ones earn — reconcile every value to its Purview source (Testing Gate 4) before anyone senior sees it.
- Where a source isn't licensed or is portal-only, **say so on the page** (*"not licensed / verify tenant," "portal-read as of <date>"*). An honest gap is credible; a fabricated number is a liability. The dashboard shows what you **have**, never what you wish you had.
- It's a **reporting layer, not a control.** If coverage is low, the fix is the underlying capability (labels, DLP, retention), not the report. Don't tune the denominator to make the page look better.

## Trend is the executive signal — protect the history
- Executives act on **direction**, not a point-in-time score. The monthly snapshot is the most valuable thing this solution produces over time — **never overwrite** `Exec Trend – Monthly Snapshot – Baseline`; always append.
- Trend only accrues **forward** from your first collection. Start capturing snapshots as early as possible, even before the page is perfect, so the history exists when the board asks "are we improving?"
- Keep the metric **definitions stable** so the trend stays comparable; when you must change a KPI or threshold, annotate the break so a step-change in the line isn't misread as a real movement.

## Least-privilege, read-only, and Insider-Risk role separation
- The dashboard author needs **read** across the sources — not write, not investigation access. Use **Global Reader / Compliance Data Administrator**-class roles; the scripts never change a Purview policy.
- **Insider Risk is HR/privacy-sensitive.** Only **aggregate, de-identified** counts belong on an executive page — never names or case detail. The person who reads the Insider Risk aggregate holds a **separate** Insider Risk role from the dashboard author; outcomes are **deferred to HR/legal**.
- Treat the compliance/risk signal itself as sensitive — the dashboard reveals where your weak spots are. Secure the distribution channel and review who receives it.

## Thresholds are a governance decision, not a default
- Green/amber/red bands encode what your organization considers **acceptable** — agree them with compliance/records/security stakeholders and record them in the definition. The tool colours against the agreed bands; it doesn't decide what "good" is.
- Revisit thresholds as posture matures: a coverage target that's aspirational at launch should tighten as the program improves, so the page keeps driving the right behaviour.

## Respect the licensing and preview reality
- DSPM, Insider Risk, Content Explorer, and advanced DLP are **E5 / E5 Compliance** (some **preview**); Compliance Manager's premium assessments are gated too. Populate a KPI only where its source is genuinely licensed, and **verify the current supported method** before automating a value — Purview's APIs and blades evolve.
- Some values are **portal-only** in many tenants (Compliance Manager score, Insider-Risk aggregate, DSPM recommendations). Keep a named owner and a **read date** for each, and re-check whether a supported API has since become available.

## Validate before every distribution
- Run `OPSEXEC-Validate.ps1` each cycle — it catches the stale portal value, the lapsed license, the broken source **before** the executive does. A dashboard that silently goes wrong is worse than no dashboard.
- Keep the reconciliation and validation evidence; when an executive challenges a number, you can show exactly which Purview blade it came from and when.

## Keep it a one-pager
- The value is **compression** — three questions, one page. Resist the urge to add every metric Purview can produce; that recreates the portal sprawl the dashboard exists to escape.
- Route anyone who wants the detail to the source blade (or a companion operational report); the executive page stays posture, risk, and trend — nothing more.
