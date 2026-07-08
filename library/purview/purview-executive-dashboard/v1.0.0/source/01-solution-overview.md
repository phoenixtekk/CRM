# 1. Solution Overview — Microsoft Purview Executive Dashboard

## What this solution is
Executives don't want to read Activity Explorer, click through Compliance Manager, and cross-reference
DLP alerts — they want **one page** that answers three questions: *how compliant are we, how exposed is
our data, and are we getting better or worse?* Microsoft Purview holds all of that signal, but it is
scattered across Compliance Manager, Data Loss Prevention, sensitivity labels, Content/Activity
Explorer, Insider Risk, Data Security Posture Management (DSPM), and Data Lifecycle/Records — each its
own portal blade, each on its own refresh. This solution assembles those signals into a **single,
repeatable, one-page executive dashboard** covering **compliance posture, data risk, and trend**. It
defines the metric set, collects the signals with safe read-only PowerShell (Security & Compliance
PowerShell / Microsoft Graph), renders the one-pager (HTML/CSV, ready for Power BI), pilots it in a
**draft** before it goes to the C-suite, validates every number against its source, and schedules it to
refresh — so the capability is in place and defensible. It uses only the **Microsoft Purview portal**,
**Security & Compliance PowerShell**, and **Microsoft Graph** — no third-party tooling.

## Why this matters
- **Boards and executives are accountable for data risk.** "Show me our compliance posture" is now a standing question from audit committees, regulators, and cyber-insurers. Without a curated view, the answer is a slow, manual scramble across a dozen Purview blades — different every time it's asked.
- **The signal already exists but isn't executive-ready.** Compliance Manager produces a score; DLP produces alerts; labels and Content Explorer produce coverage; Insider Risk and DSPM produce risk indicators. None of them, on their own, is a C-suite one-pager, and none of them shows **trend** without you capturing snapshots over time.
- **Trend is the executive's real question.** A single-point score is noise; *direction* is signal. This solution captures a **monthly snapshot** so posture, DLP volume, label coverage, and incident counts can be shown moving — the thing an executive actually acts on.
- **The sources are licensing-dependent and evolving.** DSPM, Insider Risk, Content Explorer, and advanced DLP are E5 / E5 Compliance (some preview); Compliance Manager's baseline is broader. The dashboard must show what your tenant **actually** licenses and flag the rest — not fabricate a number.

## How it works
1. **Assess the sources.** Discovery connects to Security & Compliance PowerShell and Graph and reports which signals are reachable and licensed — Compliance Manager visibility, DLP policies, published labels, Content/Activity Explorer access, retention coverage, and whether Insider Risk / DSPM are licensed (E5).
2. **Define the metric set.** A single **metric definition** names every KPI on the page, its source, its refresh, and its **thresholds** (green/amber/red) — agreed with your compliance stakeholders, not invented by the tool.
3. **Collect safely and read-only.** The collector pulls current values from each source cmdlet/API into a normalized **snapshot** (a file — no tenant change), and merges the few portal-only values (Compliance Manager score, Insider-Risk aggregate, DSPM recommendations) that Purview does not expose to automation in your tenant.
4. **Pilot in a draft.** The one-pager is built and reviewed as `Exec Dashboard – Pilot – Stage1` **first** — every number checked against its Purview source — before any executive sees it.
5. **Validate every number.** A validation pass confirms each section populates, cross-checks counts against source, and flags **stale** or **missing** data so the page is never silently wrong.
6. **Render, snapshot, and schedule.** The report renders the one-page dashboard (HTML/CSV, Power BI-ready), appends the month's values to the **trend baseline**, and the collection is scheduled so the page refreshes and trend accrues automatically.

## The signal stack this dashboard summarizes
- **Compliance posture** — **Compliance Manager** score & improvement actions; active **regulatory assessments**.
- **Data risk** — **sensitivity label** coverage; **DLP** high-severity match volume; **sensitive items** detected (Content Explorer); **retention/records** coverage; and, where licensed, **Insider Risk** aggregate alerts and **DSPM** open recommendations.
- **Trend** — a **monthly snapshot** of the above so the page shows direction, not just a point.

## What you can control
- The **metric set** and its **thresholds** (what counts as green/amber/red for each KPI).
- Which **workloads, labels, DLP policies, and assessments** are in scope for the coverage numbers.
- The **refresh cadence** and the **distribution** (who receives the one-pager, in what format).
- The **pilot draft** validated before the C-suite version is published.
- How **privacy-sensitive** signals (Insider Risk) are represented — **aggregate only, no names** (see limitations).

## Limitations (be honest with buyers)
- **This is a reporting/summarization layer, not a new control.** It surfaces posture and risk from Purview's existing capabilities; it does not itself label, block, or investigate. If DLP, labels, or Insider Risk aren't configured, the dashboard will honestly show low coverage — fix the underlying capability, not the report.
- **Several sources are licensing-gated (E5 / E5 Compliance; some preview).** DSPM, Insider Risk, Content Explorer, and advanced DLP require the right plan; Compliance Manager's premium assessments do too. The dashboard shows what your tenant **actually** has and flags the rest as *"verify your licensing/tenant"* — it never invents a value.
- **Some values are portal-only in many tenants.** Microsoft does not expose a stable public automation surface for the Compliance Manager **score**, the Insider Risk **aggregate**, or DSPM **recommendations** in every tenant; where that's the case those are **read from the portal and entered into the metric definition** (with the read date recorded), not scraped. **Verify the current supported method for your tenant.**
- **Trend requires history you must accrue.** The trend section is only as deep as the snapshots you've captured — it starts building the day you run the first collection, not retroactively.
- **Insider Risk is HR/privacy-sensitive.** Only **aggregate, de-identified** counts appear on an executive page — never user names or case detail. Access follows strict **role separation** (Insider Risk roles are distinct from dashboard authors), and outcomes are **deferred to HR/legal**.
- **Regulatory/records/legal determinations are not ours to make.** Whether a compliance score, retention coverage, or an assessment set is *adequate* is a **compliance/records/privacy/legal** determination — the dashboard reports the technical measurement, not the judgement.

## Naming convention (used in every doc and script)
Every artifact this solution creates is named `<Purpose> – <Scope> – <Stage>` and reused verbatim
across the docs, scripts, and portal. The standard set:

| Artifact | Name |
|---|---|
| The one-page executive dashboard | `Exec Dashboard – Posture-Risk-Trend – OnePage` |
| The metric definition (KPIs, sources, thresholds, scope) | `Exec Metrics – Compliance Signals – Definition` |
| The scheduled collection job | `Exec Collector – Purview Signals – Scheduled` |
| The monthly trend store | `Exec Trend – Monthly Snapshot – Baseline` |
| The distribution of the one-pager | `Exec Dashboard – C-Suite – Distribution` |
| The pilot draft validated before publish | `Exec Dashboard – Pilot – Stage1` |

## The standard deployment model
> Assess which Purview signals you actually have and license → design the metric set and thresholds →
> configure the definition, collection, and schedule → **pilot** the one-pager as a draft and check
> every number against its source → validate it populates and reconciles → expand to scheduled refresh,
> trend accrual, and C-suite distribution. Pattern:
> **Assess → Design → Configure → Pilot → Validate → Expand.**
