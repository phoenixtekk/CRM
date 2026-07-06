# Executive Summary — Exchange Online → Gmail Migration (Mail, Calendar, Contacts)

Email is the highest-visibility, highest-risk part of a Google move — users feel every lost item,
broken calendar, and mis-delivered message the moment it happens. Most mail migrations stumble the
same way: no pilot, so an architectural problem surfaces at fleet scale instead of on 50 users;
coexistence as an afterthought, so mail is lost or double-delivered while the estate is split; the
DNS/MX cutover treated as a switch flip with no rollback; and no per-user validation, so a mailbox is
called "migrated" while its calendar and contacts never arrived. This solution migrates **Exchange
Online mailboxes to Gmail — mail, calendar, and contacts** — with the right tooling pattern,
coexistence/mail-flow during the transition, a governed DNS/MX cutover, and per-user validation,
executed **pilot-first** and **rollback-ready**.

This is a complete, run-it-the-repeatable-way package written for a migration lead and mail-flow
owner. Every artifact is named once and reused across every wave, so the same proven runbook executes
from the pilot batch through the last business unit. It is authored **tool-agnostically**: it governs
*which pattern and when* — Google's built-in **data migration service** (Admin console, with delta
migrations), the **desktop tool (GWMME)** for mail/calendar/contacts in one run, or a named
third-party tool — while deferring each tool's internal screens to the vendor's own docs.

## What you get
- A **Solution Overview** of the Exchange-to-Gmail model — the three data types (mail, calendar,
  contacts), the tooling patterns, split/dual-delivery coexistence, and the DNS/MX cutover — with the
  named artifacts.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite: source Exchange
  Online / Entra access, a licensed Google Workspace target, a frozen tooling & data-types design,
  DNS control and a coexistence design, the migration tool configured, a pilot batch with per-user
  validation, and a DNS/MX cutover runbook with rollback.
- An **Implementation Guide** of precise, ordered steps: baseline the mailboxes, design tooling and
  coexistence, build a named pilot batch, migrate mail/calendar/contacts, validate each user across
  all three data types, manage coexistence, cut over DNS/MX under change control, then expand wave by
  wave and decommission coexistence.
- **Five PowerShell scripts** — source-estate discovery, per-user migration validation, a
  coverage/exception report, safe remediation, and a wave target-group builder — read-only against
  Microsoft Graph except the two write scripts, which default to `-WhatIf`.
- **Testing and Troubleshooting** guides with explicit per-batch gates (mail, calendar, contacts,
  coexistence, cutover), plus Best Practices for cutover and coexistence.

This solution **references, rather than duplicates,** the M365 ↔ Google coexistence and the broader
M365 → Google Workspace migration-program siblings: the program sequences and gates the waves across
mail, Drive, and chat; this solution owns the mail, calendar, and contacts mechanics and the mail-flow
cutover.

## What this delivers
Every in-scope mailbox on Gmail with **calendars and contacts intact**, coexistence managed during the
transition, the DNS/MX cutover governed and reversible, and the whole migration proven on a pilot
batch before any production wave.

## The deployment model
Assess, then Configure, then Pilot, then Validate, then Expand — with per-user validation across
mail/calendar/contacts and a change-controlled, reversible DNS/MX cutover before each wave, and
coexistence decommissioned only when the estate is fully on Gmail.

## Outcome
Mailboxes move to Gmail cleanly — nothing lost, calendars and contacts intact, mail flow unbroken
through coexistence, and the cutover proven on a pilot before it scales.
