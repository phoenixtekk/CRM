# Solution Overview

## What this assessment is

This is a repeatable Active Directory **capacity and architecture assessment** for any
provisioning model that creates **security groups per project** (or per any recurring object —
per site, per customer, per team). A competent administrator or architect runs it against
**their own domain** to answer one question with evidence rather than guesswork:

> **Is the proposed group-provisioning model sustainable over the long term** — without
> introducing RID exhaustion, directory-scalability problems, or unmanageable operational
> overhead?

The output is an **architectural go/no-go decision with conditions of approval** — not a
line-of-code review. "Can we create three groups per project?" is the implementation detail;
the decision this assessment supports is whether the *pattern* scales for the life of the domain.

The methodology is vendor-neutral and de-specified: every number in this package is a clearly
labeled **example**. You measure your own domain's real values with the included scripts and
plug them into the same formulas.

## Why teams ask the wrong question first

When automated provisioning starts creating several groups per project, the reflexive worry is
**"will we run out of RIDs?"** — often prompted by a platform warning about the *rate* of
security-principal creation. That worry is almost always misplaced. At real-world provisioning
rates the RID pool lasts far longer than the domain itself. The risks that actually bite at
scale are elsewhere: **Kerberos token bloat**, **group sprawl and lifecycle debt**, and
**administrative overhead**. This assessment measures RID lifetime to put that fear to rest,
then spends most of its effort on the risks that genuinely matter.

## RID fundamentals (the substance you are measuring)

- **Every security principal** — user, computer, or group — is assigned a unique **SID**. The
  SID is the **domain SID + a RID** (Relative Identifier). RIDs come from a **per-domain pool**.
  (Microsoft: *Security identifiers* / SID structure.)
- The pool is owned by the **RID Master** FSMO role holder — one domain controller per domain.
  The RID Master hands each DC a **block of 500 RIDs** at a time; a DC requests a fresh block
  when it has consumed roughly half of its current one. (Microsoft: *Managing RID issuance*.)
- The default pool is **30-bit**, giving a maximum of **2^30 − 1 = 1,073,741,823** RIDs per
  domain. This is a **per-domain** ceiling, not per-forest.
- **RIDs are never reclaimed.** Deleting a group, user, or computer does **not** return its RID
  to the pool. Consumption is therefore **cumulative over the entire life of the domain** — which
  is exactly why *rate* is the thing to reason about, not the count of live objects at any moment.
- **Safety valve — the extended RID pool.** On Windows Server 2012 and later, the domain's RID
  ceiling can be raised from 2^30 to **2^31 (2,147,483,648)** by unlocking the extended pool.
  This is a supported, one-way operation held in reserve; it effectively doubles capacity. You
  should almost never need it, but its existence means even a pessimistic projection has headroom.
  (Microsoft: *RID pool depletion / extended RID pool*.)

## What actually drives consumption

Because RIDs are cumulative and never reclaimed, consumption is driven by the **creation rate of
all security principals over time**, from **every** source in the domain — not just the
provisioning app under review:

- users, computers, and service accounts created by all processes;
- every group created by any tool, including this provisioning model;
- historical creation across the full life of the domain (already reflected in the current
  consumed count you will measure).

The provisioning model under review adds an **incremental** burn on top of that blended
organizational rate. The assessment quantifies both the app-only contribution and the blended
whole-domain view.

## The decision this assessment supports

At the end you produce a **go / no-go with conditions**:

- **RID lifetime** projected from *your* measured consumption and *your* provisioning rate.
- **The real risks assessed** — token bloat, sprawl/lifecycle, replication/GC, backup, admin.
- **Authorization architecture reviewed** — is the group model the right shape (AGDLP), and can
  nesting/RBAC bound object growth?
- **Conditions of approval** — the guardrails (lifecycle automation, dedicated OU + naming
  standard, ownership metadata, monitoring, recertification) that make an approval sustainable.

If the guardrails are in place, the typical outcome is **approve** — RID capacity is rarely the
limiting factor. If they are absent, the assessment tells you exactly what to build before the
model is switched on.
