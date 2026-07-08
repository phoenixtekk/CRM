# 1. Solution Overview — Risk & Compliance Dashboard (Microsoft Purview)

## What this solution is
This solution builds a **consolidated risk & compliance dashboard** across the signals Microsoft
Purview already produces — **Compliance Manager** score, **Data Loss Prevention (DLP)**, **sensitivity
labels**, **data lifecycle & records (retention)**, **Insider Risk Management**, **Communication
Compliance**, **Audit**, and **Data Security Posture Management (DSPM)** — and presents them in **one
view** with red/amber/green (RAG) status, coverage, and volume trend. Instead of chasing eight separate
Purview surfaces, a compliance lead, CISO, or auditor sees the whole posture in a single, repeatable
report that is **collected, rendered, validated, and refreshed** on a schedule.

Purview does **not** ship a single native "risk & compliance dashboard" that spans every one of these
workloads — each capability has its own portal card and its own report. This solution's job is to
**aggregate** those existing signals: it reads each feed (via **Security & Compliance PowerShell** and
**Microsoft Graph** where a reliable public interface exists, and via **owner-captured portal figures**
where one does not), normalizes them, and renders a consolidated dashboard artifact you own and control.

It is **vendor-neutral / white-label** and written for an administrator with no prior Purview-reporting
experience. It reads signals **read-only**; the only write action (enabling **unified audit-log
ingestion** if it is off, and writing the dashboard config/schedule) is gated behind an explicit
`-Commit` flag and piloted first.

## The consolidated dashboard in one paragraph
The dashboard is a **derived reporting layer**, not a new policy engine. A **collection** run reads each
in-scope Purview signal and writes a normalized dataset (`RiskComplianceDashboard.data.json`); a
**render** step turns that dataset into a single **HTML dashboard** (`RiskComplianceDashboard.html`) plus
a **CSV** summary, each metric shown with a **RAG threshold** defined in the dashboard config
(`RiskComplianceDashboard.config.json`). Because it is derived, it never changes a policy, never makes a
regulatory or records determination, and — critically for the HR-sensitive feeds — shows Insider Risk and
Communication Compliance as **aggregate counts only**, never case content.

## The signals it consolidates (each named)
Each signal is a **tile** on the dashboard. Availability is **licensing-dependent** — many require
**Microsoft 365 E5** or the **E5 Compliance** add-on, and some are in preview — so every tile records
*whether the capability is licensed/enabled in your tenant* and is flagged **"verify your
licensing/tenant"** where availability or interface is not guaranteed.

1. **Compliance Manager — compliance score.** Overall score and top improvement actions. *(A reliable
   public read interface is limited; captured from the portal by the owner where no cmdlet exists —
   flagged "verify your licensing/tenant".)*
2. **Data Loss Prevention (DLP).** Policy count, **enforced vs simulation/test** split, and **match /
   incident volume** over the window (from the unified audit log). High-value tile because DLP posture is
   the most common audit question.
3. **Sensitivity labels.** Published labels, label-policy coverage, and labeling activity volume.
4. **Data lifecycle & records (retention).** Retention policy count and **workload coverage** (Exchange /
   SharePoint / OneDrive / Teams).
5. **Insider Risk Management.** **Active policy count and alert counts — aggregate only, pseudonymized,
   role-separated.** No case content in this dashboard; **case actions and determinations are deferred to
   HR/legal.** *(E5; public read interface limited — aggregate figures owner-captured where no cmdlet.)*
6. **Communication Compliance.** Policy count and pending-item counts — **aggregate only, role-separated;
   review outcomes deferred to HR/legal.** *(E5.)*
7. **Audit.** Whether **unified audit-log ingestion** is on, **Audit Standard vs Premium**, and retention.
   Audit underpins the DLP/label volume tiles, so its health is shown first.
8. **Data Security Posture Management (DSPM).** Posture recommendations / risk indicators. *(E5; interface
   evolving — owner-captured / portal where no reliable public read — flagged "verify your
   licensing/tenant".)*

## What is authored exactly vs deferred
- **Exact detail is given** for the **Microsoft Purview portal** (`purview.microsoft.com`), **Security &
  Compliance PowerShell** (`Connect-IPPSSession`), and **Microsoft Graph** — for the feeds that have a
  reliable public interface (DLP/label/retention policy enumeration, unified audit-log queries, audit
  ingestion state).
- **Signals without a reliable, current public read interface** (Compliance Manager score, Insider Risk /
  Communication Compliance case detail, DSPM posture) are **not invented** — the dashboard captures them
  as **owner-entered figures** in the config, each flagged **"verify your licensing/tenant"**, so the
  consolidated view is honest about its sources.
- **Regulatory, records-retention, and legal determinations** (retention schedules, records file plans,
  insider-risk / communication-compliance case actions, regulatory applicability) are **deferred to the
  organization's compliance, records, privacy, and legal functions** — this solution provides the
  **method and the evidence**, not the determination.

## Privacy-by-design (Insider Risk & Communication Compliance)
These feeds are **HR- and privacy-sensitive**. On this dashboard they appear **only as aggregate counts**
(e.g. "policies active: 4; open alerts: 12"), **never** as user names, case content, or reviewable items.
**Role separation is enforced**: the account that builds the dashboard needs only the least-privilege
**read** roles for the metrics it consolidates, and the Insider Risk / Communication Compliance figures
are **entered by the authorized owner of those programs**, not scraped, so the dashboard cannot become a
back-door into case data.

## Benefits
- **One view** — eight Purview signals in a single RAG dashboard, refreshed on a schedule.
- **Owned and portable** — a local HTML/CSV artifact you control; no dependency on a signal you can't read.
- **Honest about sources** — every tile shows whether it's a live read or an owner-captured figure, and
  whether the capability is licensed.
- **Safe** — read-only by default; the one write action is `-Commit`-gated and piloted first.
- **Privacy-respecting** — HR-sensitive feeds are aggregate-only, role-separated, determinations deferred.

## Limitations (be honest with buyers)
- **This is a reporting layer, not a control.** It reflects posture; it does not enforce DLP, apply
  labels, or make retention/records decisions. Those live in their own Purview solutions.
- **Licensing gates the tiles.** Several signals require **E5 / E5 Compliance**; unlicensed tiles show
  "not licensed / verify your tenant" rather than fabricated numbers.
- **Some feeds have no reliable public read.** Compliance Manager score, Insider Risk / Communication
  Compliance detail, and DSPM are **owner-captured** where Microsoft exposes no stable public cmdlet —
  **verify your licensing/tenant**; the portal remains the system of record.
- **No determinations.** Regulatory, records, and legal calls are deferred to the governance functions.

## The standard deployment model
> **Assess which signals are licensed and readable → design the dashboard (tiles, thresholds, cadence,
> distribution) → configure collection + rendering (pilot in read-only / `-WhatIf`) → validate the
> numbers against the portal → expand (schedule, add signals, distribute).**
> Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand**, with explicit
> pass/fail gates and a documented rollback.
