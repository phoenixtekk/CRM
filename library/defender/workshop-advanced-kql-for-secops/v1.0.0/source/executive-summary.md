# Executive Summary — Workshop: Advanced KQL for SecOps

## The problem

Every modern Microsoft security stack — Defender XDR, Defender for Endpoint, Defender for Office
365, and Microsoft Sentinel — runs on the same query language: **KQL (Kusto Query Language)**. It is
the difference between a SOC that can only read the alerts the vendor pre-built and a SOC that can
**ask its own questions of its own data**. Most teams that own these tools use them at a fraction of
their value, because the skill to drive them was never built:

- **Alert-limited hunting.** Analysts can triage what fires, but cannot pivot — "who else touched
  this host?", "what did this identity do in the hour before the alert?" — because they cannot write
  the join.
- **Copy-paste queries no one understands.** Teams paste hunting queries from the internet, cannot
  adapt them to their own tables, and cannot tell a good result from a false one.
- **No path from a hunt to a durable detection.** Even when someone finds something, the knowledge
  evaporates — it never becomes a saved query, a custom detection, or a workbook the whole team reuses.

## The solution

This is a **structured enablement workshop** — concepts, **guided hands-on labs**, a **take-home
runbook**, and a **knowledge-check** — that takes an admin or analyst from KQL fundamentals to
**advanced joins, aggregations, cross-table hunting, detection authoring, and workbooks** across
**Defender XDR advanced hunting and Microsoft Sentinel**. It is deliberately a **skills** product:

- **Teaches the language, not just the clicks** — the mental model of tables, operators, the tabular
  pipeline, and how the same KQL runs in both Defender advanced hunting and Sentinel logs.
- **Ships a real, runnable KQL lab pack** — a progressive query library (`WSKQL-Labs.kql`) learners
  execute in a safe, read-only sandbox and keep afterward as a starting library.
- **Ends in durable artifacts** — a shared saved-query set, an alert-only custom detection, and a
  workbook the learner builds and the team keeps.
- **Includes a knowledge-check** — so you can prove the skills landed, not just that the class happened.

## How it works

We follow the same repeatable model every solution in this program uses — **Assess → Configure →
Pilot → Validate → Expand** — reframed for enablement. We first confirm the learners and the tenant
are ready (advanced-hunting access, a Sentinel workspace where used), stand up a small, safe **lab
sandbox** and a learner **cohort group**, run the **guided labs** against real telemetry read-only,
**validate** the skills with a capstone and a knowledge-check, and then **expand** — folding the new
skills, saved queries, and detection into the live hunting and detection program.

The package ships as **self-guided, click-by-click documentation plus a runnable KQL lab pack and
four PowerShell helpers** that check readiness, run a chosen lab query read-only, score the
knowledge-check, and report cohort progress — all **read-only**, with **no credentials in code**.

## Why it matters

- **The team can ask its own questions** — pivot across endpoint, identity, email, and cloud tables
  instead of waiting for a pre-built alert.
- **Hunts become detections** — the workshop closes the loop from "I found something once" to a
  saved query, a custom detection, and a workbook the whole team reuses.
- **One language, every tool** — the same KQL skill pays off in Defender XDR *and* Sentinel, so the
  investment compounds across the stack.
- **A fraction of consulting cost** — the same field-tested method a Defender/Sentinel specialist
  would teach, delivered as a repeatable, tested runbook you keep and re-run for new hires.

## Important boundaries

This is a **skills / enablement** product — it teaches people to hunt and build detections. It is
**adjacent to, and deliberately does not duplicate**, the catalog's **Threat Hunting hunt-library**
solution (a curated, ongoing *hunt program* with a maintained query set and cadence) — this workshop
builds the **capability**; that product supplies and operates a **library**. It **cross-references
rather than repeats** the Defender XDR onboarding, Sentinel analytics/SOAR, and per-pillar
(Endpoint / Office 365 / Identity / Cloud Apps) solutions, which stand up the platforms this
workshop queries. It provides the **technical skill and the labs**, not the **decisions**: which
detections to promote to production, what counts as an acceptable false-positive rate, and every
production change are the customer's **security-operations calls**. KQL table and column names, and
which features are in preview or need a specific plan (e.g. Sentinel, Defender for Endpoint P2),
**evolve and can differ by cloud (Commercial vs GCC / GCC High)** — *verify current availability and
licensing in your tenant*.
