# Executive Summary

**Outcome.** Microsoft Teams stops sprawling and comes under managed governance. Team/M365 Group creation
is restricted to approved creators, every team is named and classified to a standard, ownership is
enforced, and inactive teams are expired, retained, or archived on a defined lifecycle — with a repeatable
report that proves the posture on demand.

**The problem it solves.** Left open, Teams grows uncontrolled: anyone creates a team, duplicates
multiply, owners depart and are never replaced, and data ages indefinitely with no expiration or retention
decision behind it. The result is duplicate and orphaned teams, unclassified sensitive content, and an
estate no one can account for.

**Approach.** The solution establishes five native controls — **creation control**, **naming &
classification**, **membership/ownership standards**, **expiration + retention + archival**, and
**governance reporting** — all driven by PowerShell (Microsoft Graph, MicrosoftTeams, and Purview) with no
hardcoded secrets. It ships run-to-implement documentation plus five scripts: discovery/gap assessment,
creation+naming configuration, lifecycle (expiration/retention/archival) configuration, a governance
report, and a validation gate.

**Why it is low-risk.** Every change follows the house model — **Assess → Design → Configure → Pilot →
Validate → Expand**. Turning off open creation and enabling tenant-wide expiration are high-impact, so
every write script defaults to a **`-WhatIf` dry-run**, changes are applied **pilot-first** (expiration
scoped to selected groups before `All`), each stage has explicit **PASS/FAIL gates**, and a **documented
rollback** (re-enable creation, remove expiration, un-archive) is ready throughout. Licensing- and
cloud-dependent behavior (Entra ID P1, Purview plans, Government-cloud URLs) is flagged to verify rather
than assumed, and all **compliance determinations** — retention durations, records schedules, legal holds
— are deferred to the organization's compliance/records/legal functions, which own the decision while this
solution provides the technical method and evidence.

**Bottom line.** Teams that scale without chaos: creation governed, teams named and classified, ownership
enforced, and stale teams expired or archived — collaboration under control, with the evidence to prove it.
