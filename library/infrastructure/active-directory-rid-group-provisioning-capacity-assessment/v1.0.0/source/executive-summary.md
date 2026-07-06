# Executive Summary

## The decision

Automated provisioning that creates several Active Directory security groups per project (typically a
Read, a Write, and a Privileged tier) can quietly raise a scalability question — and teams almost
always reach for the wrong worry. This assessment answers the question that actually matters:

> **Is the proposed group-provisioning model sustainable over the long term** — without RID
> exhaustion, directory-scalability problems, or unmanageable operational overhead?

The deliverable is an **architectural go/no-go with conditions of approval**, backed by measurements
from your own domain rather than guesswork.

## Why "will we run out of RIDs?" is the wrong first question

RIDs (Relative Identifiers) are the per-object component of every security principal's SID, drawn
from a **per-domain pool of ~1.07 billion** that the RID Master issues in blocks. Because deleted
objects never return their RIDs, consumption is cumulative — which is why a fast provisioning rate can
*look* alarming. But the arithmetic is decisive: a per-project group model adds only a few thousand
RIDs per year. Against a billion-plus pool — with a supported **extended pool** that doubles capacity
in reserve — the runway is measured in **thousands of years**, even under aggressive whole-organization
assumptions. **RID exhaustion is rarely the real risk.**

## The risks that actually matter

At scale, a proliferating per-project group model creates exposure elsewhere, and this assessment
measures each:

- **Kerberos token bloat** — every group a user belongs to rides in their logon token, which has a
  hard ceiling (~1,015 group SIDs) beyond which authentication fails. The exposure is
  **portfolio-spanning users and service accounts**, not average members.
- **Group sprawl and lifecycle debt** — with no deprovisioning, closed projects leave orphaned
  groups that inflate backups, replication, and audit scope, and erode least-privilege. Lifecycle
  automation is the single most important control.
- **Replication, backup, and administrative overhead** — modest but non-zero, and compounding if
  cleanup is absent.

It also reviews the **authorization architecture** (AGDLP, RBAC, nesting) so you either confirm the
model's shape or right-size it against Microsoft best practice.

## Business value

Instead of paying for a bespoke consulting engagement, a competent administrator or architect runs
this **self-guided, tested methodology** against their own directory and produces a defensible
decision: **RID lifetime projected, the real risks assessed, and a scalable design confirmed** — with
a reusable report and read-only PowerShell scripts kept for every future recertification. Approve or
redesign with evidence, before the model is switched on.
