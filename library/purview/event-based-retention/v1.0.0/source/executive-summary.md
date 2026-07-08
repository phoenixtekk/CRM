# Executive Summary

Most retention is **date-based** — keep a document for a fixed number of years from the day it was created
or last modified, a clock the calendar starts on its own. But some of the organization's most sensitive
obligations cannot be expressed that way: keep an employee record for *N years after termination*, a
contract for *N years after it expires*, a product record for *N years after end-of-life*. On the day the
item is created, nobody knows when its clock should start; it starts only when the **event** happens. When
that capability is missing, organizations fall back to keeping everything forever — inflating breach and
eDiscovery exposure — or deleting on a guessed date, breaking a regulatory or legal obligation. This
solution implements **event-based retention in Microsoft Purview** so those obligations are enforced from
the event, not a date — configured, piloted, validated, and operable.

**Outcome.** The three parts of the mechanic, built to work together: **event types** for each real-world
event (termination, contract expiry, product end-of-life); **event-based retention (and record) labels**
whose clock starts on the event and which sit **pending** until it does; and the **asset-ID / keyword
triggering** — the `Compliance Asset Id` on SharePoint/OneDrive documents, keywords for Exchange — that lets
a raised retention event start the clock on **exactly** the affected content and nothing else. Crucially, it
delivers the piece organizations most often get wrong: a working **raise process** — who raises the event,
from which system of record (HR/CLM/PLM), with which asset IDs — so content does not sit pending forever.

**Approach.** The work is **focused on the event-based mechanic** and **aligned to the organization's broader
Microsoft Purview retention/records program** — it reuses that program's event types and labels rather than
duplicating them, and it defers records declaration in depth, the file plan, and disposition operations to
the org-wide data lifecycle & records product. It implements the **event-based schedule provided by records,
compliance, and legal**; it does not author events, retention periods, or legal determinations. Delivery
follows a disciplined, pilot-first model — **Assess → Design → Configure → Pilot → Validate → Expand** —
mapping the schedule to event types, labels, and a matching strategy, publishing labels to a bounded pilot,
and **proving the trigger with a test event on a disposable asset** before any real content is affected.
Five PowerShell tools (Security & Compliance PowerShell and Graph) handle posture assessment, event-type/
label configuration and event-raising, validation, compliance reporting, and scope/health — read-only or
dry-run (`-WhatIf`) by default, with no credentials in code.

**Why it is low-risk.** Raising a retention event starts real retention clocks, so nothing touches production
content until the trigger is proven on a pilot. Assessment, validation, and reporting are read-only;
configuration and event-raising are `-WhatIf` by default with an explicit `-Commit`; test events are raised
only on disposable assets; every change has a documented rollback, and the **irreversible** actions (an
elapsed event-based deletion, a regulatory-record designation) are explicitly flagged as no-rollback and
gated on records/legal sign-off. Plan- and cloud-dependent behavior (event-based retention, records, the
`Compliance Asset Id` property, Government-cloud portal paths and cmdlet parameters) is flagged for tenant
verification rather than assumed. The result: obligations that the calendar cannot express are enforced from
the event — nothing kept forever by accident, nothing disposed too early — with the trigger validated and
the capability defensible.
