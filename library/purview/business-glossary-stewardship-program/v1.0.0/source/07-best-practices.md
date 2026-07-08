# 7. Best Practices — Business Glossary & Stewardship Program (Microsoft Purview)

Field-tested practices for a glossary that stays trustworthy. These are operational guidance, not
regulatory or records determinations — those remain with the business data owners, compliance,
records, privacy, and legal.

## Start with Critical Data Elements, not the whole dictionary
A glossary that tries to define everything on day one defines nothing well. Seed with **5–10 Critical
Data Elements** — the terms that are most contested, most reported-on, or most regulated (Customer,
Active Account, Revenue, Churn). Prove the cycle on those, then expand. Breadth without upkeep is how
glossaries die.

## Every term has one owner and one steward — no exceptions
The single biggest failure mode is the **unowned term**. Enforce that every Published term names a
**data owner** (accountable for meaning) and a **data steward** (accountable for upkeep). The
`DGGLOSS-Report.ps1` "unowned Published terms" count should be **zero**; treat any non-zero as a
defect, not a nuance.

## Draft first, publish on approval — never publish unreviewed
Keep new and changed terms in **Draft** until the owner approves. Publishing is an outward-facing act:
the business will build reports and decisions on a Published definition, so the approver gate is what
makes it safe. Use the workflow (or a documented manual approval) every time.

## Definitions are business language, links are the anchor
Write definitions in **plain business language** the whole organization understands — not a database
column description. Then **link** the term to the actual critical data elements / assets it describes
so the meaning is anchored to real data and lineage, not floating in prose.

## Separate the *definition* from the *determination*
The glossary records **what a term means to the business**. It does **not** decide the *regulatory
classification*, the *retention/records schedule*, or *who may access* the underlying data — those are
determinations owned by compliance, records, privacy, and legal. Keep that line bright: a steward
curates meaning; a governance function makes the legal/records call.

## Least-privilege governance roles, scoped to the domain
Assign governance domain owner / data owner / steward / reader at the **narrowest scope** (the
domain), and reserve account/tenant administration for a minimal named group. A steward should be able
to curate their domain's terms and nothing else. Re-verify role coverage with `DGGLOSS-Discovery.ps1`.

## Re-certification is the heartbeat — schedule it
A Published definition that is never re-reviewed silently drifts from reality. Set a
**re-certification interval** (quarterly is common), and run `DGGLOSS-Report.ps1` on a monthly cadence
to surface **stale** Published terms and retire superseded ones to **Expired**. An unmaintained
glossary is worse than none — people trust wrong definitions.

## Status hygiene: Draft → Review → Approved → Published → Expired
Use the status model consistently so the report is meaningful. **Expired** is a first-class outcome:
retiring a superseded term is good stewardship, not failure. Never delete history where the term was
relied upon — Expire it so past references still resolve.

## Automate the read paths, gate the writes
Use the read-only scripts (`Discovery`, `Set-Scope`, `Validate`, `Report`) freely and often — they
change nothing. Keep every write behind `-WhatIf` by default and an explicit `-Commit`, and **never**
put a secret in a script or a document; the scripts acquire a data-plane token from your interactive
Azure sign-in at runtime.

## Verify the evolving portal and API before you rely on a path
Purview Data Governance — governance domains, the Unified Catalog, approval workflows, data-plane API
versions — is **actively evolving**. Before you script or document a portal path or API version as
"the way", **verify it for your current tenant**. This solution cites the method and flags each
evolving surface; treat any specific path/version as "verify first".

## Make coverage visible to leadership
The stewardship program earns its keep when leadership can see progress: terms Published per domain,
percentage of CDEs defined and owned, and stale-term trend. Use `DGGLOSS-Report.ps1` output to build a
simple recurring coverage view so the program is funded and sustained.
