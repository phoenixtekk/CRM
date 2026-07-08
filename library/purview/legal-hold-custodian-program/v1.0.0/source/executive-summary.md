# Executive Summary — Legal-Hold & Custodian Management Program (Microsoft Purview)

## The problem
When litigation, an investigation, or a regulatory inquiry arises, the organization has a legal **duty to
preserve** the potentially relevant content of the people involved — and to be able to **prove** it did. In
most organizations that duty is met **ad hoc**: a preservation email sent to a handful of people, no
enforcement on the platform, no record of who acknowledged, no way to show a court the hold was issued,
tracked, and released deliberately. When a custodian's mailbox is purged, a leaver's data is deleted, or a
hold is simply missed, the content is gone — and **spoliation** sanctions land on the organization. A
preservation duty that lives in an email is not preservation.

## The solution
Stand up a repeatable **legal-hold and custodian-management program** in **Microsoft Purview eDiscovery**,
using only the Purview portal, Security & Compliance PowerShell, and Microsoft Graph. Each matter gets an
**eDiscovery case**; the people of interest are added as **custodians** with their data sources mapped
(mailbox, OneDrive, associated Teams/SharePoint); their content is placed on a **case hold** so nothing can be
permanently purged; each custodian is issued a **legal-hold notice** they must **acknowledge**, with
**reminders and escalation** for non-responders; and the whole thing is **tracked** in a defensible **hold
register**. The defining discipline is **pilot-first**: the mechanics — hold distribution, notice issuance,
acknowledgment tracking — are proven on a **pilot matter with fabricated test custodians** before any real
matter's preservation depends on them. The result: preservation is done consistently, evidenced, and
defensible instead of improvised.

## What it delivers
- A **matter case + case hold** (the preservation floor that works at every tier), with the choice of
  **preserve-everything** or a legally-authorized **query-based** scope.
- **Custodian management** (Premium) — custodians with mapped data sources, plus explicitly-held
  **non-custodial** locations — so nothing responsive is left un-preserved.
- A **hold-notice workflow** (Premium) — issuance, acknowledgment tracking, reminder, and escalation — the
  proof a court expects that the hold reached the custodian.
- A **defensible hold register** and an evidence trail: who is on hold, since when, noticed, acknowledged,
  released.
- **Five PowerShell tools** (posture discovery, hold/custodian config helper, validation checker, tracking
  report, scope helper) — read-only or `-WhatIf` by default, **no tool releases a hold**, no credentials in
  code.

## Business outcomes
- **Preservation that holds** — held content cannot be permanently purged, enforced by the platform with an
  audit trail, across mailbox, OneDrive, Teams, and SharePoint.
- **Defensibility by evidence** — issuance, acknowledgment, reminder, escalation, and release are tracked, so
  the organization can *prove* it met its duty, not just assert it.
- **Repeatable and scalable** — a named, standardized case/hold/notice program with a tracked register runs
  the same way every matter, instead of ad-hoc holds that don't scale across a portfolio.
- **Self-guided at a fraction of consulting cost** — the same method a specialist would use, documented and
  tooled to run in-house.

## Boundaries (so scope is clear)
Custodian management and the hold-notice workflow are **eDiscovery (Premium)** — generally **Microsoft 365
E5**, the **E5 Compliance** add-on, or **E5 eDiscovery & Audit**; **case holds** are available at **E3**
without custodians or communications (**verify your tenant**). This is **not** the eDiscovery *readiness
assessment*, and collection/review/export are downstream phases — this program stops at **defensible
preservation**. Crucially, **legal owns the determination**: *whether* a duty has attached, *who* is a
custodian, the *scope* of preservation, a notice's legal sufficiency, and *when* a hold may be released are
**legal / eDiscovery-counsel** decisions. This solution provides the **technical program and the evidence**,
not the legal judgement — and **it never releases a hold automatically**.
